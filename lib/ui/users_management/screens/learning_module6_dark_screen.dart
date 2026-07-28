import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module5_dark_screen.dart';

class Modulo6AprendizajeDark extends StatefulWidget {
  const Modulo6AprendizajeDark({super.key});

  @override
  State<Modulo6AprendizajeDark> createState() => _Modulo6AprendizajeDarkState();
}

class _Modulo6AprendizajeDarkState extends State<Modulo6AprendizajeDark> {
  bool _isNavigatingToModule5 = false;

  void _goToModulo5() {
    if (_isNavigatingToModule5) return;
    _isNavigatingToModule5 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo5AprendizajeDark()),
    ).then((_) {
      _isNavigatingToModule5 = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
        ),
        title: const Text(
          'CODE4ALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF6D6D6D),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 6),
                Text(
                  'Sheher',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.overscroll < -10 &&
                    notification.metrics.pixels <=
                        notification.metrics.minScrollExtent + 1) {
                  _goToModulo5();
                  return true;
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Módulo 6',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Especialización y futuro',
                                style: TextStyle(
                                  color: Color(0xFF263238),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFF263238),
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _BigCircle(
                          icon: Icons.account_tree,
                          iconColor: const Color(0xFF64B5F6),
                          bgColor: const Color(0xFF2F1D1D),
                          size: bigSize,
                          progress: 0.75,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo3TrabajoColaborativoDark(),
                              ),
                            );
                          },
                        ),
                        _LessonBox(
                          number: 3,
                          title: 'Trabajo\ncolaborativo',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo3TrabajoColaborativoDark(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _LessonBox(
                          number: 2,
                          title: 'Componentes\nde DIU',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo2ComponentesDiuDark(),
                              ),
                            );
                          },
                        ),
                        _BigCircle(
                          icon: Icons.manage_search,
                          iconColor: const Color(0xFF90CAF9),
                          bgColor: const Color(0xFF2F1D1D),
                          size: bigSize,
                          progress: 0.6,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo2ComponentesDiuDark(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _BigCircle(
                          icon: Icons.code,
                          iconColor: const Color(0xFFBDBDBD),
                          bgColor: const Color(0xFF2F1D1D),
                          size: bigSize,
                          progress: 0.3,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo1DisenoInterfacesDark(),
                              ),
                            );
                          },
                        ),
                        _LessonBox(
                          number: 1,
                          title: 'Diseño\nInterfaces\nUsuario',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo1DisenoInterfacesDark(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Desliza hacia abajo para regresar al Módulo 5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFFCDD2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD00D3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.skip_previous, color: Colors.white, size: 32),
            const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            const Icon(Icons.skip_next, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}

class Capitulo1DisenoInterfacesDark extends StatelessWidget {
  const Capitulo1DisenoInterfacesDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 1: Diseño Interfaces Usuario',
      moduleLabel: 'Módulo 6. Especialización y futuro',
      rutaItems: const [
        _ActivityItem('¿Qué es una interfaz gráfica?', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Librerías populares', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('El ciclo de la vida', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pop(context),
      onNextChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo2ComponentesDiuDark()),
      ),
    );
  }
}

class Capitulo2ComponentesDiuDark extends StatelessWidget {
  const Capitulo2ComponentesDiuDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 2: Componentes de DIU',
      moduleLabel: 'Módulo 6. Especialización y futuro',
      rutaItems: const [
        _ActivityItem('Ventanas y Etiquetas', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Botones y Campos de texto', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('Layouts', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Capitulo1DisenoInterfacesDark(),
        ),
      ),
      onNextChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Capitulo3TrabajoColaborativoDark(),
        ),
      ),
    );
  }
}

class Capitulo3TrabajoColaborativoDark extends StatelessWidget {
  const Capitulo3TrabajoColaborativoDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 3: Trabajo colaborativo',
      moduleLabel: 'Módulo 6. Especialización y futuro',
      rutaItems: const [
        _ActivityItem('Roles en el equipo', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Introducción a Git', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('Comunicación y documentación', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo2ComponentesDiuDark()),
      ),
    );
  }
}

class _ChapterDetailDark extends StatefulWidget {
  final String chapterTitle;
  final String moduleLabel;
  final List<_ActivityItem> rutaItems;
  final VoidCallback? onPreviousChapter;
  final VoidCallback? onNextChapter;

  const _ChapterDetailDark({
    required this.chapterTitle,
    required this.moduleLabel,
    required this.rutaItems,
    this.onPreviousChapter,
    this.onNextChapter,
  });

  @override
  State<_ChapterDetailDark> createState() => _ChapterDetailDarkState();
}

class _ChapterDetailDarkState extends State<_ChapterDetailDark> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  void _goPreviousChapter() {
    if (widget.onPreviousChapter != null) {
      widget.onPreviousChapter!.call();
      return;
    }
    Navigator.maybePop(context);
  }

  void _goNextChapter() {
    if (widget.onNextChapter != null) {
      widget.onNextChapter!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
        ),
        title: const Text(
          'CODE4ALL',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF6D6D6D),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 6),
                Text(
                  'Sheher',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 250) {
            _goPreviousChapter();
          } else if (velocity < -250) {
            _goNextChapter();
          }
        },
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF2F1D1D),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                widget.moduleLabel,
                style: const TextStyle(
                  color: Color(0xFFFFCDD2),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  children: [
                    _DetailCardDark(
                      title: widget.chapterTitle,
                      expanded: _resumenExpanded,
                      onToggle: () =>
                          setState(() => _resumenExpanded = !_resumenExpanded),
                      child: const _ResumenContenidoDark(),
                    ),
                    const SizedBox(height: 12),
                    _DetailCardDark(
                      title: 'Ruta de actividades',
                      expanded: _rutaExpanded,
                      onToggle: () =>
                          setState(() => _rutaExpanded = !_rutaExpanded),
                      child: Column(
                        children: widget.rutaItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: _ActivityRowDark(item: item),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCD00D3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: widget.onPreviousChapter,
              icon: const Icon(
                Icons.skip_previous,
                color: Colors.white,
                size: 32,
              ),
            ),
            const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            IconButton(
              onPressed: widget.onNextChapter,
              icon: Icon(
                Icons.skip_next,
                color: widget.onNextChapter == null
                    ? Colors.white24
                    : Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCircle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double size;
  final double progress;
  final VoidCallback? onTap;

  const _BigCircle({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.size,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: size * 0.36),
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonBox extends StatelessWidget {
  final int number;
  final String title;
  final VoidCallback? onTap;

  const _LessonBox({required this.number, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2222),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C3B3B)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF8A80), width: 2),
                color: const Color(0xFF1B1B1B),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  const _ArcPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF7A3B3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetailCardDark extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _DetailCardDark({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFF5F5F5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFFBDBDBD),
                ),
              ],
            ),
          ),
          if (expanded) ...[const SizedBox(height: 10), child],
        ],
      ),
    );
  }
}

class _ResumenContenidoDark extends StatelessWidget {
  const _ResumenContenidoDark();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen del capítulo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFFECEFF1),
          ),
        ),
        SizedBox(height: 8),
        Text(
          '• 📖 5 Temas',
          style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        ),
        SizedBox(height: 4),
        Text(
          '• 💡 2 Cápsulas',
          style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        ),
        SizedBox(height: 4),
        Text(
          '• 🧩 3 Ejercicios',
          style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        ),
        SizedBox(height: 4),
        Text(
          '• 📝 1 Quiz parcial',
          style: TextStyle(fontSize: 14, color: Color(0xFFE0E0E0)),
        ),
      ],
    );
  }
}

class _ActivityItem {
  final String label;
  final String emoji;

  const _ActivityItem(this.label, this.emoji);
}

class _ActivityRowDark extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRowDark({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 5, color: Color(0xFFBDBDBD)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE0E0E0),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(item.emoji, style: const TextStyle(fontSize: 22)),
      ],
    );
  }
}
