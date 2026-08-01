import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module2_light_screen.dart';

class ModuloAprendizaje extends StatefulWidget {
  final String userName;
  final VoidCallback? onLogout;

  const ModuloAprendizaje({
    super.key,
    this.userName = 'Usuario',
    this.onLogout,
  });

  @override
  State<ModuloAprendizaje> createState() => _ModuloAprendizajeState();
}

class _ModuloAprendizajeState extends State<ModuloAprendizaje> {
  bool _isNavigatingToModule2 = false;

  void _goToModulo2() {
    if (_isNavigatingToModule2) return;
    _isNavigatingToModule2 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo2AprendizajeLight()),
    ).then((_) {
      _isNavigatingToModule2 = false;
    });
  }

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
                          bgColor: const Color(0xFFFFF3E0),
                          size: bigSize,
                          progress: 0.75,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo3DetalleLight(),
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
                                builder: (_) => const Capitulo3DetalleLight(),
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
                                builder: (_) => const Capitulo2DetalleLight(),
                              ),
                            );
                          },
                        ),
                        _BigCircle(
                          icon: Icons.manage_search,
                          iconColor: const Color(0xFF8E24AA),
                          bgColor: const Color(0xFFF3E5F5),
                          size: bigSize,
                          progress: 0.6,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Capitulo2DetalleLight(),
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
                          iconColor: const Color(0xFF5C6BC0),
                          bgColor: const Color(0xFFE8EAF6),
                          size: bigSize,
                          progress: 0.3,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CapituloDetalleLight(),
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
                                builder: (_) => const CapituloDetalleLight(),
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
                        color: Color(0xFF607D8B),
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
      bottomNavigationBar: const MultimodalNavBar(),
    );
  }
}

class CapituloDetalleLight extends StatefulWidget {
  const CapituloDetalleLight({super.key});

  @override
  State<CapituloDetalleLight> createState() => _CapituloDetalleLightState();
}

class _CapituloDetalleLightState extends State<CapituloDetalleLight> {
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
        builder: (_) => LecturaTemaLightScreen(
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
        builder: (_) => VideoTemaLightScreen(actividad: actividad),
      ),
    );
  }

  void _goToModulo2() {
    if (_isNavigatingToModule2) return;
    _isNavigatingToModule2 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo2AprendizajeLight()),
    ).then((_) {
      _isNavigatingToModule2 = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
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
                  backgroundColor: Color(0xFF90CAF9),
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
            color: const Color(0xFFE8F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFF607D8B),
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
                    _DetailCard(
                      title: 'Capítulo 1: Conociendo Python',
                      expanded: _resumenExpanded,
                      onToggle: () =>
                          setState(() => _resumenExpanded = !_resumenExpanded),
                      child: const _ResumenContenido(),
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
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
                                child: _ActivityRow(
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
                        color: Color(0xFF607D8B),
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
        color: const Color(0xFFE53935),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.black, size: 32),
            Icon(Icons.play_arrow, color: Colors.black, size: 36),
            Icon(Icons.skip_next, color: Colors.black, size: 32),
          ],
        ),
      ),
    );
  }
}

class Capitulo2DetalleLight extends StatefulWidget {
  const Capitulo2DetalleLight({super.key});

  @override
  State<Capitulo2DetalleLight> createState() => _Capitulo2DetalleLightState();
}

class _Capitulo2DetalleLightState extends State<Capitulo2DetalleLight> {
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
        builder: (_) => LecturaTemaLightScreen(
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
        builder: (_) => VideoTemaLightScreen(actividad: actividad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
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
                  backgroundColor: Color(0xFF90CAF9),
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
            color: const Color(0xFFE8F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFF607D8B),
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
                  _DetailCard(
                    title: 'Capítulo 2: El entorno',
                    expanded: _resumenExpanded,
                    onToggle: () =>
                        setState(() => _resumenExpanded = !_resumenExpanded),
                    child: const _ResumenContenido(),
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    title: 'Ruta de actividades',
                    expanded: _rutaExpanded,
                    onToggle: () =>
                        setState(() => _rutaExpanded = !_rutaExpanded),
                    child: Column(
                      children: _rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _ActivityRow(
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
              child: const HelpActionButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFE53935),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.black, size: 32),
            Icon(Icons.play_arrow, color: Colors.black, size: 36),
            Icon(Icons.skip_next, color: Colors.black, size: 32),
          ],
        ),
      ),
    );
  }
}

class Capitulo3DetalleLight extends StatefulWidget {
  const Capitulo3DetalleLight({super.key});

  @override
  State<Capitulo3DetalleLight> createState() => _Capitulo3DetalleLightState();
}

class _Capitulo3DetalleLightState extends State<Capitulo3DetalleLight> {
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
        builder: (_) => LecturaTemaLightScreen(
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
        builder: (_) => VideoTemaLightScreen(actividad: actividad),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width < 360 ? 10.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
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
                  backgroundColor: Color(0xFF90CAF9),
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
            color: const Color(0xFFE8F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: const Text(
              'Módulo 1. Preparación',
              style: TextStyle(
                color: Color(0xFF607D8B),
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
                  _DetailCard(
                    title: 'Capítulo 3: El factor inglés',
                    expanded: _resumenExpanded,
                    onToggle: () =>
                        setState(() => _resumenExpanded = !_resumenExpanded),
                    child: const _ResumenContenido(),
                  ),
                  const SizedBox(height: 12),
                  _DetailCard(
                    title: 'Ruta de actividades',
                    expanded: _rutaExpanded,
                    onToggle: () =>
                        setState(() => _rutaExpanded = !_rutaExpanded),
                    child: Column(
                      children: _rutaItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _ActivityRow(
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
              child: const HelpActionButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFE53935),
        height: 56,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.skip_previous, color: Colors.black, size: 32),
            Icon(Icons.play_arrow, color: Colors.black, size: 36),
            Icon(Icons.skip_next, color: Colors.black, size: 32),
          ],
        ),
      ),
    );
  }
}

class _ResumenContenido extends StatelessWidget {
  const _ResumenContenido();

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
            color: Color(0xFF263238),
          ),
        ),
        SizedBox(height: 8),
        Text('• 📖 5 Temas', style: TextStyle(fontSize: 14)),
        SizedBox(height: 4),
        Text('• 💡 2 Cápsulas', style: TextStyle(fontSize: 14)),
        SizedBox(height: 4),
        Text('• 🧩 3 Ejercicios', style: TextStyle(fontSize: 14)),
        SizedBox(height: 4),
        Text('• 📝 1 Quiz parcial', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _DetailCard({
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
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
                      color: Color(0xFF212121),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF424242),
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

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback? onBookTap;
  final VoidCallback? onVideoTap;

  const _ActivityRow({required this.item, this.onBookTap, this.onVideoTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 5, color: Color(0xFF424242)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF263238),
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
                  decorationColor: const Color(0xFF1E88E5),
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
                  color: Color(0xFF1E88E5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class VideoTemaLightScreen extends StatelessWidget {
  final String actividad;

  const VideoTemaLightScreen({super.key, required this.actividad});

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF45D1D6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 36,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Video',
                    style: TextStyle(fontSize: 44, color: Color(0xFF263238)),
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
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'En este espacio podras ver un video relacionado con $actividad aplicado en Python:',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Color(0xFF2A67AB),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
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
                            color: Color(0xFF212121),
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
                          child: const _NavButton(label: 'Anterior'),
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
                children: [const HelpActionButton(), const SizedBox(width: 52)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LecturaTemaLightScreen extends StatelessWidget {
  final String actividad;
  final String contenido;

  const LecturaTemaLightScreen({
    super.key,
    required this.actividad,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
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
                  backgroundColor: Color(0xFF90CAF9),
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
            color: const Color(0xFF45D1D6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'Lectura: $actividad',
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF0B4F6C),
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
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    contenido,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.45,
                      color: Color(0xFF2A67AB),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _NavButton(label: 'Anterior'),
                      const SizedBox(width: 10),
                      _NavButton(label: 'Siguiente'),
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
              child: const HelpActionButton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;

  const _NavButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88E5),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
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
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
                      blurRadius: 6,
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
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263238),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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
