import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BuscarAmigosScreen extends StatefulWidget {
  const BuscarAmigosScreen({super.key});

  @override
  State<BuscarAmigosScreen> createState() => _BuscarAmigosScreenState();
}

class _BuscarAmigosScreenState extends State<BuscarAmigosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _busquedaCtrl = TextEditingController();

  // Búsqueda
  List<Map<String, dynamic>> _resultados = [];
  bool _buscando = false;
  bool _busquedaActiva = false;
  Timer? _debounce;

  // Solicitudes pendientes
  List<Map<String, dynamic>> _pendientes = [];
  bool _cargandoPendientes = true;

  // Mis amigos
  List<Map<String, dynamic>> _amigos = [];
  bool _cargandoAmigos = true;

  // Estado de solicitudes enviadas por mí
  final Map<int, String> _estadoSolicitud = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargarPendientes();
    _cargarAmigos();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _busquedaCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarPendientes() async {
    final resp = await ApiService.get('/amistades/pendientes');
    if (!mounted) return;
    setState(() {
      _cargandoPendientes = false;
      if (resp.ok && resp.data != null) {
        _pendientes = (resp.data['solicitudes'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      }
    });
  }

  Future<void> _cargarAmigos() async {
    final resp = await ApiService.get('/amistades');
    if (!mounted) return;
    setState(() {
      _cargandoAmigos = false;
      if (resp.ok && resp.data != null) {
        _amigos = (resp.data['amigos'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      }
    });
  }

  void _onBusquedaChanged(String texto) {
    _debounce?.cancel();
    if (texto.trim().isEmpty) {
      setState(() {
        _resultados = [];
        _busquedaActiva = false;
        _buscando = false;
      });
      return;
    }
    if (texto.trim().length < 2) return;
    setState(() => _busquedaActiva = true);
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _buscar(texto.trim()));
  }

  Future<void> _buscar(String q) async {
    setState(() => _buscando = true);
    final resp =
        await ApiService.get('/perfil/buscar?q=${Uri.encodeComponent(q)}');
    if (!mounted) return;
    setState(() {
      _buscando = false;
      if (resp.ok && resp.data != null) {
        final items =
            resp.data['data'] as List? ?? resp.data as List? ?? [];
        _resultados = items.cast<Map<String, dynamic>>();
      } else {
        _resultados = [];
      }
    });
  }

  Future<void> _solicitar(int userId) async {
    setState(() => _estadoSolicitud[userId] = 'enviando');
    final resp =
        await ApiService.post('/amistades/solicitar/$userId', {});
    if (!mounted) return;
    setState(() => _estadoSolicitud[userId] = resp.ok ? 'enviada' : 'error');
    if (!resp.ok) {
      _snack(
          resp.mensaje.isNotEmpty ? resp.mensaje : 'Error al enviar solicitud',
          error: true);
    }
  }

  Future<void> _aceptar(int amistadId) async {
    final resp =
        await ApiService.put('/amistades/$amistadId/aceptar', {});
    if (!mounted) return;
    if (resp.ok) {
      _snack('¡Ahora son amigos!');
      _cargarPendientes();
      _cargarAmigos();
    } else {
      _snack('Error al aceptar solicitud', error: true);
    }
  }

  Future<void> _rechazar(int amistadId) async {
    await ApiService.delete('/amistades/$amistadId/rechazar');
    if (!mounted) return;
    _cargarPendientes();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor:
          error ? const Color(0xFFFF4D4D) : const Color(0xFF3DCB6B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pendCount = _pendientes.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        title: const Text('Amigos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        bottom: _busquedaActiva
            ? null
            : TabBar(
                controller: _tabCtrl,
                indicatorColor: const Color(0xFFFF6B35),
                labelColor: const Color(0xFFFF6B35),
                unselectedLabelColor: const Color(0xFF7878AA),
                labelStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w800),
                tabs: [
                  Tab(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Solicitudes'),
                          if (pendCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4D),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('$pendCount',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                            ),
                          ],
                        ]),
                  ),
                  const Tab(text: 'Mis amigos'),
                ],
              ),
      ),
      body: Column(children: [
        // ── Barra de búsqueda siempre visible ──────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _busquedaCtrl,
            onChanged: _onBusquedaChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o @usuario...',
              hintStyle: const TextStyle(
                  color: Color(0xFF7878AA), fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: Color(0xFF7878AA), size: 20),
              suffixIcon: _busquedaCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close,
                          color: Color(0xFF7878AA), size: 18),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _resultados = [];
                          _busquedaActiva = false;
                          _buscando = false;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF181828),
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0x20FFFFFF))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0x20FFFFFF))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFFF6B35), width: 1.5)),
            ),
          ),
        ),

        // ── Contenido: resultados O tabs ───────────────
        Expanded(
          child: _busquedaActiva
              ? _buildResultados()
              : TabBarView(
                  controller: _tabCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSolicitudes(),
                    _buildAmigos(),
                  ],
                ),
        ),
      ]),
    );
  }

  // ── Resultados de búsqueda ──────────────────────────
  Widget _buildResultados() {
    if (_buscando) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFFF6B35), strokeWidth: 2));
    }
    if (_resultados.isEmpty) {
      return const _EstadoVacio(
        emoji: '🔍',
        titulo: 'Sin resultados',
        subtitulo: 'No encontramos usuarios con ese nombre o @usuario',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _resultados.length,
      itemBuilder: (_, i) {
        final u = _resultados[i];
        final uid = (u['id'] as num?)?.toInt() ?? 0;
        return _UsuarioCard(
          usuario: u,
          estado: _estadoSolicitud[uid] ?? 'ninguno',
          onAgregar: () => _solicitar(uid),
        );
      },
    );
  }

  // ── Tab Solicitudes ─────────────────────────────────
  Widget _buildSolicitudes() {
    if (_cargandoPendientes) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFFF6B35), strokeWidth: 2));
    }
    if (_pendientes.isEmpty) {
      return const _EstadoVacio(
        emoji: '📬',
        titulo: 'Sin solicitudes',
        subtitulo: 'Cuando alguien te envíe una solicitud aparecerá aquí',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF6B35),
      backgroundColor: const Color(0xFF181828),
      onRefresh: _cargarPendientes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendientes.length,
        itemBuilder: (_, i) {
          final s = _pendientes[i];
          final amistadId = (s['id'] as num?)?.toInt() ?? 0;
          final user =
              s['solicitante'] as Map<String, dynamic>? ?? {};
          final nombre = user['nombre'] as String? ?? 'Usuario';
          final username = user['username'] as String? ?? '';
          final ciudad = user['ciudad'] as String? ?? '';
          final ini = _iniciales(nombre);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF181828),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(children: [
              _Avatar(iniciales: ini, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '@$username${ciudad.isNotEmpty ? '  ·  $ciudad' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7878AA))),
                    ]),
              ),
              Row(children: [
                GestureDetector(
                  onTap: () => _rechazar(amistadId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x15FF4D4D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0x40FF4D4D)),
                    ),
                    child: const Text('Rechazar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4D4D))),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _aceptar(amistadId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFF6B35),
                        Color(0xFFFF4D88)
                      ]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Aceptar',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── Tab Mis amigos ──────────────────────────────────
  Widget _buildAmigos() {
    if (_cargandoAmigos) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFFF6B35), strokeWidth: 2));
    }
    if (_amigos.isEmpty) {
      return const _EstadoVacio(
        emoji: '👥',
        titulo: 'Aún no tienes amigos',
        subtitulo: 'Busca usuarios arriba y envíales una solicitud',
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFFF6B35),
      backgroundColor: const Color(0xFF181828),
      onRefresh: _cargarAmigos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _amigos.length,
        itemBuilder: (_, i) {
          final u = _amigos[i];
          final nombre = u['nombre_usuario'] as String? ??
              u['nombre'] as String? ??
              'Usuario';
          final username = u['username_usuario'] as String? ??
              u['username'] as String? ??
              '';
          final ciudad = u['ciudad_usuario'] as String? ??
              u['ciudad'] as String? ??
              '';
          final xp = (u['xp_total_usuario'] as num? ??
                  u['xp_total'] as num?)
              ?.toInt() ??
              0;
          final ini = _iniciales(nombre);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF181828),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(children: [
              _Avatar(iniciales: ini, size: 44),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(
                          '@$username${ciudad.isNotEmpty ? '  ·  $ciudad' : ''}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7878AA))),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFD93D),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: const Color(0x66FFD93D)),
                ),
                child: Text(
                    '⚡ ${xp >= 1000 ? '${(xp / 1000).toStringAsFixed(1)}k' : '$xp'} XP',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFD93D))),
              ),
            ]),
          );
        },
      ),
    );
  }

  String _iniciales(String nombre) {
    final palabras = nombre.trim().split(' ');
    return palabras
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();
  }
}

// ── Widgets auxiliares ─────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  const _EstadoVacio(
      {required this.emoji,
      required this.titulo,
      required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(titulo,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF7878AA),
                  height: 1.5)),
        ]),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String iniciales;
  final double size;
  const _Avatar({required this.iniciales, required this.size});

  static const _gradientes = [
    [Color(0xFFFF6B35), Color(0xFFFF4D88)],
    [Color(0xFF9B59FF), Color(0xFF4DAAFF)],
    [Color(0xFF3DCB6B), Color(0xFF00D4AA)],
    [Color(0xFF4DAAFF), Color(0xFF9B59FF)],
    [Color(0xFFFFD93D), Color(0xFFFF9A5C)],
  ];

  @override
  Widget build(BuildContext context) {
    final idx = iniciales.isNotEmpty
        ? iniciales.codeUnitAt(0) % _gradientes.length
        : 0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: _gradientes[idx]),
      ),
      child: Center(
        child: Text(
          iniciales.isEmpty ? '?' : iniciales,
          style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              color: Colors.white),
        ),
      ),
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final String estado;
  final VoidCallback onAgregar;
  const _UsuarioCard(
      {required this.usuario,
      required this.estado,
      required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final nombre =
        usuario['nombre_usuario'] as String? ?? 'Usuario';
    final username =
        usuario['username_usuario'] as String? ?? '';
    final ciudad =
        usuario['ciudad_usuario'] as String? ?? '';
    final xp =
        (usuario['xp_total_usuario'] as num?)?.toInt() ?? 0;
    final palabras = nombre.trim().split(' ');
    final ini = palabras
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181828),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(children: [
        _Avatar(iniciales: ini, size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                    '@$username${ciudad.isNotEmpty ? '  ·  $ciudad' : ''}',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF7878AA))),
                const SizedBox(height: 2),
                Text(
                  '⚡ ${xp >= 1000 ? '${(xp / 1000).toStringAsFixed(1)}k' : '$xp'} XP',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFD93D)),
                ),
              ]),
        ),
        _BtnAgregar(estado: estado, onTap: onAgregar),
      ]),
    );
  }
}

class _BtnAgregar extends StatelessWidget {
  final String estado;
  final VoidCallback onTap;
  const _BtnAgregar({required this.estado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (estado == 'enviada') {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x1A3DCB6B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x663DCB6B)),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check, size: 13, color: Color(0xFF3DCB6B)),
          SizedBox(width: 4),
          Text('Enviada',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3DCB6B))),
        ]),
      );
    }
    if (estado == 'enviando') {
      return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              color: Color(0xFFFF6B35), strokeWidth: 2));
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.person_add_outlined,
              size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('Agregar',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ]),
      ),
    );
  }
}
