import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_progress.dart';

class CircleProgressWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double size;
  final int moduleNumber;
  final int sectionNumber;
  final VoidCallback? onTap;

  const CircleProgressWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.size,
    required this.moduleNumber,
    required this.sectionNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // El almacen avisa cuando se completa una actividad, asi que la
    // circunferencia se redibuja sola sin que nadie la refresque a mano.
    ensureProgressLoaded();
    return ListenableBuilder(
      listenable: CourseProgressStore.instance,
      builder: (context, _) => _buildCircle(context),
    );
  }

  Widget _buildCircle(BuildContext context) {
    final progress = sectionProgress(moduleNumber, sectionNumber);
    final percentage = (progress * 100).round();
    return Semantics(
      button: true,
      label: sectionProgressLabel(moduleNumber, sectionNumber),
      hint: 'Toca para abrir la lección',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _ArcPainter(
                  progress: progress,
                  strokeWidth: size * 0.08,
                  isDark: false,
                ),
              ),
              Container(
                width: size * 0.68,
                height: size * 0.68,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: size * 0.28),
                    SizedBox(height: size * 0.04),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: size * 0.12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF424242),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final bool isDark;

  const _ArcPainter({
    required this.progress,
    required this.strokeWidth,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Background arc with softer color
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = isDark ? const Color(0xFF2E3A4A) : const Color(0xFFE3F2FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc with gradient effect
    final progressSweep = 2 * math.pi * progress;
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + progressSweep,
        colors: isDark
            ? [
                const Color(0xFF42A5F5),
                const Color(0xFF1E88E5),
                const Color(0xFF1565C0),
              ]
            : [
                const Color(0xFF64B5F6),
                const Color(0xFF1E88E5),
                const Color(0xFF0D47A1),
              ],
        transform: const GradientRotation(-math.pi / 2),
      );

      canvas.drawArc(
        rect,
        -math.pi / 2,
        progressSweep,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
