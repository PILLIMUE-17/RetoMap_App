import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class OlvidePasswordScreen extends StatefulWidget {
  const OlvidePasswordScreen({super.key});

  @override
  State<OlvidePasswordScreen> createState() => _OlvidePasswordScreenState();
}

class _OlvidePasswordScreenState extends State<OlvidePasswordScreen> {
  // Paso 1: email
  final _emailCtrl = TextEditingController();
  // Paso 2: código + nueva contraseña
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  int _paso = 1;
  bool _cargando = false;
  bool _verPass = false;
  bool _verConfirm = false;
  String _passText = '';

  bool get _req8   => _passText.length >= 8;
  bool get _reqMay => RegExp(r'[A-Z]').hasMatch(_passText);
  bool get _reqMin => RegExp(r'[a-z]').hasMatch(_passText);
  bool get _reqNum => RegExp(r'[0-9]').hasMatch(_passText);
  bool get _reqEsp => RegExp(r'[!@#\$%^&*()\-_=+\[\]{}|;:,.<>?/]').hasMatch(_passText);

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() => _passText = _passCtrl.text));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snackError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFFFF4D4D),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _snackOk(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF3DCB6B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Paso 1: solicitar código ────────────────────
  Future<void> _solicitarCodigo() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snackError('Ingresa tu correo electrónico');
      return;
    }
    setState(() => _cargando = true);
    final resp = await ApiService.post('/password/forgot', {'email': email});
    if (!mounted) return;
    setState(() => _cargando = false);

    if (!resp.ok) {
      _snackError(resp.mensaje.isNotEmpty ? resp.mensaje : 'Error al enviar el código');
      return;
    }

    // El backend devuelve el token en la respuesta (en producción lo envía por email)
    final token = resp.data?['token'] as String? ?? '';
    _tokenCtrl.text = token;

    setState(() => _paso = 2);
  }

  // ── Paso 2: restablecer contraseña ─────────────
  Future<void> _restablecerPassword() async {
    final token = _tokenCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (token.isEmpty) {
      _snackError('Ingresa el código que recibiste');
      return;
    }
    if (pass.isEmpty || confirm.isEmpty) {
      _snackError('Completa todos los campos');
      return;
    }
    if (pass != confirm) {
      _snackError('Las contraseñas no coinciden');
      return;
    }
    if (!(_req8 && _reqMay && _reqMin && _reqNum && _reqEsp)) {
      _snackError('La contraseña no cumple los requisitos');
      return;
    }

    setState(() => _cargando = true);
    final resp = await ApiService.post('/password/reset', {
      'email': _emailCtrl.text.trim(),
      'token': token,
      'password_nuevo': pass,
      'password_nuevo_confirmation': confirm,
    });
    if (!mounted) return;
    setState(() => _cargando = false);

    if (!resp.ok) {
      _snackError(resp.mensaje.isNotEmpty ? resp.mensaje : 'Código inválido o expirado');
      return;
    }

    _snackOk('¡Contraseña actualizada! Inicia sesión');
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () {
            if (_paso == 2) {
              setState(() => _paso = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icono hero ──────────────────────────────
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Center(
                  child: Text('🔐', style: TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Indicador de pasos ──────────────────────
            Row(
              children: [
                _PasoIndicador(numero: 1, activo: _paso == 1, completado: _paso > 1),
                Expanded(
                  child: Container(
                    height: 2,
                    color: _paso > 1
                        ? const Color(0xFF3DCB6B)
                        : const Color(0x20FFFFFF),
                  ),
                ),
                _PasoIndicador(numero: 2, activo: _paso == 2, completado: false),
              ],
            ),
            const SizedBox(height: 28),

            if (_paso == 1) ..._buildPaso1() else ..._buildPaso2(),
          ],
        ),
      ),
    );
  }

  // ── Paso 1 UI ────────────────────────────────────
  List<Widget> _buildPaso1() => [
        const Text('¿Olvidaste tu contraseña?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
          style: TextStyle(fontSize: 13, color: Color(0xFF7878AA)),
        ),
        const SizedBox(height: 32),
        _CampoOlvide(
          ctrl: _emailCtrl,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),
        _BtnOlvide(
          texto: 'Enviar código',
          cargando: _cargando,
          onTap: _solicitarCodigo,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Volver al inicio de sesión',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ];

  // ── Paso 2 UI ────────────────────────────────────
  List<Widget> _buildPaso2() => [
        const Text('Crea tu nueva contraseña',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(
          'Código enviado a ${_emailCtrl.text.trim()}',
          style: const TextStyle(fontSize: 13, color: Color(0xFF7878AA)),
        ),
        const SizedBox(height: 32),
        _CampoOlvide(
          ctrl: _tokenCtrl,
          label: 'Código de verificación',
          icon: Icons.vpn_key_outlined,
        ),
        const SizedBox(height: 14),
        _CampoOlvide(
          ctrl: _passCtrl,
          label: 'Nueva contraseña',
          icon: Icons.lock_outline,
          esPassword: true,
          verPassword: _verPass,
          onToggleVer: () => setState(() => _verPass = !_verPass),
        ),
        const SizedBox(height: 6),
        // Requisitos
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
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF7878AA),
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _ReqItemOlvide(texto: 'Mínimo 8 caracteres', cumple: _req8),
              _ReqItemOlvide(texto: 'Al menos una mayúscula (A-Z)', cumple: _reqMay),
              _ReqItemOlvide(texto: 'Al menos una minúscula (a-z)', cumple: _reqMin),
              _ReqItemOlvide(texto: 'Al menos un número (0-9)', cumple: _reqNum),
              _ReqItemOlvide(
                  texto: 'Al menos un carácter especial (!@#\$%)',
                  cumple: _reqEsp),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _CampoOlvide(
          ctrl: _confirmCtrl,
          label: 'Confirmar nueva contraseña',
          icon: Icons.lock_outline,
          esPassword: true,
          verPassword: _verConfirm,
          onToggleVer: () => setState(() => _verConfirm = !_verConfirm),
        ),
        const SizedBox(height: 28),
        _BtnOlvide(
          texto: 'Restablecer contraseña',
          cargando: _cargando,
          onTap: _restablecerPassword,
        ),
      ];
}

// ── Widgets locales ──────────────────────────────────

class _PasoIndicador extends StatelessWidget {
  final int numero;
  final bool activo;
  final bool completado;
  const _PasoIndicador(
      {required this.numero, required this.activo, required this.completado});

  @override
  Widget build(BuildContext context) {
    final color = completado
        ? const Color(0xFF3DCB6B)
        : activo
            ? const Color(0xFFFF6B35)
            : const Color(0x40FFFFFF);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: completado
            ? const Icon(Icons.check, color: Color(0xFF3DCB6B), size: 16)
            : Text('$numero',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}

class _CampoOlvide extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType teclado;
  final bool esPassword;
  final bool verPassword;
  final VoidCallback? onToggleVer;

  const _CampoOlvide({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.teclado = TextInputType.text,
    this.esPassword = false,
    this.verPassword = false,
    this.onToggleVer,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: teclado,
        obscureText: esPassword && !verPassword,
        style: const TextStyle(fontSize: 14, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7878AA), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF7878AA), size: 20),
          suffixIcon: esPassword
              ? IconButton(
                  icon: Icon(
                      verPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF7878AA),
                      size: 20),
                  onPressed: onToggleVer)
              : null,
          filled: true,
          fillColor: const Color(0xFF181828),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x20FFFFFF))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0x20FFFFFF))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFFF6B35), width: 1.5)),
        ),
      );
}

class _BtnOlvide extends StatelessWidget {
  final String texto;
  final bool cargando;
  final VoidCallback onTap;
  const _BtnOlvide(
      {required this.texto, required this.onTap, this.cargando = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: cargando ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF4D88)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: cargando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(texto,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
          ),
        ),
      );
}

class _ReqItemOlvide extends StatelessWidget {
  final String texto;
  final bool cumple;
  const _ReqItemOlvide({required this.texto, required this.cumple});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: cumple
                  ? const Icon(Icons.check_circle,
                      size: 13,
                      color: Color(0xFF3DCB6B),
                      key: ValueKey('check'))
                  : const Icon(Icons.radio_button_unchecked,
                      size: 13,
                      color: Color(0xFF7878AA),
                      key: ValueKey('empty')),
            ),
            const SizedBox(width: 6),
            Text(texto,
                style: TextStyle(
                    fontSize: 10,
                    color: cumple
                        ? const Color(0xFF3DCB6B)
                        : const Color(0xFF7878AA),
                    fontWeight:
                        cumple ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      );
}
