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

  void _onPlayStopPressed(BuildContext context, bool isCurrentlyReading) {
    if (isCurrentlyReading) {
      accessibilityReadingState.stop();
    } else {
      final explicitText = announcementText?.trim();
      final extractedText = ScreenContentExtractor.extractFromContext(context);
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
        child: ValueListenableBuilder<bool>(
          valueListenable: accessibilityReadingState.isHighlighting,
          builder: (context, isReading, child) {
            final currentLabel = isReading
                ? (stopLabel ?? StaticMessages.navStopLabel)
                : (playLabel ?? StaticMessages.navPlayLabel);
            final currentHint = isReading
                ? StaticMessages.navStopHint
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
                    icon: Icon(isReading ? Icons.stop : Icons.play_arrow),
                    iconSize: 44,
                    color: colorScheme.onPrimary,
                    onPressed: () => _onPlayStopPressed(context, isReading),
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
