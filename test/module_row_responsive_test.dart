import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/circle_progress_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/lesson_box_widget.dart';

/// La ruta de secciones son parejas de círculo y tarjeta, una a cada lado.
///
/// Dos cosas se rompían y estas pruebas las fijan:
///
/// 1. El tamaño salía de `(anchoPantalla * 0.32).clamp(140, 320)`. En
///    cualquier teléfono ese 32 % queda por debajo de 140 —en uno de 430 px
///    da 137,6—, así que el suelo del clamp lo dejaba clavado en 140 de 320 a
///    430 px. Lo único que crecía era el hueco del medio.
/// 2. El botón de ayuda flotaba sobre el contenido y tapaba la última
///    tarjeta. Flotando no hay margen que lo arregle: se queda fijo aunque el
///    contenido se desplace.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: child,
  );

  Rect rectOf(WidgetTester tester, Finder finder, int index) {
    final element = finder.evaluate().elementAt(index);
    final box = element.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> pumpAt(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
    await tester.pump();
  }

  group('el círculo crece con el ancho', () {
    testWidgets('un teléfono ancho no se ve igual que uno estrecho', (
      tester,
    ) async {
      final medidas = <double, double>{};

      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        await pumpAt(tester, width);
        medidas[width] = rectOf(
          tester,
          find.byType(CircleProgressWidget),
          0,
        ).width;
      }

      // Antes los cuatro daban 140 clavado.
      expect(
        medidas.values.toSet().length,
        medidas.length,
        reason: 'cada ancho debe dar un tamaño distinto: $medidas',
      );
      expect(medidas[430.0]! > medidas[320.0]!, isTrue);
    });

    testWidgets('el círculo y la tarjeta miden lo mismo y no se tocan', (
      tester,
    ) async {
      for (final width in [320.0, 390.0, 600.0]) {
        await pumpAt(tester, width);

        final circulo = rectOf(tester, find.byType(CircleProgressWidget), 0);
        final tarjeta = rectOf(tester, find.byType(LessonBoxWidget), 0);

        expect(
          circulo.width,
          closeTo(tarjeta.width, 0.01),
          reason: 'la pareja debe ir a la par, en $width px',
        );
        expect(
          circulo.overlaps(tarjeta),
          isFalse,
          reason: 'no deben solaparse en $width px',
        );
      }
    });

    testWidgets('no crece sin freno en pantallas grandes', (tester) async {
      await pumpAt(tester, 1200);
      expect(
        rectOf(tester, find.byType(CircleProgressWidget), 0).width,
        lessThanOrEqualTo(260.0),
      );
    });
  });

  testWidgets('el botón de ayuda queda fuera de la zona que se desplaza', (
    tester,
  ) async {
    // Comprobar «no solapa con ninguna tarjeta» no serviría: las coordenadas
    // son absolutas, así que una tarjeta que el scroll recorta por abajo
    // aparece solapando aunque no se vea. Lo que hay que fijar es que el
    // botón no esté dentro de la región que se desplaza; si lo está, tapará
    // lo que quede debajo sin que ningún margen lo evite.
    for (final width in [320.0, 360.0, 390.0, 430.0, 600.0]) {
      await pumpAt(tester, width);

      final ayuda = rectOf(tester, find.byType(HelpActionButton), 0);
      final scroll = rectOf(tester, find.byType(SingleChildScrollView), 0);

      expect(
        ayuda.overlaps(scroll),
        isFalse,
        reason:
            'en $width px el botón de ayuda está encima del contenido que '
            'se desplaza (ayuda=$ayuda, scroll=$scroll)',
      );
    }
  });
}
