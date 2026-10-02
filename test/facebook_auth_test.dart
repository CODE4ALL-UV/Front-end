import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/facebook_auth_service.dart';
import 'package:flutter_code4all/data/services/launch_link.dart';
import 'package:flutter_code4all/utils/browser_port_stub.dart';

class _FakeApi extends ApiService {
  final List<(String, String)> calls = [];

  @override
  Future<LoginResponse> signInWithFacebook({
    required String code,
    required String redirectUri,
  }) async {
    calls.add((code, redirectUri));
    return LoginResponse.fromJson({
      'access_token': 'sesion',
      'token_type': 'bearer',
      'user_id': 7,
      'email': 'ana@hotmail.com',
      'nombre': 'Ana',
      'rol': 'estudiante',
    });
  }
}

/// Entrar con Facebook: ir, volver y comprobar que la vuelta es la nuestra.
void main() {
  const web = 'https://code4all-web.onrender.com';

  late MemoryBrowserPort browser;
  late _FakeApi api;

  FacebookAuthService service({String appId = '1234', bool isWeb = true}) =>
      FacebookAuthService(
        apiService: api,
        browser: browser,
        appId: appId,
        isWeb: isWeb,
        random: Random(1),
      );

  setUp(() {
    LaunchLink.debugReset();
    browser = MemoryBrowserPort(Uri.parse('$web/'));
    api = _FakeApi();
  });

  /// Lo que pasa al volver: Facebook abre la app con estos parámetros.
  void comeBackWith(String query) {
    browser.current = Uri.parse('$web/?$query#_=_');
    LaunchLink.capture(browser);
  }

  test('sin el identificador de la app, el botón no hace como si fuera', () {
    expect(service(appId: '').isAvailable, isFalse);
    expect(service(isWeb: false).isAvailable, isFalse);
    expect(service().isAvailable, isTrue);
  });

  test('va a Facebook pidiendo el correo y volviendo a la portada', () {
    service().start();

    final dialog = Uri.parse(browser.opened.single);
    expect(dialog.host, 'www.facebook.com');
    expect(dialog.path, '/dialog/oauth');
    expect(dialog.queryParameters['client_id'], '1234');
    expect(dialog.queryParameters['redirect_uri'], '$web/');
    expect(dialog.queryParameters['response_type'], 'code');
    expect(dialog.queryParameters['scope'], contains('email'));
    expect(
      dialog.queryParameters['state'],
      browser.storage[FacebookAuthService.stateKey],
    );
  });

  test('a la vuelta, el servidor canjea el código y se entra', () async {
    final facebook = service()..start();
    final state = browser.storage[FacebookAuthService.stateKey]!;

    comeBackWith('code=codigo-de-facebook&state=$state');
    final session = await facebook.finishIfReturning();

    expect(api.calls, [('codigo-de-facebook', '$web/')]);
    expect(session!.rol, 'estudiante');
    // La dirección queda limpia y el valor de comprobación, gastado.
    expect(browser.current.toString(), '$web/');
    expect(browser.storage, isEmpty);
  });

  test('una vuelta que no empezó esta pestaña no entra', () async {
    // Un enlace preparado por otro, con su propio código: si se aceptara, la
    // persona entraría en la cuenta de ese otro sin darse cuenta.
    final facebook = service()..start();

    comeBackWith('code=codigo-ajeno&state=otro-valor');

    await expectLater(
      facebook.finishIfReturning(),
      throwsA(isA<FacebookAuthException>()),
    );
    expect(api.calls, isEmpty);
  });

  test('si se cancela en Facebook, se dice así', () async {
    final facebook = service()..start();

    comeBackWith('error=access_denied&error_reason=user_denied');

    await expectLater(
      facebook.finishIfReturning(),
      throwsA(isA<FacebookAuthCanceledException>()),
    );
  });

  test('si no se viene de Facebook no hace nada', () async {
    expect(LaunchLink.hasFacebookReturn, isFalse);
    expect(await service().finishIfReturning(), isNull);
  });
}
