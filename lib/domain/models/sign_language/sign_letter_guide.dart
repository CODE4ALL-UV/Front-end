import 'hand_alphabet.dart';
import 'hand_landmark_classifier.dart';

/// Cómo hacer cada letra para que la cámara de «Lee mi mano» la reconozca,
/// dicho con palabras.
///
/// Sale de la misma tabla que usa el reconocimiento ([signAlphabet]) y de su
/// misma forma de medir. Por eso lo que dice la guía es exactamente lo que la
/// cámara espera: si se corrige una letra en la tabla, la guía cambia sola.
///
/// Como la tabla, es una aproximación del alfabeto manual pensada para esta
/// cámara, no una referencia de Lengua de Señas Colombiana.
abstract final class SignLetterGuide {
  static const List<String> fingerNames = [
    'Índice',
    'Corazón',
    'Anular',
    'Meñique',
  ];

  /// Cada cuánto mira la cámara y cuántas fotos seguidas hay que sostener
  /// la letra. Son los valores de la pantalla y de [SignDictation].
  static const Duration frameInterval = Duration(milliseconds: 550);
  static const int framesToAccept = 4;

  /// Lo que hay que sostener la letra, en segundos, redondeado.
  static String get holdSeconds {
    final ms = frameInterval.inMilliseconds * framesToAccept;
    return (ms / 1000).toStringAsFixed(0);
  }

  /// Las letras en el orden del alfabeto.
  static List<String> get letters => signAlphabet.keys.toList();

  static String fingerState(int value) => switch (value) {
    2 => 'estirado',
    1 => 'doblado a medias, en gancho',
    _ => 'recogido sobre la palma',
  };

  static String thumbState(HandShape shape) {
    if (shape.thumbAcross) {
      return shape.thumb == 0
          ? 'doblado sobre la palma, hacia el meñique'
          : 'cruzado por delante de los dedos';
    }
    return switch (shape.thumb) {
      2 => 'bien separado, hacia el lado',
      1 => 'un poco separado de la mano',
      _ => 'pegado al costado de la mano',
    };
  }

  /// Lo que hay que hacer, una instrucción por renglón.
  static List<String> steps(String letter) {
    final shape = signAlphabet[letter];
    if (shape == null) return const [];

    final fingers = shape.fingers;
    final lines = <String>[
      for (var i = 0; i < fingers.length; i++)
        '${fingerNames[i]}: ${fingerState(fingers[i])}.',
      'Pulgar: ${thumbState(shape)}.',
    ];

    final open = [
      for (var i = 0; i < fingers.length; i++)
        if (fingers[i] == 2) fingerNames[i].toLowerCase(),
    ];

    if (shape.crossed) {
      lines.add('Cruza el índice sobre el corazón.');
    } else if (open.length >= 2) {
      if (shape.spread >= 0.75) {
        lines.add('Abre bien los dedos estirados, en V.');
      } else if (shape.spread >= 0.4) {
        lines.add('Separa un poco los dedos estirados.');
      } else {
        lines.add('Los dedos estirados, juntos.');
      }
    } else if (shape.thumb == 2 && open.length == 1 && shape.spread >= 0.4) {
      lines.add('Abre el pulgar y el ${open.first} en ángulo.');
    }

    if (shape.pointsDown) {
      lines.add('La mano apunta hacia abajo: la muñeca queda arriba.');
    }
    return lines;
  }

  /// Letras que la cámara no sabe separar de esta: se hacen igual.
  static List<String> identicalTo(String letter) => _near(letter, (d) {
    return d <= HandLandmarkClassifier.tieMargin;
  });

  /// Letras que se parecen tanto que la cámara puede leer una por otra.
  static List<String> similarTo(String letter) => _near(letter, (d) {
    return d > HandLandmarkClassifier.tieMargin && d <= 1.0;
  });

  /// Las parejas de letras que la cámara no distingue, sin repetir.
  static List<(String, String)> get identicalPairs => [
    for (final letter in letters)
      for (final other in identicalTo(letter))
        if (letters.indexOf(letter) < letters.indexOf(other)) (letter, other),
  ];

  /// Qué corregir si la cámara lee [read] cuando se quería hacer [target].
  ///
  /// Es la misma pista que da la pantalla mientras se practica.
  static String fixWhenReadAs(String target, String read) {
    final shape = signAlphabet[read];
    if (shape == null) return '';
    return HandLandmarkClassifier.hint(shape, target);
  }

  static List<String> _near(String letter, bool Function(double) test) {
    final shape = signAlphabet[letter];
    if (shape == null || shape.hasMotion) return const [];
    return [
      for (final entry in signAlphabet.entries)
        if (entry.key != letter &&
            !entry.value.hasMotion &&
            test(HandLandmarkClassifier.shapeDistance(shape, entry.value)))
          entry.key,
    ];
  }
}
