import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/unused_circle_progress_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_lesson_box_widget.dart';
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
    final appModuleTheme = context.courseTheme;
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

    // 2. Instanciar los componentes (Asumiendo que ya los extrajiste a sus propios archivos)
    final circleWidget = CircleProgressWidget(
      icon: icon,
      iconColor: iconColor,
      bgColor: bgColor,
      size: bigSize,
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
    );

    // 3. Retornar el Row envuelto en Semantics para accesibilidad
    return Semantics(
      button: true,
      label: 'Acceder a la sección $sectionNumber del módulo $moduleId',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        // Aquí ocurre la magia de la intercalación:
        children: isCircleLeft
            ? [circleWidget, boxWidget]
            : [boxWidget, circleWidget],
      ),
    );
  }
}
