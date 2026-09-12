import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'hand_alphabet.dart';

/// Uno de los 21 puntos de la mano que devuelve MediaPipe.
///
/// Las coordenadas vienen normalizadas entre 0 y 1 respecto al ancho y alto de
/// la foto, con la `y` creciendo hacia abajo, como en cualquier imagen.
@immutable
class HandLandmark {
  const HandLandmark(this.x, this.y, [this.z = 0]);

  factory HandLandmark.fromJson(Map<String, dynamic> json) => HandLandmark(
    (json['x'] as num?)?.toDouble() ?? 0,
    (json['y'] as num?)?.toDouble() ?? 0,
    (json['z'] as num?)?.toDouble() ?? 0,
  );

  final double x;
  final double y;
  final double z;

  /// Distancia en el plano de la imagen.
  ///
  /// Se ignora la `z` a propósito: MediaPipe la estima con mucho menos acierto
  /// que las otras dos y meterla en la cuenta empeora el reconocimiento.
  double distanceTo(HandLandmark other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}

/// Lo que el sistema cree que está haciendo la mano.
@immutable
class SignReading {
  const SignReading({
    required this.letter,
    required this.confidence,
    required this.observed,
    this.alternatives = const [],
  });

  /// Letra reconocida, o `null` si ninguna encaja lo suficiente.
  final String? letter;

  /// Cuánto encaja, de 0 a 1.
  final double confidence;

  /// La forma que se observó de verdad.
  ///
  /// Sirve para decirle al estudiante qué le falta —"estira el anular"— en
  /// lugar de un simple "incorrecto".
  final HandShape observed;

  /// Otras letras que encajan casi igual de bien.
  ///
  /// No está vacío cuando dos letras se hacen prácticamente igual. Enseñarlas
  /// las dos es más honesto que elegir una al azar.
  final List<String> alternatives;

  /// Hay una lectura clara y sin competencia.
  bool get isConfident =>
      letter != null && confidence >= 0.72 && alternatives.isEmpty;

  /// Se reconoció algo, pero hay más de una letra posible.
  bool get isAmbiguous => letter != null && alternatives.isNotEmpty;
}

/// Traduce los puntos de la mano a una letra del alfabeto manual.
///
/// Compara el grado de extensión de cada dedo con la misma tabla que usa el
/// panel para dibujar las letras, así que lo que se reconoce y lo que se
/// dibuja no pueden contradecirse.
///
/// **Limitaciones, dichas de frente.** Desde una foto fija no se pueden
/// reconocer las letras que llevan movimiento (J, Z y Ñ), y varias parejas se
/// hacen de forma tan parecida que este método no las separa: H y U son
/// idénticas en la tabla, y M, N, S y T se distinguen por dónde queda el
/// pulgar entre los dedos, un detalle demasiado fino para estas medidas.
/// Cuando pasa, se devuelven todas las candidatas en [SignReading.alternatives]
/// en vez de fingir una certeza que no hay.
///
/// Es una ayuda para practicar el alfabeto manual, no una evaluación fiable ni
/// un traductor de Lengua de Señas Colombiana.
abstract final class HandLandmarkClassifier {
  /// Cuántos puntos tiene que traer una mano para poder analizarla.
  static const int landmarkCount = 21;

  // Índices de los puntos, tal y como los numera MediaPipe.
  static const int _wrist = 0;
  static const int _thumbCmc = 1;
  static const int _thumbTip = 4;
  static const int _indexMcp = 5;
  static const int _indexTip = 8;
  static const int _middleMcp = 9;
  static const int _middleTip = 12;
  static const int _pinkyMcp = 17;

  /// Los cuatro dedos largos: punta, y los tres nudillos que bajan hasta la
  /// palma. En orden índice, corazón, anular y meñique.
  static const List<(int tip, int dip, int pip, int mcp)> _fingers = [
    (8, 7, 6, 5),
    (12, 11, 10, 9),
    (16, 15, 14, 13),
    (20, 19, 18, 17),
  ];

  /// Un dedo estirado recorre casi todo su largo en línea recta.
  static const double _straightRatio = 0.88;

  /// Uno medio doblado recorre bastante menos.
  static const double _halfRatio = 0.55;

  /// A partir de aquí la lectura ya no dice nada útil.
  static const double _worstUsefulScore = 3.0;

  /// Diferencia por debajo de la cual dos letras se consideran empatadas.
  static const double _tieMargin = 0.30;

  /// Tamaño mínimo de la mano, en proporción a la foto.
  ///
  /// Por debajo de esto la mano está demasiado lejos —o los puntos llegaron
  /// amontonados— y las medidas dejan de significar nada. Conviene decir que
  /// no se ve, porque una forma vacía se parece bastante a la E y contestar
  /// «E» a una mano que no se ve es peor que no contestar.
  static const double _minHandScale = 0.04;

  static SignReading classify(List<HandLandmark> points) {
    if (points.length < landmarkCount ||
        points[_wrist].distanceTo(points[_middleMcp]) < _minHandScale) {
      return const SignReading(
        letter: null,
        confidence: 0,
        observed: _unknownShape,
      );
    }

    final observed = describe(points);

    final scores = <String, double>{};
    signAlphabet.forEach((letter, shape) {
      // Las letras con movimiento no se pueden ver en una foto fija.
      if (shape.hasMotion) return;
      scores[letter] = _distance(observed, shape);
    });

    if (scores.isEmpty) {
      return SignReading(letter: null, confidence: 0, observed: observed);
    }

    final ranked = scores.keys.toList()
      ..sort((a, b) => scores[a]!.compareTo(scores[b]!));

    final best = ranked.first;
    final bestScore = scores[best]!;
    final confidence = (1 - bestScore / _worstUsefulScore).clamp(0.0, 1.0);

    if (confidence < 0.5) {
      return SignReading(
        letter: null,
        confidence: confidence,
        observed: observed,
      );
    }

    final tied = ranked
        .skip(1)
        .where((letter) => scores[letter]! - bestScore <= _tieMargin)
        .toList();

    return SignReading(
      letter: best,
      confidence: confidence,
      observed: observed,
      alternatives: tied,
    );
  }

  /// Traduce los puntos a la misma descripción que usa la tabla del alfabeto.
  @visibleForTesting
  static HandShape describe(List<HandLandmark> points) {
    final wrist = points[_wrist];
    final scale = wrist.distanceTo(points[_middleMcp]);
    if (scale <= 0) return _unknownShape;

    final extensions = [
      for (final finger in _fingers) _extensionOf(points, finger),
    ];

    final thumbTip = points[_thumbTip];
    final indexMcp = points[_indexMcp];
    final pinkyMcp = points[_pinkyMcp];

    // El pulgar no se dobla como los demás, así que no se mide por su curva
    // sino por cuánto se aparta del canto de la mano.
    final thumbOut = thumbTip.distanceTo(pinkyMcp) / scale;
    final thumb = thumbOut >= 1.15 ? 2 : (thumbOut >= 0.85 ? 1 : 0);

    // Pulgar cruzado: su punta se ha ido hacia el lado del meñique, más cerca
    // de ese canto que del nudillo del índice del que sale.
    final thumbAcross =
        thumbTip.distanceTo(pinkyMcp) < thumbTip.distanceTo(indexMcp);

    // La mano apunta hacia abajo cuando los nudillos quedan por debajo de la
    // muñeca; recuerda que la `y` crece hacia abajo.
    final pointsDown = points[_middleMcp].y > wrist.y + scale * 0.25;

    // Índice y corazón cruzados: su orden horizontal se invierte respecto al
    // de sus nudillos.
    final tipOrder = points[_indexTip].x - points[_middleTip].x;
    final mcpOrder = indexMcp.x - points[_middleMcp].x;
    final crossed =
        extensions[0] == 2 &&
        extensions[1] == 2 &&
        mcpOrder.abs() > 1e-6 &&
        tipOrder.sign != mcpOrder.sign;

    return HandShape(
      thumb: thumb,
      index: extensions[0],
      middle: extensions[1],
      ring: extensions[2],
      pinky: extensions[3],
      spread: _spreadOf(points, extensions, thumb),
      thumbAcross: thumbAcross,
      pointsDown: pointsDown,
      crossed: crossed,
    );
  }

  /// Cuánto está estirado un dedo: 0 recogido, 1 a medias, 2 estirado.
  ///
  /// Se mide comparando la distancia en línea recta del nudillo a la punta con
  /// lo que mide el dedo recorriendo sus falanges. Un dedo recto recorre casi
  /// todo su largo; uno recogido, mucho menos. Al ser una proporción, no
  /// depende de lo cerca que esté la mano de la cámara ni de que el meñique
  /// sea más corto que el corazón.
  static int _extensionOf(
    List<HandLandmark> points,
    (int, int, int, int) finger,
  ) {
    final tip = points[finger.$1];
    final dip = points[finger.$2];
    final pip = points[finger.$3];
    final mcp = points[finger.$4];

    final bones =
        mcp.distanceTo(pip) + pip.distanceTo(dip) + dip.distanceTo(tip);
    if (bones <= 0) return 0;

    final ratio = mcp.distanceTo(tip) / bones;
    if (ratio >= _straightRatio) return 2;
    if (ratio >= _halfRatio) return 1;
    return 0;
  }

  /// Cuánto se abren los dedos estirados, de 0 (juntos) a 1 (en abanico).
  ///
  /// Se compara la separación de las puntas con la de sus propios nudillos: si
  /// van juntas, la proporción es 1; cuanto más se abren, más sube.
  static double _spreadOf(
    List<HandLandmark> points,
    List<int> extensions,
    int thumb,
  ) {
    final open = [
      for (var i = 0; i < extensions.length; i++)
        if (extensions[i] == 2) i,
    ];

    final int tipA;
    final int mcpA;
    final int tipB;
    final int mcpB;

    // El pulgar sale de la muñeca, no de la fila de nudillos, así que su
    // separación crece mucho más despacio y hay que medirla con otra vara.
    final double range;

    if (open.length >= 2) {
      // Los dos dedos más separados de entre los que estén estirados.
      tipA = _fingers[open.first].$1;
      mcpA = _fingers[open.first].$4;
      tipB = _fingers[open.last].$1;
      mcpB = _fingers[open.last].$4;
      range = 1.2;
    } else if (thumb == 2 && open.length == 1) {
      // Letras como la L o la Y, donde la apertura es la del pulgar.
      tipA = _thumbTip;
      mcpA = _thumbCmc;
      tipB = _fingers[open.first].$1;
      mcpB = _fingers[open.first].$4;
      range = 0.6;
    } else {
      return 0;
    }

    final knuckles = points[mcpA].distanceTo(points[mcpB]);
    if (knuckles <= 0) return 0;

    final ratio = points[tipA].distanceTo(points[tipB]) / knuckles;
    return ((ratio - 1.0) / range).clamp(0.0, 1.0);
  }

  /// Cuánto se parecen dos formas. Cero es idéntico.
  static double _distance(HandShape observed, HandShape expected) {
    var score = 0.0;

    score += (observed.index - expected.index).abs().toDouble();
    score += (observed.middle - expected.middle).abs().toDouble();
    score += (observed.ring - expected.ring).abs().toDouble();
    score += (observed.pinky - expected.pinky).abs().toDouble();
    // El pulgar pesa menos: es el que peor se mide desde una sola foto.
    score += (observed.thumb - expected.thumb).abs() * 0.6;

    if (observed.thumbAcross != expected.thumbAcross) score += 0.5;
    if (observed.pointsDown != expected.pointsDown) score += 1.2;
    if (observed.crossed != expected.crossed) score += 0.9;

    score += (observed.spread - expected.spread).abs() * 0.5;

    return score;
  }

  /// Qué le falta al estudiante para completar [target].
  ///
  /// Devuelve una frase corta y accionable, no un "incorrecto" a secas.
  static String hint(HandShape observed, String target) {
    final expected = signAlphabet[target];
    if (expected == null) return 'Esa letra no está en el alfabeto.';
    if (expected.hasMotion) {
      return 'La $target se hace con movimiento, así que no se puede '
          'comprobar con una foto.';
    }

    const names = ['índice', 'corazón', 'anular', 'meñique'];
    final observedFingers = observed.fingers;
    final expectedFingers = expected.fingers;

    for (var i = 0; i < names.length; i++) {
      if (observedFingers[i] == expectedFingers[i]) continue;
      return expectedFingers[i] > observedFingers[i]
          ? 'Estira más el ${names[i]}.'
          : 'Recoge el ${names[i]}.';
    }

    if (observed.thumb != expected.thumb) {
      return expected.thumb > observed.thumb
          ? 'Separa el pulgar de la mano.'
          : 'Pega el pulgar a la mano.';
    }
    if (observed.thumbAcross != expected.thumbAcross) {
      return expected.thumbAcross
          ? 'Cruza el pulgar sobre la palma.'
          : 'Saca el pulgar hacia el lado.';
    }
    if (observed.pointsDown != expected.pointsDown) {
      return expected.pointsDown
          ? 'Apunta la mano hacia abajo.'
          : 'Apunta la mano hacia arriba.';
    }
    if (observed.crossed != expected.crossed) {
      return expected.crossed
          ? 'Cruza el índice sobre el corazón.'
          : 'Separa el índice del corazón.';
    }

    return 'Casi. Mantén la mano quieta y bien enfocada.';
  }

  static const HandShape _unknownShape = HandShape(
    thumb: 0,
    index: 0,
    middle: 0,
    ring: 0,
    pinky: 0,
  );
}
