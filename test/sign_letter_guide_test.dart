import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_dictation.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_letter_guide.dart';

/// La guía del alfabeto dice lo mismo que espera la cámara.
void main() {
  test('cada letra del alfabeto tiene sus instrucciones', () {
    for (final letter in signAlphabet.keys) {
      final steps = SignLetterGuide.steps(letter);
      expect(steps.length, greaterThanOrEqualTo(5), reason: letter);
      expect(steps.first, startsWith('Índice:'), reason: letter);
    }
  });

  test('la A: puño con el pulgar hacia el lado', () {
    expect(SignLetterGuide.steps('A'), [
      'Índice: recogido sobre la palma.',
      'Corazón: recogido sobre la palma.',
      'Anular: recogido sobre la palma.',
      'Meñique: recogido sobre la palma.',
      'Pulgar: bien separado, hacia el lado.',
    ]);
  });

  test('la V pide abrir los dedos; la U, juntarlos', () {
    expect(
      SignLetterGuide.steps('V'),
      contains('Abre bien los dedos estirados, en V.'),
    );
    expect(
      SignLetterGuide.steps('U'),
      contains('Los dedos estirados, juntos.'),
    );
  });

  test('P y Q avisan de que la mano va hacia abajo', () {
    for (final letter in ['P', 'Q']) {
      expect(
        SignLetterGuide.steps(letter).last,
        contains('hacia abajo'),
        reason: letter,
      );
    }
  });

  test('H y U: la guía dice que la cámara no las distingue', () {
    // En la tabla son idénticas. Prometer otra cosa sería mentir.
    expect(SignLetterGuide.identicalTo('H'), contains('U'));
    expect(SignLetterGuide.identicalTo('U'), contains('H'));
  });

  test('V y U: la pista dice que junte o separe los dedos', () {
    // Antes decía «Casi. Mantén la mano quieta», que no ayuda a nada.
    expect(SignLetterGuide.fixWhenReadAs('V', 'U'), contains('Separa más'));
    expect(SignLetterGuide.fixWhenReadAs('U', 'V'), contains('Junta más'));
  });

  test('las parejas que la cámara no distingue se listan una vez', () {
    final pairs = SignLetterGuide.identicalPairs;
    expect(pairs, contains(('H', 'U')));
    expect(pairs, isNot(contains(('U', 'H'))));
  });

  test('las letras con movimiento no prometen nada', () {
    for (final letter in ['J', 'Ñ', 'Z']) {
      expect(signAlphabet[letter]!.hasMotion, isTrue);
      expect(SignLetterGuide.identicalTo(letter), isEmpty);
      expect(SignLetterGuide.similarTo(letter), isEmpty);
    }
  });

  test('para letras parecidas, dice qué corregir', () {
    expect(SignLetterGuide.similarTo('M'), contains('N'));
    // Si se quería M y la cámara lee N, falta estirar a medias el anular.
    expect(SignLetterGuide.fixWhenReadAs('M', 'N'), 'Estira más el anular.');
  });

  test('el tiempo que se dice coincide con el de la pantalla', () {
    expect(SignLetterGuide.framesToAccept, SignDictation().framesToAccept);
    expect(SignLetterGuide.holdSeconds, '2');
  });

  test('las letras parecidas lo son para el reconocimiento de verdad', () {
    for (final letter in signAlphabet.keys) {
      for (final other in SignLetterGuide.identicalTo(letter)) {
        expect(
          HandLandmarkClassifier.shapeDistance(
            signAlphabet[letter]!,
            signAlphabet[other]!,
          ),
          lessThanOrEqualTo(HandLandmarkClassifier.tieMargin),
        );
      }
    }
  });
}
