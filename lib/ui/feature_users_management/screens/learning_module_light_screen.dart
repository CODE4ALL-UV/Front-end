import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModuloAprendizaje extends StatelessWidget {
  const ModuloAprendizaje({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
        ),
        title: const Text('CODE4ALL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(children: const [
              CircleAvatar(radius: 14, backgroundColor: Color(0xFFBDBDBD),
                  child: Icon(Icons.person, color: Colors.white, size: 18)),
              SizedBox(width: 6),
              Text('Sheher', style: TextStyle(color: Colors.white, fontSize: 13)),
              SizedBox(width: 8),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                children: [
                  // Card Módulo 1
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Módulo 1',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Preparación', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ]),
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fila 1: círculo grande izq + cajita número+título der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircle(
                        icon: Icons.account_tree,
                        iconColor: const Color(0xFFE53935),
                        bgColor: const Color(0xFFFFF3E0),
                        size: bigSize,
                        progress: 0.75,
                      ),
                      _LessonBox(number: 3, title: 'El factor inglés'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 2: cajita número+título izq + círculo grande der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LessonBox(number: 2, title: 'El entorno'),
                      _BigCircle(
                        icon: Icons.manage_search,
                        iconColor: const Color(0xFF8E24AA),
                        bgColor: const Color(0xFFF3E5F5),
                        size: bigSize,
                        progress: 0.6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 3: círculo grande izq + cajita número+título der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircle(
                        icon: Icons.code,
                        iconColor: const Color(0xFF5C6BC0),
                        bgColor: const Color(0xFFE8EAF6),
                        size: bigSize,
                        progress: 0.3,
                      ),
                      _LessonBox(number: 1, title: 'Conociendo\nPython'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Ícono accesibilidad
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(color: Color(0xFF5C6BC0), shape: BoxShape.circle),
                child: const Icon(Icons.accessibility_new, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFE53935),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Icon(Icons.skip_previous, color: Colors.white, size: 28),
            Icon(Icons.play_arrow, color: Colors.white, size: 32),
            Icon(Icons.skip_next, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// Círculo grande con ícono y arco de progreso azul
class _BigCircle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double size;
  final double progress;

  const _BigCircle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.size,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ArcPainter(progress: progress, strokeWidth: size * 0.07),
        child: Center(
          child: Container(
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.36),
          ),
        ),
      ),
    );
  }
}

// Cajita con número en círculo pequeño + título
class _LessonBox extends StatelessWidget {
  final int number;
  final String title;

  const _LessonBox({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Círculo pequeño con número
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E88E5), width: 2),
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Color(0xFF424242), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter arco de progreso
class _ArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _ArcPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Fondo gris claro
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = const Color(0xFFD0E8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Arco azul de progreso
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..color = const Color(0xFF1E88E5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}