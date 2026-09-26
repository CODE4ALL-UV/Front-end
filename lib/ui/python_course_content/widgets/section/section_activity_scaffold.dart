import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'section_widgets.dart';

/// Estructura común de todas las pantallas de actividad de la ruta.
///
/// Reúne en un solo lugar lo que hace la ruta utilizable para todo el mundo:
///
/// * **Para quien no ve**: jerarquía de encabezados, etiquetas semánticas en
///   cada control, y un botón "Escuchar" que lee la pantalla completa.
/// * **Para quien no oye**: nada se comunica solo con sonido. Todo lo que se
///   lee en voz alta está también escrito en la pantalla, y cada cambio de
///   estado se anuncia con texto e icono, nunca con un pitido.
/// * **Para baja visión**: contraste AA, controles para agrandar la letra y un
///   ancho de línea limitado para no perder el renglón.
class SectionActivityScaffold extends StatefulWidget {
  const SectionActivityScaffold({
    super.key,
    required this.moduleLabel,
    required this.sectionTitle,
    required this.activityLabel,
    required this.activityIcon,
    required this.spokenText,
    required this.child,
    this.bottomBar,
    this.progress,
    this.progressLabel,
    this.onBack,
  });

  /// "Módulo 2. Fundamentos de Python".
  final String moduleLabel;

  /// "Capítulo 1: Sintaxis".
  final String sectionTitle;

  /// "Lectura", "Quiz", "Ejemplo"...
  final String activityLabel;
  final IconData activityIcon;

  /// Texto completo de la pantalla, en el orden en que debe escucharse.
  final String spokenText;

  final Widget child;
  final Widget? bottomBar;

  /// Avance entre 0 y 1. Si es nulo no se muestra barra.
  final double? progress;
  final String? progressLabel;

  final VoidCallback? onBack;

  @override
  State<SectionActivityScaffold> createState() =>
      _SectionActivityScaffoldState();
}

class _SectionActivityScaffoldState extends State<SectionActivityScaffold> {
  final ScrollController _scrollController = ScrollController();

  final LearningPreferences _prefs = LearningPreferences.instance;

  /// Si ya se mostró la guía en esta pantalla.
  bool _manualShown = false;

  @override
  void initState() {
    super.initState();
    _prefs.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() {});
      _startAutoReadIfAsked();
      _showManualIfAsked();
    });
  }

  /// Empieza a leer en voz alta sola, si el estudiante prefirió «Audios».
  ///
  /// De poco sirve decir que se prefiere el audio si luego hay que pedirlo a
  /// mano en cada pantalla.
  void _startAutoReadIfAsked() {
    if (!_prefs.autoReadAloud) return;
    if (!mounted) return;
    accessibilityReadingState.read(_spokenScript, context);
  }

  /// Muestra la guía de la pantalla, si el manual interactivo está activo.
  ///
  /// Se explica lo que hay en esta pantalla concreta y cómo usarlo, una vez
  /// por visita. Repetirlo en cada redibujado lo convertiría en un estorbo.
  void _showManualIfAsked() {
    if (!_prefs.manualEnabled || _manualShown || !mounted) return;
    _manualShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => _ManualDialog(
          activityLabel: widget.activityLabel,
          sectionTitle: widget.sectionTitle,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Si el estudiante sale a mitad de la lectura, la voz no debe seguir
    // sonando sobre la pantalla siguiente.
    accessibilityReadingState.stop();
    super.dispose();
  }

  /// El guion de esta pantalla, en el orden en que debe escucharse.
  String get _spokenScript =>
      '${widget.activityLabel}. ${widget.sectionTitle}. ${widget.spokenText}';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Scaffold(
      backgroundColor: appColorScheme.surface,
      appBar: const GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: Column(
        children: [
          _ActivityBanner(
            moduleLabel: widget.moduleLabel,
            sectionTitle: widget.sectionTitle,
            activityLabel: widget.activityLabel,
            activityIcon: widget.activityIcon,
          ),
          AccessibilityToolbar(spokenText: _spokenScript),
          if (widget.progress != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: SectionProgressBar(
                value: widget.progress!,
                label: widget.progressLabel ?? 'Avance de la actividad',
              ),
            ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: AppMetrics.pagePadding(width),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppMetrics.maxContentWidth,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          if (widget.bottomBar != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: appSemanticColors.infoBackground,
                border: Border(
                  top: BorderSide(color: appSemanticColors.infoBorder),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 380 ? 14 : 20,
                    vertical: 12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppMetrics.maxContentWidth,
                      ),
                      child: widget.bottomBar!,
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

class _ActivityBanner extends StatelessWidget {
  const _ActivityBanner({
    required this.moduleLabel,
    required this.sectionTitle,
    required this.activityLabel,
    required this.activityIcon,
  });

  final String moduleLabel;
  final String sectionTitle;
  final String activityLabel;
  final IconData activityIcon;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Semantics(
      header: true,
      label: '$activityLabel. $sectionTitle. $moduleLabel',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: appSemanticColors.infoBackground,
            border: Border(
              bottom: BorderSide(color: appSemanticColors.infoBorder),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppMetrics.maxContentWidth,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: appSemanticColors.infoBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      activityIcon,
                      size: 24,
                      color: appColorScheme.surface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moduleLabel,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: appSemanticColors.infoText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$activityLabel · $sectionTitle',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: appSemanticColors.infoText,
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
    );
  }
}

/// Barra con los controles de accesibilidad de la pantalla.

/// La guía que aparece al abrir una actividad con el manual interactivo
/// activo.
///
/// Explica qué hay en **esta** pantalla y cómo usarlo, no una ayuda genérica.
/// Se escribe aquí y no en el catálogo del curso porque habla de los controles
/// de la aplicación, que son los mismos para todos los módulos: si estuviera
/// en el temario, habría que repetirla en cada una de las secciones.
class _ManualDialog extends StatelessWidget {
  const _ManualDialog({
    required this.activityLabel,
    required this.sectionTitle,
  });

  final String activityLabel;
  final String sectionTitle;

  /// Los pasos de cada tipo de actividad.
  ///
  /// Si aparece una actividad nueva y nadie escribe su guía, cae en la lista
  /// general, que habla de los controles que están en todas las pantallas. Se
  /// prefiere eso a no decir nada.
  static const Map<String, List<String>> _steps = {
    'Lectura': [
      'El contenido va por páginas: avanza con el botón de abajo.',
      'El botón «Escuchar» de la barra superior lee la página en voz alta, y '
          'puedes pausarla donde quieras.',
      'Con A− y A+ cambias el tamaño de la letra en toda la aplicación.',
    ],
    'Quiz': [
      'Elige una opción para responder. Al hacerlo verás si acertaste y por qué.',
      'Si activaste las pistas en el menú de ayuda, antes de responder aparece '
          'el botón «Ver una pista».',
      'Se aprueba con el 60 % de aciertos, y puedes repetir el intento.',
    ],
    'Evaluación': [
      'Funciona como el quiz, pero cuenta para cerrar la sección.',
      'Responde con calma: se guarda cuánto tardas, y sirve para que el docente '
          'sepa qué pregunta está costando.',
      'Puedes repetirla si no la apruebas.',
    ],
    'Ejemplo': [
      'El código viene explicado línea por línea.',
      'Debajo verás qué imprime al ejecutarse.',
      'El botón «Escuchar» lee la explicación completa.',
    ],
    'Video': [
      'El video tiene transcripción escrita: todo lo que se dice está también '
          'en texto.',
      'Si activaste «Lengua de señas» en el menú de ayuda, verás el panel que '
          'deletrea lo que se está diciendo.',
    ],
    'Cápsula': [
      'Son consejos cortos sobre el tema de la sección.',
      'Léelos antes de pasar al ejercicio: resuelven los errores más comunes.',
    ],
  };

  static const List<String> _general = [
    'El botón «Escuchar» de la barra superior lee esta pantalla en voz alta.',
    'Con A− y A+ cambias el tamaño de la letra en toda la aplicación.',
    'El botón morado de ayuda abre los ajustes de aprendizaje y accesibilidad.',
  ];

  @override
  Widget build(BuildContext context) {
    final appSemanticColors = Theme.of(
      context,
    ).extension<ActivityThemeColors>()!;
    final steps = _steps[activityLabel] ?? _general;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(Icons.menu_book, color: appSemanticColors.infoText),
          const SizedBox(width: 10),
          Expanded(child: Text('Cómo usar esta pantalla')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$activityLabel · $sectionTitle',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: appSemanticColors.infoText,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: appSemanticColors.infoBackground,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: appSemanticColors.infoText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(steps[i], style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
