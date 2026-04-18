import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'mapa_screen.dart';
import 'feed_screen.dart';
import 'retos_screen.dart';
import 'perfil_screen.dart';
import 'notificaciones_screen.dart';
import '../estado_reto.dart';
import '../services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MapaScreen(),
    const FeedScreen(),
    const RetosScreen(),
    const PerfilScreen(),
  ];

  void _irA(int i) => setState(() => _currentIndex = i);

  // ── Subida de evidencia ──────────────────────────────────────
  Future<void> _subirEvidencia(ImageSource source) async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;

    // Mostrar loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: Color(0xFF181828),
        content: Padding(
          padding: EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFFFF6B35)),
            SizedBox(height: 16),
            Text('Subiendo evidencia...',
                style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
          ]),
        ),
      ),
    );

    try {
      // 1. Subir archivo
      final uploadResp = await ApiService.uploadEvidencia(picked.path);
      if (!uploadResp.ok) {
        if (mounted) Navigator.pop(context);
        _mostrarSnack('Error al subir imagen: ${uploadResp.mensaje}');
        return;
      }

      final evidenciaUrl = uploadResp.data['url'] as String;

      // 2. Completar el reto
      final retoId = EstadoReto.instancia.reto?['id'];
      if (retoId == null) {
        if (mounted) Navigator.pop(context);
        _mostrarSnack('Este reto no tiene ID del backend. Selecciona un reto real.');
        return;
      }

      final completarResp = await ApiService.post(
        '/retos/$retoId/completar',
        {'evidencia_url': evidenciaUrl},
      );

      if (mounted) Navigator.pop(context); // cerrar loading

      if (!completarResp.ok) {
        _mostrarSnack(completarResp.mensaje.isNotEmpty
            ? completarResp.mensaje
            : 'Error al completar el reto');
        return;
      }

      final xpGanado = completarResp.data?['xp_ganado']
          ?? EstadoReto.instancia.reto?['xp']
          ?? 0;

      // 3. Cancelar reto activo (ya completado)
      EstadoReto.instancia.cancelar();

      // 4. Mostrar éxito
      _mostrarExito('¡Reto completado! +$xpGanado XP 🎉');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _mostrarSnack('Error inesperado: $e');
    }
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFFFF4D4D),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF3DCB6B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  // ── Bottom sheet para subir evidencia ───────────────────────
  void _mostrarSubirEvidencia() {
    final estado = EstadoReto.instancia;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181828),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: const Color(0x40FFFFFF),
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 20),
            const Text('Subir evidencia',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),

            if (estado.tieneReto) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E32),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: const Color(0x40FF6B35)),
                ),
                child: Row(children: [
                  Text(estado.lugar!['emoji'] as String,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Subiendo evidencia para:',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.w800)),
                        Text(estado.reto!['nombre'] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(
                            '⚡ +${estado.reto!['xp']} XP  ·  ${estado.lugar!['nombre']}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF7878AA))),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: _BtnEvidencia(
                    icon: Icons.camera_alt_outlined,
                    label: 'Cámara',
                    color: const Color(0xFF4DAAFF),
                    onTap: () {
                      Navigator.pop(context);
                      _subirEvidencia(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BtnEvidencia(
                    icon: Icons.photo_library_outlined,
                    label: 'Galería',
                    color: const Color(0xFF9B59FF),
                    onTap: () {
                      Navigator.pop(context);
                      _subirEvidencia(ImageSource.gallery);
                    },
                  ),
                ),
              ]),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E32),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x20FFFFFF)),
                ),
                child: const Column(children: [
                  Text('📍', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 8),
                  Text('Primero acepta un reto',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                    'Ve al mapa, selecciona un lugar y acepta un reto para poder subir evidencia.',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF7878AA)),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RetoMapTopBar(),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF181828),
          border:
              Border(top: BorderSide(color: Color(0x14FFFFFF), width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.explore,
                    label: 'Mapa',
                    index: 0,
                    current: _currentIndex,
                    onTap: _irA),
                _NavItem(
                    icon: Icons.article,
                    label: 'Feed',
                    index: 1,
                    current: _currentIndex,
                    onTap: _irA),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _mostrarSubirEvidencia,
                  child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
                _NavItem(
                    icon: Icons.flash_on,
                    label: 'Retos',
                    index: 2,
                    current: _currentIndex,
                    onTap: _irA),
                _NavItem(
                    icon: Icons.person,
                    label: 'Perfil',
                    index: 3,
                    current: _currentIndex,
                    onTap: _irA),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.index,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activo = index == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: activo
                    ? const Color(0xFFFF6B35)
                    : const Color(0xFF7878AA),
                size: 26),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        activo ? FontWeight.w800 : FontWeight.w400,
                    color: activo
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF7878AA))),
          ],
        ),
      ),
    );
  }
}

class _BtnEvidencia extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _BtnEvidencia(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

// ── TopBar con datos reales ──────────────────────────────────
class RetoMapTopBar extends StatefulWidget implements PreferredSizeWidget {
  const RetoMapTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  State<RetoMapTopBar> createState() => _RetoMapTopBarState();
}

class _RetoMapTopBarState extends State<RetoMapTopBar> {
  int _xp = 0;
  int _racha = 0;
  int _noLeidas = 0;
  bool _gpsActivo = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final u = await ApiService.cargarUsuario();
    final contResp = await ApiService.get('/notificaciones/contador');
    final perm = await Geolocator.checkPermission();
    if (!mounted) return;
    setState(() {
      if (u != null) {
        _xp = (u['xp_total'] as num?)?.toInt() ?? 0;
        _racha = (u['racha_dias'] as num?)?.toInt() ?? 0;
      }
      if (contResp.ok && contResp.data != null) {
        _noLeidas = (contResp.data['no_leidas'] as num?)?.toInt() ?? 0;
      }
      _gpsActivo = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    });
  }

  @override
  Widget build(BuildContext context) {
    final xpLabel = _xp >= 1000
        ? '⚡ ${(_xp / 1000).toStringAsFixed(1)}k XP'
        : '⚡ $_xp XP';
    final rachaLabel = '🔥 $_racha día${_racha == 1 ? '' : 's'}';

    return AppBar(
      shape: const Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 1)),
      titleSpacing: 14,
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD93D), Color(0xFFFF6B35)],
            ).createShader(bounds),
            child: const Text('RetoMap',
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
          const Spacer(),
          _TopPill(
              texto: xpLabel,
              colorTexto: const Color(0xFFFFD93D),
              colorBorde: const Color(0x66FFD93D),
              colorFondo: const Color(0x1FFFD93D)),
          const SizedBox(width: 6),
          _TopPill(
              texto: rachaLabel,
              colorTexto: const Color(0xFFFF6B35),
              colorBorde: const Color(0x4DFF6B35),
              colorFondo: const Color(0x1AFF6B35)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              if (!_gpsActivo) {
                await Geolocator.requestPermission();
                _cargarDatos();
              }
            },
            child: _TopPill(
                texto: _gpsActivo ? '● GPS' : '○ GPS',
                colorTexto: _gpsActivo
                    ? const Color(0xFF3DCB6B)
                    : const Color(0xFF7878AA),
                colorBorde: _gpsActivo
                    ? const Color(0x663DCB6B)
                    : const Color(0x407878AA),
                colorFondo: _gpsActivo
                    ? const Color(0x1A3DCB6B)
                    : const Color(0x107878AA)),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificacionesScreen()),
              ).then((_) => _cargarDatos());
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Color(0xFF7878AA), size: 24),
                if (_noLeidas > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF4D4D),
                          shape: BoxShape.circle),
                      child: Text('$_noLeidas',
                          style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  final String texto;
  final Color colorTexto;
  final Color colorBorde;
  final Color colorFondo;
  const _TopPill(
      {required this.texto,
      required this.colorTexto,
      required this.colorBorde,
      required this.colorFondo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorBorde, width: 1),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colorTexto)),
    );
  }
}


