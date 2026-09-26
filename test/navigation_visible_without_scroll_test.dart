import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';

/// Cómo salir de una pantalla no puede estar escondido bajo el contenido.
///
/// Antes «Desliza hacia arriba para ir al Módulo 2» vivía al final de una
/// columna con scroll, así que había que bajar hasta abajo del todo para
/// enterarse de que se podía avanzar. Con la letra agrandada —y esta
/// aplicación la agranda hasta el 200 %— quedaba todavía más lejos.
///
/// Estas pruebas miran que el control esté **dentro de la pantalla** sin
/// tocar el scroll, incluso a tamaños de letra grandes, que es cuando más
/// fácil es que algo se caiga por debajo del pliegue.
void main() {
  Widget host(Widget child, {double textScale = 1.0}) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );

  /// Verdadero si el widget cabe dentro de la ventana, sin desplazarse.
  bool isOnScreen(WidgetTester tester, Finder finder) {
    final box = tester.renderObject<RenderBox>(finder);
    final topLeft = box.localToGlobal(Offset.zero);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    return topLeft.dy >= 0 && topLeft.dy + box.size.height <= size.height;
  }

  void usePhone(WidgetTester tester, {Size size = const Size(390, 844)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('ir al módulo siguiente se ve sin bajar', () {
    testWidgets('en un teléfono normal', (tester) async {
      usePhone(tester);

      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
      await tester.pump();

      final boton = find.textContaining('ir al Módulo 2');
      expect(boton, findsOneWidget);
      expect(
        isOnScreen(tester, boton),
        isTrue,
        reason: 'hay que verlo sin desplazarse',
      );
    });

    testWidgets('con la letra al 200 por ciento', (tester) async {
      usePhone(tester);

      await tester.pumpWidget(
        host(const LearningModuleScreen(moduleId: 1), textScale: 2.0),
      );
      await tester.pump();

      final boton = find.textContaining('ir al Módulo 2');
      expect(boton, findsOneWidget);
      expect(
        isOnScreen(tester, boton),
        isTrue,
        reason: 'con la letra grande es cuando más se esconde',
      );
    });

    testWidgets('en una pantalla estrecha de 320 px', (tester) async {
      usePhone(tester, size: const Size(320, 640));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 3)));
      await tester.pump();

      // En el módulo 3 se puede ir en las dos direcciones.
      expect(
        isOnScreen(tester, find.textContaining('ir al Módulo 4')),
        isTrue,
      );
      expect(
        isOnScreen(tester, find.textContaining('volver al Módulo 2')),
        isTrue,
      );
    });
  });

  group('la navegación del capítulo se ve sin bajar', () {
    testWidgets('anterior y siguiente quedan a la vista', (tester) async {
      usePhone(tester);

      final module = PythonCourseCatalog.moduleByNumber(1)!;
      final section = module.sections.first;

      await tester.pumpWidget(
        host(
          ChapterSectionScreen(
            module: module,
            section: section,
            onNextChapter: () {},
            onPreviousChapter: () {},
          ),
        ),
      );
      await tester.pump();

      expect(isOnScreen(tester, find.text('Siguiente')), isTrue);
      expect(isOnScreen(tester, find.text('Anterior')), isTrue);
    });
  });
}
