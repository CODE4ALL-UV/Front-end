import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_code4all/config/static_messages.dart';
// Asegúrate de importar la ruta que elegiste para tus rutas multimedia/assets
import 'package:flutter_code4all/config/assets_routes.dart';
import 'social_auth_button.dart';

class SocialAuthBlock extends StatelessWidget {
  final VoidCallback? onGoogleTap;
  final VoidCallback? onFacebookTap;

  const SocialAuthBlock({super.key, this.onGoogleTap, this.onFacebookTap});

  @override
  Widget build(BuildContext context) {
    // Extraemos un color dinámico del tema para el fondo de los botones (Accesibilidad adaptativa)
    final buttonBackgroundColor = Theme.of(context).cardColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de Google
        SocialAuthButton(
          onTap: onGoogleTap ?? () {},
          backgroundColor: buttonBackgroundColor, // Cambiado por el tema global
          iconSize: 22.0, // 👈 Dejamos a 32px para que no resalte tanto
          icon: SvgPicture.asset(
            AssetsRoutes.googleIcon,
            fit: BoxFit.contain,
            // 💡 Así se manejan los fallos en SvgPicture para evitar pantallas rotas
            placeholderBuilder: (BuildContext context) =>
                const Icon(Icons.g_mobiledata, color: Colors.red, size: 28),
          ),
          semanticLabel: StaticMessages.googleButtonLabel,
          semanticHint: StaticMessages.googleButtonHint,
        ),

        // Un espacio ligeramente mayor para mejorar el área táctil (Acessibilidad)
        // Espacio de 16px recomendado para ergonomía motriz
        const SizedBox(width: 10),
        // Botón de Facebook
        SocialAuthButton(
          onTap: onFacebookTap ?? () {},
          backgroundColor: buttonBackgroundColor, // Cambiado por el tema global
          iconSize: 50.0, // 👈 Subimos a 34px para que resalte igual al otro
          icon: Image.asset(
            AssetsRoutes.facebookIcon,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
          ),
          semanticLabel: StaticMessages.facebookButtonLabel,
          semanticHint: StaticMessages.facebookButtonHint,
        ),
      ],
    );
  }
}
