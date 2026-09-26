import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';

/// La barra de «escuchar» y tamaño del texto vivía solo dentro de las cinco
/// pantallas de actividad. Las de módulo y capítulo —por donde se entra al
/// curso— no la tenían, así que quien necesita la voz o la letra más grande se
/// topaba primero justo con las pantallas que no lo ofrecían.
///
/// Estas pruebas fijan que está donde se entra, para que no se vuelva a perder
/// en el próximo refactor.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: child,
  );

  /// Los controles que debe ofrecer la barra, por su etiqueta de lector de
  /// pantalla. Se buscan por etiqueta y no por icono a propósito: es lo que
  /// oye quien no ve la pantalla, y es lo que no debe romperse.
  void expectToolbarPresent() {
    expect(find.byType(AccessibilityToolbar), findsOneWidget);
    expect(
      find.bySemanticsLabel('Escuchar esta pantalla en voz alta'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Aumentar el tamaño del texto'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Reducir el tamaño del texto'), findsOneWidget);
  }

  testWidgets('la vista de un módulo ofrece escuchar y agrandar la letra', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
    await tester.pump();

    expectToolbarPresent();
    semantics.dispose();
  });

  testWidgets('la vista de un capítulo ofrece escuchar y agrandar la letra', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final module = PythonCourseCatalog.moduleByNumber(1)!;
    final section = module.sections.first;

    await tester.pumpWidget(
      host(ChapterSectionScreen(module: module, section: section)),
    );
    await tester.pump();

    expectToolbarPresent();
    semantics.dispose();
  });

  testWidgets('el login la tiene: es la primera pantalla de la aplicación', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(host(const LoginScreen()));
    await tester.pump();

    expectToolbarPresent();
    semantics.dispose();
  });

  testWidgets('los seis módulos la tienen, no solo el primero', (tester) async {
    final semantics = tester.ensureSemantics();

    for (final module in PythonCourseCatalog.modules) {
      await tester.pumpWidget(
        host(LearningModuleScreen(moduleId: module.number)),
      );
      await tester.pump();

      expect(
        find.byType(AccessibilityToolbar),
        findsOneWidget,
        reason: 'falta la barra en el módulo ${module.number}',
      );
    }
    semantics.dispose();
  });
}
