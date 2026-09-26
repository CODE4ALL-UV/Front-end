import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/circle_progress_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/lesson_box_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_screen.dart';

/// Componente modularizado que maneja la intercalación y semántica de las filas
class ModuleRowWidget extends StatelessWidget {
  final int moduleId;
  final int sectionNumber;
  final bool isCircleLeft;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double bigSize;
  final bool enableTeacherEditor;

  const ModuleRowWidget({
    super.key,
    required this.moduleId,
    required this.sectionNumber,
    required this.isCircleLeft,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.bigSize = 150.0,
    this.enableTeacherEditor = false,
  });

  @override
  Widget build(BuildContext context) {
    final appModuleTheme = context.moduleTheme;
    // 1. Definir la acción de navegación común para la sección
    void navigateToSection() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseChapterPage(
            moduleId: moduleId,
            sectionNumber: sectionNumber,
            enableTeacherEditor: enableTeacherEditor,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : bigSize + 150;

        // El tamaño sale del sitio que hay, a lo ancho y a lo alto.
        //
        // Antes era `(anchoPantalla * 0.32).clamp(140, 320)`, y en cualquier
        // teléfono ese 32 % se queda por debajo de 140 —en uno de 430 px da
        // 137,6—, así que el suelo del clamp lo dejaba clavado en 140 de 320
        // a 430 px. El círculo no crecía nunca: lo único que crecía era el
        // hueco del medio, y la fila se veía cada vez más vacía.
        //
        // Pero sólo con el ancho tampoco vale: en un teléfono de 390 px la
        // mitad da 167, y tres filas de 167 no caben de alto, así que había
        // que desplazarse para ver la ruta entera. `bigSize` trae el tope que
        // calcula la pantalla con el alto que le queda, y manda el menor de
        // los dos.
        const gapBetween = 24.0;
        final widthBudget = (availableWidth - gapBetween) / 2;
        final componentSize = math
            .min(widthBudget, bigSize)
            .clamp(110.0, 260.0);
        final lessonScale = (componentSize / 150).clamp(0.95, 2.0).toDouble();

        final circleWidget = CircleProgressWidget(
          icon: icon,
          iconColor: iconColor,
          bgColor: bgColor,
          size: componentSize,
          moduleId: moduleId,
          sectionNumber: sectionNumber,
          onTap: navigateToSection,
          progressTrackRemaining: appModuleTheme.progressTrackRemaining,
          progressTrackFilled: appModuleTheme.progressTrackFilled,
        );

        final boxWidget = LessonBoxWidget(
          number: sectionNumber,
          title:
              PythonCourseCatalog.section(moduleId, sectionNumber)?.boxTitle ??
              'Sección $sectionNumber',
          onTap: navigateToSection,
          backgroundColor: appModuleTheme.lessonCardBackground,
          borderColor: appModuleTheme.lessonCardBorder,
          textColor: appModuleTheme.lessonCardText,
          numberColor: appModuleTheme.lessonCardNumber,
          numberBackgroundColor: appModuleTheme.lessonCardNumberBackground,
          width: componentSize,
          scale: lessonScale,
        );

        return Semantics(
          button: true,
          label: 'Acceder a la sección $sectionNumber del módulo $moduleId',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isCircleLeft
                ? [circleWidget, boxWidget]
                : [boxWidget, circleWidget],
          ),
        );
      },
    );
  }
}
