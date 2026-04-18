import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  List<Map<String, dynamic>> _notifs = [];
  bool _cargando = true;
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final resp = await ApiService.get('/notificaciones');
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (resp.ok && resp.data != null) {
        final data = resp.data['data'] as List? ?? [];
        _notifs = data.cast<Map<String, dynamic>>();
        _noLeidas = (resp.data['no_leidas'] as num?)?.toInt() ?? 0;
      }
    });
  }

  Future<void> _leerTodas() async {
    await ApiService.put('/notificaciones/leer-todas', {});
    _cargar();
  }

  Future<void> _leerUna(int id, int index) async {
    if (_notifs[index]['leida'] == true) return;
    await ApiService.put('/notificaciones/$id/leer', {});
    if (!mounted) return;
    setState(() {
      _notifs[index] = Map.from(_notifs[index])..['leida'] = true;
      _noLeidas = (_noLeidas - 1).clamp(0, 9999);
    });
  }

  Future<void> _eliminar(int id, int index) async {
    await ApiService.delete('/notificaciones/$id');
    if (!mounted) return;
    setState(() => _notifs.removeAt(index));
  }

  String _tiempoRelativo(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final fecha = DateTime.parse(fechaStr);
      final diff = DateTime.now().difference(fecha);
      if (diff.inMinutes < 1) return 'ahora';
      if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'hace ${diff.inHours} h';
      return 'hace ${diff.inDays} días';
    } catch (_) {
      return '';
    }
  }

  String _iconoTipo(String? tipo) {
    switch (tipo) {
      case 'like':
        return '❤️';
      case 'comentario':
        return '💬';
      case 'reto_completado':
        return '🏆';
      case 'nueva_insignia':
        return '🏅';
      case 'amistad':
        return '👋';
      default:
        return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Row(children: [
          const Text('Notificaciones',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          if (_noLeidas > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$_noLeidas',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ],
        ]),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
        actions: [
          if (_noLeidas > 0)
            TextButton(
              onPressed: _leerTodas,
              child: const Text('Leer todas',
                  style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : _notifs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔔', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('Sin notificaciones',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF7878AA))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF6B35),
                  backgroundColor: const Color(0xFF181828),
                  onRefresh: _cargar,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifs.length,
                    itemBuilder: (_, i) {
                      final n = _notifs[i];
                      final id = (n['id'] as num).toInt();
                      final leida = n['leida'] as bool? ?? false;
                      return Dismissible(
                        key: Key('notif_$id'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFFF4D4D),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white),
                        ),
                        onDismissed: (_) => _eliminar(id, i),
                        child: GestureDetector(
                          onTap: () => _leerUna(id, i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: leida
                                  ? Colors.transparent
                                  : const Color(0x0AFF6B35),
                              border: const Border(
                                  bottom: BorderSide(
                                      color: Color(0x10FFFFFF))),
                            ),
                            child: Row(children: [
                              if (!leida)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin:
                                      const EdgeInsets.only(right: 10),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFF6B35),
                                  ),
                                )
                              else
                                const SizedBox(width: 18),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  color: const Color(0xFF1E1E32),
                                ),
                                child: Center(
                                  child: Text(
                                      _iconoTipo(
                                          n['tipo'] as String?),
                                      style: const TextStyle(
                                          fontSize: 20)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        n['titulo'] as String? ?? '',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: leida
                                                ? FontWeight.w500
                                                : FontWeight.w800,
                                            color: Colors.white)),
                                    const SizedBox(height: 2),
                                    Text(
                                        n['cuerpo'] as String? ?? '',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                Color(0xFF7878AA))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  _tiempoRelativo(
                                      n['fecha'] as String?),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF7878AA))),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
