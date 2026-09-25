import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

class ModuleCardWidget extends StatelessWidget {
  final int moduleId;
  final String moduleName;

  const ModuleCardWidget({
    super.key,
    required this.moduleId,
    required this.moduleName,
  });

  @override
  Widget build(BuildContext context) {
    // LLAMAMOS A NUESTRA NUEVA CLASE DESDE APP_THEME
    final appModuleTheme = context.courseTheme;

    // Obtenemos el tamaño/fuente del tema global
    final textStyle = Theme.of(context).textTheme.titleSmall;

    return Container(
      width: double.infinity,
      color: appModuleTheme.lessonCardBackground, // <-- Color de fondo dinámico
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        moduleName, // <-- Usamos la variable del widget
        style: textStyle?.copyWith(
          color: appModuleTheme.lessonCardBorder, // <-- Color de texto dinámico
        ),
      ),
    );
  }
}
