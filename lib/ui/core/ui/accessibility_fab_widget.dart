import 'package:flutter/material.dart';
import 'package:flutter_code4all/config/static_messages.dart'; // Tu archivo de textos centralizados

class AccessibilityFab extends StatelessWidget {
  final VoidCallback? onPressed;

  const AccessibilityFab({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    // 1. Mantenemos tu desacoplamiento estético del AppTheme
    final theme = Theme.of(context).floatingActionButtonTheme;

    // 2. Envolvemos todo en el árbol semántico para TalkBack / VoiceOver
    return Semantics(
      button: true,
      label: StaticMessages.accessibilityButtonLabel,
      hint: StaticMessages.accessibilityButtonHint,

      child: FloatingActionButton(
        onPressed:
            onPressed ??
            () {
              // Lógica por defecto para desplegar el menú de accesibilidad/adaptación
            },
        backgroundColor: theme.backgroundColor,
        foregroundColor: theme.foregroundColor,
        elevation: theme.elevation,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.accessibility_new,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
