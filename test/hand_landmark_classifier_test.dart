import 'dart:math' as math;

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pruebas del reconocimiento del alfabeto manual.
///
/// Las manos se construyen a mano, colocando los 21 puntos como lo haría
/// MediaPipe: la muñeca abajo, la fila de nudillos encima y cada dedo como una
/// cadena de tres falanges que se dobla un ángulo en cada articulación. Doblar
/// de verdad la cadena es lo que hace que la prueba valga: el clasificador
/// tiene que deducir el grado de extensión a partir de la geometría, igual que
/// hará con una mano real.
///
/// Lo que **no** prueban es el acierto con manos reales, que depende de la
/// cámara, la luz y de que la persona haga la letra como la describe la tabla.
/// Eso solo se sabe probándolo con personas.
void main() {
  group('extensión de los dedos', () {
    test('un dedo recto se lee como estirado y uno cerrado como recogido', () {
      final open = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 2, 2], thumb: 0, thumbAcross: true),
      );
      expect(open.fingers, [2, 2, 2, 2]);

      final fist = HandLandmarkClassifier.describe(
        _hand(fingers: [0, 0, 0, 0], thumb: 2),
      );
      expect(fist.fingers, [0, 0, 0, 0]);
    });

    test('un dedo a medio doblar no se confunde con ninguno de los dos', () {
      final half = HandLandmarkClassifier.describe(
        _hand(fingers: [1, 1, 1, 1], thumb: 1),
      );
      expect(half.fingers, [1, 1, 1, 1]);
    });

    test('la lectura no cambia si la mano está más cerca de la cámara', () {
      // El meñique es más corto que el corazón y una mano cercana ocupa más
      // pantalla: ni una cosa ni la otra pueden alterar el resultado.
      final near = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 0, 0, 2], thumb: 2, scale: 2.4),
      );
      expect(near.fingers, [2, 0, 0, 2]);
    });
  });

  group('rasgos de la mano', () {
    test('la apertura sube cuando los dedos se abren en abanico', () {
      final together = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 0),
      );
      final apart = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 0, spread: 0.8),
      );

      expect(together.spread, lessThan(0.2));
      expect(apart.spread, greaterThan(0.6));
    });

    test('la mano invertida se detecta como apuntando hacia abajo', () {
      final up = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 2, spread: 0.6),
      );
      final down = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 2, spread: 0.6, pointsDown: true),
      );

      expect(up.pointsDown, isFalse);
      expect(down.pointsDown, isTrue);
    });

    test('el índice cruzado sobre el corazón se detecta', () {
      final straight = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 0),
      );
      final crossed = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 0, crossed: true),
      );

      expect(straight.crossed, isFalse);
      expect(crossed.crossed, isTrue);
    });

    test('el pulgar cruzado sobre la palma se distingue del que sale al lado', () {
      final across = HandLandmarkClassifier.describe(
        _hand(fingers: [0, 0, 0, 0], thumb: 0, thumbAcross: true),
      );
      final aside = HandLandmarkClassifier.describe(
        _hand(fingers: [0, 0, 0, 0], thumb: 2),
      );

      expect(across.thumbAcross, isTrue);
      expect(aside.thumbAcross, isFalse);
      expect(aside.thumb, 2);
    });
  });

  group('letras que se reconocen con claridad', () {
    // Estas son las letras cuya forma se distingue de verdad con estas
    // medidas. No es todo el alfabeto, y decirlo es parte del trato.
    const clear = {
      'A': (fingers: [0, 0, 0, 0], thumb: 2, across: false, spread: 0.0),
      'B': (fingers: [2, 2, 2, 2], thumb: 0, across: true, spread: 0.0),
      'D': (fingers: [2, 0, 0, 0], thumb: 1, across: false, spread: 0.0),
      'I': (fingers: [0, 0, 0, 2], thumb: 0, across: false, spread: 0.0),
      'L': (fingers: [2, 0, 0, 0], thumb: 2, across: false, spread: 0.9),
      'V': (fingers: [2, 2, 0, 0], thumb: 0, across: false, spread: 0.8),
      'W': (fingers: [2, 2, 2, 0], thumb: 0, across: false, spread: 0.7),
      'Y': (fingers: [0, 0, 0, 2], thumb: 2, across: false, spread: 1.0),
    };

    clear.forEach((letter, pose) {
      test('la $letter se reconoce sin dudas', () {
        final reading = HandLandmarkClassifier.classify(
          _hand(
            fingers: pose.fingers,
            thumb: pose.thumb,
            thumbAcross: pose.across,
            spread: pose.spread,
          ),
        );

        expect(reading.letter, letter, reason: 'se leyó ${reading.letter}');
        expect(reading.alternatives, isEmpty);
        expect(reading.isConfident, isTrue);
      });
    });

    test('la P se reconoce por apuntar hacia abajo, no se confunde con la K', () {
      final reading = HandLandmarkClassifier.classify(
        _hand(fingers: [2, 2, 0, 0], thumb: 2, spread: 0.6, pointsDown: true),
      );

      expect(reading.letter, 'P');
      expect(reading.alternatives, isNot(contains('K')));
    });
  });

  group('lo que el método no puede distinguir', () {
    test('la H y la U salen las dos, porque se hacen igual', () {
      // En la tabla son idénticas dedo por dedo. Elegir una sería inventarse
      // una certeza que no existe.
      final reading = HandLandmarkClassifier.classify(
        _hand(fingers: [2, 2, 0, 0], thumb: 0),
      );

      expect(reading.isAmbiguous, isTrue);
      expect({reading.letter, ...reading.alternatives}, containsAll(['H', 'U']));
      expect(reading.isConfident, isFalse);
    });

    test('la J no se propone nunca: lleva movimiento', () {
      // La J es la I con un trazo. Ante esa forma hay que decir I, no J.
      final reading = HandLandmarkClassifier.classify(
        _hand(fingers: [0, 0, 0, 2], thumb: 0),
      );

      expect(reading.letter, isNot('J'));
      expect(reading.alternatives, isNot(contains('J')));
    });

    test('ninguna letra con movimiento entra en el resultado', () {
      final motion = signAlphabet.entries
          .where((entry) => entry.value.hasMotion)
          .map((entry) => entry.key)
          .toSet();
      expect(motion, isNotEmpty, reason: 'la tabla debería tener J, Z y Ñ');

      for (final pose in _sampleHands) {
        final reading = HandLandmarkClassifier.classify(pose);
        expect(motion, isNot(contains(reading.letter)));
        for (final alternative in reading.alternatives) {
          expect(motion, isNot(contains(alternative)));
        }
      }
    });
  });

  group('cuando no hay nada que leer', () {
    test('con menos de 21 puntos no se arriesga ninguna letra', () {
      final reading = HandLandmarkClassifier.classify(const [
        HandLandmark(0.5, 0.5),
        HandLandmark(0.4, 0.4),
      ]);

      expect(reading.letter, isNull);
      expect(reading.confidence, 0);
    });

    test('unos puntos amontonados no producen una letra', () {
      final blob = List.filled(21, const HandLandmark(0.5, 0.5));
      final reading = HandLandmarkClassifier.classify(blob);

      expect(reading.letter, isNull);
    });
  });

  group('la ayuda dice qué corregir', () {
    test('señala el dedo que falta por estirar', () {
      final observed = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 0, 0, 0], thumb: 0),
      );

      // Le falta el corazón para llegar a la U.
      expect(HandLandmarkClassifier.hint(observed, 'U'), contains('corazón'));
    });

    test('señala el dedo que sobra', () {
      final observed = HandLandmarkClassifier.describe(
        _hand(fingers: [2, 2, 0, 0], thumb: 0),
      );

      expect(HandLandmarkClassifier.hint(observed, 'D'), contains('corazón'));
      expect(HandLandmarkClassifier.hint(observed, 'D'), contains('Recoge'));
    });

    test('avisa de que una letra con movimiento no se puede comprobar', () {
      final observed = HandLandmarkClassifier.describe(
        _hand(fingers: [0, 0, 0, 2], thumb: 0),
      );

      expect(HandLandmarkClassifier.hint(observed, 'J'), contains('movimiento'));
    });

    test('una letra que no existe no revienta', () {
      final observed = HandLandmarkClassifier.describe(
        _hand(fingers: [0, 0, 0, 0], thumb: 2),
      );

      expect(HandLandmarkClassifier.hint(observed, '#'), isNotEmpty);
    });
  });
}

// --- Manos de mentira, colocadas como las colocaría MediaPipe --------------

const double _wristX = 0.50;
const double _wristY = 0.90;
const double _knuckleY = 0.68;

/// Dónde cae el nudillo de cada dedo, de índice a meñique.
const List<double> _knuckleX = [0.42, 0.49, 0.56, 0.63];

/// Largo de cada dedo. El meñique es más corto a propósito.
const List<double> _fingerLength = [0.20, 0.22, 0.20, 0.16];

/// Reparto del largo entre las tres falanges.
const List<double> _boneShare = [0.45, 0.30, 0.25];

/// Cuánto se dobla cada articulación según el grado de extensión.
const List<double> _bendDegrees = [95, 50, 0];

/// Cuánto se abre un dedo en abanico cuando la apertura es máxima.
const double _maxFanDegrees = 22;

/// Dónde queda la punta del pulgar según cómo esté colocado.
///
/// Se coloca a mano porque el pulgar no se dobla como los demás dedos: lo que
/// lo define es hacia dónde apunta, no cuánto se curva.
const Map<(int, bool), (double, double)> _thumbTips = {
  (0, false): (0.50, 0.72), // metido en la palma
  (1, false): (0.45, 0.80), // pegado al canto, sin sobresalir
  (0, true): (0.56, 0.62), // cruzado por delante de los dedos
  (1, true): (0.70, 0.87), // cruzado, asomando por el otro canto
};

/// El pulgar separado, pero pegado al índice: la G.
const (double, double) _thumbAlongside = (0.36, 0.58);

/// El pulgar separado y abierto en ángulo recto: la L.
const (double, double) _thumbWideOpen = (0.25, 0.70);

/// La base del pulgar, junto a la muñeca.
const (double, double) _thumbBase = (0.44, 0.84);

/// Construye los 21 puntos de una mano con la postura que se le pida.
///
/// [fingers] lleva el grado de extensión de índice, corazón, anular y meñique.
List<HandLandmark> _hand({
  required List<int> fingers,
  required int thumb,
  bool thumbAcross = false,
  double spread = 0.0,
  bool pointsDown = false,
  bool crossed = false,
  double scale = 1.0,
}) {
  final points = <HandLandmark>[const HandLandmark(_wristX, _wristY)];

  // Pulgar: base, dos nudillos interpolados y la punta.
  //
  // Con el pulgar separado, la apertura pedida decide dónde cae: pegado al
  // índice en la G, abierto en ángulo recto en la L. Son dos posturas
  // distintas de verdad, y si el ejemplo no las distingue tampoco se le puede
  // pedir al clasificador que lo haga.
  final (double, double)? tip;
  if (thumb == 2 && !thumbAcross) {
    final t = spread.clamp(0.0, 1.0);
    tip = (
      _thumbAlongside.$1 + (_thumbWideOpen.$1 - _thumbAlongside.$1) * t,
      _thumbAlongside.$2 + (_thumbWideOpen.$2 - _thumbAlongside.$2) * t,
    );
  } else {
    tip = _thumbTips[(thumb, thumbAcross)];
  }
  if (tip == null) {
    throw ArgumentError('No hay pulgar de ejemplo para ($thumb, $thumbAcross)');
  }
  for (var i = 0; i < 4; i++) {
    final t = i / 3;
    points.add(
      HandLandmark(
        _thumbBase.$1 + (tip.$1 - _thumbBase.$1) * t,
        _thumbBase.$2 + (tip.$2 - _thumbBase.$2) * t,
      ),
    );
  }

  // Los cuatro dedos largos, cada uno como una cadena que se dobla.
  final open = [
    for (var i = 0; i < fingers.length; i++)
      if (fingers[i] == 2) i,
  ];
  final centre = open.isEmpty
      ? 1.5
      : open.reduce((a, b) => a + b) / open.length;

  for (var f = 0; f < 4; f++) {
    var fan = 0.0;
    if (fingers[f] == 2) {
      fan = (f - centre) * spread * _maxFanDegrees;
      // Al cruzar, el índice y el corazón se intercambian los lados.
      if (crossed && f == 0) fan += _maxFanDegrees;
      if (crossed && f == 1) fan -= _maxFanDegrees;
    }

    var direction = _degrees(fan);
    var x = _knuckleX[f];
    var y = _knuckleY;
    points.add(HandLandmark(x, y));

    final bend = _bendDegrees[fingers[f]];
    for (var bone = 0; bone < 3; bone++) {
      final length = _fingerLength[f] * _boneShare[bone];
      x += direction.$1 * length;
      y += direction.$2 * length;
      points.add(HandLandmark(x, y));
      direction = _rotate(direction, bend);
    }
  }

  assert(points.length == 21, 'una mano tiene 21 puntos');

  return [
    for (final point in points)
      _place(point, pointsDown: pointsDown, scale: scale),
  ];
}

/// Un vector que apunta hacia arriba, girado [degrees] grados.
(double, double) _degrees(double degrees) {
  final radians = degrees * math.pi / 180;
  return (math.sin(radians), -math.cos(radians));
}

(double, double) _rotate((double, double) vector, double degrees) {
  final radians = degrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);
  return (
    vector.$1 * cos - vector.$2 * sin,
    vector.$1 * sin + vector.$2 * cos,
  );
}

/// Aleja o acerca la mano, y la voltea si hace falta, siempre alrededor de la
/// muñeca para no moverla de sitio.
HandLandmark _place(
  HandLandmark point, {
  required bool pointsDown,
  required double scale,
}) {
  final dx = (point.x - _wristX) * scale;
  final dy = (point.y - _wristY) * scale * (pointsDown ? -1 : 1);
  return HandLandmark(_wristX + dx, _wristY + dy);
}

/// Una muestra de posturas variadas, para comprobaciones generales.
final List<List<HandLandmark>> _sampleHands = [
  _hand(fingers: [0, 0, 0, 0], thumb: 2),
  _hand(fingers: [2, 2, 2, 2], thumb: 0, thumbAcross: true),
  _hand(fingers: [0, 0, 0, 2], thumb: 0),
  _hand(fingers: [2, 2, 0, 0], thumb: 0, spread: 0.8),
  _hand(fingers: [1, 1, 1, 1], thumb: 1),
  _hand(fingers: [2, 0, 0, 0], thumb: 1),
  _hand(fingers: [2, 2, 0, 0], thumb: 0, crossed: true),
  _hand(fingers: [2, 2, 0, 0], thumb: 2, spread: 0.6, pointsDown: true),
];
