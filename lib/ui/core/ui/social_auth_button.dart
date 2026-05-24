import 'package:flutter/material.dart';

class SocialAuthButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final String semanticHint;
  final Color backgroundColor;
  final double iconSize; // 👈 NUEVO: Tamaño configurable con valor por defecto

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    required this.semanticHint,
    this.backgroundColor = Colors.white,
    this.iconSize = 32.0, // 👈 32px por defecto para mantener la consistencia
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(width: iconSize, height: iconSize, child: icon),
          ),
        ),
      ),
    );
  }
}
