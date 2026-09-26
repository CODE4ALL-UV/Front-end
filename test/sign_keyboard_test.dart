import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_widget.dart';
import 'package:flutter_code4all/ui/core/ui/sign_letter_icon_widget.dart';

/// El teclado de dactilología: cada tecla es una letra y su seña.
///
/// Lo que hay que fijar es que escriba de verdad —insertar, borrar, respetar
/// dónde está el cursor— y que las letras que se hacen con movimiento se
/// anuncien como tales, porque una imagen quieta no puede enseñarlas y
/// callarlo sería enseñarlas mal.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: Scaffold(body: child),
  );

  Future<void> pumpKeyboard(
    WidgetTester tester,
    TextEditingController controller,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(host(SignKeyboard(controller: controller)));
    await tester.pump();
  }

  group('escribir con el teclado', () {
    testWidgets('tocar una letra la escribe', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.text('H'));
      await tester.pump();
      await tester.tap(find.text('O'));
      await tester.pump();
      await tester.tap(find.text('L'));
      await tester.pump();
      await tester.tap(find.text('A'));
      await tester.pump();

      expect(controller.text, 'HOLA');
    });

    testWidgets('la Ñ está y se escribe', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.text('Ñ'));
      await tester.pump();

      expect(controller.text, 'Ñ');
    });

    testWidgets('borrar quita la última letra, no todo', (tester) async {
      final controller = TextEditingController(text: 'SOL');
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pump();

      expect(controller.text, 'SO');
    });

    testWidgets('borrar con el campo vacío no rompe nada', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pump();

      expect(controller.text, '');
    });

    testWidgets('escribe donde está el cursor, no al final', (tester) async {
      final controller = TextEditingController(text: 'AC');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 1);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.text('B'));
      await tester.pump();

      expect(controller.text, 'ABC');
      expect(controller.selection.baseOffset, 2);
    });

    testWidgets('escribir reemplaza lo que estuviera seleccionado', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'XYZ');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 3);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.text('A'));
      await tester.pump();

      expect(controller.text, 'A');
    });

    testWidgets('el espacio separa palabras', (tester) async {
      final controller = TextEditingController(text: 'HOLA');
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);
      await tester.tap(find.widgetWithText(FilledButton, 'Espacio'));
      await tester.pump();

      expect(controller.text, 'HOLA ');
    });
  });

  group('lo que se ve y lo que se oye', () {
    testWidgets('están las 27 letras del abecedario español', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);

      expect(SignKeyboard.letters.length, 27);
      for (final letter in SignKeyboard.letters) {
        expect(
          find.text(letter),
          findsOneWidget,
          reason: 'falta la tecla $letter',
        );
      }
    });

    testWidgets('cada tecla lleva su seña dibujada', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);

      expect(
        find.byType(SignLetterIcon),
        findsNWidgets(SignKeyboard.letters.length),
      );
    });

    testWidgets('las letras con movimiento se anuncian como tales', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pumpKeyboard(tester, controller);

      // J, Z y Ñ llevan movimiento: una foto quieta no las enseña.
      for (final letter in ['J', 'Z', 'Ñ']) {
        expect(
          signAlphabet[letter]?.hasMotion,
          isTrue,
          reason: '$letter debería estar marcada como de movimiento',
        );
        expect(
          find.bySemanticsLabel('Letra $letter. Se hace con movimiento.'),
          findsOneWidget,
        );
      }

      // Una que no lleva movimiento se anuncia sin el aviso.
      expect(find.bySemanticsLabel('Letra A'), findsOneWidget);

      semantics.dispose();
    });
  });
}
