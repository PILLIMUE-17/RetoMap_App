import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import 'buscar_amigos_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _tabActiva = 0;
  List<Map<String, dynamic>> _posts = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarFeed();
  }

  Future<void> _cargarFeed() async {
    setState(() => _cargando = true);
    final resp = await ApiService.get('/feed');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resp.ok && resp.data != null) {
        final items = resp.data['data'] as List? ?? [];
        _posts = items.map<Map<String, dynamic>>((p) => _mapPost(p)).toList();
      }
    });
  }

  Map<String, dynamic> _mapPost(Map<String, dynamic> p) {
    final usuario = p['usuario'] as Map<String, dynamic>? ?? {};
    final nombre = usuario['nombre'] as String? ?? 'Usuario';
    final userId = (usuario['id'] as num?)?.toInt() ?? 0;

    // Iniciales
    final palabras = nombre.trim().split(' ');
    final iniciales = palabras
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Gradiente basado en userId
    const gradientes = [
      [Color(0xFFFF6B35), Color(0xFFFF4D88)],
      [Color(0xFF9B59FF), Color(0xFF4DAAFF)],
      [Color(0xFF3DCB6B), Color(0xFF00D4AA)],
      [Color(0xFF4DAAFF), Color(0xFF9B59FF)],
      [Color(0xFFFFD93D), Color(0xFFFF9A5C)],
    ];
    final gradiente = gradientes[userId % gradientes.length];

    // Tiempo relativo
    final fechaStr = p['fecha'] as String? ?? '';
    final fecha = DateTime.tryParse(fechaStr);
    final tiempo = fecha != null ? _formatTiempo(fecha) : '';

    final reto = p['reto'] as Map<String, dynamic>?;
    const tagColors = [
      Color(0xFF3DCB6B),
      Color(0xFF4DAAFF),
      Color(0xFFFF6B35),
      Color(0xFF9B59FF),
      Color(0xFFFFD93D),
    ];

    return {
      'id': p['id'],
      'iniciales': iniciales.isEmpty ? '??' : iniciales,
      'gradiente': gradiente,
      'usuario': nombre,
      'avatar': usuario['avatar'],
      'tiempo': tiempo,
      'tag': reto?['nombre'] ?? 'Reto completado',
      'tagColor': tagColors[userId % tagColors.length],
      'emoji': '🏆',
      'imagen_url': p['imagen_url'],
      'lugar': reto?['lugar'] ?? '',
      'caption': p['caption'] as String? ?? '',
      'likes': (p['likes'] as num?)?.toInt() ?? 0,
      'comentarios': 0,
      'xp': (reto?['xp'] as num?)?.toInt() ?? 0,
      'yo_di_like': p['yo_di_like'] as bool? ?? false,
    };
  }

  String _formatTiempo(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    return 'hace ${diff.inDays ~/ 7} sem';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Feed de Retos',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('Global 🌍',
                  style:
                      TextStyle(fontSize: 11, color: Color(0xFF7878AA))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(children: [
            _Tab(
                texto: 'Para ti',
                activa: _tabActiva == 0,
                onTap: () => setState(() => _tabActiva = 0)),
            _Tab(
                texto: 'Amigos',
                activa: _tabActiva == 1,
                onTap: () => setState(() => _tabActiva = 1)),
            _Tab(
                texto: 'Trending',
                activa: _tabActiva == 2,
                onTap: () => setState(() => _tabActiva = 2)),
          ]),
        ),
        Expanded(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF6B35)))
              : _tabActiva == 1
                  ? _EstadoSinAmigos()
                  : _posts.isEmpty
                      ? _EstadoVacio(onRefresh: _cargarFeed)
                      : RefreshIndicator(
                          color: const Color(0xFFFF6B35),
                          backgroundColor: const Color(0xFF181828),
                          onRefresh: _cargarFeed,
                          child: Builder(builder: (context) {
                            final lista = _tabActiva == 2
                                ? (List<Map<String, dynamic>>.from(_posts)
                                  ..sort((a, b) =>
                                      (b['likes'] as int)
                                          .compareTo(a['likes'] as int)))
                                : _posts;
                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: lista.length,
                              itemBuilder: (_, i) =>
                                  _PostCard(post: lista[i]),
                            );
                          }),
                        ),
        ),
      ],
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EstadoVacio({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📰', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('El feed está vacío',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Completa retos para que aparezcan aquí',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Color(0xFF7878AA), height: 1.5)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text('Actualizar',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _EstadoSinAmigos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('👥', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Aún no tienes amigos',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text(
            'Agrega amigos para ver sus retos y competir con ellos',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Color(0xFF7878AA), height: 1.5),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BuscarAmigosScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text('🔍 Buscar amigos',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String texto;
  final bool activa;
  final VoidCallback onTap;
  const _Tab({required this.texto, required this.activa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: activa ? const Color(0x26FF6B35) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: activa
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF7878AA))),
      ),
    );
  }
}

class _PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late bool _liked;
  late int _likes;
  late int _comentarios;

  @override
  void initState() {
    super.initState();
    _liked = widget.post['yo_di_like'] as bool? ?? false;
    _likes = (widget.post['likes'] as num?)?.toInt() ?? 0;
    _comentarios = (widget.post['comentarios'] as num?)?.toInt() ?? 0;
  }

  Future<void> _toggleLike() async {
    final nuevoLike = !_liked;
    setState(() {
      _liked = nuevoLike;
      _likes += nuevoLike ? 1 : -1;
    });
    final id = widget.post['id'];
    if (id != null) {
      final resp = await ApiService.post('/publicaciones/$id/like', {});
      if (resp.ok && resp.data != null && mounted) {
        setState(() {
          _likes = (resp.data['total_likes'] as num?)?.toInt() ?? _likes;
          _liked = resp.data['yo_di_like'] as bool? ?? _liked;
        });
      }
    }
  }

  void _abrirComentarios() {
    final id = widget.post['id'];
    if (id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181828),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ComentariosSheet(
        pubId: id as int,
        onComentado: () => setState(() => _comentarios++),
      ),
    );
  }

  void _compartir() async {
    final post = widget.post;
    try {
      await Share.share(
        '¡Mira este reto completado en RetoMap!\n\n'
        '${post['usuario']} completó un reto en ${post['lugar']} '
        'y ganó +${post['xp']} XP 🔥\n\n'
        '${post['caption']}\n\n'
        'Descarga RetoMap y compite en tu ciudad 🌍',
        subject: 'Reto completado en RetoMap',
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final gradiente = post['gradiente'] as List<Color>;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181828),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 7),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: gradiente)),
              child: Center(
                child: Text(post['iniciales'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post['usuario'] as String,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(post['tiempo'] as String,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF7878AA))),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: (post['tagColor'] as Color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(post['tag'] as String,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: post['tagColor'] as Color)),
            ),
          ]),
        ),

        // Imagen o placeholder emoji
        _PostImagen(imagenUrl: post['imagen_url'] as String?, emoji: post['emoji'] as String),

        // Caption y acciones
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((post['lugar'] as String).isNotEmpty)
              Text('📍 ${post['lugar']}',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF00D4AA))),
            if ((post['caption'] as String).isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(post['caption'] as String,
                  style: const TextStyle(fontSize: 12, height: 1.5)),
            ],
            const SizedBox(height: 9),
            Row(children: [
              GestureDetector(
                onTap: _toggleLike,
                child: Row(children: [
                  Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: _liked
                        ? const Color(0xFFFF4D88)
                        : const Color(0xFF7878AA),
                  ),
                  const SizedBox(width: 4),
                  Text('$_likes',
                      style: TextStyle(
                          fontSize: 11,
                          color: _liked
                              ? const Color(0xFFFF4D88)
                              : const Color(0xFF7878AA))),
                ]),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _abrirComentarios,
                child: Row(children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 16, color: Color(0xFF7878AA)),
                  const SizedBox(width: 4),
                  Text('$_comentarios',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF7878AA))),
                ]),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _compartir,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.share_outlined,
                      size: 16, color: Color(0xFF7878AA)),
                ),
              ),
              const Spacer(),
              if ((post['xp'] as int) > 0)
                Text('⚡ +${post['xp']} XP',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFD93D))),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ── Sheet de comentarios ─────────────────────────────────────
class _ComentariosSheet extends StatefulWidget {
  final int pubId;
  final VoidCallback? onComentado;
  const _ComentariosSheet({required this.pubId, this.onComentado});

  @override
  State<_ComentariosSheet> createState() => _ComentariosSheetState();
}

class _ComentariosSheetState extends State<_ComentariosSheet> {
  List<Map<String, dynamic>> _comentarios = [];
  bool _cargando = true;
  bool _enviando = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final resp = await ApiService.get('/publicaciones/${widget.pubId}');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resp.ok && resp.data != null) {
        final items = resp.data['comentarios'] as List? ?? [];
        _comentarios = items
            .map<Map<String, dynamic>>((c) => c as Map<String, dynamic>)
            .toList();
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    final resp = await ApiService.post(
        '/publicaciones/${widget.pubId}/comentar', {'contenido': texto});
    if (!mounted) return;
    setState(() => _enviando = false);
    if (resp.ok) {
      _ctrl.clear();
      widget.onComentado?.call();
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 420,
        child: Column(children: [
          // Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Comentarios',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const Divider(color: Color(0x20FFFFFF), height: 16),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFFF6B35), strokeWidth: 2))
                : _comentarios.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('💬', style: TextStyle(fontSize: 32)),
                            SizedBox(height: 8),
                            Text('Sé el primero en comentar',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7878AA))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comentarios.length,
                        itemBuilder: (_, i) {
                          final c = _comentarios[i];
                          final user = c['usuario'] as Map<String, dynamic>? ?? {};
                          final nombre = user['nombre'] as String? ?? 'Usuario';
                          final palabras = nombre.trim().split(' ');
                          final ini = palabras
                              .take(2)
                              .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                              .join();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                        colors: [Color(0xFF9B59FF), Color(0xFFFF4D88)]),
                                  ),
                                  child: Center(
                                    child: Text(ini,
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(nombre,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700)),
                                      Text(c['contenido'] as String? ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xCCFFFFFF),
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0x20FFFFFF))),
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Escribe un comentario...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF7878AA), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E1E32),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _enviando ? null : _enviar,
                child: Container(
                  width: 38, height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
                  ),
                  child: _enviando
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PostImagen extends StatelessWidget {
  final String? imagenUrl;
  final String emoji;
  const _PostImagen({required this.imagenUrl, required this.emoji});

  @override
  Widget build(BuildContext context) {
    if (imagenUrl != null && imagenUrl!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 200,
        child: Image.network(
          imagenUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFF1E1E32),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFF6B35), strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stack) => Container(
            height: 200,
            color: const Color(0xFF1E1E32),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 175,
      color: const Color(0xFF1E1E32),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 56)),
      ),
    );
  }
}
