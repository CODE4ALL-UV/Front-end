import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_dictation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sostener la letra', () {
    test('una letra suelta no se escribe: hay que mantenerla', () {
      final dictation = SignDictation(framesToAccept: 4);

      dictation.offer(_clear('A'));
      dictation.offer(_clear('A'));

      expect(dictation.text, isEmpty);
      expect(dictation.holding, 'A');
      expect(dictation.progress, closeTo(0.5, 0.01));
    });

    test('mantenerla las fotos necesarias la escribe', () {
      final dictation = SignDictation(framesToAccept: 4);

      final events = [for (var i = 0; i < 4; i++) dictation.offer(_clear('A'))];

      expect(events.last, SignDictationEvent.accepted);
      expect(dictation.text, 'A');
    });

    test('cambiar de letra a medias empieza la cuenta de nuevo', () {
      final dictation = SignDictation(framesToAccept: 4);

      dictation
        ..offer(_clear('A'))
        ..offer(_clear('A'))
        ..offer(_clear('B'));

      expect(dictation.holding, 'B');
      expect(dictation.progress, closeTo(0.25, 0.01));
      expect(dictation.text, isEmpty);
    });

    test('la mano moviéndose entre letras no escribe nada', () {
      final dictation = SignDictation(framesToAccept: 4);

      for (final letter in ['A', 'B', 'D', 'B', 'A', 'L']) {
        dictation.offer(_clear(letter));
      }

      expect(dictation.text, isEmpty);
    });
  });

  group('no repetir sin querer', () {
    test('sostener la mano quieta no llena la pantalla de la misma letra', () {
      final dictation = SignDictation(framesToAccept: 3);

      for (var i = 0; i < 20; i++) {
        dictation.offer(_clear('A'));
      }

      expect(dictation.text, 'A');
    });

    test('para repetir letra hay que bajar la mano y volver a subirla', () {
      final dictation = SignDictation(framesToAccept: 3, framesToRelease: 2);

      for (var i = 0; i < 3; i++) {
        dictation.offer(_clear('A'));
      }
      expect(dictation.text, 'A');

      // La mano sale de cuadro.
      dictation.offer(SignRecognitionService.noHand);
      final released = dictation.offer(SignRecognitionService.noHand);
      expect(released, SignDictationEvent.released);

      // Y vuelve con la misma letra.
      for (var i = 0; i < 3; i++) {
        dictation.offer(_clear('A'));
      }

      expect(dictation.text, 'AA');
    });

    test('otra letra distinta sí entra sin bajar la mano', () {
      final dictation = SignDictation(framesToAccept: 3);

      for (var i = 0; i < 3; i++) {
        dictation.offer(_clear('A'));
      }
      for (var i = 0; i < 3; i++) {
        dictation.offer(_clear('B'));
      }

      expect(dictation.text, 'AB');
    });
  });

  group('lecturas que no se deben creer', () {
    test('una lectura dudosa no escribe, por mucho que se repita', () {
      final dictation = SignDictation(framesToAccept: 3);

      for (var i = 0; i < 10; i++) {
        dictation.offer(_doubtful('A'));
      }

      expect(dictation.text, isEmpty);
      expect(dictation.holding, isNull);
    });

    test('una letra ambigua tampoco se escribe', () {
      final dictation = SignDictation(framesToAccept: 3);

      for (var i = 0; i < 10; i++) {
        dictation.offer(_ambiguous('U', ['H']));
      }

      expect(dictation.text, isEmpty);
    });

    test('no ver ninguna mano no rompe nada', () {
      final dictation = SignDictation();

      for (var i = 0; i < 5; i++) {
        expect(
          dictation.offer(SignRecognitionService.noHand),
          SignDictationEvent.nothing,
        );
      }

      expect(dictation.text, isEmpty);
    });
  });

  group('corregir a mano', () {
    test('se puede borrar la última letra', () {
      final dictation = SignDictation(framesToAccept: 2);

      for (final letter in ['A', 'A', 'B', 'B']) {
        dictation.offer(_clear(letter));
      }
      expect(dictation.text, 'AB');

      dictation.backspace();
      expect(dictation.text, 'A');
    });

    test('borrar libera la letra: se puede volver a poner la misma', () {
      final dictation = SignDictation(framesToAccept: 2);

      dictation
        ..offer(_clear('A'))
        ..offer(_clear('A'));
      expect(dictation.text, 'A');

      dictation.backspace();
      dictation
        ..offer(_clear('A'))
        ..offer(_clear('A'));

      expect(dictation.text, 'A');
    });

    test('borrar con la pantalla vacía no revienta', () {
      final dictation = SignDictation()..backspace();
      expect(dictation.text, isEmpty);
    });

    test('el espacio separa palabras y no se duplica', () {
      final dictation = SignDictation(framesToAccept: 2);

      dictation
        ..offer(_clear('A'))
        ..offer(_clear('A'))
        ..addSpace()
        ..addSpace();

      expect(dictation.text, 'A ');
    });

    test('no se empieza el texto con un espacio', () {
      final dictation = SignDictation()..addSpace();
      expect(dictation.text, isEmpty);
    });

    test('empezar de cero deja todo limpio', () {
      final dictation = SignDictation(framesToAccept: 2);

      dictation
        ..offer(_clear('A'))
        ..offer(_clear('A'))
        ..offer(_clear('B'))
        ..clear();

      expect(dictation.text, isEmpty);
      expect(dictation.holding, isNull);
      expect(dictation.progress, 0);
    });
  });
}

SignReading _clear(String letter) => SignReading(
  letter: letter,
  confidence: 0.95,
  observed: signAlphabet[letter]!,
);

SignReading _doubtful(String letter) => SignReading(
  letter: letter,
  confidence: 0.55,
  observed: signAlphabet[letter]!,
);

SignReading _ambiguous(String letter, List<String> others) => SignReading(
  letter: letter,
  confidence: 0.95,
  observed: signAlphabet[letter]!,
  alternatives: others,
);
