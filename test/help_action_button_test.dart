import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HelpActionButton expands floating accessibility icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HelpActionButton())),
    );

    // Verifica que el botón inicial está presente
    expect(find.byIcon(Icons.help_outline), findsOneWidget);

    // Toca el botón principal para expandir el menú
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    // Verifica que el botón cambió a icono de cerrar
    expect(find.byIcon(Icons.close), findsOneWidget);

    // Verifica que los iconos de accesibilidad están visibles
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny), findsOneWidget);
    expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    expect(find.byIcon(Icons.translate), findsOneWidget);

    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.pumpAndSettle();

    expect(find.text('Tamaño de texto'), findsNWidgets(2));
    expect(find.text('Ajustar el tamaño de texto.'), findsOneWidget);

    // Toca el botón de nuevo para colapsar
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    // Verifica que los iconos desaparecieron
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
