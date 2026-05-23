import 'package:flutter/material.dart';
import 'package:flutter_code4all/config/static_messages.dart';

class MultimodalNavBar extends StatelessWidget {
  const MultimodalNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    /* OJO NO UTILIZA APP_THEME */
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
              label: StaticMessages.navPreviousLabel,
              hint: StaticMessages.navPreviousHint,
              child: InkWell(
                // Cambiado a InkWell para que el lector detecte que es cliqueable
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
              label: StaticMessages.navPlayLabel,
              hint: StaticMessages.navPlayHint,
              child: InkWell(
                onTap: () {},
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
              label: StaticMessages.navNextLabel,
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
