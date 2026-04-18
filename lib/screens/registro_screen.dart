import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import '../services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nombre1Ctrl = TextEditingController();
  final _nombre2Ctrl = TextEditingController();
  final _apellido1Ctrl = TextEditingController();
  final _apellido2Ctrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _verPass = false;
  bool _verConfirm = false;
  bool _cargando = false;
  String _passText = '';

  void _onPassChanged() => setState(() => _passText = _passCtrl.text);

  // Validaciones de la contraseña
  bool get _req8    => _passText.length >= 8;
  bool get _reqMay  => RegExp(r'[A-Z]').hasMatch(_passText);
  bool get _reqMin  => RegExp(r'[a-z]').hasMatch(_passText);
  bool get _reqNum  => RegExp(r'[0-9]').hasMatch(_passText);
  bool get _reqEsp  => RegExp(r'[!@#\$%^&*()\-_=+\[\]{}|;:,.<>?/]').hasMatch(_passText);

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_onPassChanged);
  }

  @override
  void dispose() {
    _passCtrl.removeListener(_onPassChanged);
    _nombre1Ctrl.dispose();
    _nombre2Ctrl.dispose();
    _apellido1Ctrl.dispose();
    _apellido2Ctrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _ciudadCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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

  void _registrar() async {
    final nombre1 = _nombre1Ctrl.text.trim();
    final apellido1 = _apellido1Ctrl.text.trim();
    final apellido2 = _apellido2Ctrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (nombre1.isEmpty || apellido1.isEmpty ||
        username.isEmpty || email.isEmpty || pass.isEmpty) {
      _mostrarError('Completa todos los campos obligatorios');
      return;
    }
    if (pass != confirm) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }
    if (!(_req8 && _reqMay && _reqMin && _reqNum && _reqEsp)) {
      _mostrarError('La contraseña no cumple los requisitos');
      return;
    }

    // Combinar nombres para nombre_usuario
    final partes = [nombre1, _nombre2Ctrl.text.trim(), apellido1, apellido2]
        .where((p) => p.isNotEmpty)
        .toList();
    final nombreCompleto = partes.join(' ');

    setState(() => _cargando = true);

    final resp = await ApiService.post('/register', {
      'nombre_usuario': nombreCompleto,
      'email_usuario': email,
      'username_usuario': username,
      'ciudad_usuario': _ciudadCtrl.text.trim(),
      'password': pass,
      'password_confirmation': confirm,
    });

    setState(() => _cargando = false);
    if (!mounted) return;

    if (!resp.ok) {
      // Mostrar primer error de validación si existe
      final errores = resp.erroresValidacion;
      if (errores.isNotEmpty) {
        _mostrarError(errores.values.first.first);
      } else {
        _mostrarError(resp.mensaje.isNotEmpty ? resp.mensaje : 'Error al registrarse');
      }
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
            _HeroRegistro(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Únete a RetoMap',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Crea tu cuenta y empieza a ganar XP 🔥',
                      style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _Campo(
                          label: 'Primer nombre *',
                          icono: Icons.person_outline,
                          controller: _nombre1Ctrl,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Campo(
                          label: 'Segundo nombre',
                          icono: Icons.person_outline,
                          controller: _nombre2Ctrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _Campo(
                          label: 'Primer apellido *',
                          icono: Icons.badge_outlined,
                          controller: _apellido1Ctrl,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Campo(
                          label: 'Segundo apellido',
                          icono: Icons.badge_outlined,
                          controller: _apellido2Ctrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _Campo(
                    label: 'Username * (ej: juan_84)',
                    icono: Icons.alternate_email,
                    controller: _usernameCtrl,
                  ),
                  const SizedBox(height: 14),

                  _Campo(
                    label: 'Correo electrónico *',
                    icono: Icons.email_outlined,
                    controller: _emailCtrl,
                    teclado: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _Campo(
                    label: 'Ciudad (opcional)',
                    icono: Icons.location_city_outlined,
                    controller: _ciudadCtrl,
                  ),
                  const SizedBox(height: 14),

                  _Campo(
                    label: 'Contraseña *',
                    icono: Icons.lock_outline,
                    controller: _passCtrl,
                    esPassword: true,
                    verPassword: _verPass,
                    onToggleVer: () => setState(() => _verPass = !_verPass),
                  ),
                  const SizedBox(height: 6),

                  // Requisitos de contraseña
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E32),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x20FFFFFF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('La contraseña debe tener:',
                            style: TextStyle(fontSize: 10, color: Color(0xFF7878AA),
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        _ReqItem(texto: 'Mínimo 8 caracteres', cumple: _req8),
                        _ReqItem(texto: 'Al menos una mayúscula (A-Z)', cumple: _reqMay),
                        _ReqItem(texto: 'Al menos una minúscula (a-z)', cumple: _reqMin),
                        _ReqItem(texto: 'Al menos un número (0-9)', cumple: _reqNum),
                        _ReqItem(texto: 'Al menos un carácter especial (!@#\$%^&*)', cumple: _reqEsp),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _Campo(
                    label: 'Confirmar contraseña *',
                    icono: Icons.lock_outline,
                    controller: _confirmCtrl,
                    esPassword: true,
                    verPassword: _verConfirm,
                    onToggleVer: () => setState(() => _verConfirm = !_verConfirm),
                  ),
                  const SizedBox(height: 10),

                  // Términos
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 13, color: Color(0xFF7878AA)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Al registrarte aceptas nuestros términos y condiciones',
                          style: TextStyle(fontSize: 11, color: Color(0xFF7878AA)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  _BtnPrimario(
                    texto: 'Crear cuenta 🚀',
                    cargando: _cargando,
                    onTap: _registrar,
                    colores: const [Color(0xFF9B59FF), Color(0xFFFF4D88)],
                    sombraColor: const Color(0xFF9B59FF),
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
                      const Text('¿Ya tienes cuenta? ',
                          style: TextStyle(fontSize: 13, color: Color(0xFF7878AA))),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                        child: const Text('Iniciar sesión',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9B59FF),
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

class _HeroRegistro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0A2E), Color(0xFF0D0D1A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -30, right: -30,
            child: _Circulo(size: 160, color: const Color(0x15FF4D88))),
          Positioned(bottom: 0, left: -20,
            child: _Circulo(size: 100, color: const Color(0x109B59FF))),

          // Íconos de logros flotantes
          const Positioned(top: 30, right: 50,
            child: _LogroBadge(emoji: '🏅', xp: '+50 XP')),
          const Positioned(top: 80, left: 30,
            child: _LogroBadge(emoji: '⭐', xp: 'Nivel 1')),
          const Positioned(top: 140, right: 25,
            child: _LogroBadge(emoji: '🚀', xp: 'Explorador')),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Avatar inicial con gradiente morado
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9B59FF), Color(0xFFFF4D88)],
                    ),
                    border: Border.all(color: const Color(0xFFFFD93D), width: 3),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF9B59FF).withValues(alpha: 0.4),
                      blurRadius: 20, spreadRadius: 2,
                    )],
                  ),
                  child: const Center(
                    child: Text('?', style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF9B59FF), Color(0xFFFF4D88)],
                  ).createShader(b),
                  child: const Text('Nuevo Explorador',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 4),
                const Text('Tu aventura por el mundo está a punto de comenzar',
                    style: TextStyle(fontSize: 11, color: Color(0xFF7878AA))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogroBadge extends StatelessWidget {
  final String emoji;
  final String xp;
  const _LogroBadge({required this.emoji, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E32),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(xp, style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFFD93D))),
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

class _ReqItem extends StatelessWidget {
  final String texto;
  final bool cumple;
  const _ReqItem({required this.texto, required this.cumple});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: cumple
              ? const Icon(Icons.check_circle, size: 13,
                  color: Color(0xFF3DCB6B), key: ValueKey('check'))
              : const Icon(Icons.radio_button_unchecked, size: 13,
                  color: Color(0xFF7878AA), key: ValueKey('empty')),
        ),
        const SizedBox(width: 6),
        Text(texto,
            style: TextStyle(
                fontSize: 10,
                color: cumple ? const Color(0xFF3DCB6B) : const Color(0xFF7878AA),
                fontWeight: cumple ? FontWeight.w700 : FontWeight.w400)),
      ],
    ),
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

  const _Campo({
    required this.label,
    required this.icono,
    required this.controller,
    this.teclado = TextInputType.text,
    this.esPassword = false,
    this.verPassword = false,
    this.onToggleVer,
  });

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
                icon: Icon(
                  verPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF7878AA), size: 20,
                ),
                onPressed: onToggleVer,
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF181828),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x20FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF9B59FF), width: 1.5),
        ),
      ),
    );
  }
}

class _BtnPrimario extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback onTap;
  final List<Color> colores;
  final Color sombraColor;

  const _BtnPrimario({
    required this.texto,
    required this.onTap,
    this.cargando = false,
    this.colores = const [Color(0xFFFF6B35), Color(0xFFFF4D88)],
    this.sombraColor = const Color(0xFFFF6B35),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colores),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: sombraColor.withValues(alpha: 0.35),
            blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        child: Center(
          child: cargando
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(texto,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}


