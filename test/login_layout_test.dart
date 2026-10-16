import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';

/// El login entero a la vista, sin desplazarse.
///
/// Los tamaños son lo que queda dentro del navegador, no la pantalla: en un
/// portátil de 1366 × 768 la barra de pestañas y la de direcciones se comen
/// unos 110 px.
void main() {
  const laptops = <String, Size>{
    'portátil 1366 × 768': Size(1366, 657),
    'portátil 1280 × 720': Size(1280, 600),
    'portátil 1536 × 864 (escala 125 %)': Size(1536, 730),
    'portátil 1920 × 1080': Size(1920, 950),
    'tablet en horizontal': Size(1024, 690),
  };

  const phones = <String, Size>{
    'celular pequeño': Size(360, 640),
    'celular': Size(390, 844),
    'tablet en vertical': Size(768, 1024),
  };

  Future<void> pumpLogin(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    AccessibilityTextScaleController.global.setScale(textScale);
    addTearDown(() {
      tester.view.reset();
      AccessibilityTextScaleController.global.reset();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const LoginScreen(),
      ),
    );
    await tester.pump();
  }

  void expectFinderVisible(
    WidgetTester tester,
    Finder finder,
    String what,
    Size size,
  ) {
    final rect = tester.getRect(finder);
    expect(
      rect.top >= 0 &&
          rect.bottom <= size.height &&
          rect.left >= 0 &&
          rect.right <= size.width,
      isTrue,
      reason:
          '«$what» ocupa $rect; la ventana mide ${size.width} × '
          '${size.height}',
    );
  }

  void expectFullyVisible(WidgetTester tester, String text, Size size) =>
      expectFinderVisible(tester, find.text(text), text, size);

  for (final entry in laptops.entries) {
    for (final scale in [0.9, 1.0]) {
      testWidgets('${entry.key}, letra al ${(scale * 100).round()} %: '
          'se ve todo, hasta «Registrarse»', (tester) async {
        await pumpLogin(tester, entry.value, textScale: scale);

        expectFullyVisible(tester, 'INICIAR SESIÓN', entry.value);
        expectFullyVisible(tester, 'REGISTRARSE', entry.value);
        expectFullyVisible(tester, '¿Olvidaste tu contraseña?', entry.value);
        expectFullyVisible(
          tester,
          '¿Cómo se usa Code4All? Ver el manual',
          entry.value,
        );
        expectFullyVisible(
          tester,
          'Política de tratamiento de datos',
          entry.value,
        );
        expectFinderVisible(
          tester,
          find.byKey(const ValueKey('social-privacy-consent')),
          'aviso de Google y Facebook',
          entry.value,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  // En celular el login se desplaza: lo que importa es que la política y el
  // aviso existan, quepan de ancho y no desborden con la letra grande.
  for (final entry in phones.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${entry.key}, letra al ${(scale * 100).round()} %: '
          'la política y el aviso se leen enteros', (tester) async {
        await pumpLogin(tester, entry.value, textScale: scale);

        for (final finder in [
          find.byKey(const ValueKey('privacy-policy')),
          find.byKey(const ValueKey('social-privacy-consent')),
        ]) {
          await tester.ensureVisible(finder);
          await tester.pump();
          expectFinderVisible(tester, finder, finder.toString(), entry.value);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final entry in phones.entries) {
    testWidgets('${entry.key}: «Iniciar sesión» se ve sin desplazarse', (
      tester,
    ) async {
      await pumpLogin(tester, entry.value);

      expectFullyVisible(tester, 'INICIAR SESIÓN', entry.value);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('en portátil, logo y formulario van lado a lado', (tester) async {
    await pumpLogin(tester, laptops.values.first);

    final logo = tester.getRect(find.byType(Image).first);
    final email = tester.getRect(find.byType(TextField).first);
    expect(logo.right, lessThan(email.left));
  });
}
