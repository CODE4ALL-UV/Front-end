import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModuloAprendizajeDark extends StatelessWidget {
  const ModuloAprendizajeDark({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 136, 135, 135),
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
              CircleAvatar(radius: 14, backgroundColor: Color(0xFF757575),
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
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
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
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fila 1: círculo grande izq + cajita der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircleDark(
                        icon: Icons.account_tree,
                        iconColor: const Color(0xFFFF6F00),
                        bgColor: const Color(0xFF2A2A2A),
                        size: bigSize,
                        progress: 0.75,
                      ),
                      _LessonBoxDark(number: 3, title: 'El factor inglés'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 2: cajita izq + círculo grande der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LessonBoxDark(number: 2, title: 'El entorno'),
                      _BigCircleDark(
                        icon: Icons.manage_search,
                        iconColor: const Color(0xFFCE93D8),
                        bgColor: const Color(0xFF2A2A2A),
                        size: bigSize,
                        progress: 0.6,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fila 3: círculo grande izq + cajita der
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircleDark(
                        icon: Icons.code,
                        iconColor: const Color(0xFF9FA8DA),
                        bgColor: const Color(0xFF2A2A2A),
                        size: bigSize,
                        progress: 0.3,
                      ),
                      _LessonBoxDark(number: 1, title: 'Conociendo\nPython'),
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
        color: const Color.fromARGB(255, 136, 135, 135),
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

class _BigCircleDark extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double size;
  final double progress;

  const _BigCircleDark({
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
        painter: _ArcPainterDark(progress: progress, strokeWidth: size * 0.07),
        child: Center(
          child: Container(
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.36),
          ),
        ),
      ),
    );
  }
}

class _LessonBoxDark extends StatelessWidget {
  final int number;
  final String title;

  const _LessonBoxDark({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.transparent,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainterDark extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _ArcPainterDark({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    // Fondo oscuro del arco
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi, false,
      Paint()
        ..color = const Color(0xFF2C2C2C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Arco degradado azul → morado
    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi * progress,
      colors: const [Color(0xFF1E88E5), Color(0xFF7B1FA2)],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}