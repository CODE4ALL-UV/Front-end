import 'dart:math' as math;

import 'package:flutter/material.dart';

class ModuloAprendizajeDark extends StatelessWidget {
  const ModuloAprendizajeDark({super.key});

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
            child: SingleChildScrollView(
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
                        colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
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
                              'Módulo 1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Preparación',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
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
                            color: Colors.white,
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
                        iconColor: const Color(0xFFE53935),
                        bgColor: const Color(0xFF2E2B24),
                        size: bigSize,
                        progress: 0.75,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Capitulo3DetalleDark(),
                            ),
                          );
                        },
                      ),
                      _LessonBox(
                        number: 3,
                        title: 'El factor inglés',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Capitulo3DetalleDark(),
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
                        title: 'El entorno',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Capitulo2DetalleDark(),
                            ),
                          );
                        },
                      ),
                      _BigCircle(
                        icon: Icons.manage_search,
                        iconColor: const Color(0xFF8E24AA),
                        bgColor: const Color(0xFF2E2635),
                        size: bigSize,
                        progress: 0.6,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Capitulo2DetalleDark(),
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
                        iconColor: const Color(0xFF8AA5FF),
                        bgColor: const Color(0xFF252B3B),
                        size: bigSize,
                        progress: 0.3,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CapituloDetalleDark(),
                            ),
                          );
                        },
                      ),
                      _LessonBox(
                        number: 1,
                        title: 'Conociendo\nPython',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CapituloDetalleDark(),
                            ),
                          );
                        },
                      ),
                    ],
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
                  color: Color(0xFF5C6BC0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.white, size: 28),
            Icon(Icons.play_arrow, color: Colors.white, size: 32),
            Icon(Icons.skip_next, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

class CapituloDetalleDark extends StatefulWidget {
  const CapituloDetalleDark({super.key});

  @override
  State<CapituloDetalleDark> createState() => _CapituloDetalleDarkState();
}

class _CapituloDetalleDarkState extends State<CapituloDetalleDark> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  static const _rutaItems = [
    _ActivityItem('Relevancia del lenguaje Python', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejemplo', '⚙️'),
    _ActivityItem('Descarga y puesta en marcha', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejercicio', '🎮'),
    _ActivityItem('Preparando la versión instalada', '📦🖥️🎧'),
    _ActivityItem('Nombre de la buena práctica', '🏅'),
    _ActivityItem('Quiz', '❓'),
    _ActivityItem('Laboratorio', '🧪'),
    _ActivityItem('Evaluación final', '📋'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF607D8B),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 6),
                Text(
                  'Sheher',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF263238),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFFB0BEC5),
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
                    title: 'Capítulo 1: Conociendo Python',
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
                      children: _rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.white, size: 32),
            Icon(Icons.play_arrow, color: Colors.white, size: 36),
            Icon(Icons.skip_next, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}

class Capitulo2DetalleDark extends StatefulWidget {
  const Capitulo2DetalleDark({super.key});

  @override
  State<Capitulo2DetalleDark> createState() => _Capitulo2DetalleDarkState();
}

class _Capitulo2DetalleDarkState extends State<Capitulo2DetalleDark> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  static const _rutaItems = [
    _ActivityItem('¿Qué es un IDE/Editor?', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejemplo', '⚙️'),
    _ActivityItem('Configuración para accesibilidad', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejercicio', '🎮'),
    _ActivityItem('Tu primer "Hola Mundo"', '📦🖥️🎧'),
    _ActivityItem('Nombre de la buena práctica', '🏅'),
    _ActivityItem('Quiz', '❓'),
    _ActivityItem('Laboratorio', '🧪'),
    _ActivityItem('Evaluación final', '📋'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF607D8B),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 6),
                Text(
                  'Sheher',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF263238),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFFB0BEC5),
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
                    title: 'Capítulo 2: El entorno',
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
                      children: _rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.white, size: 32),
            Icon(Icons.play_arrow, color: Colors.white, size: 36),
            Icon(Icons.skip_next, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }
}

class Capitulo3DetalleDark extends StatefulWidget {
  const Capitulo3DetalleDark({super.key});

  @override
  State<Capitulo3DetalleDark> createState() => _Capitulo3DetalleDarkState();
}

class _Capitulo3DetalleDarkState extends State<Capitulo3DetalleDark> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;

  static const _rutaItems = [
    _ActivityItem('Palabras clave', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejemplo', '⚙️'),
    _ActivityItem('Glosario visual/auditivo', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejercicio', '🎮'),
    _ActivityItem('Nombre de la buena práctica', '🏅'),
    _ActivityItem('Quiz', '❓'),
    _ActivityItem('Laboratorio', '🧪'),
    _ActivityItem('Evaluación final', '📋'),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
            child: Row(
              children: const [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF607D8B),
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 6),
                Text(
                  'Sheher',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF263238),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFFB0BEC5),
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
                    title: 'Capítulo 3: El factor inglés',
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
                      children: _rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
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
      bottomNavigationBar: Container(
        color: const Color(0xFF2A2A2A),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.white, size: 32),
            Icon(Icons.play_arrow, color: Colors.white, size: 36),
            Icon(Icons.skip_next, color: Colors.white, size: 32),
          ],
        ),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
                      fontSize: 18,
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
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF424242)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF64B5F6), width: 2),
                color: const Color(0xFF1C1C1C),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF64B5F6),
                size: 18,
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
        ..color = const Color(0xFF3A4656)
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
        ..color = const Color(0xFF42A5F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
