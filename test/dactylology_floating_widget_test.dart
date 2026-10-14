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
}
