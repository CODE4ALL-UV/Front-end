import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
//import 'package:flutter_svg/flutter_svg.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showUserIcon; // Propiedad para intercambiar sesion on/off
  final String? userName;
  final String? userPhotoUrl;
  final String? userEmail;
  final String? userRole;
  final VoidCallback? onLogout;

  const HeaderWidget({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showUserIcon = true,
    this.userName,
    this.userPhotoUrl,
    this.userEmail,
    this.userRole,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    // Lee directamente los colores y fuentes definidos en el AppTheme activo
    final theme = Theme.of(context).appBarTheme;
    final toolbarColor =
        theme.backgroundColor ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      header: true, // Avisa al lector de pantalla que es un navbar
      label: 'Encabezado de la pantalla: $title',
      child: AppBar(
        backgroundColor: toolbarColor,
        foregroundColor: theme.foregroundColor,
        elevation: theme.elevation,
        leading:
            leading ??
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Semantics(
                label: 'Logo Oficial de la Universidad del Valle',
                child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
              ),
            ),
        title: Text(title, style: theme.titleTextStyle),
        centerTitle: true,
        actions: showUserIcon
            ? [
                UserProfileMenu(
                  userName: userName,
                  userPhotoUrl: userPhotoUrl,
                  userEmail: userEmail,
                  userRole: userRole,
                  onLogout: onLogout,
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
