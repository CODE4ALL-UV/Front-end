import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
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
