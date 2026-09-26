import 'package:flutter/material.dart';

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
  GlobalKey<NavigatorState>? _navigatorKey;

  /// La aplicación registra aquí qué hacer al cerrar sesión.
  ///
  /// El `navigatorKey` no es opcional de verdad: sin él, cerrar sesión desde
  /// cualquier pantalla que no sea la de inicio no saca a nadie. La razón es
  /// que la aplicación cambia de pantalla con un `setState` sobre su página
  /// de inicio, pero los módulos siguientes, los capítulos y las actividades
  /// se abren con `Navigator.push` y quedan **encima**. Cambiar la página de
  /// abajo deja el login escondido debajo del módulo donde se estaba.
  void registerLogout(
    VoidCallback? onLogout, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    _onLogout = onLogout;
    _navigatorKey = navigatorKey;
  }

  /// Hay una forma conocida de salir.
  bool get canLogout => _onLogout != null;

  /// Cierra la sesión. Devuelve falso si nadie dijo cómo hacerlo.
  ///
  /// Primero vacía lo que hubiera apilado encima y después cambia la página.
  /// En ese orden: si se cambiara antes, el login se dibujaría debajo de las
  /// pantallas que todavía están puestas.
  bool logout() {
    final action = _onLogout;
    if (action == null) return false;

    _navigatorKey?.currentState?.popUntil((route) => route.isFirst);
    action();
    return true;
  }

  @visibleForTesting
  void debugReset() {
    _onLogout = null;
    _navigatorKey = null;
  }
}
