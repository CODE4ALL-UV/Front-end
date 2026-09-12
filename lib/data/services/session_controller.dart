import 'package:flutter/foundation.dart';

/// Cómo se sale de la sesión, desde cualquier pantalla.
///
/// El problema que resuelve: el menú de la cuenta solo estaba en las pantallas
/// principales, porque para cerrar sesión hacía falta que alguien le pasara
/// una función que supiera volver al login. Dentro de una lectura, de un
/// editor o de la cámara no había quién se la pasara, así que no había menú.
///
/// Con esto la aplicación registra **una vez** cómo se sale, y cualquier
/// pantalla puede ofrecerlo sin recibir nada.
class SessionController {
  SessionController._();

  static final SessionController instance = SessionController._();

  VoidCallback? _onLogout;

  /// La aplicación registra aquí qué hacer al cerrar sesión.
  void registerLogout(VoidCallback? onLogout) {
    _onLogout = onLogout;
  }

  /// Hay una forma conocida de salir.
  bool get canLogout => _onLogout != null;

  /// Cierra la sesión. Devuelve falso si nadie dijo cómo hacerlo.
  bool logout() {
    final action = _onLogout;
    if (action == null) return false;

    action();
    return true;
  }

  @visibleForTesting
  void debugReset() => _onLogout = null;
}
