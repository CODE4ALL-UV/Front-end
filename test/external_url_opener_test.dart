import 'package:flutter/services.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajusta la importación según la ruta de tu proyecto

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExternalUrlOpener (Router) Tests', () {
    setUp(() {
      // Interceptamos el canal nativo de url_launcher para simular éxito
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'launch') {
                return true;
              }
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            null,
          );
    });

    test(
      'openExternalUrl delega correctamente y retorna el resultado esperado',
      () async {
        final result = await openExternalUrl('https://www.youtube.com');
        expect(result, isTrue);
      },
    );
  });
}
