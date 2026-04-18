import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../estado_reto.dart';
import '../services/api_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  String _filtro = 'all';
  Map<String, dynamic>? _lugarSeleccionado;
  Map<String, dynamic>? _retoActivo;
  Map<String, dynamic>? _lugarActivo;
  List<LatLng> _rutaPuntos = [];
  LatLng? _miUbicacion;
  bool _buscandoUbicacion = false;
  bool _cargandoRetos = false;
  final _mapController = MapController();

  // Centro del mapa — Neiva, Huila
  static final _centro = LatLng(2.9273, -75.2892);

  // Lugares con datos (inicialmente hardcoded, reemplazados por API)
  List<Map<String, dynamic>> _lugares = <Map<String, dynamic>>[];

  // Datos hardcoded como respaldo si el API falla
  static final _lugaresFallback = <Map<String, dynamic>>[
    {
      'lat': 2.9262767, 'lng': -75.2892111,
      'nombre': 'Parque Central Santander',
      'type': 'parque', 'emoji': '🌳',
      'color': const Color(0xFF3DCB6B),
      'retos': [
        {'nombre': 'El Rey del Parque', 'xp': 80, 'desc': 'Toma una foto con la fuente y la Catedral de fondo.'},
        {'nombre': 'Contador de palomas', 'xp': 50, 'desc': 'Graba 15 segundos contando las palomas del parque.'},
      ],
    },
    {
      'lat': 2.927085, 'lng': -75.295662,
      'nombre': 'Malecón Río Magdalena',
      'type': 'parque', 'emoji': '🌊',
      'color': const Color(0xFF00D4AA),
      'retos': [
        {'nombre': 'Caminata al Magdalena', 'xp': 100, 'desc': 'Selfie con el río de fondo. Bonus si hay una canoa.'},
        {'nombre': 'Atardecer huilense', 'xp': 150, 'desc': 'Foto del atardecer antes de las 6pm.'},
      ],
    },
    {
      'lat': 2.925932, 'lng': -75.284409,
      'nombre': 'El Patio Casa Cultural',
      'type': 'rest', 'emoji': '🍽️',
      'color': const Color(0xFFFF9A5C),
      'retos': [
        {'nombre': 'Gourmet Huilense', 'xp': 90, 'desc': 'Fotografía la presentación del plato especial.'},
      ],
    },
    {
      'lat': 2.9279347, 'lng': -75.2897868,
      'nombre': 'Penelope Waffles',
      'type': 'rest', 'emoji': '🧇',
      'color': const Color(0xFFFF6B35),
      'retos': [
        {'nombre': 'El Waffle Perfecto', 'xp': 60, 'desc': 'Foto artística de tu waffle desde arriba (flat lay).'},
      ],
    },
    {
      'lat': 2.9507459, 'lng': -75.2884085,
      'nombre': 'San Pedro Plaza',
      'type': 'mall', 'emoji': '🏬',
      'color': const Color(0xFF4DAAFF),
      'retos': [
        {'nombre': 'Cazador de ofertas', 'xp': 70, 'desc': 'Encuentra el item más barato pero más cool del mall.'},
      ],
    },
    {
      'lat': 2.9618835, 'lng': -75.293392,
      'nombre': 'UNICO Outlet Neiva',
      'type': 'mall', 'emoji': '🛍️',
      'color': const Color(0xFF9B59FF),
      'retos': [
        {'nombre': 'Descuento épico', 'xp': 90, 'desc': 'Encuentra una oferta mayor al 50%.'},
      ],
    },
    {
      'lat': 2.9305157, 'lng': -75.2841344,
      'nombre': 'Tulum Neiva',
      'type': 'noche', 'emoji': '🌙',
      'color': const Color(0xFF9B59FF),
      'retos': [
        {'nombre': 'Cóctel artístico', 'xp': 80, 'desc': 'Fotografía tu cóctel con la decoración del lugar.'},
      ],
    },
    {
      'lat': 2.9317115, 'lng': -75.2912643,
      'nombre': 'Mayté Discoteca',
      'type': 'noche', 'emoji': '🎵',
      'color': const Color(0xFFFF4D88),
      'retos': [
        {'nombre': 'Pista Reina', 'xp': 150, 'desc': 'Graba 10 segundos en la pista mostrando tu mejor move.'},
      ],
    },
    {
      'lat': 2.9372925, 'lng': -75.2933916,
      'nombre': 'Museo Arte Contemporáneo',
      'type': 'parque', 'emoji': '🎨',
      'color': const Color(0xFFFFD93D),
      'retos': [
        {'nombre': 'Crítico de Arte', 'xp': 100, 'desc': 'Graba una mini reseña de 15 segundos de tu obra favorita.'},
      ],
    },
  ];

  List<Map<String, dynamic>> get _lugaresFiltrados =>
      _filtro == 'all' ? _lugares : _lugares.where((l) => l['type'] == _filtro).toList();

  @override
  void initState() {
    super.initState();
    _lugares = List.from(_lugaresFallback);
    _cargarLugaresAPI();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── Carga lugares desde el API ───────────────────────────────
  Future<void> _cargarLugaresAPI() async {
    final resp = await ApiService.get('/lugares?per_page=50');
    if (!resp.ok || resp.data == null) return;

    final items = resp.data['data'] as List? ?? [];
    if (items.isEmpty) return;

    final nuevos = items.map<Map<String, dynamic>>((l) {
      final cat = l['categoria'] as Map<String, dynamic>? ?? {};
      return {
        'id': l['id'],
        'lat': (l['latitud'] as num).toDouble(),
        'lng': (l['longitud'] as num).toDouble(),
        'nombre': l['nombre'] as String? ?? '',
        'type': _categoriaAType(cat['nombre'] as String? ?? ''),
        'emoji': cat['icono'] as String? ?? '📍',
        'color': _hexColor(cat['color'] as String?),
        'retos': <Map<String, dynamic>>[],
      };
    }).toList();

    if (mounted) setState(() => _lugares = nuevos);
  }

  // ── Carga retos de un lugar específico ───────────────────────
  Future<void> _cargarRetosLugar(Map<String, dynamic> lugar) async {
    final id = lugar['id'];
    if (id == null) return; // lugar hardcoded sin ID
    final retos = lugar['retos'] as List;
    if (retos.isNotEmpty) return; // ya cargados

    setState(() => _cargandoRetos = true);

    final resp = await ApiService.get('/lugares/$id');

    if (!mounted) return;
    setState(() => _cargandoRetos = false);

    if (!resp.ok || resp.data == null) return;

    final retosRaw = resp.data['lugar']?['retos'] as List? ?? [];
    final retosConv = retosRaw.map<Map<String, dynamic>>((r) => {
          'id': r['id'],
          'nombre': r['nombre'] as String? ?? '',
          'xp': (r['xp'] as num?)?.toInt() ?? 0,
          'desc': r['descripcion'] as String? ?? '',
        }).toList();

    // Actualizar lugar en la lista
    final idx = _lugares.indexOf(lugar);
    if (idx != -1) {
      setState(() => _lugares[idx]['retos'] = retosConv);
      // Actualizar referencia del lugar seleccionado
      if (_lugarSeleccionado?['id'] == id) {
        setState(() => _lugarSeleccionado = _lugares[idx]);
      }
    }
  }

  Color _hexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF7878AA);
    final h = hex.replaceAll('#', '');
    final full = h.length == 6 ? 'FF$h' : h;
    return Color(int.tryParse(full, radix: 16) ?? 0xFF7878AA);
  }

  String _categoriaAType(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('rest') || n.contains('food') || n.contains('gastro') ||
        n.contains('caf') || n.contains('pizza') || n.contains('waf')) {
      return 'rest';
    }
    if (n.contains('mall') || n.contains('comercial') || n.contains('compra') ||
        n.contains('tienda') || n.contains('outlet')) {
      return 'mall';
    }
    if (n.contains('bar') || n.contains('noche') || n.contains('disco') ||
        n.contains('club') || n.contains('tulum') || n.contains('may')) {
      return 'noche';
    }
    return 'parque';
  }

  void _mostrarMensaje(String msg, {VoidCallback? accion}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: const Color(0xFF9B59FF),
        action: accion != null
            ? SnackBarAction(
                label: 'Activar',
                textColor: Colors.white,
                onPressed: accion,
              )
            : null,
      ));
  }

  Future<void> _obtenerUbicacion() async {
    if (_buscandoUbicacion) return;
    setState(() => _buscandoUbicacion = true);

    try {
      final activo = await Geolocator.isLocationServiceEnabled();
      if (!activo) {
        if (mounted) setState(() => _buscandoUbicacion = false);
        _mostrarMensaje('No tienes el GPS activado',
            accion: () => Geolocator.openLocationSettings());
        return;
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied) {
        if (mounted) setState(() => _buscandoUbicacion = false);
        _mostrarMensaje('Permiso de ubicación denegado');
        return;
      }
      if (permiso == LocationPermission.deniedForever) {
        if (mounted) setState(() => _buscandoUbicacion = false);
        _mostrarMensaje('Permiso bloqueado — ábrelo en ajustes',
            accion: () => Geolocator.openAppSettings());
        return;
      }

      // Usar posición rápida si está disponible y terminar
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          _miUbicacion = LatLng(lastKnown.latitude, lastKnown.longitude);
          _buscandoUbicacion = false;
        });
        _mapController.move(_miUbicacion!, 16.0);
        return; // Ya tenemos posición, no necesitamos getCurrentPosition
      }

      // Solo si no hay posición conocida, pedir posición fresca
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _miUbicacion = LatLng(pos.latitude, pos.longitude);
          _buscandoUbicacion = false;
        });
        _mapController.move(_miUbicacion!, 16.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _buscandoUbicacion = false);
        // Solo mostrar error si no tenemos ya una posición
        if (_miUbicacion == null) {
          _mostrarMensaje('No se pudo obtener tu ubicación');
        }
      }
    }
  }

  void _centrarEnMi() {
    if (_miUbicacion != null) {
      _mapController.move(_miUbicacion!, 16.0);
    } else {
      _obtenerUbicacion();
    }
  }

  Future<void> _calcularRuta(LatLng origen, LatLng destino) async {
    // Línea recta como fallback inmediato
    if (mounted) setState(() => _rutaPuntos = [origen, destino]);

    try {
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
        '${origen.longitude},${origen.latitude};'
        '${destino.longitude},${destino.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return;

      final coords = (routes[0]['geometry']['coordinates'] as List)
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();

      if (mounted) setState(() => _rutaPuntos = coords);
    } catch (_) {
      // Mantiene la línea recta si OSRM falla
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Mapa de fondo ───────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centro,
            initialZoom: 15.0,
            onTap: (_, _) => setState(() => _lugarSeleccionado = null),
          ),
          children: [
            // Tiles oscuros de CartoDB
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.retomap.app',
            ),
            // Pines de los lugares
            MarkerLayer(
              markers: _lugaresFiltrados.map((lugar) {
                final color = lugar['color'] as Color;
                final seleccionado = _lugarSeleccionado?['nombre'] == lugar['nombre'];
                return Marker(
                  point: LatLng(lugar['lat'] as double, lugar['lng'] as double),
                  width: seleccionado ? 50 : 40,
                  height: seleccionado ? 50 : 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _lugarSeleccionado = lugar);
                      _cargarRetosLugar(lugar);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.85),
                        border: Border.all(
                          color: seleccionado ? Colors.white : Colors.white.withValues(alpha: 0.3),
                          width: seleccionado ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: seleccionado ? 0.7 : 0.4),
                            blurRadius: seleccionado ? 16 : 8,
                            spreadRadius: seleccionado ? 3 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(lugar['emoji'] as String,
                            style: TextStyle(fontSize: seleccionado ? 22 : 18)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Ruta por carreteras al reto activo
            if (_rutaPuntos.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _rutaPuntos,
                    color: const Color(0xFF4DAAFF),
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            // Punto de mi ubicación (encima de los pines)
            if (_miUbicacion != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _miUbicacion!,
                    width: 28, height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF4DAAFF).withValues(alpha: 0.25),
                      ),
                      child: Center(
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4DAAFF),
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4DAAFF).withValues(alpha: 0.6),
                                blurRadius: 10, spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ── Filtros en la parte superior ────────────────
        Positioned(
          top: 10, left: 0, right: 0,
          child: _BarraFiltros(
            filtroActivo: _filtro,
            onFiltrar: (f) => setState(() {
              _filtro = f;
              _lugarSeleccionado = null;
            }),
          ),
        ),

        // ── Panel inferior con lugares cercanos ──────────
        // Solo se muestra si no hay lugar seleccionado
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          bottom: _lugarSeleccionado == null ? 0 : -200,
          left: 0, right: 0,
          child: _PanelCercanos(
            lugares: _lugaresFiltrados,
            onSeleccionar: (l) {
              setState(() => _lugarSeleccionado = l);
              _cargarRetosLugar(l);
            },
          ),
        ),

        // ── Botón centrar en mi ubicación (debajo de los filtros) ──
        Positioned(
          top: 54,
          right: 12,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_buscandoUbicacion) _centrarEnMi();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _buscandoUbicacion
                    ? const Color(0xFF1E1E32)
                    : const Color(0xFF181828),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _miUbicacion != null
                      ? const Color(0xFF4DAAFF)
                      : const Color(0x50FFFFFF),
                  width: 1.5,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: _buscandoUbicacion
                  ? const Padding(
                      padding: EdgeInsets.all(11),
                      child: CircularProgressIndicator(
                          color: Color(0xFF4DAAFF), strokeWidth: 2.5),
                    )
                  : Icon(
                      Icons.my_location,
                      color: _miUbicacion != null
                          ? const Color(0xFF4DAAFF)
                          : Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ),

        // ── Banner de reto activo ────────────────────────
        if (_retoActivo != null && _lugarActivo != null)
          Positioned(
            bottom: 148, left: 12, right: 12,
            child: _BannerRetoActivo(
              reto: _retoActivo!,
              lugar: _lugarActivo!,
              onCancelar: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: const Color(0xFF181828),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Text('¿Cancelar reto?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  content: const Text(
                    'Perderás el progreso de este reto. ¿Seguro que quieres cancelarlo?',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7878AA)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Seguir con el reto',
                          style: TextStyle(color: Color(0xFF7878AA), fontWeight: FontWeight.w700)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _retoActivo = null;
                          _lugarActivo = null;
                          _rutaPuntos = [];
                        });
                        EstadoReto.instancia.cancelar();
                      },
                      child: const Text('Cancelar reto',
                          style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // ── Dim + Panel de detalle del lugar ────────────
        if (_lugarSeleccionado != null) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _lugarSeleccionado = null),
              child: Container(color: Colors.black45),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _PanelDetalle(
              lugar: _lugarSeleccionado!,
              cargandoRetos: _cargandoRetos,
              onCerrar: () => setState(() => _lugarSeleccionado = null),
              onAceptarReto: (reto) {
                final lugar = _lugarSeleccionado!;

                void aplicarReto() {
                  final destino = LatLng(lugar['lat'] as double, lugar['lng'] as double);
                  setState(() {
                    _retoActivo = reto;
                    _lugarActivo = lugar;
                    _rutaPuntos = [];
                    _lugarSeleccionado = null;
                  });
                  EstadoReto.instancia.aceptar(reto, lugar);
                  if (_miUbicacion != null) _calcularRuta(_miUbicacion!, destino);
                }

                if (_retoActivo != null) {
                  // Ya hay un reto activo — pedir confirmación
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF181828),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Text('¿Cambiar reto?',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      content: Text(
                        'Ya tienes el reto "${_retoActivo!['nombre']}" activo.\n\n¿Quieres cancelarlo y tomar este nuevo reto?',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF7878AA)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Mantener el actual',
                              style: TextStyle(color: Color(0xFF7878AA), fontWeight: FontWeight.w700)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            aplicarReto();
                          },
                          child: const Text('Cambiar reto',
                              style: TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                } else {
                  aplicarReto();
                }
              },
            ),
          ),
        ],
      ],
    );
  }
}

// ── Barra de filtros por tipo de lugar ───────────────────────
class _BarraFiltros extends StatelessWidget {
  final String filtroActivo;
  final ValueChanged<String> onFiltrar;
  const _BarraFiltros({required this.filtroActivo, required this.onFiltrar});

  static const _filtros = [
    {'id': 'all',    'label': 'Todos',    'color': Color(0xFFFFD93D)},
    {'id': 'rest',   'label': '🍽️',       'color': Color(0xFFFF9A5C)},
    {'id': 'parque', 'label': '🌿',       'color': Color(0xFF3DCB6B)},
    {'id': 'mall',   'label': '🏬',       'color': Color(0xFF4DAAFF)},
    {'id': 'noche',  'label': '🌙',       'color': Color(0xFFFF4D88)},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _filtros.map((f) {
          final activo = filtroActivo == f['id'];
          final color = f['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onFiltrar(f['id'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: activo ? color.withValues(alpha: 0.2) : const Color(0xE60D0D1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activo ? color : color.withValues(alpha: 0.3),
                    width: activo ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  f['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: activo ? color : color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Panel inferior con scroll horizontal de lugares ──────────
class _PanelCercanos extends StatelessWidget {
  final List<Map<String, dynamic>> lugares;
  final ValueChanged<Map<String, dynamic>> onSeleccionar;
  const _PanelCercanos({required this.lugares, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF181828),
        border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
      ),
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text('LUGARES EN NEIVA',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: Color(0xFF7878AA), letterSpacing: 0.8)),
          ),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: lugares.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (_, i) {
                final l = lugares[i];
                final color = l['color'] as Color;
                final retos = l['retos'] as List;
                return GestureDetector(
                  onTap: () => onSeleccionar(l),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E32),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l['emoji'] as String,
                                style: const TextStyle(fontSize: 20)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${retos.length} reto${retos.length > 1 ? 's' : ''}',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(l['nombre'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(retos.isEmpty
                            ? 'Toca para ver retos'
                            : (retos[0] as Map)['nombre'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF7878AA))),
                        const Spacer(),
                        if (retos.isNotEmpty)
                          Text('⚡ +${(retos[0] as Map)['xp']} XP',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w800,
                                  color: Color(0xFFFFD93D))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Panel de detalle al seleccionar un lugar ─────────────────
class _PanelDetalle extends StatelessWidget {
  final Map<String, dynamic> lugar;
  final bool cargandoRetos;
  final VoidCallback onCerrar;
  final ValueChanged<Map<String, dynamic>> onAceptarReto;
  const _PanelDetalle(
      {required this.lugar, required this.onCerrar,
       required this.onAceptarReto, this.cargandoRetos = false});

  @override
  Widget build(BuildContext context) {
    final color = lugar['color'] as Color;
    final retos = lugar['retos'] as List;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181828),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: const Color(0x40FFFFFF),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Badge de tipo + botón cerrar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${lugar['emoji']}  ${lugar['nombre']}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onCerrar,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0x20FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.close, size: 15, color: Color(0xFF7878AA)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.location_on, size: 12, color: Color(0xFF00D4AA)),
              SizedBox(width: 4),
              Text('⭐ Lugar verificado',
                  style: TextStyle(fontSize: 10, color: Color(0xFF00D4AA))),
            ],
          ),
          const SizedBox(height: 14),

          // Retos disponibles
          Row(children: [
            Text('Retos disponibles (${retos.length})',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD93D))),
            if (cargandoRetos) ...[
              const SizedBox(width: 8),
              const SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(
                      color: Color(0xFFFFD93D), strokeWidth: 2)),
            ],
          ]),
          const SizedBox(height: 8),

          // Lista de retos
          if (retos.isEmpty && !cargandoRetos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Sin retos disponibles en este lugar',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7878AA))),
              ),
            ),

          ...retos.map((r) {
            final reto = r as Map;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E32),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reto['nombre'] as String,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(reto['desc'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF7878AA), height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text('+${reto['xp']}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD93D))),
                      const Text('XP',
                          style: TextStyle(fontSize: 9, color: Color(0xFF7878AA))),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Botón aceptar reto (solo si hay retos cargados)
          if (retos.isNotEmpty)
            GestureDetector(
              onTap: () {
                final primerReto = retos[0] as Map<String, dynamic>;
                onAceptarReto(primerReto);
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12, offset: const Offset(0, 4),
                  )],
                ),
                child: const Center(
                  child: Text('¡Aceptar reto! 🎯',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          if (retos.isEmpty && cargandoRetos)
            Container(
              width: double.infinity, height: 50,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF6B35), strokeWidth: 2.5)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Banner de reto activo ────────────────────────────────────
class _BannerRetoActivo extends StatelessWidget {
  final Map<String, dynamic> reto;
  final Map<String, dynamic> lugar;
  final VoidCallback onCancelar;
  const _BannerRetoActivo(
      {required this.reto, required this.lugar, required this.onCancelar});

  @override
  Widget build(BuildContext context) {
    final color = lugar['color'] as Color;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Row(
        children: [
          // Emoji del lugar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(
                child: Text(lugar['emoji'] as String,
                    style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 10),
          // Info del reto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('RETO ACTIVO',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF6B35),
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 6),
                  Text('⚡ +${reto['xp']} XP',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFFD93D))),
                ]),
                const SizedBox(height: 3),
                Text(reto['nombre'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                Text(lugar['nombre'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF7878AA))),
              ],
            ),
          ),
          // Botón cancelar
          GestureDetector(
            onTap: onCancelar,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: const Color(0x15FF4D4D),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x40FF4D4D)),
              ),
              child: const Icon(Icons.close, size: 14, color: Color(0xFFFF4D4D)),
            ),
          ),
        ],
      ),
    );
  }
}



