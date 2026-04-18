import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> _usuarios = [];
  int _miPosicion = 0;
  int _miXp = 0;
  String _miNivel = '';
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final results = await Future.wait([
      ApiService.get('/ranking'),
      ApiService.get('/ranking/mi-posicion'),
    ]);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (results[0].ok && results[0].data != null) {
        final data = results[0].data['data'] as List? ?? [];
        _usuarios = data.cast<Map<String, dynamic>>();
      }
      if (results[1].ok && results[1].data != null) {
        _miPosicion = (results[1].data['posicion'] as num?)?.toInt() ?? 0;
        _miXp = (results[1].data['xp_actual'] as num?)?.toInt() ?? 0;
        _miNivel = results[1].data['nivel_actual'] as String? ?? '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Ranking',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : RefreshIndicator(
              color: const Color(0xFFFF6B35),
              backgroundColor: const Color(0xFF181828),
              onRefresh: _cargar,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9B59FF), Color(0xFFFF4D88)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: Center(
                            child: Text('#$_miPosicion',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tu posición',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white70)),
                            Text('⚡ $_miXp XP  ·  $_miNivel',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white)),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TarjetaRanking(
                          usuario: _usuarios[i], miPosicion: _miPosicion),
                      childCount: _usuarios.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }
}

class _TarjetaRanking extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final int miPosicion;
  const _TarjetaRanking(
      {required this.usuario, required this.miPosicion});

  @override
  Widget build(BuildContext context) {
    final pos = (usuario['posicion'] as num?)?.toInt() ?? 0;
    final nombre = usuario['nombre'] as String? ?? 'Usuario';
    final username = usuario['username'] as String? ?? '';
    final xp = (usuario['xp_total'] as num?)?.toInt() ?? 0;
    final nivel = usuario['nivel'] as String? ?? '';
    final esMio = pos == miPosicion;

    String medalla = '';
    if (pos == 1) {
      medalla = '🥇';
    } else if (pos == 2) {
      medalla = '🥈';
    } else if (pos == 3) {
      medalla = '🥉';
    }

    final palabras = nombre.split(' ');
    final iniciales = palabras
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: esMio
            ? const Color(0x1AFF6B35)
            : const Color(0xFF181828),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esMio
              ? const Color(0x66FF6B35)
              : const Color(0x14FFFFFF),
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: medalla.isNotEmpty
              ? Text(medalla,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center)
              : Text('#$pos',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7878AA)),
                  textAlign: TextAlign.center),
        ),
        const SizedBox(width: 10),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                HSLColor.fromAHSL(1, (pos * 37.0) % 360, 0.7, 0.5).toColor(),
                HSLColor.fromAHSL(
                        1, (pos * 37.0 + 60) % 360, 0.7, 0.4)
                    .toColor(),
              ],
            ),
          ),
          child: Center(
            child: Text(iniciales,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nombre,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: esMio
                          ? const Color(0xFFFF6B35)
                          : Colors.white)),
              Text('@$username  ·  $nivel',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF7878AA))),
            ],
          ),
        ),
        Text(
            xp >= 1000
                ? '${(xp / 1000).toStringAsFixed(1)}k XP'
                : '$xp XP',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD93D))),
      ]),
    );
  }
}
