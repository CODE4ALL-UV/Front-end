import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

/// Comprueba que las piezas del editor del docente se dibujan sin romperse.
///
/// Nacen de un fallo real: un campo de dos líneas intentaba abrirse con tres y
/// Flutter tumbaba la pantalla entera con un recuadro rojo. Se veía en varios
/// sitios a la vez porque el campo se reutiliza en todos los editores.
void main() {
  Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  group('el campo de texto aguanta cualquier alto', () {
    // Se prueban todos los altos que usan los editores, no solo el que falló.
    for (final maxLines in [1, 2, 3, 4, 5, 6, 10, 12]) {
      testWidgets('con maxLines $maxLines no revienta', (tester) async {
        final controller = TextEditingController(text: 'texto de ejemplo');
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          wrap(
            Builder(
              builder: (context) => TeacherField(
                palette: SectionPalette.of(context),
                label: 'Campo',
                controller: controller,
                maxLines: maxLines,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Campo'), findsOneWidget);
      });
    }

    testWidgets('la etiqueta sigue visible con texto escrito', (tester) async {
      // La etiqueta no debe desaparecer al escribir: en un formulario largo
      // hace falta saber qué es cada campo sin tener que vaciarlo.
      final controller = TextEditingController(text: 'ya hay contenido');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TeacherField(
              palette: SectionPalette.of(context),
              label: 'Transcripción',
              controller: controller,
              maxLines: 2,
              helper: 'Para quien no oye el video',
            ),
          ),
        ),
      );

      expect(find.text('Transcripción'), findsOneWidget);
      expect(find.text('Para quien no oye el video'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('cabe con el texto al doble de tamaño', (tester) async {
      final controller = TextEditingController(text: 'x');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TeacherField(
              palette: SectionPalette.of(context),
              label: 'Campo',
              controller: controller,
              maxLines: 2,
            ),
          ),
          textScale: 2.0,
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('la fila de lista se dibuja entera', () {
    testWidgets('con sus controles y sin desbordarse en 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TeacherListRow(
              palette: SectionPalette.of(context),
              title: 'Una pregunta bastante larga para ver si cabe bien',
              subtitle: '4 opciones · correcta: la segunda',
              position: 1,
              total: 3,
              onTap: () {},
              onMoveDown: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Una pregunta'), findsOneWidget);
    });

    testWidgets('un título vacío se dice, no se deja en blanco', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TeacherListRow(
              palette: SectionPalette.of(context),
              title: '',
              subtitle: 'sin contenido',
              position: 1,
              total: 1,
            ),
          ),
        ),
      );

      expect(find.text('Sin título'), findsOneWidget);
    });
  });

  group('el aviso se dibuja', () {
    testWidgets('con su texto completo', (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TeacherBanner(
              palette: SectionPalette.of(context),
              icon: Icons.error_outline,
              text: 'No se pudo guardar: el servidor no responde.',
            ),
          ),
        ),
      );

      expect(
        find.text('No se pudo guardar: el servidor no responde.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
