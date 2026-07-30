import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

void main() {
  testWidgets('muestra el nombre y el menú desplegable de perfil', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [UserProfileMenu(userName: 'Ana María')]),
        ),
      ),
    );

    expect(find.text('Ana María'), findsOneWidget);

    await tester.tap(find.byType(UserProfileMenu));
    await tester.pumpAndSettle();

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
