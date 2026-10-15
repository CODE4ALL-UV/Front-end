import 'dart:math';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/facebook_auth_service.dart';
import 'package:flutter_code4all/utils/browser_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Ajusta estas rutas según tu proyecto
// import 'package:flutter_code4all/data/services/api_service.dart';
// import 'package:flutter_code4all/utils/browser_port.dart';
// import 'package:flutter_code4all/data/services/facebook_auth_service.dart';

class MockApiService extends Mock implements ApiService {}

class MockBrowserPort extends Mock implements BrowserPort {}

class MockRandom extends Mock implements Random {}

void main() {
  group('FacebookAuthService Tests', () {
    late MockApiService mockApi;
    late MockBrowserPort mockBrowser;
    late MockRandom mockRandom;

    setUp(() {
      mockApi = MockApiService();
      mockBrowser = MockBrowserPort();
      mockRandom = MockRandom();

      // Asumimos que BrowserPort.current devuelve un Uri o una clase con la propiedad 'origin'
      when(
        () => mockBrowser.current,
      ).thenReturn(Uri.parse('https://mi-app.com'));
    });

    test(
      'Excepciones personalizadas devuelven el mensaje esperado en toString',
      () {
        const ex = FacebookAuthException('Error con Facebook');
        expect(ex.toString(), 'Error con Facebook');
      },
    );

    test('isAvailable depende de isWeb y de que el appId no esté vacío', () {
      final serviceWebValido = FacebookAuthService(
        isWeb: true,
        appId: '12345',
        browser: mockBrowser,
      );
      expect(serviceWebValido.isAvailable, true);

      final serviceNoWeb = FacebookAuthService(
        isWeb: false,
        appId: '12345',
        browser: mockBrowser,
      );
      expect(serviceNoWeb.isAvailable, false);

      final serviceSinAppId = FacebookAuthService(
        isWeb: true,
        appId: '',
        browser: mockBrowser,
      );
      expect(serviceSinAppId.isAvailable, false);
    });

    test('redirectUri construye la URL usando el origin del navegador', () {
      final service = FacebookAuthService(
        browser: mockBrowser,
        isWeb: true,
        appId: '12345',
      );
      expect(service.redirectUri, 'https://mi-app.com/');
    });

    test(
      'start() genera un estado seguro y abre el dialog de OAuth de Facebook',
      () {
        // Configuramos el Random simulado para que siempre devuelva 255 (FF en hexadecimal)
        when(() => mockRandom.nextInt(256)).thenReturn(255);

        // Simulamos los métodos void del navegador para que no hagan nada real
        when(() => mockBrowser.write(any(), any())).thenReturn(null);
        when(() => mockBrowser.open(any())).thenReturn(null);

        final service = FacebookAuthService(
          browser: mockBrowser,
          appId: 'mi_app_id',
          isWeb: true,
          random: mockRandom,
        );

        service.start();

        // 1. Verificamos que se haya generado un state de 24 bytes convertido a hexadecimal (48 caracteres 'ff')
        final expectedState = List.filled(24, 'ff').join();
        verify(
          () => mockBrowser.write(FacebookAuthService.stateKey, expectedState),
        ).called(1);

        // 2. Verificamos que se haya construido y abierto la URL correctamente
        final capturedArgs = verify(
          () => mockBrowser.open(captureAny()),
        ).captured;
        final openedUrl = capturedArgs.first as String;
        final uri = Uri.parse(openedUrl);

        expect(uri.scheme, 'https');
        expect(uri.host, 'www.facebook.com');
        expect(uri.path, '/dialog/oauth');
        expect(uri.queryParameters['client_id'], 'mi_app_id');
        expect(uri.queryParameters['redirect_uri'], 'https://mi-app.com/');
        expect(uri.queryParameters['state'], expectedState);
        expect(uri.queryParameters['response_type'], 'code');
        expect(uri.queryParameters['scope'], 'public_profile,email');
      },
    );

    test(
      'finishIfReturning() retorna null si LaunchLink no detecta parámetros de retorno',
      () async {
        final service = FacebookAuthService(browser: mockBrowser);

        // Dado que LaunchLink.takeFacebookReturn() es estático y en un entorno
        // de test (Dart puro) evalúa en nulo porque no hay un deep link real,
        // esto valida las líneas iniciales de escape temprano de la función.
        final result = await service.finishIfReturning();

        expect(result, isNull);
      },
    );
  });
}
