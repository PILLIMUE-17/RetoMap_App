import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  // ─── IMPORTANTE: cambia esta IP si usas dispositivo físico ───
  // Emulador Android → 10.0.2.2
  // Dispositivo físico → IP de tu PC (ej: 192.168.1.5)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static String? _token;

  // ── Token ────────────────────────────────────────────────────
  static Future<void> guardarToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> cargarToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  static Future<void> borrarToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario');
  }

  static Future<bool> hayToken() async {
    final t = await cargarToken();
    return t != null && t.isNotEmpty;
  }

  // ── Usuario en caché ─────────────────────────────────────────
  static Future<void> guardarUsuario(Map<String, dynamic> u) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(u));
  }

  static Future<Map<String, dynamic>?> cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('usuario');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Headers ──────────────────────────────────────────────────
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET ──────────────────────────────────────────────────────
  static Future<ApiResp> get(String endpoint) async {
    await cargarToken();
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      return ApiResp._from(res);
    } catch (e) {
      return ApiResp._error('Sin conexión con el servidor');
    }
  }

  // ── POST ─────────────────────────────────────────────────────
  static Future<ApiResp> post(String endpoint, Map<String, dynamic> body) async {
    await cargarToken();
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$endpoint'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return ApiResp._from(res);
    } catch (e) {
      return ApiResp._error('Sin conexión con el servidor');
    }
  }

  // ── PUT ──────────────────────────────────────────────────────
  static Future<ApiResp> put(String endpoint, Map<String, dynamic> body) async {
    await cargarToken();
    try {
      final res = await http
          .put(Uri.parse('$baseUrl$endpoint'),
              headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));
      return ApiResp._from(res);
    } catch (e) {
      return ApiResp._error('Sin conexión con el servidor');
    }
  }

  // ── DELETE ───────────────────────────────────────────────────
  static Future<ApiResp> delete(String endpoint) async {
    await cargarToken();
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _headers)
          .timeout(const Duration(seconds: 12));
      return ApiResp._from(res);
    } catch (e) {
      return ApiResp._error('Sin conexión con el servidor');
    }
  }

  // ── UPLOAD evidencia (multipart/form-data) ───────────────────
  static Future<ApiResp> uploadEvidencia(String filePath) async {
    await cargarToken();
    try {
      final uri = Uri.parse('$baseUrl/upload/evidencia');
      final req = http.MultipartRequest('POST', uri);
      if (_token != null) req.headers['Authorization'] = 'Bearer $_token';
      req.headers['Accept'] = 'application/json';

      final ext = filePath.split('.').last.toLowerCase();
      final mediaType = MediaType(
        ext == 'mp4' ? 'video' : 'image',
        ext == 'png' ? 'png' : ext == 'mp4' ? 'mp4' : 'jpeg',
      );

      req.files.add(await http.MultipartFile.fromPath(
        'archivo',
        filePath,
        contentType: mediaType,
      ));

      final streamed = await req.send().timeout(const Duration(seconds: 30));
      final res = await http.Response.fromStream(streamed);
      return ApiResp._from(res);
    } catch (e) {
      return ApiResp._error('Error al subir archivo');
    }
  }
}

// ── Respuesta tipada ─────────────────────────────────────────
class ApiResp {
  final bool ok;
  final dynamic data;
  final String mensaje;
  final int status;

  ApiResp._({required this.ok, this.data, this.mensaje = '', this.status = 0});

  factory ApiResp._from(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      return ApiResp._(
        ok: ok,
        data: body,
        mensaje: ok ? '' : (body['message'] ?? 'Error desconocido'),
        status: res.statusCode,
      );
    } catch (_) {
      return ApiResp._(ok: false, mensaje: 'Error al procesar respuesta', status: res.statusCode);
    }
  }

  factory ApiResp._error(String msg) =>
      ApiResp._(ok: false, mensaje: msg, status: 0);

  // Errores de validación del Form Request de Laravel
  Map<String, List<String>> get erroresValidacion {
    if (data is Map && data['errors'] != null) {
      final e = data['errors'] as Map;
      return e.map((k, v) => MapEntry(k.toString(),
          (v as List).map((x) => x.toString()).toList()));
    }
    return {};
  }
}


