import 'package:flutter/foundation.dart';

/// Estado global simple del reto activo.
/// Lo usan MapaScreen (para escribir) y MainScreen (para leer en el botón +).
class EstadoReto extends ChangeNotifier {
  static final EstadoReto instancia = EstadoReto._();
  EstadoReto._();

  Map<String, dynamic>? reto;
  Map<String, dynamic>? lugar;

  bool get tieneReto => reto != null;

  void aceptar(Map<String, dynamic> r, Map<String, dynamic> l) {
    reto = r;
    lugar = l;
    notifyListeners();
  }

  void cancelar() {
    reto = null;
    lugar = null;
    notifyListeners();
  }
}


