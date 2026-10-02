import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../utils/browser_port.dart';
import '../models/auth_models.dart';
import 'api_service.dart';
import 'launch_link.dart';

class FacebookAuthException implements Exception {
  const FacebookAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FacebookAuthCanceledException implements Exception {
  const FacebookAuthCanceledException();
}

/// Entrar o registrarse con Facebook.
///
/// No se carga el SDK de Facebook: la página entera va a Facebook y vuelve
/// con un código que el servidor canjea con la clave secreta de la app. Así:
/// - no hay ventana emergente que el navegador bloquee o que el lector de
///   pantalla no anuncie;
/// - el script de Facebook, que rastrea, no se carga en cada visita al login;
/// - el token de Facebook nunca pasa por el navegador.
///
/// El identificador de la app se fija al compilar:
///
///     flutter build web --dart-define=FACEBOOK_APP_ID=1234567890
///
/// Sin él, el botón dice que todavía no está disponible.
class FacebookAuthService {
  FacebookAuthService({
    ApiService? apiService,
    BrowserPort? browser,
    String? appId,
    bool? isWeb,
    Random? random,
  }) : _api = apiService ?? ApiService(),
       _browser = browser ?? BrowserPort.instance,
       appId = appId ?? _configuredAppId,
       _isWeb = isWeb ?? kIsWeb,
       _random = random ?? Random.secure();

  static const String _configuredAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
  );

  /// Dónde se guarda, mientras se va y se vuelve de Facebook, el valor que
  /// prueba que la vuelta la empezó esta pestaña y no un enlace ajeno.
  static const stateKey = 'code4all.facebook.state';

  final ApiService _api;
  final BrowserPort _browser;
  final String appId;
  final bool _isWeb;
  final Random _random;

  bool get isAvailable => _isWeb && appId.isNotEmpty;

  /// La dirección a la que Facebook devuelve: la portada de la app. Tiene que
  /// estar, tal cual, en «URI de redireccionamiento de OAuth válidos» de la
  /// app de Facebook.
  String get redirectUri => '${_browser.current.origin}/';

  /// Manda la página a Facebook. La app se cierra y vuelve a abrirse a la
  /// vuelta; entonces sigue [finishIfReturning].
  void start() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    final state = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _browser.write(stateKey, state);

    final dialog = Uri.https('www.facebook.com', '/dialog/oauth', {
      'client_id': appId,
      'redirect_uri': redirectUri,
      'state': state,
      'response_type': 'code',
      'scope': 'public_profile,email',
    });
    _browser.open(dialog.toString());
  }

  /// Si la app se abrió volviendo de Facebook, termina de entrar.
  ///
  /// Devuelve null si no se viene de Facebook.
  Future<LoginResponse?> finishIfReturning() async {
    final back = LaunchLink.takeFacebookReturn();
    if (back == null) return null;

    final expected = _browser.read(stateKey);
    _browser.remove(stateKey);

    if (back.canceled) throw const FacebookAuthCanceledException();
    if (back.error != null) {
      throw FacebookAuthException(
        'Facebook no dejó iniciar sesión'
        '${back.errorMessage == null ? '' : ': ${back.errorMessage}'}.',
      );
    }

    // Sin esta comprobación, un enlace preparado por otro podría meter a la
    // persona en la cuenta de Facebook de ese otro sin que se diera cuenta.
    if (expected == null || back.state != expected || back.code == null) {
      throw const FacebookAuthException(
        'No se pudo comprobar el inicio con Facebook. Vuelve a intentarlo.',
      );
    }

    return _api.signInWithFacebook(code: back.code!, redirectUri: redirectUri);
  }
}
