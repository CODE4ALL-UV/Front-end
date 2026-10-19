import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/dactylology_floating_widget.dart';

void main() {
  group('DactylologyFloatingWidget Tests', () {
    testWidgets('renderiza inicialmente colapsado como botón flotante', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [DactylologyFloatingWidget(text: 'HOLA')]),
          ),
        ),
      );

      // Verifica que el botón flotante esté presente y el panel expandido no
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Dactilología'), findsNothing);
    });

    testWidgets('se expande al presionar el botón flotante', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                DactylologyFloatingWidget(text: 'HOLA', showWordSigns: true),
              ],
            ),
          ),
        ),
      );

      // Presionamos el botón flotante para abrir el panel
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificamos que el título y el botón de cerrar aparezcan en el panel expandido
      expect(find.text('Dactilología'), findsWidgets);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('se colapsa nuevamente al presionar el botón de cerrar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [DactylologyFloatingWidget(text: 'HOLA')]),
          ),
        ),
      );

      // 1. Expandimos el widget
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Dactilología'), findsWidgets);

      // 2. Presionamos el icono de cerrar
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // 3. Verificamos que regresa al estado inicial (botón flotante)
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Dactilología'), findsNothing);
    });
  });

  /// Desplegado, el lector es el mismo del manual web: mano y letra, la
  /// palabra en manos pequeñas, el avance por palabras y los controles.
  group('Lector con el diseño del manual', () {
    const normal = Duration(milliseconds: 620);
    const pause = Duration(milliseconds: 372);

    Future<void> open(WidgetTester tester, String text) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [DactylologyFloatingWidget(text: text)]),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
    }

    String letter(WidgetTester tester) => tester
        .widget<Text>(find.byKey(const ValueKey('dactylology-letter')))
        .data!;

    // Cierra el lector al acabar para que no quede ningún temporizador.
    Future<void> close(WidgetTester tester) =>
        tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    testWidgets('muestra la letra, la palabra, el avance y los controles', (
      tester,
    ) async {
      await open(tester, '¡Hola, mundo!');

      expect(letter(tester), 'H');
      expect(find.text('«¡Hola, mundo!»'), findsOneWidget);
      // La palabra entera en la tira, sin los signos de los lados.
      for (final l in ['O', 'L', 'A']) {
        expect(find.text(l), findsOneWidget);
      }
      expect(find.text('Palabra 1 de 2'), findsOneWidget);
      for (final tip in [
        'Palabra anterior',
        'Repetir la palabra',
        'Pausar',
        'Palabra siguiente',
        'Cambiar la velocidad',
        'Encoger el lector',
      ]) {
        expect(find.byTooltip(tip), findsOneWidget, reason: tip);
      }
      expect(find.text('Normal'), findsOneWidget);

      await close(tester);
    });

    testWidgets('deletrea letra a letra y pasa a la palabra siguiente', (
      tester,
    ) async {
      await open(tester, 'Si no');

      expect(letter(tester), 'S');
      await tester.pump(normal);
      expect(letter(tester), 'I');

      // Entre palabras, una pausa más corta con la mano en reposo.
      await tester.pump(normal);
      expect(letter(tester), '␣');
      expect(find.text('Espacio entre palabras'), findsOneWidget);

      await tester.pump(pause);
      expect(letter(tester), 'N');
      expect(find.text('Palabra 2 de 2'), findsOneWidget);

      // Al final se queda quieto y ofrece volver a empezar.
      await tester.pump(normal);
      expect(letter(tester), 'O');
      await tester.pump(normal);
      expect(
        find.byTooltip('Deletrear otra vez desde el principio'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Deletrear otra vez desde el principio'));
      await tester.pump();
      expect(letter(tester), 'S');
      expect(find.byTooltip('Pausar'), findsOneWidget);

      await close(tester);
    });

    testWidgets('se pausa y salta de palabra con los botones', (tester) async {
      await open(tester, 'uno dos tres');

      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();
      expect(find.byTooltip('Seguir deletreando'), findsOneWidget);
      await tester.pump(normal * 3);
      expect(letter(tester), 'U');

      await tester.tap(find.byTooltip('Palabra siguiente'));
      await tester.pump();
      expect(letter(tester), 'D');
      expect(find.text('Palabra 2 de 3'), findsOneWidget);

      await tester.tap(find.byTooltip('Palabra anterior'));
      await tester.pump();
      expect(letter(tester), 'U');

      await tester.tap(find.byTooltip('Seguir deletreando'));
      await tester.pump(normal);
      expect(letter(tester), 'N');

      await tester.tap(find.byTooltip('Repetir la palabra'));
      await tester.pump();
      expect(letter(tester), 'U');

      await close(tester);
    });

    testWidgets('la velocidad cambia entre lenta, normal y rápida', (
      tester,
    ) async {
      await open(tester, 'abc');

      await tester.tap(find.byTooltip('Cambiar la velocidad'));
      await tester.pump();
      expect(find.text('Rápida'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(letter(tester), 'B');

      await tester.tap(find.byTooltip('Cambiar la velocidad'));
      await tester.pump();
      expect(find.text('Lenta'), findsOneWidget);

      // Se deja en «Normal», que se recuerda entre pantallas.
      await tester.tap(find.byTooltip('Cambiar la velocidad'));
      await tester.pump();
      expect(find.text('Normal'), findsOneWidget);

      await close(tester);
    });

    testWidgets('encogido deja solo la mano y la letra', (tester) async {
      await open(tester, 'hola');

      await tester.tap(find.byTooltip('Encoger el lector'));
      await tester.pump();
      expect(find.byTooltip('Pausar'), findsNothing);
      expect(find.textContaining('Palabra 1'), findsNothing);
      expect(letter(tester), 'H');

      await tester.tap(find.byTooltip('Agrandar el lector'));
      await tester.pump();
      expect(find.byTooltip('Pausar'), findsOneWidget);

      await close(tester);
    });

    testWidgets('números y signos se muestran tal cual', (tester) async {
      await open(tester, 'x = 1');
      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();

      await tester.tap(find.byTooltip('Palabra siguiente'));
      await tester.pump();
      expect(letter(tester), '=');
      expect(find.text('Signo: se muestra tal cual'), findsOneWidget);

      await tester.tap(find.byTooltip('Palabra siguiente'));
      await tester.pump();
      expect(letter(tester), '1');
      expect(find.text('Número: se muestra tal cual'), findsOneWidget);

      await close(tester);
    });

    testWidgets('las tildes se quitan y la Ñ se queda', (tester) async {
      await open(tester, 'Año');
      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();

      expect(find.text('Ñ'), findsOneWidget);
      expect(letter(tester), 'A');

      await close(tester);
    });

    testWidgets('sin texto lo dice en lugar de quedarse en blanco', (
      tester,
    ) async {
      await open(tester, '   ');

      expect(letter(tester), '—');
      expect(find.text('No hay texto que deletrear.'), findsOneWidget);
      expect(find.textContaining('Palabra'), findsNothing);

      await close(tester);
    });
  });
}
