import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';
import 'quiz_screen.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module3_dark_screen.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module5_dark_screen.dart';

class Modulo4AprendizajeDark extends StatefulWidget {
  const Modulo4AprendizajeDark({super.key});

  @override
  State<Modulo4AprendizajeDark> createState() => _Modulo4AprendizajeDarkState();
}

class _Modulo4AprendizajeDarkState extends State<Modulo4AprendizajeDark> {
  bool _isNavigatingToModule3 = false;
  bool _isNavigatingToModule5 = false;

  void _goToModulo3() {
    if (_isNavigatingToModule3) return;
    _isNavigatingToModule3 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo3AprendizajeDark()),
    ).then((_) {
      _isNavigatingToModule3 = false;
    });
  }

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkTheme
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFE53935),
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return Navigator.canPop(context)
                ? IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  )
                : Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
                  );
          },
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
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.overscroll > 10 &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 1) {
                  _goToModulo5();
                  return true;
                }
                if (notification.overscroll < -10 &&
                    notification.metrics.pixels <=
                        notification.metrics.minScrollExtent + 1) {
                  _goToModulo3();
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
                          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
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
                                'Módulo 4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Especialización y futuro',
                                style: TextStyle(
                                  color: Color(0xFFC8E6C9),
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFFFFCC80),
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
                          bgColor: const Color(0xFF1C2D20),
                          size: bigSize,
                          progress: 0.75,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo3VariablesDark(),
                              ),
                            );
                          },
                        ),
                        _LessonBox(
                          number: 3,
                          title: 'Variables\nlocales y\nglobales',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo3VariablesDark(),
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
                          title: 'Partes de\nuna función',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo2PartesFuncionDark(),
                              ),
                            );
                          },
                        ),
                        _BigCircle(
                          icon: Icons.manage_search,
                          iconColor: const Color(0xFF90CAF9),
                          bgColor: const Color(0xFF1C2D20),
                          size: bigSize,
                          progress: 0.6,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const Capitulo2PartesFuncionDark(),
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
                          bgColor: const Color(0xFF1C2D20),
                          size: bigSize,
                          progress: 0.3,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo1FuncionesDark(),
                              ),
                            );
                          },
                        ),
                        _LessonBox(
                          number: 1,
                          title: 'Funciones',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo1FuncionesDark(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Desliza hacia arriba para abrir Módulo 5',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA5D6A7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Desliza hacia abajo para regresar al Módulo 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA5D6A7),
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
              child: const HelpActionButton(),
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

class Capitulo1FuncionesDark extends StatelessWidget {
  const Capitulo1FuncionesDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 1: Funciones',
      moduleLabel: 'Módulo 4. Modularización y Manejo de Datos',
      rutaItems: const [
        _ActivityItem('Creación y partes de una función', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Definición y llamado de funciones', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('Variables locales y globales', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pop(context),
      onNextChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo2PartesFuncionDark()),
      ),
    );
  }
}

class Capitulo2PartesFuncionDark extends StatelessWidget {
  const Capitulo2PartesFuncionDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 2: Partes de una función',
      moduleLabel: 'Módulo 4. Modularización y Manejo de Datos',
      rutaItems: const [
        _ActivityItem('Entrada de datos', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Salida de datos', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('Múltiples argumentos', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo1FuncionesDark()),
      ),
      onNextChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo3VariablesDark()),
      ),
    );
  }
}

class Capitulo3VariablesDark extends StatelessWidget {
  const Capitulo3VariablesDark({super.key});

  @override
  Widget build(BuildContext context) {
    return _ChapterDetailDark(
      chapterTitle: 'Capítulo 3: Variables locales y globales',
      moduleLabel: 'Módulo 4. Modularización y Manejo de Datos',
      rutaItems: const [
        _ActivityItem('Variables locales', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejemplo', '⚙️'),
        _ActivityItem('Variables globales', '📚🖥️🎧'),
        _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
        _ActivityItem('Ejercicio', '🏋️'),
        _ActivityItem('Scope y buenas prácticas', '📚🖥️🎧'),
        _ActivityItem('Nombre de la buena práctica', '🏅'),
        _ActivityItem('Quiz', '❓'),
        _ActivityItem('Laboratorio', '🧪'),
        _ActivityItem('Evaluación final', '📋'),
      ],
      onPreviousChapter: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Capitulo2PartesFuncionDark()),
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
            padding: const EdgeInsets.only(right: 12),
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
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
              color: const Color(0xFF1F3420),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                widget.moduleLabel,
                style: const TextStyle(
                  color: Color(0xFFA5D6A7),
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
                                child: item.label == 'Quiz'
                                    ? Row(
                                        children: [
                                          Expanded(
                                            child: _ActivityRowDark(item: item),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.quiz,
                                              color: Color(0xFF45D1D6),
                                            ),
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const QuizScreen(),
                                              ),
                                            ),
                                            tooltip: 'Abrir Quiz',
                                          ),
                                        ],
                                      )
                                    : _ActivityRowDark(item: item),
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
                child: const HelpActionButton(),
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
    final percentage = (progress * 100).toInt();
    return Semantics(
      button: true,
      label: 'Lección con $percentage% de progreso',
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
                  isDark: true,
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
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 14,
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
                        color: const Color(0xFFE0E0E0),
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

class _LessonBox extends StatelessWidget {
  final int number;
  final String title;
  final VoidCallback? onTap;

  const _LessonBox({required this.number, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lección $number: $title',
      hint: 'Toca para abrir',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE8E8E8),
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
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
