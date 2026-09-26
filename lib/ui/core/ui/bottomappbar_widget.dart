import 'package:flutter/material.dart';
import 'package:flutter_code4all/config/static_messages.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';

class MultimodalBottomAppBarWidget extends StatelessWidget {
  final String? announcementText;
  final String? playLabel;
  final String? stopLabel;

  const MultimodalBottomAppBarWidget({
    super.key,
    this.announcementText,
    this.playLabel,
    this.stopLabel,
  });

  /// Un solo botón para las tres situaciones, como un reproductor.
  ///
  /// Parado arranca la lectura, leyendo la pausa, y pausado sigue por donde
  /// iba. Lo importante es que pausar no tira el texto: al volver no se
  /// empieza otra vez desde arriba, que es lo que hacía antes.
  void _onPlayPausePressed(BuildContext context, ReadingStatus status) {
    switch (status) {
      case ReadingStatus.speaking:
      case ReadingStatus.paused:
        accessibilityReadingState.togglePause();
      case ReadingStatus.idle:
        final explicitText = announcementText?.trim();
        final extractedText = ScreenContentExtractor.extractFromContext(
          context,
        );
        final text =
            (explicitText?.isNotEmpty == true ? explicitText! : extractedText)
                .trim();

        if (text.isNotEmpty) {
          accessibilityReadingState.read(text, context);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return BottomAppBar(
      child: SafeArea(
        child: ValueListenableBuilder<ReadingStatus>(
          valueListenable: accessibilityReadingState.status,
          builder: (context, status, child) {
            final isSpeaking = status == ReadingStatus.speaking;
            final isPaused = status == ReadingStatus.paused;

            final currentLabel = isSpeaking
                ? (stopLabel ?? StaticMessages.navPauseLabel)
                : isPaused
                ? StaticMessages.navResumeLabel
                : (playLabel ?? StaticMessages.navPlayLabel);
            final currentHint = isSpeaking
                ? StaticMessages.navPauseHint
                : isPaused
                ? StaticMessages.navResumeHint
                : StaticMessages.navPlayHint;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: currentLabel,
                  hint: currentHint,
                  liveRegion: true, // Notifica cambios de estado a TalkBack
                  child: IconButton(
                    icon: Icon(
                      isSpeaking ? Icons.pause : Icons.play_arrow,
                    ),
                    iconSize: 44,
                    color: colorScheme.onPrimary,
                    onPressed: () => _onPlayPausePressed(context, status),
                    tooltip: currentLabel,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
