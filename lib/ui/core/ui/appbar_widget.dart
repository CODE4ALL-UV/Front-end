import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

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
  final PreferredSizeWidget?
  bottom; // <-- Permite pestañas o elementos inferiores opcionales

  /// Botones que van antes del menú de perfil, sin quitarlo. Con `actions`
  /// se sustituye la fila entera.
  final List<Widget> extraActions;

  const GlobalAppBarWidget({
    super.key,
    this.title = 'CODE4ALL', // Fusionado: Valor por defecto para no repetirlo,
    this.leading,
    this.actions,
    this.showUserIcon = true,
    this.userName,
    this.userPhotoUrl,
    this.userEmail,
    this.userRole,
    this.onLogout,
    this.bottom,
    this.extraActions = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Lee directamente los colores y fuentes definidos en el AppTheme activo
    final colorScheme = context.colorScheme;

    // Logo dinámico según el tema claro/oscuro
    final logoAsset = colorScheme.brightness == Brightness.light
        ? 'assets/images/logoUV_Oficial_Blanco_1.png'
        : 'assets/images/logoUV_Oficial_Rojo.png';

    // FUSIÓN: Lógica inteligente para el lado izquierdo (leading)
    Widget? buildLeading() {
      // 1. Si mandas un widget manual desde otra pantalla, tiene prioridad
      if (leading != null) return leading;

      // 2. Si la pantalla fue "empujada" (push) sobre otra, muestra la flecha de atrás
      if (Navigator.canPop(context)) {
        return IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
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
        leading: buildLeading(),
        title: Text(title),
        actions:
            actions ??
            (showUserIcon
                ? [
                    ...extraActions,
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 12,
                      ), //ORIGINAL ES/ERA EdgeInsets.symmetric(horizontal: 8.0)
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
                : (extraActions.isEmpty ? null : extraActions)),
        bottom:
            bottom, // <-- Renderiza el TabBar pasándole el control desde la pantalla
      ),
    );
  }

  /// La barra mide lo suyo más lo de abajo: sin sumar las pestañas, el
  /// Scaffold les dejaba sitio solo para la barra y quedaban recortadas.
  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
