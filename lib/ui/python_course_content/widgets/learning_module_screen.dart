import 'dart:math' as math;
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart'; //MIX
//import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart'; //PAPACHO - ELIMINADO USAR app_theme.dart
import 'package:flutter_code4all/ui/core/ui/multimodal_bottomappbar_widget.dart'; //REFACTOR-MULTIMODALBOTTOMAPPBARWIDGET - RENOMBRADO DE multimodal_footer_bar
//import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart'; //PAPACHO - MOVIDO A GlobalAppBarWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module2_light_screen.dart'; //PAPACHO - ELIMINADO USAR LearningModuleScreen
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/data/services/auth_storage.dart'; //PAPACHO
//import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart'; //PAPACHO - MOVIDO A ModuleHeaderWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_page.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/course/python_course_catalog.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/services/course_progress_store.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_progress.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart'; //REFACTOR-APPBAR
import 'package:flutter_code4all/ui/core/ui/NEW_module_header_widget.dart'; //REFACTOR-MODULEHEADERCARD
import 'package:flutter_code4all/ui/python_course_content/widgets/NEW_chapter_detail_screen.dart'; //REFACTOR-CHAPTERDETAILSCREEN
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/NEW_detail_card_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/NEW_module_row_widget.dart'; //REFACTOR-MODULEROWWIDGET

class LearningModuleScreen extends StatefulWidget {
  final int moduleNumber; // Remplaza la necesidad de tener 6 pantallas
  final int totalModules;
  final String userName;
  final VoidCallback? onLogout;
  final List<String>? bottomLabels;

  const LearningModuleScreen({
    super.key,
    this.moduleNumber = 1,
    this.totalModules = 6, // Define tu máximo de módulos aquí
    this.userName = 'Usuario',
    this.onLogout,
    this.bottomLabels,
  });

  @override
  State<LearningModuleScreen> createState() => _LearningModuleScreenState();
}

class _LearningModuleScreenState extends State<LearningModuleScreen> {
  bool _isNavigating = false;
  bool _isTeacher = false;
  late String _moduleName = 'Módulo 1';
  late String _currentModuleId;

  final _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    _moduleName = 'Módulo ${widget.moduleNumber}';
    _currentModuleId =
        'module-${widget.moduleNumber}'; // Generación dinámica del ID
    _checkRole();
    _fetchModuleAndApply(_currentModuleId);
  }

  void _checkRole() async {
    final role = await _authStorage.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacher = (role ?? '').toLowerCase() == 'docente';
    });
  }

  Future<void> _fetchModuleAndApply(String moduleId) async {
    final backend = ApiService().baseUrl;
    try {
      final res = await http.get(Uri.parse('$backend/api/modules/$moduleId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          _moduleName = data['name'] ?? 'Módulo ${widget.moduleNumber}';
          //_currentModuleId = data['id'] ?? _currentModuleId;
        });
      }
    } catch (_) {}
  }

  void _goToNextModule() {
    if (_isNavigating || widget.moduleNumber >= widget.totalModules) return;
    _isNavigating = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningModuleScreen(
          moduleNumber: widget.moduleNumber + 1,
          totalModules: widget.totalModules,
          userName: widget.userName,
          onLogout: widget.onLogout,
          bottomLabels: widget.bottomLabels,
        ),
      ),
    ).then((_) => _isNavigating = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = screenW * 0.40;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasNextModule = widget.moduleNumber < widget.totalModules;
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
                _goToNextModule();
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
                            : _currentModuleId,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Fila 1 (Sección 3)
                  ModuleRowWidget(
                    moduleNumber: widget.moduleNumber,
                    sectionNumber: 3,
                    isCircleLeft: true,
                    icon: Icons.account_tree,
                    iconColor: colors.primary, // Azul centralizado
                    bgColor: colors.primaryContainer,
                    bigSize: bigSize,
                  ),
                  const SizedBox(height: 12),
                  // Fila 2 (Sección 2)
                  ModuleRowWidget(
                    moduleNumber: widget.moduleNumber,
                    sectionNumber: 2,
                    isCircleLeft: false, // ¡Intercala la posición!
                    icon: Icons.manage_search,
                    iconColor: colors.secondary, // Morado centralizado
                    bgColor: colors.secondaryContainer,
                  ),
                  const SizedBox(height: 12),
                  // Fila 3 (Sección 1)
                  ModuleRowWidget(
                    moduleNumber: widget.moduleNumber,
                    sectionNumber: 1,
                    isCircleLeft: true,
                    icon: Icons.code,
                    iconColor: colors.tertiary, // Índigo centralizado
                    bgColor: colors.tertiaryContainer,
                    bigSize: bigSize,
                    enableTeacherEditor: true,
                  ),
                  const SizedBox(height: 12),
                  // Indicador dinámico de siguiente módulo
                  if (hasNextModule)
                    Semantics(
                      label:
                          'Desliza hacia arriba para ir al Módulo ${widget.moduleNumber + 1}',
                      child: Text(
                        'Desliza hacia arriba para ir al Módulo ${widget.moduleNumber + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors
                              .onSurfaceVariant, // Color semántico del tema
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(left: 16, bottom: 8, child: const HelpActionButton()),
        ],
      ),
      bottomNavigationBar: MultimodalBottomAppBarWidget(
        previousLabel: widget.bottomLabels?.elementAtOrNull(0),
        playLabel: widget.bottomLabels?.elementAtOrNull(1),
        nextLabel: widget.bottomLabels?.elementAtOrNull(2),
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
