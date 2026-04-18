import 'package:flutter/material.dart';
import 'registro_screen.dart';
import 'main_screen.dart';
import 'olvide_password_screen.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;
  bool _cargando = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFFFF4D4D),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _mostrarError('Completa todos los campos');
      return;
    }

    setState(() => _cargando = true);

    final resp = await ApiService.post('/login', {
      'email_usuario': email,
      'password': pass,
    });

    setState(() => _cargando = false);
    if (!mounted) return;

    if (!resp.ok) {
      _mostrarError(resp.mensaje.isNotEmpty ? resp.mensaje : 'Credenciales incorrectas');
      return;
    }

    await ApiService.guardarToken(resp.data['token'] as String);
    await ApiService.guardarUsuario(resp.data['usuario'] as Map<String, dynamic>);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeroLogin(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenido de vuelta',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Inicia sesión para seguir explorando',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
                  const SizedBox(height: 28),
                  _Campo(
                    label: 'Correo electrónico',
                    icono: Icons.email_outlined,
                    controller: _emailCtrl,
                    teclado: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _Campo(
                    label: 'Contraseña',
                    icono: Icons.lock_outline,
                    controller: _passCtrl,
                    esPassword: true,
                    verPassword: _verPassword,
                    onToggleVer: () => setState(() => _verPassword = !_verPassword),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const OlvidePasswordScreen())),
                      child: const Text('¿Olvidaste tu contraseña?',
                          style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _BtnPrimario(
                    texto: 'Iniciar sesión ⚡',
                    cargando: _cargando,
                    onTap: _login,
                  ),
                  const SizedBox(height: 24),
                  Row(children: const [
                    Expanded(child: Divider(color: Color(0x20FFFFFF))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('o', style: TextStyle(color: Color(0xFF7878AA), fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Color(0x20FFFFFF))),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes cuenta? ',
                          style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RegistroScreen()),
                        ),
                        child: const Text('Crear cuenta',
                            style: TextStyle(fontSize: 13, color: Color(0xFFFF6B35),
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, right: -40,
              child: _Circulo(size: 180, color: const Color(0x159B59FF))),
          Positioned(bottom: 20, left: -30,
              child: _Circulo(size: 120, color: const Color(0x10FF6B35))),
          Positioned(top: 60, left: 30,
              child: _Circulo(size: 60, color: const Color(0x20FFD93D))),
          const Positioned(top: 55, right: 65, child: _Pin(emoji: '🌿', color: Color(0xFF3DCB6B))),
          const Positioned(top: 105, right: 32, child: _Pin(emoji: '🏆', color: Color(0xFFFFD93D))),
          const Positioned(top: 75, left: 38, child: _Pin(emoji: '📸', color: Color(0xFF4DAAFF))),
          const Positioned(top: 145, left: 85, child: _Pin(emoji: '⚡', color: Color(0xFFFF6B35))),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
                        blurRadius: 22, spreadRadius: 2)],
                  ),
                  child: const Center(child: Text('🗺️', style: TextStyle(fontSize: 34))),
                ),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFD93D), Color(0xFFFF6B35)],
                  ).createShader(b),
                  child: const Text('RetoMap',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 5),
                const Text('Explora · Completa · Gana XP',
                    style: TextStyle(fontSize: 12, color: Color(0xFF7878AA), letterSpacing: 1.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circulo extends StatelessWidget {
  final double size;
  final Color color;
  const _Circulo({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _Pin extends StatelessWidget {
  final String emoji;
  final Color color;
  const _Pin({required this.emoji, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5)),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
  );
}

class _Campo extends StatelessWidget {
  final String label;
  final IconData icono;
  final TextEditingController controller;
  final TextInputType teclado;
  final bool esPassword;
  final bool verPassword;
  final VoidCallback? onToggleVer;

  const _Campo({required this.label, required this.icono, required this.controller,
      this.teclado = TextInputType.text, this.esPassword = false,
      this.verPassword = false, this.onToggleVer});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      obscureText: esPassword && !verPassword,
      style: const TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7878AA), fontSize: 13),
        prefixIcon: Icon(icono, color: const Color(0xFF7878AA), size: 20),
        suffixIcon: esPassword
            ? IconButton(
                icon: Icon(verPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF7878AA), size: 20),
                onPressed: onToggleVer)
            : null,
        filled: true,
        fillColor: const Color(0xFF181828),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x20FFFFFF))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0x20FFFFFF))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5)),
      ),
    );
  }
}

class _BtnPrimario extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback onTap;
  const _BtnPrimario({required this.texto, required this.onTap, this.cargando = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
              blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: cargando
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(texto, style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}


