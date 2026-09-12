/// El alfabeto manual, descrito dedo a dedo.
///
/// Esta tabla se usa para dos cosas a la vez: dibujar la letra en el panel de
/// señas y reconocerla cuando el estudiante la hace frente a la cámara. Al
/// estar en un solo sitio, corregir la forma de una letra arregla las dos.
///
/// **Es una aproximación.** Las formas están descritas por el grado de
/// extensión de cada dedo, que distingue bien la mayoría de las letras pero no
/// todas (M, N, S y T se diferencian por detalles que este modelo no captura).
/// No sustituye la validación de un intérprete de Lengua de Señas Colombiana.
library;

import 'package:flutter/foundation.dart';

@immutable
class HandShape {
  const HandShape({
    required this.thumb,
    required this.index,
    required this.middle,
    required this.ring,
    required this.pinky,
    this.spread = 0.0,
    this.thumbAcross = false,
    this.hasMotion = false,
    this.pointsDown = false,
    this.crossed = false,
  });

  final int thumb;
  final int index;
  final int middle;
  final int ring;
  final int pinky;

  /// Separación extra entre los dedos estirados, de 0 a 1.
  final double spread;

  /// El pulgar cruza la palma en lugar de salir hacia el lado.
  final bool thumbAcross;

  /// La letra se hace con un movimiento (J, Z, Ñ...).
  final bool hasMotion;

  /// La mano apunta hacia abajo (P, Q).
  final bool pointsDown;

  /// Los dedos índice y corazón van cruzados (R).
  final bool crossed;

  List<int> get fingers => [index, middle, ring, pinky];
}

/// Alfabeto manual aproximado, letra por letra.
///
/// Es una representación esquemática pensada para acompañar la lectura, no
/// una referencia de Lengua de Señas Colombiana. Ver la nota de la clase
/// [SignLanguagePanel].
const Map<String, HandShape> signAlphabet = {
  'A': HandShape(thumb: 2, index: 0, middle: 0, ring: 0, pinky: 0),
  'B': HandShape(
    thumb: 0,
    index: 2,
    middle: 2,
    ring: 2,
    pinky: 2,
    thumbAcross: true,
  ),
  'C': HandShape(thumb: 1, index: 1, middle: 1, ring: 1, pinky: 1),
  'D': HandShape(thumb: 1, index: 2, middle: 0, ring: 0, pinky: 0),
  'E': HandShape(
    thumb: 0,
    index: 0,
    middle: 0,
    ring: 0,
    pinky: 0,
    thumbAcross: true,
  ),
  'F': HandShape(thumb: 1, index: 1, middle: 2, ring: 2, pinky: 2, spread: 0.4),
  'G': HandShape(thumb: 2, index: 2, middle: 0, ring: 0, pinky: 0, spread: 0.2),
  'H': HandShape(thumb: 0, index: 2, middle: 2, ring: 0, pinky: 0),
  'I': HandShape(thumb: 0, index: 0, middle: 0, ring: 0, pinky: 2),
  'J': HandShape(
    thumb: 0,
    index: 0,
    middle: 0,
    ring: 0,
    pinky: 2,
    hasMotion: true,
  ),
  'K': HandShape(thumb: 2, index: 2, middle: 2, ring: 0, pinky: 0, spread: 0.6),
  'L': HandShape(thumb: 2, index: 2, middle: 0, ring: 0, pinky: 0, spread: 0.9),
  'M': HandShape(
    thumb: 0,
    index: 1,
    middle: 1,
    ring: 1,
    pinky: 0,
    thumbAcross: true,
  ),
  'N': HandShape(
    thumb: 0,
    index: 1,
    middle: 1,
    ring: 0,
    pinky: 0,
    thumbAcross: true,
  ),
  'Ñ': HandShape(
    thumb: 0,
    index: 1,
    middle: 1,
    ring: 0,
    pinky: 0,
    thumbAcross: true,
    hasMotion: true,
  ),
  'O': HandShape(thumb: 1, index: 1, middle: 1, ring: 1, pinky: 1, spread: 0.1),
  'P': HandShape(
    thumb: 2,
    index: 2,
    middle: 2,
    ring: 0,
    pinky: 0,
    spread: 0.6,
    pointsDown: true,
  ),
  'Q': HandShape(
    thumb: 2,
    index: 2,
    middle: 0,
    ring: 0,
    pinky: 0,
    spread: 0.2,
    pointsDown: true,
  ),
  'R': HandShape(
    thumb: 0,
    index: 2,
    middle: 2,
    ring: 0,
    pinky: 0,
    crossed: true,
  ),
  'S': HandShape(
    thumb: 1,
    index: 0,
    middle: 0,
    ring: 0,
    pinky: 0,
    thumbAcross: true,
  ),
  'T': HandShape(
    thumb: 1,
    index: 1,
    middle: 0,
    ring: 0,
    pinky: 0,
    thumbAcross: true,
  ),
  'U': HandShape(thumb: 0, index: 2, middle: 2, ring: 0, pinky: 0),
  'V': HandShape(thumb: 0, index: 2, middle: 2, ring: 0, pinky: 0, spread: 0.8),
  'W': HandShape(thumb: 0, index: 2, middle: 2, ring: 2, pinky: 0, spread: 0.7),
  'X': HandShape(thumb: 0, index: 1, middle: 0, ring: 0, pinky: 0),
  'Y': HandShape(thumb: 2, index: 0, middle: 0, ring: 0, pinky: 2, spread: 1.0),
  'Z': HandShape(
    thumb: 0,
    index: 2,
    middle: 0,
    ring: 0,
    pinky: 0,
    hasMotion: true,
  ),
};
