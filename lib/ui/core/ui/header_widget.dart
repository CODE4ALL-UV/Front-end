import 'package:flutter/material.dart';
//import 'package:flutter_svg/flutter_svg.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showUserIcon; // Propiedad para intercambiar sesion on/off

  const HeaderWidget({
    super.key,
    required this.title,
    this.actions,
    this.showUserIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    // Lee directamente los colores y fuentes definidos en el AppTheme activo
    final theme = Theme.of(context);

    return Semantics(
      header: true, // Avisa al lector de pantalla que es un navbar
      label: 'Encabezado de la pantalla: $title',
      child: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        // 1. Agregamos el logo oficial adaptado semánticamente para personas con baja visión
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Semantics(
            label: 'Logo Oficial de la Universidad del Valle',
            child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
          ),
        ),
        title: Text(title, style: theme.appBarTheme.titleTextStyle),
        /* OJO NO UTILIZA APP_THEME */
        centerTitle: true,
        // 2. Icono de perfil interactivo y accesible
        actions: showUserIcon
            ? [
                Semantics(
                  button: true,
                  label: 'Perfil de usuario y configuración de cuenta',
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.account_circle_outlined,
                      color: theme
                          .appBarTheme
                          .foregroundColor, // Dinámico según el tema
                      size: 28,
                    ),
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
