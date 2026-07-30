import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module2_dark_screen.dart';

class ModuloAprendizajeDark extends StatefulWidget {
  final String userName;
  final VoidCallback? onLogout;

  const ModuloAprendizajeDark({
    super.key,
    this.userName = 'Usuario',
    this.onLogout,
  });

  @override
  State<ModuloAprendizajeDark> createState() => _ModuloAprendizajeDarkState();
}

class _ModuloAprendizajeDarkState extends State<ModuloAprendizajeDark> {
  bool _isNavigatingToModule2 = false;

  void _goToModulo2() {
    if (_isNavigatingToModule2) return;
    _isNavigatingToModule2 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo2AprendizajeDark()),
    ).then((_) {
      _isNavigatingToModule2 = false;
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
            child: UserProfileMenu(
              userName: widget.userName,
              onLogout: widget.onLogout,
              showName: true,
            ),
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
                  _goToModulo2();
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
                    const SizedBox(height: 10),
                    const Text(
                      'Desliza hacia arriba para abrir Módulo 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9FB3C1),
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
  bool _isNavigatingToModule2 = false;

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

  void _openLectura(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturaTemaDarkScreen(
          actividad: actividad,
          contenido: _textoLecturaPorActividad(actividad),
        ),
      ),
    );
  }

  void _openVideo(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTemaDarkScreen(actividad: actividad),
      ),
    );
  }

  void _goToModulo2() {
    if (_isNavigatingToModule2) return;
    _isNavigatingToModule2 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo2AprendizajeDark()),
    ).then((_) {
      _isNavigatingToModule2 = false;
    });
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
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.overscroll > 14 &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 1) {
                  _goToModulo2();
                  return true;
                }
                return false;
              },
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: _ActivityRowDark(
                                  item: item,
                                  onBookTap: item.emoji.contains('📦')
                                      ? () => _openLectura(item.label)
                                      : null,
                                  onVideoTap: item.emoji.contains('🖥️')
                                      ? () => _openVideo(item.label)
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Desliza hacia arriba para abrir Módulo 2',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9FB3C1),
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

  void _openLectura(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturaTemaDarkScreen(
          actividad: actividad,
          contenido: _textoLecturaPorActividad(actividad),
        ),
      ),
    );
  }

  void _openVideo(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTemaDarkScreen(actividad: actividad),
      ),
    );
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
                              child: _ActivityRowDark(
                                item: item,
                                onBookTap: item.emoji.contains('📦')
                                    ? () => _openLectura(item.label)
                                    : null,
                                onVideoTap: item.emoji.contains('🖥️')
                                    ? () => _openVideo(item.label)
                                    : null,
                              ),
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

  void _openLectura(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturaTemaDarkScreen(
          actividad: actividad,
          contenido: _textoLecturaPorActividad(actividad),
        ),
      ),
    );
  }

  void _openVideo(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTemaDarkScreen(actividad: actividad),
      ),
    );
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
                              child: _ActivityRowDark(
                                item: item,
                                onBookTap: item.emoji.contains('📦')
                                    ? () => _openLectura(item.label)
                                    : null,
                                onVideoTap: item.emoji.contains('🖥️')
                                    ? () => _openVideo(item.label)
                                    : null,
                              ),
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
  final VoidCallback? onBookTap;
  final VoidCallback? onVideoTap;

  const _ActivityRowDark({required this.item, this.onBookTap, this.onVideoTap});

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
        Row(
          children: [
            GestureDetector(
              onTap: onBookTap,
              child: Text(
                item.emoji,
                style: TextStyle(
                  fontSize: 22,
                  decoration: onBookTap != null
                      ? TextDecoration.underline
                      : null,
                  decorationColor: const Color(0xFF64B5F6),
                ),
              ),
            ),
            if (onVideoTap != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onVideoTap,
                child: const Icon(
                  Icons.ondemand_video,
                  size: 20,
                  color: Color(0xFF64B5F6),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class VideoTemaDarkScreen extends StatelessWidget {
  final String actividad;

  const VideoTemaDarkScreen({super.key, required this.actividad});

  static const String _videoUrl =
      'https://www.youtube.com/watch?v=nKPbfIU442g&t=89s';

  Future<void> _abrirVideo(BuildContext context) async {
    final opened = await openExternalUrl(_videoUrl);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1E9FA4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 36,
                      color: Color(0xFFE0F7FA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Video',
                    style: TextStyle(fontSize: 44, color: Color(0xFFE0F7FA)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mira el video',
                      style: TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE0E0E0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En este espacio podras ver un video relacionado con $actividad aplicado en Python:',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Color(0xFF90CAF9),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => _abrirVideo(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            color: const Color(0xFF3A404A),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    size: 96,
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 10,
                                  child: Row(
                                    children: [
                                      const Text(
                                        '▶ 2:30 / 5:00',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              width: 120,
                                              decoration: BoxDecoration(
                                                color: Colors.white70,
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _abrirVideo(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Abrir en YouTube'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF3A3A3A)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Traducción en tiempo real',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const _NavButtonDark(label: 'Anterior'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCD00D3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.black,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 52),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LecturaTemaDarkScreen extends StatelessWidget {
  final String actividad;
  final String contenido;

  const LecturaTemaDarkScreen({
    super.key,
    required this.actividad,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
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
            color: const Color(0xFF1E9FA4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'Lectura: $actividad',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFFE0F7FA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Realiza la siguiente lectura',
                    style: TextStyle(
                      fontSize: 44,
                      color: Color(0xFFE0E0E0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    contenido,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      color: Color(0xFF90CAF9),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _NavButtonDark(label: 'Anterior'),
                      const SizedBox(width: 10),
                      _NavButtonDark(label: 'Siguiente'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFCD00D3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.black,
                  size: 34,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButtonDark extends StatelessWidget {
  final String label;

  const _NavButtonDark({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        '▶ $label',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

String _textoLecturaPorActividad(String actividad) {
  switch (actividad) {
    case 'Relevancia del lenguaje Python':
      return 'Python es un lenguaje de programación interpretado, legible y versátil que se utiliza en desarrollo web, ciencia de datos, automatización y educación. Su sintaxis clara reduce la curva de aprendizaje y facilita que una persona se concentre en la lógica del problema en lugar de pelear con la estructura del código.\n\nEn proyectos reales, Python destaca por su ecosistema de librerías, su comunidad activa y su capacidad de integrarse con otros servicios. Esto lo vuelve ideal para construir prototipos rápidos y también para sistemas de producción cuando se diseña una arquitectura adecuada.';
    case '¿Qué es un IDE/Editor?':
      return 'Un editor de código es una herramienta para escribir y organizar archivos de programación, mientras que un IDE integra además funcionalidades como depuración, autocompletado inteligente y administración del proyecto.\n\nPara aprender Python, usar un entorno como VS Code permite ejecutar scripts, revisar errores en tiempo real y mantener una estructura ordenada. Elegir bien tu entorno mejora la productividad y disminuye errores comunes de configuración.';
    case 'Palabras clave':
      return 'En Python, las palabras clave son términos reservados por el lenguaje como if, for, while, def o class. Estas palabras tienen un significado especial y no se deben usar como nombres de variables.\n\nComprender estas palabras es fundamental porque forman la base de la lectura de cualquier programa. Identificarlas rápido te ayuda a entender el flujo del código, las condiciones y la forma en que se definen funciones y estructuras de datos.';
    default:
      return 'Esta lectura explica el contexto de la actividad y su propósito dentro del módulo. Revisa los conceptos principales, identifica las ideas clave y relaciona el contenido con los ejercicios prácticos para reforzar tu aprendizaje de Python.';
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
