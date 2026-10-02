import 'package:flutter/foundation.dart';

import '../../utils/browser_port.dart';

/// Lo que trae la dirección con la que se abrió la app.
///
/// Llegan así dos cosas:
/// - el enlace del correo para cambiar la contraseña: `?restablecer=…`;
/// - la vuelta de Facebook tras iniciar sesión: `?code=…&state=…`, o
///   `?error=…` si la persona canceló.
///
/// Se lee una vez, en `main()`, antes de arrancar Flutter, y la dirección
/// queda limpia: el token no se queda en la barra, en el historial ni en una
/// captura de pantalla, y Flutter no intenta abrir esos parámetros como si
/// fueran una ruta.
class LaunchLink {
  LaunchLink._();

  static const _ours = {
    'restablecer',
    'code',
    'state',
    'error',
    'error_reason',
    'error_code',
    'error_description',
    'error_message',
  };

  static Map<String, String> _params = {};

  static void capture([BrowserPort? browser]) {
    final port = browser ?? BrowserPort.instance;
    final uri = port.current;
    // Fuera de la web la «dirección» es una ruta de archivo, sin parámetros.
    if (uri.scheme != 'http' && uri.scheme != 'https') return;
    final params = Map.of(uri.queryParameters)
      ..removeWhere((key, _) => !_ours.contains(key));
    if (params.isEmpty) return;

    _params = params;
    port.replace('${uri.origin}${uri.path}');
  }

  /// La app se abrió volviendo de Facebook.
  static bool get hasFacebookReturn =>
      _params.containsKey('code') || _params.containsKey('error');

  /// El token del enlace para cambiar la contraseña, si se abrió con él.
  static String? takeResetToken() {
    final token = _params.remove('restablecer');
    return (token == null || token.isEmpty) ? null : token;
  }

  /// Lo que devolvió Facebook, si se viene de allí.
  static FacebookReturn? takeFacebookReturn() {
    final code = _params.remove('code');
    final state = _params.remove('state');
    final error = _params.remove('error');
    final reason = _params.remove('error_reason');
    final message =
        _params.remove('error_message') ?? _params.remove('error_description');
    _params.remove('error_code');

    if (code == null && error == null) return null;
    return FacebookReturn(
      code: code,
      state: state,
      error: error,
      errorReason: reason,
      errorMessage: message,
    );
  }

  @visibleForTesting
  static void debugReset() => _params = {};
}

/// La respuesta de Facebook al volver a la app.
class FacebookReturn {
  const FacebookReturn({
    this.code,
    this.state,
    this.error,
    this.errorReason,
    this.errorMessage,
  });

  final String? code;
  final String? state;
  final String? error;
  final String? errorReason;
  final String? errorMessage;

  /// La persona dijo que no en la pantalla de Facebook.
  bool get canceled => error == 'access_denied' || errorReason == 'user_denied';
}
