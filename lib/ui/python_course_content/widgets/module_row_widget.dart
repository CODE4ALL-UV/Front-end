import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/python_course_content/circle_progress_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/lesson_box_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_page.dart';

/// Componente modularizado que maneja la intercalación y semántica de las filas

class ModuleRowWidget extends StatelessWidget {
  final int moduleNumber;
  final int sectionNumber;
  final bool isCircleLeft;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double bigSize;
  final bool enableTeacherEditor;

  const ModuleRowWidget({
    super.key,
    required this.moduleNumber,
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
    // 1. Definir la acción de navegación común para la sección
    void navigateToSection() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseChapterPage(
            moduleNumber: moduleNumber,
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
      moduleNumber: moduleNumber,
      sectionNumber: sectionNumber,
      onTap: navigateToSection,
    );

    final boxWidget = LessonBoxWidget(
      number: sectionNumber,
      title:
          PythonCourseCatalog.section(moduleNumber, sectionNumber)?.boxTitle ??
          'Sección $sectionNumber',
      onTap: navigateToSection,
    );

    // 3. Retornar el Row envuelto en Semantics para accesibilidad
    return Semantics(
      button: true,
      label: 'Acceder a la sección $sectionNumber del módulo $moduleNumber',
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
