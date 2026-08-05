import 'package:flutter/material.dart';
import 'package:flutter_code4all/config/static_messages.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state.dart';

class MultimodalNavBar extends StatelessWidget {
  const MultimodalNavBar({
    super.key,
    this.announcementText,
    this.previousLabel,
    this.playLabel,
    this.nextLabel,
  });

  final String? announcementText;
  final String? previousLabel;
  final String? playLabel;
  final String? nextLabel;

  Future<void> _announceCurrentScreen(BuildContext context) async {
    final explicitText = announcementText?.trim();
    final extractedText = ScreenContentExtractor.extractFromContext(context);
    final text =
        (explicitText?.isNotEmpty == true ? explicitText! : extractedText)
            .trim();

    if (text.isEmpty) return;

    await accessibilityReadingState.read(text, context);
  }

  @override
  Widget build(BuildContext context) {
    // Leemos estrictamente tu contrato de diseño centralizado en app_theme
    final footerTheme = Theme.of(context).bottomNavigationBarTheme;

    return Material(
      elevation: footerTheme.elevation ?? 0,
      child: Container(
        color: footerTheme.backgroundColor,
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. BOTÓN ANTERIOR
            Semantics(
              button: true,
              label: previousLabel ?? StaticMessages.navPreviousLabel,
              hint: StaticMessages.navPreviousHint,
              child: InkWell(
                onTap: () {},
                child: Icon(
                  Icons.skip_previous,
                  color: footerTheme.unselectedItemColor,
                  size: footerTheme.unselectedIconTheme?.size ?? 28,
                ),
              ),
            ),

            // 2. BOTÓN REPRODUCIR (Selected / Destacado)
            Semantics(
              button: true,
              label: playLabel ?? StaticMessages.navPlayLabel,
              hint: StaticMessages.navPlayHint,
              onTap: () async => _announceCurrentScreen(context),
              child: InkWell(
                onTap: () async => _announceCurrentScreen(context),
                child: Icon(
                  Icons.play_arrow,
                  color: footerTheme.selectedItemColor,
                  size: footerTheme.selectedIconTheme?.size ?? 32,
                ),
              ),
            ),

            // 3. BOTÓN SIGUIENTE
            Semantics(
              button: true,
              label: nextLabel ?? StaticMessages.navNextLabel,
              hint: StaticMessages.navNextHint,
              child: InkWell(
                onTap: () {},
                child: Icon(
                  Icons.skip_next,
                  color: footerTheme.unselectedItemColor,
                  size: footerTheme.unselectedIconTheme?.size ?? 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
