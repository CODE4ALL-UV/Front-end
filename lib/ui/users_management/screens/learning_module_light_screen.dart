import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module2_light_screen.dart';
import 'package:flutter_code4all/ui/users_management/screens/learning_module2_dark_screen.dart';
import 'quiz_screen.dart';
import 'quiz_with_video_screen.dart';
import 'laboratory_console_screen.dart';
import 'quiz_screen_dark.dart';
import 'quiz_with_video_screen_dark.dart';
import 'laboratory_console_screen_dark.dart';
import 'final_evaluation_screen.dart';
import '../widgets/live_translation_box.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/users_management/screens/teacher_module_editor.dart';

class ModuloAprendizaje extends StatefulWidget {
  final String userName;
  final VoidCallback? onLogout;
  final List<String>? bottomLabels;

  const ModuloAprendizaje({
    super.key,
    this.userName = 'Usuario',
    this.onLogout,
    this.bottomLabels,
  });

  @override
  State<ModuloAprendizaje> createState() => _ModuloAprendizajeState();
}

class _ModuloAprendizajeState extends State<ModuloAprendizaje> {
  static const String _defaultModuleId = 'default-module';

  bool _isNavigatingToModule2 = false;
  bool _isTeacher = false;
  String _moduleName = 'Módulo 1';
  List<String> _topics = [];

  final _authStorage = AuthStorage();

  void _checkRole() async {
    final role = await _authStorage.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacher = (role ?? '').toLowerCase() == 'docente';
    });
  }

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchModuleAndApply(_defaultModuleId);
  }

  Future<void> _fetchModuleAndApply(String moduleId) async {
    final backend = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';
    try {
      final res = await http.get(Uri.parse('$backend/api/modules/$moduleId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final name = data['name'] ?? 'Módulo 1';
        final topics = (data['topics'] as List<dynamic>? ?? []).cast<String>();
        if (!mounted) return;
        setState(() {
          _moduleName = name;
          _topics = topics;
        });
      } else if (mounted) {
        setState(() {
          _moduleName = 'Módulo 1';
          _topics = [];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _moduleName = 'Módulo 1';
          _topics = [];
        });
      }
    }
  }

  String _topicOrFallback(int idx, String fallback) {
    if (idx < 0 || idx >= _topics.length) return fallback;
    return _topics[idx];
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
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;
    final isDarkTheme =
        VisualThemeController.of(context)?.isDarkTheme ??
        VisualThemeController.globalThemeNotifier.value;

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
                    child: Image.asset('assets/images/logoUV_Gris1.png'),
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
            child: UserProfileMenu(
              userName: widget.userName,
              onLogout: widget.onLogout,
              showName: true,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          //DELETE Expanded(
          NotificationListener<OverscrollNotification>(
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
              padding: const EdgeInsets.fromLTRB(
                16,
                20,
                16,
                80,
              ), //NEW OLD EdgeInsets.fromLTRB(16, 20, 16, 12),
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
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _moduleName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Preparación',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isTeacher)
                                IconButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TeacherModuleEditor(),
                                      ),
                                    );
                                    if (result is String && result.isNotEmpty) {
                                      await _fetchModuleAndApply(result);
                                    } else {
                                      await _fetchModuleAndApply(
                                        _defaultModuleId,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/images/logoUV_Gris1.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircle(
                        icon: Icons.account_tree,
                        iconColor: const Color(0xFF1976D2),
                        bgColor: const Color(0xFFE3F2FD),
                        size: bigSize,
                        progress: 0.75,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Capitulo2DetalleLight(),
                            ),
                          );
                        },
                      ),
                      _LessonBox(
                        number: 3,
                        title: _topicOrFallback(2, 'Tema 3'),
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
                      _LessonBox(
                        number: 2,
                        title: _topicOrFallback(1, 'Tema 2'),
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
                        title: _topicOrFallback(0, 'Tema 1'),
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
          // DELETE EXPANDED),
          Positioned(
            //NEW OLD Padding
            left: 16,
            bottom: 8,
            child: const HelpActionButton(),
          ),
        ],
      ),
      bottomNavigationBar: MultimodalNavBar(
        previousLabel:
            widget.bottomLabels != null && widget.bottomLabels!.length > 0
            ? widget.bottomLabels![0]
            : null,
        playLabel:
            widget.bottomLabels != null && widget.bottomLabels!.length > 1
            ? widget.bottomLabels![1]
            : null,
        nextLabel:
            widget.bottomLabels != null && widget.bottomLabels!.length > 2
            ? widget.bottomLabels![2]
            : null,
      ),
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
  final Set<String> _completedActivities = <String>{};

  static const _rutaItems = [
    _ActivityItem('Relevancia del lenguaje Python', '📦🖥️🎧'),
    _ActivityItem('Nombre del Tip/Cápsula de conocimiento', '🎁'),
    _ActivityItem('Ejemplo', '⚙️'),
    _ActivityItem('Ejercicio', '🎮'),
    _ActivityItem('Quiz', '❓'),
    _ActivityItem('Laboratorio', '🧪'),
    _ActivityItem('Evaluación final', '📋'),
  ];

  Future<void> _openLectura(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LecturaTemaLightScreen(
          actividad: actividad,
          contenido: _textoLecturaPorActividad(actividad),
        ),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
    }
  }

  Future<void> _openCapsulaConocimiento(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapsulaConocimientoLightScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado el tip satisfactoriamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEjemplo(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EjemploPythonLightScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado este ejemplo satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEjercicio(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EjercicioInteractivoLightScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado este ejercicio satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEvaluacionFinal(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinalEvaluationScreen()),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado la evaluación final.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openQuiz(String actividad) async {
    final isDarkTheme = VisualThemeController.resolveIsDark(context);
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            isDarkTheme ? const QuizScreenDark() : const QuizScreen(),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado el quiz satisfactoriamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openLaboratorio(String actividad) async {
    final isDarkTheme = VisualThemeController.resolveIsDark(context);
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isDarkTheme
            ? const LaboratoryConsoleScreenDark()
            : const LaboratoryConsoleScreen(),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado el laboratorio satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
    final isDarkTheme = VisualThemeController.resolveIsDark(context);
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
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
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
                                  isCompleted: _completedActivities.contains(
                                    item.label,
                                  ),
                                  onBookTap:
                                      item.label ==
                                          'Nombre del Tip/Cápsula de conocimiento'
                                      ? () =>
                                            _openCapsulaConocimiento(item.label)
                                      : item.label == 'Ejemplo'
                                      ? () => _openEjemplo(item.label)
                                      : item.label == 'Ejercicio'
                                      ? () => _openEjercicio(item.label)
                                      : item.emoji.contains('📦')
                                      ? () => _openLectura(item.label)
                                      : item.label == 'Quiz'
                                      ? () => _openQuiz(item.label)
                                      : item.label == 'Evaluación final'
                                      ? () => _openEvaluacionFinal(item.label)
                                      : item.label == 'Laboratorio'
                                      ? () => _openLaboratorio(item.label)
                                      : null,
                                  onVideoTap: item.emoji.contains('🖥️')
                                      ? () => _openVideo(item.label)
                                      : item.label == 'Quiz'
                                      ? () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => isDarkTheme
                                                ? QuizWithVideoScreenDark(
                                                    actividad: item.label,
                                                  )
                                                : QuizWithVideoScreen(
                                                    actividad: item.label,
                                                  ),
                                          ),
                                        )
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
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
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
            child: StoredUserAvatar(radius: 14, size: 28, showName: true),
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
  final bool isCompleted;

  const _ActivityRow({
    required this.item,
    this.onBookTap,
    this.onVideoTap,
    this.isCompleted = false,
  });

  String _badgeText() {
    if (item.label == 'Quiz') return 'Comenzar';
    if (item.label == 'Laboratorio') return 'Explorar';
    if (item.label == 'Ejercicio') return 'Abrir';
    if (item.label == 'Ejemplo') return 'Abrir';
    if (item.label == 'Evaluación final') return 'Abrir';
    if (item.label == 'Descarga y puesta en marcha') return 'Abrir';
    if (item.label == 'Preparando la versión instalada') return 'Ver';
    if (item.label == 'Relevancia del lenguaje Python') return 'Explorar';
    return 'Abrir';
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = onBookTap != null || onVideoTap != null;
    final badgeText = _badgeText();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3ECF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF263238),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Actividad educativa',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF607D8B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF66BB6A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, size: 16, color: Color(0xFF2E7D32)),
                  SizedBox(width: 6),
                  Text(
                    'Completado',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else if (hasAction)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBookTap ?? onVideoTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF90CAF9)),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CapsulaConocimientoLightScreen extends StatelessWidget {
  final String actividad;

  const CapsulaConocimientoLightScreen({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF0B4F6C).withOpacity(0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💡 Cápsula de conocimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Python',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B4F6C).withOpacity(0.95),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escribe código claro, legible y fácil de mantener.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF2A67AB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _LecturaCard(
                title: 'El poder de los nombres descriptivos',
                body:
                    'Cuando escribes código en Python, toma un momento extra para elegir nombres claros y descriptivos para tus variables y funciones. Python premia la claridad, y un buen nombre reduce el esfuerzo de entender el programa.',
                color: const Color(0xFF0B4F6C),
                backgroundColor: const Color(0xFFEAF7FF),
              ),
              const SizedBox(height: 12),
              _LecturaCard(
                title: 'Ejemplo',
                body:
                    'Malo: x = 25\n\ny = "Juan"\n\ndef f(a, b):\n    return a + b\n\nBueno: edad_usuario = 25\n\nnombre_cliente = "Juan"\n\ndef sumar_numeros(numero1, numero2):\n    return numero1 + numero2',
                color: const Color(0xFF1565C0),
                backgroundColor: const Color(0xFFF4F8FC),
              ),
              const SizedBox(height: 12),
              _LecturaCard(
                title: '¿Por qué importa?',
                body:
                    '• Tu código será más fácil de mantener\n• Otros desarrolladores lo entenderán rápido\n• Los errores serán más fáciles de encontrar\n• Python prioriza la legibilidad',
                color: const Color(0xFF1E88E5),
                backgroundColor: const Color(0xFFF8FBFF),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB8860B).withOpacity(0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bonus: La regla del Zen de Python',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe import this en tu intérprete y descubrirás los principios que guían a Python. El primero dice: “Beautiful is better than ugly”.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: const Color(0xFF6D4C41).withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EjemploPythonLightScreen extends StatelessWidget {
  final String actividad;

  const EjemploPythonLightScreen({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF0B4F6C).withOpacity(0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Ejemplo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mi primer programa en Python',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _LecturaCard(
                title: 'Ejemplo: Mi primer programa en Python',
                body:
                    '## Ejemplo: Mi primer programa en Python\n\n```python\n# Mi primer programa en Python\n\nprint("¡Bienvenido a Python!")\n\nprint("Este es mi primer código")\n\nnumero = 10\n\nmensaje = "Python es genial"\n\nprint(f"Número: {numero}")\n\nprint(f"Mensaje: {mensaje}")\n```\n\nResultado en la terminal:\n\n¡Bienvenido a Python!\n\nEste es mi primer código\n\nNúmero: 10\n\nMensaje: Python es genial\n\n### Explicación línea por línea:\n\n1. print("¡Bienvenido a Python!") — Imprime un texto en la pantalla\n2. print("Este es mi primer código") — Imprime otra línea de texto\n3. numero = 10 — Crea una variable llamada numero y le asigna el valor 10\n4. mensaje = "Python es genial" — Crea una variable llamada mensaje con un texto\n5. print(f"Número: {numero}") — Imprime el valor de la variable numero dentro del texto\n6. print(f"Mensaje: {mensaje}") — Imprime el valor de la variable mensaje dentro del texto',
                color: const Color(0xFF1565C0),
                backgroundColor: const Color(0xFFF4F8FC),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB8860B).withOpacity(0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado en la terminal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Bienvenido a Python!\n\nEste es mi primer código\n\nNúmero: 10\n\nMensaje: Python es genial',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF6D4C41),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explicación línea por línea',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStep(
                      'print("¡Bienvenido a Python!")',
                      'Imprime un texto en la pantalla.',
                    ),
                    _buildStep(
                      'print("Este es mi primer código")',
                      'Imprime otra línea de texto.',
                    ),
                    _buildStep(
                      'numero = 10',
                      'Crea una variable llamada numero y le asigna el valor 10.',
                    ),
                    _buildStep(
                      'mensaje = "Python es genial"',
                      'Crea una variable llamada mensaje con un texto.',
                    ),
                    _buildStep(
                      'print(f"Número: {numero}")',
                      'Imprime el valor de la variable numero dentro del texto.',
                    ),
                    _buildStep(
                      'print(f"Mensaje: {mensaje}")',
                      'Imprime el valor de la variable mensaje dentro del texto.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String code, String explanation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$code\n',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF0B4F6C),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: explanation,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2A67AB),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EjercicioInteractivoLightScreen extends StatefulWidget {
  final String actividad;

  const EjercicioInteractivoLightScreen({super.key, required this.actividad});

  @override
  State<EjercicioInteractivoLightScreen> createState() =>
      _EjercicioInteractivoLightScreenState();
}

class _EjercicioInteractivoLightScreenState
    extends State<EjercicioInteractivoLightScreen> {
  late final PageController _pageController;
  final List<String?> _selecciones = List.filled(2, null);
  final List<String?> _feedbacks = List.filled(2, null);
  final List<String> _correctas = const [
    'B) Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que tanto principiantes como expertos creen soluciones poderosas',
    'B) Para gestionar e instalar librerías externas',
  ];
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleSelection(int index, String opcion) {
    setState(() {
      _selecciones[index] = opcion;
      _feedbacks[index] = opcion == _correctas[index]
          ? null
          : 'Respuesta equivocada';
    });
  }

  void _goToNextOrFinish() {
    final seleccionActual = _selecciones[_currentPage];

    if (seleccionActual == null) {
      setState(() {
        _feedbacks[_currentPage] =
            'Selecciona una respuesta antes de continuar.';
      });
      return;
    }

    if (seleccionActual != _correctas[_currentPage]) {
      setState(() {
        _feedbacks[_currentPage] = 'Respuesta equivocada';
      });
      return;
    }

    if (_currentPage < 1) {
      setState(() {
        _currentPage += 1;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF0B4F6C).withOpacity(0.18),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Ejercicio interactivo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Responde correctamente para poder avanzar a la siguiente pregunta.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF2A67AB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Pregunta ${_currentPage + 1} de 2',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: List.generate(2, (index) {
                        final isActive = index == _currentPage;
                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFFBBDEFB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: _buildPregunta(
                      index: index,
                      pregunta: index == 0
                          ? '¿Cuál es la razón principal por la cual Python se ha convertido en el lenguaje de programación más relevante del siglo XXI?'
                          : '¿Para qué se utiliza pip en Python?',
                      opciones: index == 0
                          ? const [
                              'A) Porque fue el primer lenguaje de programación creado',
                              'B) Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que tanto principiantes como expertos creen soluciones poderosas',
                              'C) Porque es el único lenguaje compatible con Windows',
                              'D) Porque no requiere descargar ni instalar nada',
                            ]
                          : const [
                              'A) Para escribir código más rápido',
                              'B) Para gestionar e instalar librerías externas',
                              'C) Para cambiar el color de la terminal',
                              'D) Para ejecutar juegos',
                            ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _goToNextOrFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: Icon(
                        _currentPage < 1
                            ? Icons.arrow_forward
                            : Icons.check_circle_outline,
                      ),
                      label: Text(_currentPage < 1 ? 'Siguiente' : 'Terminar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPregunta({
    required int index,
    required String pregunta,
    required List<String> opciones,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF90CAF9).withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pregunta,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          ...opciones.map(
            (opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _handleSelection(index, opcion),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _selecciones[index] == opcion &&
                            opcion == _correctas[index]
                        ? const Color(0xFF2E7D32)
                        : _selecciones[index] == opcion &&
                              opcion != _correctas[index]
                        ? const Color(0xFFE53935)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _selecciones[index] == opcion &&
                              opcion == _correctas[index]
                          ? const Color(0xFF2E7D32)
                          : _selecciones[index] == opcion &&
                                opcion != _correctas[index]
                          ? const Color(0xFFE53935)
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                  child: Text(
                    opcion,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          _selecciones[index] == opcion &&
                              opcion == _correctas[index]
                          ? Colors.white
                          : _selecciones[index] == opcion &&
                                opcion != _correctas[index]
                          ? Colors.white
                          : const Color(0xFF263238),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_feedbacks[index] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _feedbacks[index]!,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
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

class LecturaTemaLightScreen extends StatefulWidget {
  final String actividad;
  final String contenido;

  const LecturaTemaLightScreen({
    super.key,
    required this.actividad,
    required this.contenido,
  });

  @override
  State<LecturaTemaLightScreen> createState() => _LecturaTemaLightScreenState();
}

class _LecturaTemaLightScreenState extends State<LecturaTemaLightScreen> {
  static const List<String> _lecturasDisponibles = [
    'Relevancia del lenguaje Python',
    '¿Qué es un IDE/Editor?',
    'Palabras clave',
  ];

  late int _indiceActual;
  bool _lecturaCompletada = false;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _indiceActual = _lecturasDisponibles.indexOf(widget.actividad);
    if (_indiceActual == -1) {
      _indiceActual = 0;
    }
  }

  void _cambiarLectura(int delta) {
    if (_isFinishing) return;

    if (_indiceActual == _lecturasDisponibles.length - 1 && delta > 0) {
      setState(() {
        _lecturaCompletada = true;
        _isFinishing = true;
      });

      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) {
          Navigator.pop(context, true);
        }
      });
      return;
    }

    setState(() {
      _indiceActual =
          (_indiceActual + delta + _lecturasDisponibles.length) %
          _lecturasDisponibles.length;
      _lecturaCompletada = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actividadActual = _lecturasDisponibles[_indiceActual];
    final contenidoActual = _textoLecturaPorActividad(actividadActual);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Gris1.png'),
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF45D1D6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              'Lectura: $actividadActual',
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    reverseDuration: const Duration(milliseconds: 240),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<String>(actividadActual),
                      child: actividadActual == 'Relevancia del lenguaje Python'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _LecturaCard(
                                  title: 'Por qué importa',
                                  body:
                                      'Python se ha vuelto clave porque combina una sintaxis clara con una gran capacidad para resolver problemas reales en ciencia de datos, desarrollo web, automatización e inteligencia artificial.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                                const SizedBox(height: 12),
                                _LecturaCard(
                                  title: '¿Dónde se usa?',
                                  body:
                                      'Empresas y equipos tecnológicos lo utilizan para crear prototipos rápidos, servicios digitales y herramientas que conectan distintos sistemas.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                                const SizedBox(height: 12),
                                _LecturaCard(
                                  title: 'Ventajas para aprender',
                                  body:
                                      'Su lectura sencilla y su comunidad activa hacen que aprender Python sea más accesible, más entretenido y más fácil de mantener a lo largo del tiempo.',
                                  color: const Color(0xFF0B4F6C),
                                  backgroundColor: const Color(0xFFEAF7FF),
                                ),
                              ],
                            )
                          : Text(
                              contenidoActual,
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.45,
                                color: Color(0xFF2A67AB),
                              ),
                              textAlign: TextAlign.justify,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF0B4F6C).withOpacity(0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value:
                                  (_indiceActual + 1) /
                                  _lecturasDisponibles.length,
                              minHeight: 8,
                              backgroundColor: const Color(
                                0xFF0B4F6C,
                              ).withOpacity(0.12),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E88E5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_indiceActual + 1}/${_lecturasDisponibles.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B4F6C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _lecturasDisponibles.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _indiceActual ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _indiceActual
                              ? const Color(0xFF1E88E5)
                              : const Color(0xFF0B4F6C).withOpacity(0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_lecturaCompletada)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.25),
                        ),
                      ),
                      child: const Text(
                        '¡Felicitaciones! Has completado la lectura satisfactoriamente.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => _cambiarLectura(-1),
                          child: const _NavButton(label: 'Anterior'),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _cambiarLectura(1),
                          child: _NavButton(
                            label:
                                _indiceActual == _lecturasDisponibles.length - 1
                                ? 'Finalizar'
                                : 'Siguiente',
                          ),
                        ),
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

class _LecturaCard extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final Color backgroundColor;

  const _LecturaCard({
    required this.title,
    required this.body,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: color.withValues(alpha: 0.9),
            ),
          ),
        ],
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
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    softWrap: false,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF263238),
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
