import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;
  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _ciudadCtrl;
  final _passActualCtrl = TextEditingController();
  final _passNuevoCtrl = TextEditingController();
  final _passConfCtrl = TextEditingController();

  bool _guardandoPerfil = false;
  bool _guardandoPass = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl =
        TextEditingController(text: widget.perfil['nombre'] as String? ?? '');
    _usernameCtrl = TextEditingController(
        text: widget.perfil['username'] as String? ?? '');
    _ciudadCtrl =
        TextEditingController(text: widget.perfil['ciudad'] as String? ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usernameCtrl.dispose();
    _ciudadCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevoCtrl.dispose();
    _passConfCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardandoPerfil = true);
    final resp = await ApiService.put('/perfil', {
      'nombre_usuario': _nombreCtrl.text.trim(),
      'username_usuario': _usernameCtrl.text.trim(),
      'ciudad_usuario': _ciudadCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _guardandoPerfil = false);
    if (resp.ok) {
      _mostrarExito('Perfil actualizado');
      Navigator.pop(context, true);
    } else {
      _mostrarError(
          resp.mensaje.isNotEmpty ? resp.mensaje : 'Error al guardar');
    }
  }

  Future<void> _cambiarPassword() async {
    if (_passActualCtrl.text.isEmpty || _passNuevoCtrl.text.isEmpty) {
      _mostrarError('Completa todos los campos de contraseña');
      return;
    }
    if (_passNuevoCtrl.text != _passConfCtrl.text) {
      _mostrarError('Las contraseñas no coinciden');
      return;
    }
    setState(() => _guardandoPass = true);
    final resp = await ApiService.put('/perfil/password', {
      'password_actual': _passActualCtrl.text,
      'password_nuevo': _passNuevoCtrl.text,
      'password_nuevo_confirmation': _passConfCtrl.text,
    });
    if (!mounted) return;
    setState(() => _guardandoPass = false);
    if (resp.ok) {
      await ApiService.borrarToken();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } else {
      _mostrarError(resp.mensaje.isNotEmpty
          ? resp.mensaje
          : 'Error al cambiar contraseña');
    }
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

  void _mostrarExito(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF3DCB6B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Editar perfil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0x14FFFFFF))),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Información personal ───────────────────────
            const _Seccion(titulo: 'INFORMACIÓN PERSONAL'),
            Form(
              key: _formKey,
              child: Column(children: [
                _Campo(
                  ctrl: _nombreCtrl,
                  label: 'Nombre completo',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _Campo(
                  ctrl: _usernameCtrl,
                  label: 'Usuario (@)',
                  icon: Icons.alternate_email,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _Campo(
                  ctrl: _ciudadCtrl,
                  label: 'Ciudad',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _guardandoPerfil ? null : _guardarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _guardandoPerfil
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar cambios',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 32),

            // ── Cambiar contraseña ─────────────────────────
            const _Seccion(titulo: 'CAMBIAR CONTRASEÑA'),
            _CampoPass(ctrl: _passActualCtrl, label: 'Contraseña actual'),
            const SizedBox(height: 12),
            _CampoPass(ctrl: _passNuevoCtrl, label: 'Nueva contraseña'),
            const SizedBox(height: 12),
            _CampoPass(
                ctrl: _passConfCtrl, label: 'Confirmar nueva contraseña'),
            const SizedBox(height: 8),
            const Text(
              'Requiere: mayúscula, número y símbolo. Al cambiar contraseña se cerrará tu sesión.',
              style: TextStyle(fontSize: 11, color: Color(0xFF7878AA)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _guardandoPass ? null : _cambiarPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0x40FFFFFF)),
                  ),
                ),
                child: _guardandoPass
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Cambiar contraseña',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  const _Seccion({required this.titulo});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(titulo,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7878AA),
                letterSpacing: 0.8)),
      );
}

class _Campo extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  const _Campo(
      {required this.ctrl,
      required this.label,
      required this.icon,
      this.validator});

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: ctrl,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF7878AA)),
          prefixIcon:
              Icon(icon, color: const Color(0xFF7878AA), size: 20),
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
                  const BorderSide(color: Color(0xFFFF6B35))),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFFF4D4D))),
        ),
      );
}

class _CampoPass extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  const _CampoPass({required this.ctrl, required this.label});

  @override
  State<_CampoPass> createState() => _CampoPassState();
}

class _CampoPassState extends State<_CampoPass> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.ctrl,
        obscureText: _oculto,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: Color(0xFF7878AA)),
          prefixIcon: const Icon(Icons.lock_outline,
              color: Color(0xFF7878AA), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                _oculto
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF7878AA),
                size: 20),
            onPressed: () => setState(() => _oculto = !_oculto),
          ),
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
                  const BorderSide(color: Color(0xFFFF6B35))),
        ),
      );
}
