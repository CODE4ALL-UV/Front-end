import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';

void main() {
  group('VoiceDictation - normalize', () {
    test(
      'DictationKind.text respeta los espacios internos pero limpia los extremos',
      () {
        expect(
          VoiceDictation.normalize('   Hola cómo estás   ', DictationKind.text),
          'Hola cómo estás',
        );
      },
    );

    test('DictationKind.password elimina absolutamente todos los espacios', () {
      expect(
        VoiceDictation.normalize(
          ' mi clave  secreta 123 ',
          DictationKind.password,
        ),
        'miclavesecreta123',
      );
    });

    test('DictationKind.email convierte palabras clave a símbolos', () {
      expect(
        VoiceDictation.normalize(
          'juan arroba gmail punto com',
          DictationKind.email,
        ),
        'juan@gmail.com',
      );
    });

    test('DictationKind.email elimina tildes y diéresis correctamente', () {
      expect(
        VoiceDictation.normalize(
          'sebastián arroba pingüino punto com',
          DictationKind.email,
        ),
        'sebastian@pinguino.com',
      );
    });
  });

  group('DictationUnavailableException', () {
    test('Muestra el mensaje correcto al convertirse a String', () {
      final exception = DictationUnavailableException(
        'Falta permiso de micrófono.',
      );
      expect(exception.toString(), 'Falta permiso de micrófono.');
    });
  });
}
