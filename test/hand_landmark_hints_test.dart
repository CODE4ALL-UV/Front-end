import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';

/// Las pistas del modo práctica de la cámara de señas.
///
/// Cuando el estudiante intenta una letra y la cámara ve otra, la pantalla no
/// dice «incorrecto»: dice qué cambiar. Las pruebas del clasificador ya
/// cubren los dedos largos; aquí se comprueba cada uno de los demás detalles,
/// en el orden en que se revisan (pulgar, pulgar cruzado, mano hacia abajo,
/// dedos cruzados y apertura), y que una mano que no se parece a ninguna letra
/// no se fuerza a serlo.
void main() {
  String hint(HandShape observed, String target) =>
      HandLandmarkClassifier.hint(observed, target);

  group('qué le falta a la mano', () {
    test('el pulgar: separarlo o pegarlo', () {
      // Puño con el pulgar recogido, cuando la A lo lleva fuera.
      expect(
        hint(
          const HandShape(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 0),
          'A',
        ),
        'Separa el pulgar de la mano.',
      );
      // Meñique arriba con el pulgar fuera, cuando la I lo lleva pegado.
      expect(
        hint(
          const HandShape(thumb: 2, index: 0, middle: 0, ring: 0, pinky: 2),
          'I',
        ),
        'Pega el pulgar a la mano.',
      );
    });

    test('el pulgar cruzado sobre la palma', () {
      expect(
        hint(
          const HandShape(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 0),
          'E',
        ),
        'Cruza el pulgar sobre la palma.',
      );
      expect(
        hint(
          const HandShape(
            thumb: 0,
            index: 0,
            middle: 0,
            ring: 0,
            pinky: 2,
            thumbAcross: true,
          ),
          'I',
        ),
        'Saca el pulgar hacia el lado.',
      );
    });

    test('hacia dónde apunta la mano', () {
      // La K y la P se hacen igual, pero la P apunta hacia abajo.
      expect(hint(signAlphabet['K']!, 'P'), 'Apunta la mano hacia abajo.');
      expect(hint(signAlphabet['P']!, 'K'), 'Apunta la mano hacia arriba.');
    });

    test('el índice cruzado sobre el corazón', () {
      expect(
        hint(signAlphabet['U']!, 'R'),
        'Cruza el índice sobre el corazón.',
      );
      expect(hint(signAlphabet['R']!, 'U'), 'Separa el índice del corazón.');
    });

    test('cuánto se abren los dedos estirados', () {
      expect(hint(signAlphabet['U']!, 'V'), 'Separa más los dedos estirados.');
      expect(hint(signAlphabet['V']!, 'U'), 'Junta más los dedos estirados.');
      // La G y la L solo cambian en cuánto se abre el pulgar del índice.
      expect(hint(signAlphabet['G']!, 'L'), 'Separa más los dedos estirados.');
    });

    test('si la forma ya es la buena, solo pide sujetarla', () {
      expect(
        hint(signAlphabet['B']!, 'B'),
        'Casi. Mantén la mano quieta y bien enfocada.',
      );
      // Una apertura casi igual también cuenta como buena.
      expect(
        hint(
          const HandShape(
            thumb: 0,
            index: 2,
            middle: 2,
            ring: 0,
            pinky: 0,
            spread: 0.6,
          ),
          'V',
        ),
        'Casi. Mantén la mano quieta y bien enfocada.',
      );
    });
  });

  group('una mano que no se parece a ninguna letra', () {
    test('no se fuerza a una letra, pero se describe lo que se vio', () {
      // Índice y anular estirados, corazón y meñique recogidos y la mano
      // hacia abajo: ninguna letra del alfabeto se hace así.
      final reading = HandLandmarkClassifier.classify(
        _hand(stretched: const [true, false, true, false], pointsDown: true),
      );

      expect(reading.letter, isNull);
      expect(reading.confidence, lessThan(0.5));
      expect(reading.isConfident, isFalse);
      expect(reading.isAmbiguous, isFalse);

      // La forma observada sí se conserva: con ella se dan las pistas.
      expect(reading.observed.fingers, [2, 0, 2, 0]);
      expect(reading.observed.pointsDown, isTrue);
      expect(hint(reading.observed, 'W'), 'Estira más el corazón.');
    });

    test('la misma mano hacia arriba con un solo dedo sí es una letra', () {
      // Control: el método de construir la mano produce letras reales.
      final reading = HandLandmarkClassifier.classify(
        _hand(stretched: const [false, false, false, true], pointsDown: false),
      );

      expect(reading.letter, 'I');
    });
  });
}

/// Una mano sencilla: cada dedo largo recto o recogido sobre su nudillo, y el
/// pulgar metido en la palma.
///
/// Con [pointsDown] se voltea alrededor de la muñeca, como una mano que apunta
/// al suelo.
List<HandLandmark> _hand({
  required List<bool> stretched,
  required bool pointsDown,
}) {
  const wrist = (0.50, 0.90);
  const knuckleY = 0.68;
  const knuckleX = [0.42, 0.49, 0.56, 0.63];

  final points = <(double, double)>[
    wrist,
    // Pulgar: de la base, junto a la muñeca, hasta la palma.
    (0.44, 0.84),
    (0.46, 0.80),
    (0.48, 0.76),
    (0.50, 0.72),
  ];

  for (var finger = 0; finger < 4; finger++) {
    final x = knuckleX[finger];
    if (stretched[finger]) {
      points.addAll([
        (x, knuckleY),
        (x, knuckleY - 0.09),
        (x, knuckleY - 0.155),
        (x, knuckleY - 0.21),
      ]);
    } else {
      // Sube una falange y vuelve hacia el nudillo: dedo recogido.
      points.addAll([
        (x, knuckleY),
        (x, knuckleY - 0.08),
        (x + 0.03, knuckleY - 0.04),
        (x + 0.01, knuckleY - 0.01),
      ]);
    }
  }

  return [
    for (final (x, y) in points)
      HandLandmark(x, pointsDown ? 2 * wrist.$2 - y : y),
  ];
}
