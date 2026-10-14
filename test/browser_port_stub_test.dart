import 'package:flutter_code4all/utils/browser_port_stub.dart';
import 'package:flutter_test/flutter_test.dart';

// Ajusta la importación según la ruta de tu proyecto

void main() {
  group('MemoryBrowserPort Stub Tests', () {
    test(
      'createBrowserPort instancia MemoryBrowserPort con Uri.base por defecto',
      () {
        final port = createBrowserPort();
        expect(port, isA<MemoryBrowserPort>());
        expect(port.current, equals(Uri.base));
      },
    );

    test('replace actualiza la dirección current correctamente', () {
      final port = MemoryBrowserPort(Uri.parse('https://inicio.com'));
      port.replace('https://destino.com/ruta?param=1');
      expect(
        port.current,
        equals(Uri.parse('https://destino.com/ruta?param=1')),
      );
    });

    test('open registra las URLs abiertas en la lista opened', () {
      final port = MemoryBrowserPort(Uri.base);
      expect(port.opened, isEmpty);

      port.open('https://ejemplo.com/pagina1');
      port.open('https://ejemplo.com/pagina2');

      expect(port.opened, [
        'https://ejemplo.com/pagina1',
        'https://ejemplo.com/pagina2',
      ]);
    });

    test(
      'read, write y remove gestionan el almacenamiento local correctamente',
      () {
        final port = MemoryBrowserPort(Uri.base);

        // Leer una clave que no existe
        expect(port.read('sesion_key'), isNull);

        // Escribir y leer un valor
        port.write('sesion_key', 'token_12345');
        expect(port.read('sesion_key'), equals('token_12345'));

        // Eliminar la clave y verificar que desaparece
        port.remove('sesion_key');
        expect(port.read('sesion_key'), isNull);
      },
    );
  });
}
