import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button_widget.dart'; //MIX
//import 'package:flutter_code4all/ui/core/ui/visual_theme_controller.dart'; //PAPACHO - ELIMINADO USAR app_theme.dart
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
//import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart'; //PAPACHO - MOVIDO A GlobalAppBarWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module2_light_screen.dart'; //PAPACHO - ELIMINADO USAR LearningModuleScreen
import 'package:flutter_code4all/data/services/auth_storage.dart'; //PAPACHO
//import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart'; //PAPACHO - MOVIDO A ModuleHeaderWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_screen.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/course/python_course_catalog.dart'; //PAPACHO - MOVIDO A ModuleRowWidget
//import 'package:flutter_code4all/data/services/course_progress_store.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
//import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_progress.dart'; //PAPACHO - MOVIDO A CircleProgressWidget
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart'; //REFACTOR-APPBAR
import 'package:flutter_code4all/ui/core/ui/responsive_layout_screen.dart';
import 'package:flutter_code4all/ui/core/ui/module_header_widget.dart'; //REFACTOR-MODULEHEADERCARD
import 'package:flutter_code4all/ui/python_course_content/widgets/module_row_widget.dart';

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
  /// Lo que ocupa de alto la cabecera del módulo, medido a tamaño de letra
  /// normal. Sirve para saber cuánto sitio queda para la ruta de secciones.
  ///
  /// Es una estimación, y por eso no pasa nada si se queda corta: con la
  /// letra agrandada la cabecera crece, las filas no caben, y entonces el
  /// contenido se desplaza como siempre.
  static const double _moduleHeaderHeight = 84;

  bool _isNavigating = false;
  bool _isTeacher = false;

  final _authStorage = AuthStorage();
  final CourseContentStore _content = CourseContentStore.instance;

  String get _currentModuleId => widget.moduleId.toString();

  /// El nombre del módulo: el del temario, con el cambio del docente encima.
  ///
  /// Antes se pedía a `/api/modules/{id}` y, mientras llegaba —o si no
  /// llegaba—, se mostraba 'Preparación'. Como ese es justo el título del
  /// módulo 1, los seis módulos acababan llamándose igual. Ahora el nombre
  /// sale del temario que la aplicación ya lleva dentro, así que es el
  /// correcto desde el primer fotograma y sin depender de la red; lo que
  /// haya editado el docente se aplica encima en cuanto llega.
  String get _moduleTitle {
    final base = PythonCourseCatalog.moduleByNumber(widget.moduleId);
    return _content.moduleTitle(
      widget.moduleId,
      base?.title ?? 'Módulo ${widget.moduleId}',
    );
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 [SCREEN] initState Módulo ${widget.moduleId}');

    // Lo que el docente haya editado del temario. Si el servidor no responde
    // no pasa nada: se sigue viendo el módulo de fábrica.
    _content.addListener(_onContentChanged);
    _content.refresh();

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
  }

  @override
  void dispose() {
    _content.removeListener(_onContentChanged);
    // Si se sale a mitad de la lectura, la voz no debe seguir sonando sobre
    // la pantalla siguiente.
    accessibilityReadingState.stop();
    super.dispose();
  }

  /// El pie con la forma de ir al módulo anterior y al siguiente.
  ///
  /// Va fuera del scroll a propósito. Antes vivía al final del contenido, así
  /// que para enterarse de que se podía pasar al módulo siguiente había que
  /// bajar hasta abajo del todo; y con la letra agrandada, más todavía. El
  /// aviso de cómo salir de una pantalla es lo último que debe esconderse.
  ///
  /// Se acompaña de botones porque deslizar no le sirve a todo el mundo: con
  /// lector de pantalla el gesto lo consume el propio lector, y hay quien
  /// maneja el teléfono con un conmutador o un teclado y no puede deslizar.
  Widget _buildModuleNavigation(BuildContext context) {
    final hasNext = widget.moduleId < widget.totalModules;
    final hasPrevious = widget.moduleId > 1;

    final appSemanticColors = Theme.of(
      context,
    ).extension<ActivityThemeColors>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appSemanticColors.infoBackground,
        border: Border(top: BorderSide(color: appSemanticColors.infoBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              // El botón de ayuda vive aquí y no flotando sobre el contenido.
              // Flotando tapaba siempre lo que quedara abajo del todo —en la
              // ruta de secciones, la última tarjeta— y ningún margen lo
              // arregla, porque se queda fijo aunque el contenido se desplace.
              const HelpActionButton(),
              const SizedBox(width: 8),
              // Los avisos, uno debajo del otro y con el mensaje entero. Dos
              // frases completas no caben lado a lado en un teléfono, y menos
              // con la letra agrandada.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasNext)
                      _ModuleNavigationHint(
                        icon: Icons.keyboard_arrow_up,
                        message:
                            'Desliza hacia arriba para ir al Módulo '
                            '${widget.moduleId + 1}',
                        onPressed: _goToNextModule,
                      ),
                    if (hasNext && hasPrevious) const SizedBox(height: 6),
                    if (hasPrevious)
                      _ModuleNavigationHint(
                        icon: Icons.keyboard_arrow_down,
                        message:
                            'Desliza hacia abajo para volver al Módulo '
                            '${widget.moduleId - 1}',
                        onPressed: _goToPreviousModule,
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

  /// Corta la lectura antes de cambiar de módulo.
  ///
  /// El asistente de voz es único para toda la aplicación, así que una pausa
  /// sobrevive al cambio de pantalla. Sin esto, pausar en el módulo 1 y pasar
  /// al 2 dejaría el botón ofreciendo «reanudar» y, al pulsarlo, se oiría el
  /// texto del módulo anterior encima del nuevo.
  void _stopSpeechBeforeLeaving() {
    accessibilityReadingState.stop();
  }

  void _onContentChanged() {
    if (!mounted) return;

    // El almacén avisa cuando le contesta el servidor, y eso puede caer justo
    // mientras el framework está construyendo: por ejemplo al cerrar sesión,
    // que cierra de golpe todas las pantallas de módulo apiladas. Pedir el
    // redibujado en ese momento es un error de Flutter, así que se aplaza al
    // siguiente fotograma.
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    setState(() {});
  }

  void _checkRole() async {
    final role = await _authStorage.getRole();
    if (!mounted) return;
    setState(() {
      _isTeacher = (role ?? '').toLowerCase() == 'docente';
    });
  }

  /// Tras volver del editor del docente, vuelve a pedir lo editado.
  ///
  /// El editor ya guardó en el servidor; esto es solo para que el cambio se
  /// vea al instante en esta pantalla sin tener que salir y entrar.
  void _reloadEditedContent() {
    _content.refresh();
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
    _stopSpeechBeforeLeaving();

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
    _stopSpeechBeforeLeaving();

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
    final horizontalPadding = screenW >= AppBreakpoints.tablet ? 28.0 : 16.0;
    final verticalGap = (MediaQuery.of(context).size.height * 0.025)
        .clamp(12.0, 28.0)
        .toDouble();
    final appModuleTheme = context.moduleTheme;
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
      body: Column(
        children: [
          // La barra de escuchar y tamano de texto va fija arriba: si se
          // fuera con el scroll, quien necesita agrandar la letra tendria
          // que buscarla primero.
          const AccessibilityToolbar(),
          Expanded(
            child: Stack(
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
                        // Cuánto puede medir cada fila para que las tres
                        // quepan sin tener que desplazarse.
                        //
                        // Se reparte el alto que queda tras descontar lo que
                        // ocupa todo lo demás: los márgenes de arriba y abajo,
                        // la cabecera del módulo y los tres huecos. Si aun así
                        // no cabe —con la letra muy grande la cabecera crece—
                        // el scroll sigue ahí, que para eso está.
                        final rowsBudget =
                            constraints.maxHeight -
                            44 -
                            _moduleHeaderHeight -
                            verticalGap * 3;
                        final bigSize = rowsBudget / 3;

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            20,
                            horizontalPadding,
                            24,
                          ),
                          child: ConstrainedBox(
                            // El alto del viewport menos el margen de arriba
                            // y abajo. Sin restarlo, el contenido medía
                            // siempre 44 px más que la ventana y quedaban
                            // esos 44 px de desplazamiento aunque no hiciera
                            // falta.
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 44,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ModuleHeaderWidget(
                                  moduleId: _currentModuleId,
                                  moduleTitle: _moduleTitle,
                                  isTeacher: _isTeacher,
                                  onEditCompleted: (_) =>
                                      _reloadEditedContent(),
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
                                  bgColor: appModuleTheme
                                      .chapterIconBackgroundColor1,
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
                                  bgColor: appModuleTheme
                                      .chapterIconBackgroundColor2,
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
                                  bgColor: appModuleTheme
                                      .chapterIconBackgroundColor3,
                                  bigSize: bigSize,
                                  enableTeacherEditor: true,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildModuleNavigation(context),
        ],
      ),
    );
  }
}

/// El aviso de cómo pasar de módulo.
///
/// Dice lo mismo de siempre —que se desliza— pero además se puede tocar.
/// Deslizar no le sirve a todo el mundo: con lector de pantalla el gesto lo
/// consume el propio lector, y quien maneja el teléfono con un conmutador o
/// un teclado no puede deslizar. Al tocarlo hace lo mismo que el gesto.
class _ModuleNavigationHint extends StatelessWidget {
  const _ModuleNavigationHint({
    required this.icon,
    required this.message,
    required this.onPressed,
  });

  final IconData icon;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final appSemanticColors = Theme.of(
      context,
    ).extension<ActivityThemeColors>()!;

    return Semantics(
      button: true,
      label: message,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: appSemanticColors.infoText),
                const SizedBox(width: 4),
                // Flexible para que con la letra agrandada parta el renglón
                // en lugar de desbordar por el lado.
                Flexible(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: appSemanticColors.infoText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
