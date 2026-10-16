import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';

/// La consola del laboratorio entiende un Python muy pequeño. Estas pruebas
/// completan lo que ya revisa `laboratory_console_screen_test.dart`: la resta
/// y la división dan lo mismo que en Python, y cada error de escritura se
/// explica con su motivo en lugar de dejar la salida en blanco sin más.
void main() {
  Finder codeField() => find.byType(TextField).first;
  Finder outputField() => find.byType(TextField).last;

  String output(WidgetTester tester) =>
      tester.widget<TextField>(outputField()).controller!.text;

  Future<void> run(WidgetTester tester, String source) async {
    await tester.pumpWidget(const MaterialApp(home: LaboratoryConsoleScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(codeField(), source);
    await tester.tap(find.text('Ejecutar'));
    await tester.pump();
  }

  testWidgets('resta y divide como Python', (tester) async {
    await run(tester, 'total = 10 - 4\nprint(total)\nprint(9 / 2)');

    expect(output(tester), '6\n4.5');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dos valores sin operador entre ellos', (tester) async {
    await run(tester, 'print(2 3)');

    expect(output(tester), isEmpty);
    expect(find.textContaining('Expresión incompleta: 2 3'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un paréntesis que no se cierra', (tester) async {
    await run(tester, 'print((2 + 3)');

    expect(output(tester), isEmpty);
    expect(find.textContaining('Falta )'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('un símbolo que la consola no conoce', (tester) async {
    await run(tester, 'print(2 * %)');

    expect(output(tester), isEmpty);
    expect(find.textContaining('Token inesperado: %'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
