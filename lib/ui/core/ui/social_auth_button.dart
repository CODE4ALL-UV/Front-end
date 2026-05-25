import 'package:flutter/material.dart';

class SocialAuthButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final String semanticHint;
  final Color backgroundColor;
  final double
  paddingSize; // NUEVO:En lugar de tamaño rígido, controlamos el "aire" perimetral

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    required this.semanticHint,
    this.backgroundColor = Colors.white,
    this.paddingSize = 16.0, // 16px por defecto para mantener la consistencia
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      hint: semanticHint,
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(), // Hace que el efecto visual de onda sea circular
        child: Container(
          padding: EdgeInsets.all(
            paddingSize,
          ), // El contenedor se auto-ajusta al tamaño del icono + el padding.
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape
                .circle, // Mantiene la consistencia del diseño de tu App
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          // El Center asegura que las coordenadas no tengan desplazamientos extraños
          child: Center(child: icon),
        ),
      ),
    );
  }
}
