import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../estado_reto.dart';

class RetosScreen extends StatefulWidget {
  const RetosScreen({super.key});

  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  List<Map<String, dynamic>> _disponibles = [];
  List<Map<String, dynamic>> _completados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarRetos();
  }

  Future<void> _cargarRetos() async {
    final results = await Future.wait([
      ApiService.get('/retos'),
      ApiService.get('/retos/completados'),
    ]);

    if (!mounted) return;

    final respDisp = results[0];
    final respComp = results[1];

    setState(() {
      _cargando = false;

      if (respDisp.ok && respDisp.data != null) {
        final items = respDisp.data['data'] as List? ?? [];
        _disponibles = items
            .where((r) => r['ya_completado'] == false)
            .map<Map<String, dynamic>>((r) => _mapReto(r))
            .toList();
      }

      if (respComp.ok && respComp.data != null) {
        final items = respComp.data['data'] as List? ?? [];
        _completados =
            items.map<Map<String, dynamic>>((c) => _mapCompletado(c)).toList();
      }
    });
  }

  Map<String, dynamic> _mapReto(Map<String, dynamic> r) {
    final dif = (r['dificultad'] as num?)?.toInt() ?? 1;
    final colores = [
      const Color(0xFF3DCB6B),
      const Color(0xFF00D4AA),
      const Color(0xFFFF6B35),
      const Color(0xFFFFD93D),
      const Color(0xFFFF4D4D),
    ];
    final color = colores[(dif - 1).clamp(0, 4)];
    final lugar = r['lugar'] as Map<String, dynamic>? ?? {};

    return {
      'id': r['id'],
      'emoji': lugar['icono'] as String? ?? r['icono_tipo'] as String? ?? '⚡',
      'nombre': r['nombre'] as String? ?? '',
      'lugar': lugar['nombre'] as String? ?? '',
      'distancia': null,
      'tipo': '${r['icono_tipo'] ?? '📸'} ${r['tipo'] ?? 'Reto'}',
      'tiempo': r['expira_en'] != null ? 'Limitado' : 'Sin límite',
      'xp': (r['xp'] as num?)?.toInt() ?? 0,
      'color': color,
    };
  }

  Map<String, dynamic> _mapCompletado(Map<String, dynamic> c) {
    return {
      'emoji': '✅',
      'nombre': c['reto'] as String? ?? '',
      'lugar': c['lugar'] as String? ?? '',
      'distancia': null,
      'tipo': '✅ Completado',
      'tiempo': '',
      'xp': (c['xp_ganado'] as num?)?.toInt() ?? 0,
      'color': const Color(0xFF9B59FF),
    };
  }

  @override
  Widget build(BuildContext context) {
    final retoActivo = EstadoReto.instancia;

    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mis Retos',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text(
                '${_disponibles.length} disponible${_disponibles.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF7878AA)),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF6B35),
            backgroundColor: const Color(0xFF181828),
            onRefresh: _cargarRetos,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Reto activo actual
                if (retoActivo.tieneReto) ...[
                  const _SeccionLabel(texto: 'Reto activo ahora'),
                  _RetoCardActivo(
                    reto: retoActivo.reto!,
                    lugar: retoActivo.lugar!,
                  ),
                ],

                // Retos disponibles
                if (_disponibles.isNotEmpty) ...[
                  const _SeccionLabel(texto: 'Disponibles'),
                  ..._disponibles.map((r) => _RetoCard(reto: r)),
                ],

                // Sin retos
                if (_disponibles.isEmpty && !retoActivo.tieneReto)
                  const _EstadoVacio(),

                // Completados
                if (_completados.isNotEmpty) ...[
                  const _SeccionLabel(texto: 'Completados'),
                  ..._completados.map((r) => _RetoCard(reto: r, completado: true)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card del reto actualmente aceptado ───────────────────────
class _RetoCardActivo extends StatelessWidget {
  final Map<String, dynamic> reto;
  final Map<String, dynamic> lugar;
  const _RetoCardActivo({required this.reto, required this.lugar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x26FF6B35), Color(0x0DFF6B35)],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x66FF6B35), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: const Color(0x26FF6B35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(lugar['emoji'] as String? ?? '📍',
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RETO ACTIVO',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF6B35),
                    letterSpacing: 0.5)),
            Text(reto['nombre'] as String? ?? '',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            Text('📍 ${lugar['nombre'] ?? ''}',
                style: const TextStyle(
                    fontSize: 10, color: Color(0xFF00D4AA))),
          ]),
        ),
        Text('+${reto['xp']}',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD93D))),
      ]),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('⚡', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('No hay retos disponibles',
              style:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('El administrador añadirá retos pronto',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF7878AA))),
        ]),
      ),
    );
  }
}

class _SeccionLabel extends StatelessWidget {
  final String texto;
  const _SeccionLabel({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xFF7878AA),
            letterSpacing: 0.8),
      ),
    );
  }
}

class _RetoCard extends StatelessWidget {
  final Map<String, dynamic> reto;
  final bool completado;
  const _RetoCard({required this.reto, this.completado = false});

  @override
  Widget build(BuildContext context) {
    final color = reto['color'] as Color;
    return Opacity(
      opacity: completado ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF181828),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(reto['emoji'] as String,
                  style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reto['nombre'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Row(children: [
                  Flexible(
                    child: Text('📍 ${reto['lugar']}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF00D4AA))),
                  ),
                  if (reto['distancia'] != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0x1A3DCB6B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(reto['distancia'] as String,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3DCB6B))),
                    ),
                  ],
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  _Chip(texto: reto['tipo'] as String, color: color),
                  if ((reto['tiempo'] as String).isNotEmpty) ...[
                    const SizedBox(width: 5),
                    _Chip(
                        texto: '⏰ ${reto['tiempo']}',
                        color: const Color(0xFF7878AA)),
                  ],
                ]),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('+${reto['xp']}',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: completado
                        ? const Color(0xFF9B59FF)
                        : const Color(0xFFFFD93D))),
            const Text('XP',
                style: TextStyle(fontSize: 9, color: Color(0xFF7878AA))),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String texto;
  final Color color;
  const _Chip({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w800, color: color)),
    );
  }
}


