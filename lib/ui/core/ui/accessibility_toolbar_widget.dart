import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

import 'accessibility_announcer_widget.dart';
import 'accessibility_reading_state_widget.dart';
import 'accessibility_text_scale_widget.dart';

/// La franja con «escuchar» y el tamaño del texto.
///
/// Vivía dentro de `SectionActivityScaffold`, así que solo la veían las cinco
/// pantallas de actividad. Las de módulo y capítulo se quedaban sin ella, que
/// es justo por donde se entra al curso: quien necesita la voz o la letra más
/// grande se topaba primero con las pantallas que no lo ofrecían.
///
/// Se saca aquí para que cualquier pantalla pueda ponerla con una línea.
class AccessibilityToolbar extends StatelessWidget {
  const AccessibilityToolbar({super.key, this.spokenText});

  /// Lo que hay que leer en voz alta.
  ///
  /// Si no se dice, se lee lo que haya escrito en la pantalla, igual que hace
  /// la barra inferior. Así una pantalla nueva no tiene que redactar su propio
  /// guion para tener voz.
  final String? spokenText;

  Future<void> _toggleSpeech(BuildContext context) async {
    switch (accessibilityReadingState.status.value) {
      case ReadingStatus.speaking:
        await accessibilityReadingState.pause();
        if (!context.mounted) return;
        announceForAccessibility(
          context,
          'Lectura pausada. Se reanudará donde se quedó.',
        );

      case ReadingStatus.paused:
        await accessibilityReadingState.resume();
        if (!context.mounted) return;
        announceForAccessibility(context, 'Lectura reanudada');

      case ReadingStatus.idle:
        final explicit = spokenText?.trim();
        final text = (explicit != null && explicit.isNotEmpty)
            ? explicit
            : ScreenContentExtractor.extractFromContext(context);

        if (text.trim().isEmpty) {
          announceForAccessibility(
            context,
            'Esta pantalla no tiene texto que leer.',
          );
          return;
        }

        await accessibilityReadingState.read(text, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = AccessibilityTextScaleScope.of(context);
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Container(
      width: double.infinity,
      color: appSemanticColors.infoBackground,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppMetrics.maxContentWidth,
          ),
          child: Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<ReadingStatus>(
                  valueListenable: accessibilityReadingState.status,
                  builder: (context, status, _) {
                    final isSpeaking = status == ReadingStatus.speaking;
                    final isPaused = status == ReadingStatus.paused;

                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: isSpeaking
                            ? 'Pausar la lectura en voz alta'
                            : isPaused
                            ? 'Reanudar la lectura en voz alta'
                            : 'Escuchar esta pantalla en voz alta',
                        hint: isSpeaking
                            ? 'La lectura se guardará donde vaya'
                            : isPaused
                            ? 'Seguirá desde donde se quedó'
                            : null,
                        child: TextButton.icon(
                          onPressed: () => _toggleSpeech(context),
                          style: TextButton.styleFrom(
                            backgroundColor: appSemanticColors.infoBackground,
                            foregroundColor: appSemanticColors.infoText,
                            minimumSize: const Size(
                              AppMetrics.minTapTarget,
                              AppMetrics.minTapTarget,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: Icon(
                            isSpeaking
                                ? Icons.pause_circle
                                : isPaused
                                ? Icons.play_circle
                                : Icons.volume_up,
                            size: 22,
                          ),
                          label: Text(
                            isSpeaking
                                ? 'Pausar'
                                : isPaused
                                ? 'Reanudar'
                                : 'Escuchar',
                          ),
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
                            color: appSemanticColors.infoText,
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
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        color: appSemanticColors.infoText,
        tooltip: label,
        constraints: const BoxConstraints(
          minWidth: AppMetrics.minTapTarget,
          minHeight: AppMetrics.minTapTarget,
        ),
      ),
    );
  }
}
