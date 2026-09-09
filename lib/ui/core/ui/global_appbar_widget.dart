//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
//import 'package:flutter_svg/flutter_svg.dart';

class GlobalAppBarWidget extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showUserIcon; // Propiedad para intercambiar sesion on/off
  final String? userName;
  final String? userPhotoUrl;
  final String? userEmail;
  final String? userRole;
  final VoidCallback? onLogout;

  const GlobalAppBarWidget({
    super.key, //Key? key,
    this.title = 'CODE4ALL', // Fusionado: Valor por defecto para no repetirlo,
    this.leading,
    this.actions,
    this.showUserIcon = true,
    this.userName,
    this.userPhotoUrl,
    this.userEmail,
    this.userRole,
    this.onLogout,
  }); // : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lee directamente los colores y fuentes definidos en el AppTheme activo
    final theme = Theme.of(context).appBarTheme;
    final toolbarColor =
        theme.backgroundColor ?? Theme.of(context).colorScheme.primary;
    final brightness = Theme.of(context).brightness;

    // Logo dinámico según el tema claro/oscuro
    final logoAsset = brightness == Brightness.light
        ? 'assets/images/logoUV_Gris1.png'
        : 'assets/images/logoUV_Oficial_Rojo.png';

    // FUSIÓN: Lógica inteligente para el lado izquierdo (leading)
    Widget? buildLeading() {
      // 1. Si mandas un widget manual desde otra pantalla, tiene prioridad
      if (leading != null) return leading;

      // 2. Si la pantalla fue "empujada" (push) sobre otra, muestra la flecha de atrás
      if (Navigator.canPop(context)) {
        return IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: theme.foregroundColor ?? Colors.white,
          ),
          tooltip: 'Volver',
        );
      }

      // 3. Si es la pantalla principal, muestra el logo de la UV
      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: Semantics(
          label: 'Logo Oficial de la Universidad del Valle',
          child: Image.asset(logoAsset),
        ),
      );
    }

    return Semantics(
      header: true, // Avisa al lector de pantalla que es un navbar
      label: 'Encabezado de la pantalla: $title',
      child: AppBar(
        backgroundColor: toolbarColor,
        foregroundColor: theme.foregroundColor,
        elevation:
            theme.elevation ??
            0, // Fusionado: elevation 0 por defecto si el tema no lo dicta
        leading: buildLeading(),
        title: Text(title, style: theme.titleTextStyle),
        centerTitle: true,
        actions:
            actions ??
            (showUserIcon
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: UserProfileMenu(
                        userName: userName,
                        userPhotoUrl: userPhotoUrl,
                        userEmail: userEmail,
                        userRole: userRole,
                        onLogout: onLogout,
                        showName:
                            true, // Fusionado: Para que se vea el nombre al lado del avatar
                      ),
                    ),
                  ]
                : null),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
