import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale.dart';
import 'package:flutter_code4all/ui/core/ui/stored_user_avatar.dart';

import 'section_theme.dart';
import 'section_widgets.dart';

/// Estructura común de todas las pantallas de actividad de la ruta.
///
/// Reúne en un solo lugar lo que hace la ruta utilizable para todo el mundo:
///
/// * **Para quien no ve**: jerarquía de encabezados, etiquetas semánticas en
///   cada control, y un botón "Escuchar" que lee la pantalla completa.
/// * **Para quien no oye**: nada se comunica solo con sonido. Lo que se lee en
///   voz alta aparece además como transcripción resaltada en la franja
///   inferior, y cada cambio de estado se anuncia con texto e icono.
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

  Future<void> _toggleSpeech() async {
    if (accessibilityReadingState.isHighlighting.value) {
      await accessibilityReadingState.stop();
      if (!mounted) return;
      _announce('Lectura en voz alta detenida');
      return;
    }

    final text =
        '${widget.activityLabel}. ${widget.sectionTitle}. ${widget.spokenText}';
    await accessibilityReadingState.read(text, context);
  }

  void _announce(String message) {
    announceForAccessibility(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Volver',
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: StoredUserAvatar(radius: 14, size: 28, showName: false),
          ),
        ],
      ),
      body: ReadableScreenHighlight(
        child: Column(
          children: [
            _ActivityBanner(
              moduleLabel: widget.moduleLabel,
              sectionTitle: widget.sectionTitle,
              activityLabel: widget.activityLabel,
              activityIcon: widget.activityIcon,
            ),
            _AccessibilityToolbar(onToggleSpeech: _toggleSpeech),
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
                  padding: SectionMetrics.pagePadding(width),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: SectionMetrics.maxContentWidth,
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
                  color: palette.surface,
                  border: Border(top: BorderSide(color: palette.border)),
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
                          maxWidth: SectionMetrics.maxContentWidth,
                        ),
                        child: widget.bottomBar!,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
    final palette = SectionPalette.of(context);

    return Semantics(
      header: true,
      label: '$activityLabel. $sectionTitle. $moduleLabel',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border(bottom: BorderSide(color: palette.border)),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: SectionMetrics.maxContentWidth,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(activityIcon, size: 24, color: palette.accent),
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
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$activityLabel · $sectionTitle',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
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
class _AccessibilityToolbar extends StatelessWidget {
  const _AccessibilityToolbar({required this.onToggleSpeech});

  final Future<void> Function() onToggleSpeech;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final textScale = AccessibilityTextScaleScope.of(context);

    return Container(
      width: double.infinity,
      color: palette.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: SectionMetrics.maxContentWidth,
          ),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: accessibilityReadingState.isHighlighting,
                  builder: (context, isReading, _) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: isReading
                            ? 'Detener la lectura en voz alta'
                            : 'Escuchar esta pantalla en voz alta',
                        hint: isReading
                            ? null
                            : 'También verás el texto resaltado abajo mientras se lee',
                        child: TextButton.icon(
                          onPressed: () => onToggleSpeech(),
                          style: TextButton.styleFrom(
                            foregroundColor: palette.accent,
                            minimumSize: const Size(
                              SectionMetrics.minTapTarget,
                              SectionMetrics.minTapTarget,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: Icon(
                            isReading ? Icons.stop_circle : Icons.volume_up,
                            size: 22,
                          ),
                          label: Text(isReading ? 'Detener' : 'Escuchar'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              _TextScaleButton(
                icon: Icons.text_decrease,
                label: 'Reducir el tamaño del texto',
                onPressed: textScale.decrease,
              ),
              AnimatedBuilder(
                animation: textScale,
                builder: (context, _) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      label:
                          'Tamaño del texto al '
                          '${(textScale.scale * 100).round()} por ciento',
                      child: ExcludeSemantics(
                        child: Text(
                          '${(textScale.scale * 100).round()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              _TextScaleButton(
                icon: Icons.text_increase,
                label: 'Aumentar el tamaño del texto',
                onPressed: textScale.increase,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextScaleButton extends StatelessWidget {
  const _TextScaleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        color: palette.accent,
        tooltip: label,
        constraints: const BoxConstraints(
          minWidth: SectionMetrics.minTapTarget,
          minHeight: SectionMetrics.minTapTarget,
        ),
      ),
    );
  }
}
