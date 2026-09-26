import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';

/// Dibuja a mano alzada la forma que tiene la mano para cada letra.
///
/// Vivia dentro del panel de senas y era privado. Se saca aqui porque el
/// teclado de dactilologia necesita pintar las mismas manos, en pequeno, y
/// duplicar el pintor habria significado que una correccion en una letra
/// arreglara una pantalla y no la otra.
///
/// Sigue siendo una aproximacion esquematica del alfabeto manual, no una
/// referencia de Lengua de Senas Colombiana.

/// Tonos con los que se pinta la mano.
@immutable
class SkinTones {
  const SkinTones({
    required this.base,
    required this.shade,
    required this.light,
    required this.line,
    required this.nail,
  });

  final Color base;
  final Color shade;
  final Color light;
  final Color line;
  final Color nail;

  /// Tono cálido para el tema claro.
  static const warm = SkinTones(
    base: Color(0xFFF0C3A0),
    shade: Color(0xFFD69C76),
    light: Color(0xFFFCE4D0),
    line: Color(0xFF8A5A3C),
    nail: Color(0xFFF9E2D2),
  );

  /// Mano en reposo, en gris, cuando todavía no hay subtítulo.
  static const idle = SkinTones(
    base: Color(0xFFCFD8E3),
    shade: Color(0xFFAAB6C4),
    light: Color(0xFFE8EDF3),
    line: Color(0xFF7B8896),
    nail: Color(0xFFE4EAF1),
  );
}

/// Dibuja la mano de una letra del alfabeto manual.
///
/// Es una ilustración original hecha con `Path`: palma con la base del pulgar,
/// dedos cónicos con punta redondeada y uña, muñeca, sombreado y pliegues de
/// nudillos. La forma de cada letra sale de [HandShape].
class HandPainter extends CustomPainter {
  HandPainter({
    required this.shape,
    required this.tones,
    required this.background,
  });

  final HandShape? shape;
  final SkinTones tones;
  final Color background;

  /// Largo de cada dedo respecto a la palma: índice, corazón, anular, meñique.
  static const List<double> _lengthFactor = [1.02, 1.12, 1.0, 0.80];

  /// Apertura natural de cada dedo, en radianes.
  static const List<double> _baseAngle = [-0.11, -0.035, 0.045, 0.125];

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, side * 0.47, Paint()..color = background);

    final current = shape;
    if (current == null) return;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (current.pointsDown) canvas.rotate(math.pi);

    final palmW = side * 0.40;
    final palmH = side * 0.33;
    final knuckleY = -side * 0.04;
    final wristY = knuckleY + palmH;

    final fill = Paint()..color = tones.base;
    final shade = Paint()..color = tones.shade;
    final stroke = Paint()
      ..color = tones.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.009
      ..strokeJoin = StrokeJoin.round;

    // --- muñeca -----------------------------------------------------------
    final wrist = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -palmW * 0.30,
        wristY - palmH * 0.10,
        palmW * 0.60,
        side * 0.13,
      ),
      Radius.circular(side * 0.05),
    );
    canvas.drawRRect(wrist, shade);
    canvas.drawRRect(wrist, stroke);

    // --- dedos (detrás de la palma, para esconder su nacimiento) ----------
    final fingerW = palmW * 0.185;
    final extensions = current.fingers;

    for (var i = 0; i < extensions.length; i++) {
      final extension = extensions[i];
      final spread = current.spread;
      final angle = _baseAngle[i] * (1 + spread * 2.2);

      var baseX = -palmW / 2 + palmW * (i + 0.5) / 4;
      if (current.crossed && i < 2) {
        baseX += i == 0 ? fingerW * 0.55 : -fingerW * 0.55;
      }
      final base = Offset(baseX, knuckleY + palmH * 0.06);

      if (extension == 0) {
        // Dedo recogido: se ve el nudillo asomando sobre la palma.
        final bump = Rect.fromCenter(
          center: Offset(baseX, knuckleY + fingerW * 0.10),
          width: fingerW * 1.12,
          height: fingerW * 1.05,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bump, Radius.circular(fingerW * 0.5)),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bump, Radius.circular(fingerW * 0.5)),
          stroke,
        );
        continue;
      }

      final full = palmH * _lengthFactor[i] * 1.06;
      final length = extension == 2 ? full : full * 0.50;
      final tipW = fingerW * (extension == 2 ? 0.80 : 0.88);

      final path = _fingerPath(base, angle, length, fingerW, tipW);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);

      if (extension == 2) {
        _drawNail(canvas, base, angle, length, tipW, side);
      }
    }

    // --- pulgar -----------------------------------------------------------
    final thumbExtension = current.thumb;
    if (thumbExtension > 0 && !current.thumbAcross) {
      final thumbBase = Offset(-palmW * 0.44, knuckleY + palmH * 0.42);
      final thumbAngle = -math.pi / 3.1 - current.spread * math.pi / 7;
      final thumbLen = palmH * (thumbExtension == 2 ? 0.82 : 0.50);
      final thumbW = fingerW * 1.25;

      final path = _fingerPath(
        thumbBase,
        thumbAngle,
        thumbLen,
        thumbW,
        thumbW * 0.82,
      );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      if (thumbExtension == 2) {
        _drawNail(canvas, thumbBase, thumbAngle, thumbLen, thumbW * 0.82, side);
      }
    }

    // --- palma ------------------------------------------------------------
    final palm = _palmPath(palmW, palmH, knuckleY);
    canvas.drawPath(palm, fill);

    // Volumen: la base del pulgar y el borde del meñique quedan más oscuros.
    canvas.save();
    canvas.clipPath(palm);
    canvas.drawCircle(
      Offset(-palmW * 0.30, knuckleY + palmH * 0.62),
      palmW * 0.34,
      Paint()..color = tones.shade.withValues(alpha: 0.45),
    );
    canvas.drawCircle(
      Offset(palmW * 0.38, knuckleY + palmH * 0.55),
      palmW * 0.22,
      Paint()..color = tones.shade.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      Offset(palmW * 0.02, knuckleY + palmH * 0.28),
      palmW * 0.26,
      Paint()..color = tones.light.withValues(alpha: 0.55),
    );
    canvas.restore();
    canvas.drawPath(palm, stroke);

    // --- pulgar cruzado sobre la palma ------------------------------------
    if (thumbExtension > 0 && current.thumbAcross) {
      final thumbBase = Offset(-palmW * 0.42, knuckleY + palmH * 0.30);
      final thumbLen = palmW * (thumbExtension == 2 ? 0.78 : 0.58);
      final thumbW = fingerW * 1.2;

      final path = _fingerPath(
        thumbBase,
        math.pi / 2,
        thumbLen,
        thumbW,
        thumbW * 0.85,
      );
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    }

    canvas.restore();

    if (current.hasMotion) _drawMotion(canvas, center, side);
  }

  /// Dedo cónico con la punta redondeada y un ligero abombamiento lateral.
  Path _fingerPath(
    Offset base,
    double angle,
    double length,
    double wBase,
    double wTip,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final perp = Offset(-dir.dy, dir.dx);
    final tip = base + dir * length;

    final b1 = base + perp * (wBase / 2);
    final b2 = base - perp * (wBase / 2);
    final t1 = tip + perp * (wTip / 2);
    final t2 = tip - perp * (wTip / 2);
    final beyond = tip + dir * (wTip * 0.66);
    final bulge = wBase * 0.08;

    return Path()
      ..moveTo(b1.dx, b1.dy)
      ..quadraticBezierTo(
        (b1.dx + t1.dx) / 2 + perp.dx * bulge,
        (b1.dy + t1.dy) / 2 + perp.dy * bulge,
        t1.dx,
        t1.dy,
      )
      ..quadraticBezierTo(beyond.dx, beyond.dy, t2.dx, t2.dy)
      ..quadraticBezierTo(
        (b2.dx + t2.dx) / 2 - perp.dx * bulge,
        (b2.dy + t2.dy) / 2 - perp.dy * bulge,
        b2.dx,
        b2.dy,
      )
      ..close();
  }

  void _drawNail(
    Canvas canvas,
    Offset base,
    double angle,
    double length,
    double tipW,
    double side,
  ) {
    final dir = Offset(math.sin(angle), -math.cos(angle));
    final nailCenter = base + dir * (length - tipW * 0.30);

    canvas.save();
    canvas.translate(nailCenter.dx, nailCenter.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: tipW * 0.56,
          height: tipW * 0.70,
        ),
        Radius.circular(tipW * 0.26),
      ),
      Paint()..color = tones.nail,
    );
    canvas.restore();
  }

  /// Silueta de la palma: ancha en los nudillos, con la base del pulgar
  /// abultada a la izquierda y estrechándose hacia la muñeca.
  Path _palmPath(double w, double h, double topY) {
    final left = -w / 2;
    final right = w / 2;
    final bottomY = topY + h;

    return Path()
      ..moveTo(left, topY + h * 0.12)
      ..cubicTo(
        left - w * 0.09,
        topY + h * 0.48,
        left + w * 0.01,
        bottomY - h * 0.04,
        left + w * 0.17,
        bottomY,
      )
      ..quadraticBezierTo(0, bottomY + h * 0.07, right - w * 0.17, bottomY)
      ..cubicTo(
        right - w * 0.01,
        bottomY - h * 0.06,
        right + w * 0.04,
        topY + h * 0.46,
        right,
        topY + h * 0.12,
      )
      ..quadraticBezierTo(0, topY - h * 0.07, left, topY + h * 0.12)
      ..close();
  }

  void _drawMotion(Canvas canvas, Offset center, double side) {
    final arrow = Paint()
      ..color = tones.line.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.018
      ..strokeCap = StrokeCap.round;

    final start = Offset(center.dx + side * 0.24, center.dy + side * 0.26);
    final end = Offset(center.dx + side * 0.32, center.dy + side * 0.40);

    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          center.dx + side * 0.36,
          center.dy + side * 0.32,
          end.dx,
          end.dy,
        ),
      arrow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(end.dx - side * 0.05, end.dy - side * 0.03)
        ..lineTo(end.dx, end.dy)
        ..lineTo(end.dx - side * 0.01, end.dy - side * 0.06),
      arrow,
    );
  }

  @override
  bool shouldRepaint(covariant HandPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.tones != tones ||
      oldDelegate.background != background;
}
