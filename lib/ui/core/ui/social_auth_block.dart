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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón de Google
        SocialAuthButton(
          onTap: onGoogleTap ?? () {},
          backgroundColor: Colors.white,
          icon: SvgPicture.asset(AssetsRoutes.googleIcon),
          semanticLabel: StaticMessages.googleButtonLabel,
          semanticHint: StaticMessages.googleButtonHint,
        ),

        const SizedBox(
          width: 10,
        ), // Un espacio ligeramente mayor para mejorar el área táctil (Acessibilidad)
        // Botón de Facebook
        SocialAuthButton(
          icon: Image.asset(
            AssetsRoutes.facebookIcon,
            /* OJO ¿PORQUE ERROR BUILDER NO ESTÁ EN EL BOTÓN DE ARRIBA? */
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
          ),
          semanticLabel: StaticMessages.facebookButtonLabel,
          semanticHint: StaticMessages.facebookButtonHint,
          onTap: onFacebookTap ?? () {},
        ),
      ],
    );
  }
}
