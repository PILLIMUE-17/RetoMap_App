import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'editar_perfil_screen.dart';
import 'ranking_screen.dart';
import '../services/api_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _perfil;
  int _xpSiguiente = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final results = await Future.wait([
      ApiService.get('/perfil'),
      ApiService.get('/ranking/mi-posicion'),
    ]);

    if (!mounted) return;

    final respPerfil = results[0];
    final respRanking = results[1];

    setState(() {
      _cargando = false;
      if (respPerfil.ok && respPerfil.data != null) {
        _perfil = respPerfil.data['perfil'] as Map<String, dynamic>;
      }
      if (respRanking.ok && respRanking.data != null) {
        _xpSiguiente =
            (respRanking.data['xp_siguiente_nivel'] as num?)?.toInt() ?? 0;
      }
    });
  }

  Future<void> _cerrarSesion() async {
    await ApiService.post('/logout', {});
    await ApiService.borrarToken();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _confirmarCerrarSesion() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('¿Cerrar sesión?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const Text('Se cerrará tu sesión en este dispositivo.',
            style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style:
                    TextStyle(color: Color(0xFF7878AA), fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cerrarSesion();
            },
            child: const Text('Cerrar sesión',
                style:
                    TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    final p = _perfil;
    final nombre = p?['nombre'] as String? ?? 'Usuario';
    final username = p?['username'] as String? ?? '';
    final ciudad = p?['ciudad'] as String? ?? '';
    final xp = (p?['xp_total'] as num?)?.toInt() ?? 0;
    final racha = (p?['racha_dias'] as num?)?.toInt() ?? 0;
    final nivel = p?['nivel'] as String? ?? 'Principiante';
    final posicion = (p?['posicion_ranking'] as num?)?.toInt() ?? 0;
    final stats = p?['estadisticas'] as Map<String, dynamic>? ?? {};
    final retosCompletados = (stats['retos_completados'] as num?)?.toInt() ?? 0;
    final insignias = p?['insignias'] as List? ?? [];

    // Iniciales del nombre
    final palabras = nombre.split(' ');
    final iniciales = palabras
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Nivel progress
    final xpSig = _xpSiguiente > 0 ? _xpSiguiente : (xp + 500);
    final progress = (xp / xpSig).clamp(0.0, 1.0);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Hero ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x409B59FF), Color(0x000D0D1A)],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF9B59FF), Color(0xFFFF4D88)]),
                    border: Border.all(color: const Color(0xFFFFD93D), width: 3),
                  ),
                  child: Center(
                    child: Text(iniciales,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(nombre,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  '@$username  ·  $ciudad',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF7878AA)),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final actualizado = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditarPerfilScreen(perfil: p ?? {})),
                    );
                    if (actualizado == true) _cargarPerfil();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x20FF6B35),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0x60FF6B35)),
                    ),
                    child: const Text('Editar perfil',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF6B35))),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Stat(valor: '$retosCompletados', label: 'Retos'),
                    const SizedBox(width: 28),
                    _Stat(
                        valor: xp >= 1000
                            ? '${(xp / 1000).toStringAsFixed(1)}k'
                            : '$xp',
                        label: 'XP'),
                    const SizedBox(width: 28),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RankingScreen())),
                      child: _Stat(valor: '#$posicion', label: 'Ranking'),
                    ),
                    const SizedBox(width: 28),
                    _Stat(valor: '$racha días', label: 'Racha'),
                  ],
                ),
              ],
            ),
          ),

          // ── Barra de nivel ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(nivel,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF7878AA))),
                    Text('$xp / $xpSig XP',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFFD93D),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFF2A2A40),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6B35)),
                  ),
                ),
              ],
            ),
          ),

          // ── Insignias ───────────────────────────────────
          if (insignias.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('INSIGNIAS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7878AA),
                        letterSpacing: 0.8)),
              ),
            ),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: insignias.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final b = insignias[i] as Map<String, dynamic>;
                  const color = Color(0xFFFFD700);
                  return Column(children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Center(
                        child: Text(b['icono'] as String? ?? '🏅',
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(b['nombre'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFF7878AA))),
                  ]);
                },
              ),
            ),
          ] else
            const _InsigniasPlaceholder(),

          // ── Fotos de retos reales ─────────────────────
          _FotosRetos(userId: (p?['id'] as num?)?.toInt() ?? 0),

          // ── Botón cerrar sesión ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GestureDetector(
              onTap: _confirmarCerrarSesion,
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  color: const Color(0x15FF4D4D),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x40FF4D4D), width: 1.5),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFFF4D4D), size: 18),
                    SizedBox(width: 8),
                    Text('Cerrar sesión',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF4D4D))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String valor;
  final String label;
  const _Stat({required this.valor, required this.label});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD93D))),
        Text(label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7878AA))),
      ]);
}

class _InsigniasPlaceholder extends StatelessWidget {
  const _InsigniasPlaceholder();

  static const _badges = [
    {'emoji': '🔒', 'nombre': '???', 'color': Color(0xFF333333)},
    {'emoji': '🔒', 'nombre': '???', 'color': Color(0xFF333333)},
    {'emoji': '🔒', 'nombre': '???', 'color': Color(0xFF333333)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Text('INSIGNIAS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7878AA),
                letterSpacing: 0.8)),
      ),
      SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _badges.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final b = _badges[i];
            final color = b['color'] as Color;
            return Column(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                    child: Text(b['emoji'] as String,
                        style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(height: 4),
              Text(b['nombre'] as String,
                  style:
                      const TextStyle(fontSize: 9, color: Color(0xFF7878AA))),
            ]);
          },
        ),
      ),
    ]);
  }
}

class _FotosRetos extends StatefulWidget {
  final int userId;
  const _FotosRetos({required this.userId});

  @override
  State<_FotosRetos> createState() => _FotosRetosState();
}

class _FotosRetosState extends State<_FotosRetos> {
  List<Map<String, dynamic>> _pubs = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (widget.userId == 0) {
      setState(() => _cargando = false);
      return;
    }
    final resp = await ApiService.get('/publicaciones/usuario/${widget.userId}');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resp.ok && resp.data != null) {
        final items = resp.data['data'] as List? ?? resp.data as List? ?? [];
        _pubs = items
            .take(9)
            .map<Map<String, dynamic>>((p) => p as Map<String, dynamic>)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Text('FOTOS DE RETOS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7878AA),
                letterSpacing: 0.8)),
      ),
      if (_cargando)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFF6B35), strokeWidth: 2)),
        )
      else if (_pubs.isEmpty)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Center(
            child: Column(children: [
              Text('📷', style: TextStyle(fontSize: 32)),
              SizedBox(height: 8),
              Text('Aún no has completado retos con foto',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7878AA))),
            ]),
          ),
        )
      else
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            children: _pubs.map((pub) {
              final url = pub['imagen_url'] as String?;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: const Color(0xFF1E1E32),
                          child: const Center(
                              child: Text('🏆',
                                  style: TextStyle(fontSize: 24))),
                        ),
                      )
                    : Container(
                        color: const Color(0xFF1E1E32),
                        child: const Center(
                            child:
                                Text('🏆', style: TextStyle(fontSize: 24))),
                      ),
              );
            }).toList(),
          ),
        ),
    ]);
  }
}


