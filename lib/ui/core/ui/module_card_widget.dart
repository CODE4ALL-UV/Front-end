//REFACTOR-APROVED x 2 - COLOR TEST REMAINING - DONT TESTED IN UI YET
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor.dart';

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
    final bgColor = ModuleCardThemeColors.getBackgroundColor(moduleId);
    final textColor = ModuleCardThemeColors.getTextColor(moduleId);

    // Obtenemos el tamaño/fuente del tema global
    final textStyle = Theme.of(context).textTheme.titleSmall;

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        moduleName, // <-- Usamos la variable del widget
        style: textStyle?.copyWith(
          color: textColor, // <-- Color de texto dinámico
        ),
      ),
    );
  }
}
