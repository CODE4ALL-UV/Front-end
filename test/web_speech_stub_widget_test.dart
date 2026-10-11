import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/web_speech_stub_widget.dart'
    as web_speech;

void main() {
  group('WebSpeechStub Tests (móvil y escritorio)', () {
    test('speakWithBrowserVoice no lanza excepciones', () {
      expect(
        () => web_speech.speakWithBrowserVoice('Hola mundo'),
        returnsNormally,
      );
    });

    test('speakWithBrowserVoice acepta idioma y velocidad personalizados', () {
      expect(
        () => web_speech.speakWithBrowserVoice(
          'Texto de prueba',
          language: 'es-CO',
          rate: 1.2,
        ),
        returnsNormally,
      );
    });

    test('cancelBrowserVoice no lanza excepciones', () {
      expect(web_speech.cancelBrowserVoice, returnsNormally);
    });

    test('pauseBrowserVoice no lanza excepciones', () {
      expect(web_speech.pauseBrowserVoice, returnsNormally);
    });

    test('resumeBrowserVoice no lanza excepciones', () {
      expect(web_speech.resumeBrowserVoice, returnsNormally);
    });

    test('isBrowserVoiceAvailable devuelve false', () {
      expect(web_speech.isBrowserVoiceAvailable, isFalse);
    });
  });
}
