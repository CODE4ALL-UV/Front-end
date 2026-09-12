import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

import 'module1_sections.dart';
import 'module2_sections.dart';
import 'module3_sections.dart';
import 'module4_sections.dart';
import 'module5_sections.dart';
import 'module6_sections.dart';

/// Punto único de acceso a todo el contenido del curso de Python.
///
/// Las pantallas nunca declaran contenido: lo piden aquí. Agregar o corregir
/// una sección es editar datos, no widgets.
abstract final class PythonCourseCatalog {
  static const List<CourseModule> modules = [
    module1,
    module2,
    module3,
    module4,
    module5,
    module6,
  ];

  /// Devuelve el módulo con ese número, o `null` si no existe.
  static CourseModule? moduleByNumber(int number) {
    for (final module in modules) {
      if (module.number == number) return module;
    }
    return null;
  }

  /// Devuelve la sección `sectionNumber` del módulo `moduleNumber`.
  static CourseSection? section(int moduleNumber, int sectionNumber) =>
      moduleByNumber(moduleNumber)?.sectionByNumber(sectionNumber);

  /// Busca una sección por su identificador, por ejemplo `m2-s3`.
  static CourseSection? sectionById(String id) {
    for (final module in modules) {
      for (final section in module.sections) {
        if (section.id == id) return section;
      }
    }
    return null;
  }

  /// Todas las secciones del curso, en orden de módulo y número.
  static List<CourseSection> get allSections => [
    for (final module in modules) ...module.sections,
  ];

  /// La sección siguiente dentro del mismo módulo, si existe.
  static CourseSection? nextSectionInModule(CourseSection section) =>
      moduleByNumber(section.moduleNumber)?.sectionByNumber(section.number + 1);

  /// La sección anterior dentro del mismo módulo, si existe.
  static CourseSection? previousSectionInModule(CourseSection section) =>
      moduleByNumber(section.moduleNumber)?.sectionByNumber(section.number - 1);
}
