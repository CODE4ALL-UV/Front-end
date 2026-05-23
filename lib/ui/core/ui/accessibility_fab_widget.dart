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
          Icons.accessibility_new, //Icons.palette para los colores
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

/* OJO Quitar e integrar con el botón de accesibilidad AccesibilityFab*/
// Ícono accesibilidad
/*Padding(
  padding: const EdgeInsets.only(left: 16, bottom: 8),
  child: Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF5C6BC0),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.accessibility_new,
        color: Colors.white,
        size: 30,
      ),
    ),
  ),
),*/
