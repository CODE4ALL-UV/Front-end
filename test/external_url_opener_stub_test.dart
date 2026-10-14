import 'package:flutter/services.dart';
import 'package:flutter_code4all/utils/external_url_opener_stub.dart';
import 'package:flutter_test/flutter_test.dart';

// Asegúrate de ajustar la ruta de importación según tu proyecto
// import 'package:flutter_code4all/external_url_opener_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExternalUrlOpener Tests', () {
    setUp(() {
      // Interceptamos por defecto el canal de url_launcher para simular éxito
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'launch') {
                return true; // Simula que se abrió con éxito
              }
              return null;
            },
          );
    });

    tearDown(() {
      // Limpiamos el handler después de cada test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            null,
          );
    });

    test(
      'openExternalUrl retorna true cuando el lanzamiento es exitoso',
      () async {
        final result = await openExternalUrl(
          'https://www.youtube.com/watch?v=123456',
        );
        expect(result, isTrue);
      },
    );

    test('openExternalUrl retorna false cuando el lanzamiento falla', () async {
      // Configuramos el mock para simular un fallo (retorna false)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/url_launcher'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'launch') {
                return false;
              }
              return null;
            },
          );

      final result = await openExternalUrl('https://url-fallida.com');
      expect(result, isFalse);
    });
  });
}
