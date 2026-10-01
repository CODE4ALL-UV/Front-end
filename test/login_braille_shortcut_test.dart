import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';

/// El atajo al teclado Braille desde el login.
///
/// Quien no ve no puede buscar un botón concreto, así que basta con tocar dos
/// veces en cualquier parte. El botón queda también, abajo a la izquierda,
/// para quien ve o usa lector de pantalla.
void main() {
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: const LoginScreen(),
      ),
    );
    await tester.pump();
  }

  Offset emptySpot(WidgetTester tester) =>
      tester.getCenter(find.byKey(const ValueKey('braille-login-hint')));

  testWidgets('el login explica el atajo y tiene el botón Braille', (
    tester,
  ) async {
    await pumpLogin(tester);
    expect(find.textContaining('Toca dos veces'), findsOneWidget);
    expect(find.byTooltip('Teclado Braille'), findsOneWidget);
  });

  testWidgets('al abrir el login la voz dice el aviso del atajo', (
    tester,
  ) async {
    addTearDown(accessibilityReadingState.clearHighlight);
    await pumpLogin(tester);
    // La voz pasa por el canal del motor de voz, que en pruebas responde de
    // forma asíncrona de verdad.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      accessibilityReadingState.currentText.value,
      LoginScreen.brailleHint,
    );
    // Y es el mismo texto que se ve en pantalla.
    expect(find.text(LoginScreen.brailleHint), findsOneWidget);
  });

  testWidgets('tocar dos veces la pantalla abre el teclado Braille', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tapAt(emptySpot(tester));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tapAt(emptySpot(tester));
    await tester.pumpAndSettle();

    expect(find.byType(BrailleKeyboardScreen), findsOneWidget);
    // Abierto para rellenar el correo y la contraseña del login.
    final keyboard = tester.widget<BrailleKeyboardScreen>(
      find.byType(BrailleKeyboardScreen),
    );
    expect(keyboard.fields?.map((f) => f.label), [
      'Correo electrónico',
      'Contraseña',
    ]);
    expect(keyboard.fields!.last.obscure, isTrue);
  });

  testWidgets('un solo toque no lo abre', (tester) async {
    await pumpLogin(tester);
    await tester.tapAt(emptySpot(tester));
    await tester.pumpAndSettle();
    expect(find.byType(BrailleKeyboardScreen), findsNothing);
  });

  testWidgets('dos toques separados por una pausa tampoco', (tester) async {
    await pumpLogin(tester);
    await tester.tapAt(emptySpot(tester));
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(emptySpot(tester));
    await tester.pumpAndSettle();
    expect(find.byType(BrailleKeyboardScreen), findsNothing);
  });

  testWidgets('el botón Braille también lo abre', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.byTooltip('Teclado Braille'));
    await tester.pumpAndSettle();
    expect(find.byType(BrailleKeyboardScreen), findsOneWidget);
  });
}
