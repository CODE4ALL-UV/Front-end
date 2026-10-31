import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_alphabet.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_reading_models.dart';

// Los colores de la boca son fijos: es un dibujo de una boca, no una pieza de
// la interfaz, y lo que dice cada dibujo también está escrito al lado.
const Color _lipColor = Color(0xFFC9525F);
const Color _lipEdge = Color(0xFF7E2A35);
const Color _insideColor = Color(0xFF43191C);
const Color _teethColor = Color(0xFFF7F3EA);
const Color _tongueColor = Color(0xFFE58A93);

Path _contourPath(Iterable<Offset> points) {
  final path = Path();
  var first = true;
  for (final point in points) {
    if (first) {
      path.moveTo(point.dx, point.dy);
      first = false;
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  return path..close();
}

/// El contorno de los labios encima de la imagen de la cámara.
class LipOverlayPainter extends CustomPainter {
  const LipOverlayPainter({required this.frame, this.mirror = false});

  final LipFrame? frame;

  /// La vista previa de la cámara frontal se ve como un espejo, y en el móvil
  /// la foto que se analiza no.
  final bool mirror;

  // Verde muy claro con un borde oscuro: se ve sobre cualquier piel y con
  // cualquier luz.
  static const Color _line = Color(0xFF69F0AE);
  static const Color _halo = Color(0xB3000000);

  @override
  void paint(Canvas canvas, Size size) {
    final current = frame;
    if (current == null) return;

    Offset place(LipPoint point) => Offset(
      (mirror ? 1 - point.x : point.x) * size.width,
      point.y * size.height,
    );

    final outer = _contourPath(current.outer.map(place));
    final inner = _contourPath(current.inner.map(place));

    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeJoin = StrokeJoin.round
      ..color = _halo;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = _line;

    canvas
      ..drawPath(outer, halo)
      ..drawPath(inner, halo)
      ..drawPath(outer, line)
      ..drawPath(inner, line);
  }

  @override
  bool shouldRepaint(LipOverlayPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.mirror != mirror;
}

/// Solo la boca, ampliada, para ver bien cómo se mueve.
class MouthZoomPainter extends CustomPainter {
  const MouthZoomPainter({required this.frame, required this.aspectRatio});

  final LipFrame? frame;

  /// Ancho entre alto de la foto. Las coordenadas son relativas a cada lado, y
  /// sin esto una boca en una foto apaisada saldría aplastada.
  final double aspectRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final current = frame;
    if (current == null || current.outer.length < 11 || current.width <= 0) {
      return;
    }

    Offset raw(LipPoint point) => Offset(point.x * aspectRatio, point.y);

    final outerRaw = current.outer.map(raw).toList();
    // Los puntos 0 y 10 son las comisuras. Se escala con la distancia entre
    // ojos, no con la boca: si no, abrir y cerrar no cambiaría de tamaño.
    final mouthSpan = (outerRaw[0] - outerRaw[10]).distance;
    final betweenEyes = mouthSpan / current.width;
    if (betweenEyes <= 0) return;
    final scale = size.width * 0.8 / betweenEyes;

    final xs = outerRaw.map((point) => point.dx);
    final ys = outerRaw.map((point) => point.dy);
    final center = Offset(
      (xs.reduce(math.min) + xs.reduce(math.max)) / 2,
      (ys.reduce(math.min) + ys.reduce(math.max)) / 2,
    );

    Offset place(Offset point) =>
        size.center(Offset.zero) + (point - center) * scale;

    final outer = _contourPath(outerRaw.map(place));
    final inner = _contourPath(current.inner.map((p) => place(raw(p))));

    // Los labios enteros y encima el interior de la boca, en ese orden.
    canvas
      ..drawPath(outer, Paint()..color = _lipColor)
      ..drawPath(inner, Paint()..color = _insideColor)
      ..drawPath(
        outer,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _lipEdge,
      );
  }

  @override
  bool shouldRepaint(MouthZoomPainter oldDelegate) =>
      oldDelegate.frame != frame || oldDelegate.aspectRatio != aspectRatio;
}

/// Cómo se ha movido la boca en los últimos segundos.
class LipMovementPainter extends CustomPainter {
  const LipMovementPainter({
    required this.history,
    required this.neutralWidth,
    required this.openingColor,
    required this.widthColor,
    required this.roundingColor,
    required this.gridColor,
    this.capacity = 60,
  });

  final List<LipFrame> history;
  final double neutralWidth;
  final Color openingColor;
  final Color widthColor;
  final Color roundingColor;
  final Color gridColor;

  /// Cuántas fotos caben: así la gráfica entra por la derecha y no se estira.
  final int capacity;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final level in const [0.0, 0.5, 1.0]) {
      final y = size.height * level;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (history.length < 2) return;

    final step = size.width / (capacity - 1);
    Offset at(int index, double value) => Offset(
      size.width - (history.length - 1 - index) * step,
      size.height * (1 - value.clamp(0.0, 1.0)),
    );

    void line(
      double Function(LipFrame frame) value,
      Color color,
      double width,
    ) {
      final path = Path();
      for (var i = 0; i < history.length; i++) {
        final point = at(i, value(history[i]));
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    }

    line((frame) => (frame.width / neutralWidth - 0.5) / 0.8, widthColor, 1.5);
    line((frame) => frame.opening / 0.4, openingColor, 3);

    // La redondez va en puntos: las tres líneas tienen que distinguirse sin
    // depender del color.
    final dotPaint = Paint()
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = roundingColor;
    canvas.drawPoints(ui.PointMode.points, [
      for (var i = 0; i < history.length; i++) at(i, history[i].rounding),
    ], dotPaint);
  }

  @override
  bool shouldRepaint(LipMovementPainter oldDelegate) => true;
}

/// Una boca dibujada de frente, para explicar cómo se hace una letra.
class MouthPosePainter extends CustomPainter {
  const MouthPosePainter(this.pose);

  final MouthPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = size.center(Offset.zero);
    final halfWidth = side * (0.26 + 0.2 * pose.width);
    final gap = side * 0.36 * pose.opening;
    // Los labios adelantados se ven más gruesos.
    final lip = side * (0.08 + 0.05 * (1 - pose.width));

    final left = center.dx - halfWidth;
    final right = center.dx + halfWidth;
    final top = center.dy - gap / 2;
    final bottom = center.dy + gap / 2;

    final outer = Path()
      ..moveTo(left, center.dy)
      ..cubicTo(
        center.dx - halfWidth * 0.6,
        top - lip * 1.1,
        center.dx - halfWidth * 0.25,
        top - lip * 1.3,
        center.dx,
        top - lip * 0.85,
      )
      ..cubicTo(
        center.dx + halfWidth * 0.25,
        top - lip * 1.3,
        center.dx + halfWidth * 0.6,
        top - lip * 1.1,
        right,
        center.dy,
      )
      ..cubicTo(
        center.dx + halfWidth * 0.6,
        bottom + lip * 1.5,
        center.dx - halfWidth * 0.6,
        bottom + lip * 1.5,
        left,
        center.dy,
      )
      ..close();

    canvas.drawPath(outer, Paint()..color = _lipColor);

    if (pose.opening > 0) {
      final innerLeft = center.dx - halfWidth * 0.8;
      final innerRight = center.dx + halfWidth * 0.8;
      final inner = Path()
        ..moveTo(innerLeft, center.dy)
        ..quadraticBezierTo(center.dx, top - gap * 0.25, innerRight, center.dy)
        ..quadraticBezierTo(center.dx, bottom + gap * 0.25, innerLeft, center.dy)
        ..close();

      canvas
        ..save()
        ..clipPath(inner)
        ..drawPath(inner, Paint()..color = _insideColor);

      if (pose.tongue == MouthTongue.low) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, bottom + gap * 0.1),
            width: halfWidth * 1.2,
            height: gap * 0.7,
          ),
          Paint()..color = _tongueColor,
        );
      }
      if (pose.tongue == MouthTongue.behindTeeth) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, top + gap * 0.45),
            width: halfWidth * 0.8,
            height: gap * 0.75,
          ),
          Paint()..color = _tongueColor,
        );
      }
      if (pose.teeth) {
        canvas.drawRect(
          Rect.fromLTRB(innerLeft, top - gap, innerRight, top + gap * 0.42),
          Paint()..color = _teethColor,
        );
      }
      canvas.restore();
    } else {
      // Con los labios juntos solo se ve la línea entre los dos.
      canvas.drawPath(
        Path()
          ..moveTo(left + 2, center.dy)
          ..quadraticBezierTo(center.dx, center.dy + lip * 0.2, right - 2, center.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, side * 0.018)
          ..color = _lipEdge,
      );
    }

    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, side * 0.012)
        ..color = _lipEdge,
    );
  }

  @override
  bool shouldRepaint(MouthPosePainter oldDelegate) => oldDelegate.pose != pose;
}

/// El icono de la lectura de labios, del color que se le pida.
///
/// Material no trae ninguno: los que hay de voz o de cara no dicen «labios».
class LipsIcon extends StatelessWidget {
  const LipsIcon({super.key, required this.color, this.size = 24});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LipsIconPainter(color)),
    ),
  );
}

class _LipsIconPainter extends CustomPainter {
  const _LipsIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;

    // El contorno de los dos labios y, en medio, la línea entre ellos.
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.06, h * 0.5)
          ..cubicTo(w * 0.22, h * 0.34, w * 0.34, h * 0.22, w * 0.5, h * 0.34)
          ..cubicTo(w * 0.66, h * 0.22, w * 0.78, h * 0.34, w * 0.94, h * 0.5)
          ..cubicTo(w * 0.74, h * 0.86, w * 0.26, h * 0.86, w * 0.06, h * 0.5)
          ..close(),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.06, h * 0.5)
          ..quadraticBezierTo(w * 0.5, h * 0.58, w * 0.94, h * 0.5),
        stroke,
      );
  }

  @override
  bool shouldRepaint(_LipsIconPainter oldDelegate) =>
      oldDelegate.color != color;
}
