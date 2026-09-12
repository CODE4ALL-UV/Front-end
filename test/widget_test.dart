import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_page.dart';

/// Prueba de humo de la ruta de aprendizaje.
///
/// Comprueba que un capítulo del catálogo se dibuja con su título, sus
/// objetivos y su ruta de actividades, que es el camino que recorre el
/// estudiante en cada sección.
void main() {
  testWidgets('un capítulo muestra su resumen y su ruta de actividades', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseChapterPage(moduleNumber: 2, sectionNumber: 1),
      ),
    );
    await tester.pump();

    final seccion = PythonCourseCatalog.section(2, 1)!;

    // Cabecera del capítulo.
    expect(find.text(seccion.displayTitle), findsOneWidget);
    expect(find.text('Módulo 2. Fundamentos de Python'), findsOneWidget);

    // Ruta de actividades con sus pasos.
    expect(find.text('Ruta de actividades'), findsOneWidget);
    expect(find.textContaining('Paso 1 · Lectura'), findsOneWidget);
    expect(find.textContaining('Quiz'), findsWidgets);
  });

  testWidgets('una sección sin material avisa en lugar de romperse', (
    tester,
  ) async {
    // Módulo 6: todavía sin contenido cargado.
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseChapterPage(moduleNumber: 6, sectionNumber: 1),
      ),
    );
    await tester.pump();

    expect(find.text('Contenido en preparación'), findsOneWidget);
  });

  testWidgets('un capítulo inexistente muestra una pantalla explicativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseChapterPage(moduleNumber: 99, sectionNumber: 1),
      ),
    );
    await tester.pump();

    expect(find.text('Capítulo no disponible'), findsOneWidget);
  });
}
