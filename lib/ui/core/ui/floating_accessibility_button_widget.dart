import 'package:flutter/material.dart';

class FloatingAccessibilityButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingAccessibilityButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Botón de asistencia. Presione para abrir el menú de soporte en Lengua de Señas o ajustes visuales.',
      hint: 'Doble toque para desplegar las opciones de accesibilidad.',
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(
          Icons.accessibility_new,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
