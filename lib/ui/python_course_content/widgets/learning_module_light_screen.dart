import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart'; //REFACTOR-APPBAR
import 'package:flutter_code4all/ui/core/ui/module_header_widget.dart'; //REFACTOR-MODULEHEADERCARD
import 'package:flutter_code4all/ui/python_course_content/widgets/chapter_detail_screen.dart'; //REFACTOR-CHAPTERDETAILSCREEN
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_bottomappbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/detail_card_widget.dart';
import 'package:flutter_code4all/utils/external_url_opener.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module2_light_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module2_dark_screen.dart';
import 'quiz_screen.dart';
import 'quiz_with_video_screen.dart';
import 'laboratory_console_screen.dart';
import 'quiz_screen_dark.dart';
import 'quiz_with_video_screen_dark.dart';
import 'laboratory_console_screen_dark.dart';
import 'final_evaluation_screen.dart';
import '../../users_management/widgets/live_translation_box.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor.dart';

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

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchModuleAndApply(_defaultModuleId);
  }

  void _checkRole() async {
    final role = await _authStorage.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacher = (role ?? '').toLowerCase() == 'docente';
    });
  }

  Future<void> _fetchModuleAndApply(String moduleId) async {
    final backend = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';
    try {
      final res = await http.get(Uri.parse('$backend/api/modules/$moduleId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          _moduleName = data['name'] ?? 'Módulo 1';
          _topics = (data['topics'] as List<dynamic>? ?? []).cast<String>();
        });
      } else {
        _setDefaultState();
      }
    } catch (_) {
      _setDefaultState();
    }
  }

  void _setDefaultState() {
    if (mounted) {
      setState(() {
        _moduleName = 'Módulo 1';
        _topics = [];
      });
    }
  }

  String _topicOrFallback(int idx, String fallback) =>
      (idx >= 0 && idx < _topics.length) ? _topics[idx] : fallback;

  void _goToModulo2() {
    if (_isNavigatingToModule2) return;
    _isNavigatingToModule2 = true;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Modulo2AprendizajeLight()),
    ).then((_) => _isNavigatingToModule2 = false);
  }

  // Método auxiliar para evitar repetir el Navigator en cada botón
  void _navigateToDetail(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;
    final labels = widget.bottomLabels ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Stack(
        children: [
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
              child: Column(
                children: [
                  ModuleHeaderWidget(
                    moduleName: _moduleName,
                    isTeacher: _isTeacher,
                    onEditCompleted: (result) {
                      _fetchModuleAndApply(
                        (result != null && result.isNotEmpty)
                            ? result
                            : _defaultModuleId,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Fila 1
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircle(
                        icon: Icons.account_tree,
                        iconColor: const Color(0xFF1976D2),
                        bgColor: const Color(0xFFE3F2FD),
                        size: bigSize,
                        progress: 0.75,
                        onTap: () =>
                            _navigateToDetail(const Capitulo2DetalleLight()),
                      ),
                      _LessonBox(
                        number: 3,
                        title: _topicOrFallback(2, 'Tema 3'),
                        onTap: () =>
                            _navigateToDetail(const Capitulo2DetalleLight()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fila 2
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _LessonBox(
                        number: 2,
                        title: _topicOrFallback(1, 'Tema 2'),
                        onTap: () =>
                            _navigateToDetail(const Capitulo2DetalleLight()),
                      ),
                      _BigCircle(
                        icon: Icons.manage_search,
                        iconColor: const Color(0xFF8E24AA),
                        bgColor: const Color(0xFFF3E5F5),
                        size: bigSize,
                        progress: 0.6,
                        onTap: () =>
                            _navigateToDetail(const Capitulo2DetalleLight()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Fila 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _BigCircle(
                        icon: Icons.code,
                        iconColor: const Color(0xFF5C6BC0),
                        bgColor: const Color(0xFFE8EAF6),
                        size: bigSize,
                        progress: 0.3,
                        onTap: () =>
                            _navigateToDetail(const CapituloDetalleLight()),
                      ),
                      _LessonBox(
                        number: 1,
                        title: _topicOrFallback(0, 'Tema 1'),
                        onTap: () =>
                            _navigateToDetail(const CapituloDetalleLight()),
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
          Positioned(left: 16, bottom: 8, child: const HelpActionButton()),
        ],
      ),
      bottomNavigationBar: MultimodalNavBar(
        previousLabel: labels.isNotEmpty ? labels[0] : null,
        playLabel: labels.length > 1 ? labels[1] : null,
        nextLabel: labels.length > 2 ? labels[2] : null,
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
