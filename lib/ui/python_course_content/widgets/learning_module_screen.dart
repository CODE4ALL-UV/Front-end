import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart'; //MIX
//import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart'; //PAPACHO - ELIMINADO USAR app_theme.dart
import 'package:flutter_code4all/ui/core/ui/bottomappbar_widget.dart'; //REFACTOR-MULTIMODALBOTTOMAPPBARWIDGET - RENOMBRADO DE multimodal_footer_bar
//import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart'; //PAPACHO - MOVIDO A GlobalAppBarWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module2_light_screen.dart'; //PAPACHO - ELIMINADO USAR LearningModuleScreen
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_code4all/data/services/auth_storage.dart'; //PAPACHO
//import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart'; //PAPACHO - MOVIDO A ModuleHeaderWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_screen.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/course/python_course_catalog.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/services/course_progress_store.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_progress.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart'; //REFACTOR-APPBAR
import 'package:flutter_code4all/ui/core/ui/responsive_layout.dart';
import 'package:flutter_code4all/ui/core/ui/new_module_header_widget.dart'; //REFACTOR-MODULEHEADERCARD
import 'package:flutter_code4all/ui/python_course_content/widgets/new_chapter_detail_screen.dart'; //REFACTOR-CHAPTERDETAILSCREEN
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_detail_card_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_module_row_widget.dart';
import '../../core/themes/module_theme.dart'; //REFACTOR-MODULEROWWIDGET

class LearningModuleScreen extends StatefulWidget {
  final int moduleId; // Remplaza la necesidad de tener 6 pantallas
  final int totalModules;
  final String userName;
  final VoidCallback? onLogout;
  final List<String>? bottomLabels;

  // NUEVO: Añadimos un callback para avisarle a app.dart que cambiamos de módulo
  final ValueChanged<int>? onModuleChanged;

  const LearningModuleScreen({
    super.key,
    this.moduleId = 1,
    this.totalModules = 6, // Define tu máximo de módulos aquí
    this.userName = 'Usuario',
    this.onLogout,
    this.bottomLabels,
    this.onModuleChanged, // NUEVO
  });

  @override
  State<LearningModuleScreen> createState() => _LearningModuleScreenState();
}

class _LearningModuleScreenState extends State<LearningModuleScreen> {
  bool _isNavigating = false;
  bool _isTeacher = false;
  late String _currentModuleId;
  late String _moduleTitle;

  final _authStorage = AuthStorage();

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [SCREEN] initState Módulo ${widget.moduleId}');
    _currentModuleId = widget.moduleId.toString(); // Generación dinámica del ID
    _moduleTitle =
        'Preparación'; // Valor por defecto hasta que se obtenga del backend

    // NUEVO: Le avisamos a app.dart en qué módulo estamos para que actualice la paleta.
    // Usamos addPostFrameCallback para evitar errores de redibujado de Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.onModuleChanged != null) {
        debugPrint(
          '🔵 [SCREEN] Avisando a app.dart que estamos en el Módulo ${widget.moduleId}',
        );
        widget.onModuleChanged!(widget.moduleId);
      }
    });

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
          _currentModuleId = data['id'].toString();
          _moduleTitle = data['name'] ?? 'Preparación';
        });
      }
    } catch (_) {}
  }

  Widget _responsiveContent(Widget content) {
    return ResponsiveLayout(
      mobileLayout: content,
      tabletLayout: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: content,
        ),
      ),
      desktopLayout: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: content,
        ),
      ),
    );
  }

  void _goToNextModule() {
    if (_isNavigating || widget.moduleId >= widget.totalModules) return;
    _isNavigating = true;

    debugPrint(
      '⏩ [SCREEN] Navegando del Módulo ${widget.moduleId} al ${widget.moduleId + 1}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningModuleScreen(
          moduleId: widget.moduleId + 1,
          totalModules: widget.totalModules,
          userName: widget.userName,
          onLogout: widget.onLogout,
          bottomLabels: widget.bottomLabels,
          onModuleChanged: widget
              .onModuleChanged, // NUEVO: Pasamos el callback a la siguiente pantalla
        ),
      ),
    ).then((_) {
      _isNavigating = false;
      debugPrint('⏪ [SCREEN] Regresamos (pop) al Módulo ${widget.moduleId}');
      // NUEVO: Cuando el usuario le da "Atrás" (pop) y vuelve a este módulo,
      // volvemos a avisarle a app.dart que recupere el color de ESTE módulo.
      if (mounted && widget.onModuleChanged != null) {
        widget.onModuleChanged!(widget.moduleId);
      }
    });
  }

  void _goToPreviousModule() {
    if (_isNavigating || widget.moduleId <= 1) return;
    _isNavigating = true;

    debugPrint(
      '⏪ [SCREEN] Navegando del Módulo ${widget.moduleId} al ${widget.moduleId - 1}',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningModuleScreen(
          moduleId: widget.moduleId - 1,
          totalModules: widget.totalModules,
          userName: widget.userName,
          onLogout: widget.onLogout,
          bottomLabels: widget.bottomLabels,
          onModuleChanged: widget.onModuleChanged,
        ),
      ),
    ).then((_) {
      _isNavigating = false;
      debugPrint('⏪ [SCREEN] Regresamos (pop) al Módulo ${widget.moduleId}');
      if (mounted && widget.onModuleChanged != null) {
        widget.onModuleChanged!(widget.moduleId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final bigSize = (screenW * 0.32).clamp(112.0, 260.0).toDouble();
    final horizontalPadding = screenW >= AppBreakpoints.tablet ? 28.0 : 16.0;
    final verticalGap = (MediaQuery.of(context).size.height * 0.025)
        .clamp(12.0, 28.0)
        .toDouble();
    final hasNextModule = widget.moduleId < widget.totalModules;
    final hasPreviousModule = widget.moduleId > 1;

    final appTheme = Theme.of(context);
    final appModuleTheme = context.courseTheme;
    final currentThemeMode = ThemeManager.themeNotifier.value;

    debugPrint(
      '🟣 [SCREEN] Haciendo BUILD Módulo ${widget.moduleId} with AppThemeMode $currentThemeMode',
    );
    // debugPrint(
    //   '🟣 [SCREEN] Colores extraídos: Header=${appModuleTheme.headerBackground}, Icono1=${appModuleTheme.chapterIconColor1}',
    // );

    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Stack(
        children: [
          NotificationListener<OverscrollNotification>(
            onNotification: (notification) {
              if (notification.overscroll < -10 &&
                  notification.metrics.pixels <=
                      notification.metrics.minScrollExtent) {
                _goToPreviousModule();
                return true;
              }
              if (notification.overscroll > 10 &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent - 1) {
                _goToNextModule();
                return true;
              }
              return false;
            },
            child: _responsiveContent(
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ModuleHeaderWidget(
                            moduleId: _currentModuleId,
                            moduleTitle: _moduleTitle,
                            isTeacher: _isTeacher,
                            onEditCompleted: (result) {
                              _fetchModuleAndApply(
                                (result != null && result.isNotEmpty)
                                    ? result
                                    : _currentModuleId,
                              );
                            },
                          ),
                          SizedBox(height: verticalGap),
                          // Fila 1 (Sección 3)
                          ModuleRowWidget(
                            moduleId: widget.moduleId,
                            sectionNumber: 1,
                            isCircleLeft: false,
                            icon: Icons.account_tree,
                            iconColor: appModuleTheme
                                .chapterIconColor1, // Azul centralizado
                            bgColor: appModuleTheme.chapterIconBackgroundColor1,
                            bigSize: bigSize,
                          ),
                          SizedBox(height: verticalGap),
                          // Fila 2 (Sección 2)
                          ModuleRowWidget(
                            moduleId: widget.moduleId,
                            sectionNumber: 2,
                            isCircleLeft: true, // ¡Intercala la posición!
                            icon: Icons.manage_search,
                            iconColor: appModuleTheme
                                .chapterIconColor2, // Morado centralizado
                            bgColor: appModuleTheme.chapterIconBackgroundColor2,
                            bigSize: bigSize,
                          ),
                          SizedBox(height: verticalGap),
                          // Fila 3 (Sección 1)
                          ModuleRowWidget(
                            moduleId: widget.moduleId,
                            sectionNumber: 3,
                            isCircleLeft: false,
                            icon: Icons.code,
                            iconColor: appModuleTheme
                                .chapterIconColor3, // Índigo centralizado
                            bgColor: appModuleTheme.chapterIconBackgroundColor3,
                            bigSize: bigSize,
                            enableTeacherEditor: true,
                          ),
                          const SizedBox(height: 12),
                          // Indicador dinámico de siguiente módulo
                          if (hasNextModule)
                            Semantics(
                              label:
                                  'Desliza hacia arriba para ir al Módulo ${widget.moduleId + 1}',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.keyboard_arrow_up, size: 20),
                                  Text(
                                    'Desliza hacia arriba para ir al Módulo ${widget.moduleId + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          appTheme
                                              .textTheme
                                              .bodyMedium
                                              ?.color ??
                                          Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (hasPreviousModule) ...[
                            const SizedBox(height: 6),
                            Semantics(
                              label:
                                  'Desliza hacia abajo para volver al Módulo ${widget.moduleId - 1}',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 20,
                                  ),
                                  Text(
                                    'Desliza hacia abajo para volver al Módulo ${widget.moduleId - 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          appTheme
                                              .textTheme
                                              .bodyMedium
                                              ?.color ??
                                          Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(left: 12, bottom: 8, child: const HelpActionButton()),
        ],
      ),
      bottomNavigationBar: MultimodalBottomAppBarWidget(
        playLabel: widget.bottomLabels?.elementAtOrNull(1),
      ),
    );
  }
}
