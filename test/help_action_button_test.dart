import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HelpActionButton despliega las categorías de ayuda', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HelpActionButton())),
    );

    // Botón cerrado: un único signo de interrogación.
    expect(find.byIcon(Icons.question_mark), findsOneWidget);

    await tester.tap(find.byIcon(Icons.question_mark));
    await tester.pumpAndSettle();

    // El menú se dibuja en un Overlay: el botón principal pasa a ser una X y
    // aparecen las tres categorías.
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.help), findsOneWidget);
    expect(find.byIcon(Icons.psychology), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism), findsOneWidget);

    // Al abrir "Ayuda" se muestran sus opciones de accesibilidad.
    await tester.tap(find.byIcon(Icons.help));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.text_fields), findsOneWidget);
    expect(find.byIcon(Icons.brightness_4), findsOneWidget);
    expect(find.byIcon(Icons.hearing), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);

    // Cerrar devuelve el botón a su estado inicial.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.question_mark), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
