import 'package:flutter_code4all/utils/browser_port.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajusta la importación según la ruta de tu proyecto

void main() {
  group('BrowserPort Tests (Stub implementation)', () {
    test('BrowserPort.instance está inicializada correctamente', () {
      final port = BrowserPort.instance;
      expect(port, isNotNull);
    });

    test(
      'Las operaciones de navegación y almacenamiento del stub se ejecutan sin errores',
      () {
        final port = BrowserPort.instance;

        // Verifica la propiedad current
        expect(port.current, isA<Uri>());

        // Verifica los métodos de navegación (stub no hace nada o no lanza excepción)
        expect(() => port.replace('https://example.com/path'), returnsNormally);
        expect(() => port.open('https://example.com/path'), returnsNormally);

        // Verifica las operaciones de sesión (sessionStorage stub)
        expect(() => port.write('my_key', 'my_value'), returnsNormally);

        // Dependiendo de cómo esté implementado el stub en memoria, read puede devolver null o el valor escrito
        final value = port.read('my_key');
        expect(value, anyOf(isNull, equals('my_value')));

        expect(() => port.remove('my_key'), returnsNormally);
      },
    );
  });
}
