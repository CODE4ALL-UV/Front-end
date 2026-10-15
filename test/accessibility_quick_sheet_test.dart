import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_quick_button.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';

/// Los dos accesos rápidos a la accesibilidad que no pasan por el menú «?»:
///
/// - El botón de la barra superior del docente y la dirección, que abre un
///   panel con el tamaño del texto y los colores. Sin él, alguien con baja
///   visión que entrara como docente se quedaba con la letra por defecto.
/// - La franja «Escuchar» de las pantallas del curso, en sus estados de
///   reanudar y de empezar a leer.
///
/// Se comprueba lo que cambia de verdad (la escala global, el tema activo, lo
/// que se manda leer) y lo que se anuncia al lector de pantalla.
void main() {
  final textScale = AccessibilityTextScaleController.global;
  const tts = MethodChannel('flutter_tts');
  final spoken = <String>[];

  setUp(() {
    spoken.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, (call) async {
          if (call.method == 'speak') spoken.add(call.arguments.toString());
          return 1;
        });
  });

  tearDown(() async {
    textScale.reset();
    ThemeManager.changeTheme(AppThemeMode.light);
    await accessibilityReadingState.stop();
    accessibilityReadingState.currentText.value = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, null);
  });

  List<String> announced(WidgetTester tester) =>
      tester.takeAnnouncements().map((a) => a.message).toList();

  group('panel rápido de accesibilidad', () {
    Future<void> openSheet(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ValueListenableBuilder<AppThemeMode>(
          valueListenable: ThemeManager.themeNotifier,
          builder: (context, mode, _) => MaterialApp(
            theme: AppTheme.getTheme(mode: mode),
            home: Scaffold(
              appBar: AppBar(actions: const [AccessibilityQuickButton()]),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byTooltip('Accesibilidad: colores y tamaño del texto'),
      );
      await tester.pumpAndSettle();
      announced(tester);
    }

    testWidgets('A+ y A− cambian la letra de toda la app y lo anuncian', (
      tester,
    ) async {
      await openSheet(tester);
      expect(find.text('100 %'), findsOneWidget);
      // A tamaño normal no se ofrece volver al tamaño normal.
      expect(find.text('Volver al tamaño normal'), findsNothing);

      await tester.tap(find.byTooltip('Texto más grande'));
      await tester.pumpAndSettle();

      expect(textScale.scale, closeTo(1.1, 0.001));
      expect(find.text('110 %'), findsOneWidget);
      expect(announced(tester), contains('Texto al 110 por ciento'));
      expect(find.text('Volver al tamaño normal'), findsOneWidget);

      await tester.tap(find.byTooltip('Texto más pequeño'));
      await tester.tap(find.byTooltip('Texto más pequeño'));
      await tester.pumpAndSettle();

      expect(textScale.scale, closeTo(0.9, 0.001));
      expect(find.text('90 %'), findsOneWidget);
      expect(announced(tester), contains('Texto al 90 por ciento'));
    });

    testWidgets('«Volver al tamaño normal» deja la letra al 100 %', (
      tester,
    ) async {
      textScale.setScale(1.5);
      await openSheet(tester);

      await tester.tap(find.text('Volver al tamaño normal'));
      await tester.pumpAndSettle();

      expect(textScale.scale, 1.0);
      expect(find.text('100 %'), findsOneWidget);
      expect(announced(tester), contains('Texto a su tamaño normal'));
    });

    testWidgets('en los límites el botón correspondiente se desactiva', (
      tester,
    ) async {
      textScale.setScale(2.0);
      await openSheet(tester);

      IconButton button(String tooltip) => tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        ),
      );

      expect(button('Texto más grande').onPressed, isNull);
      expect(button('Texto más pequeño').onPressed, isNotNull);

      textScale.setScale(0.9);
      await tester.pumpAndSettle();

      expect(button('Texto más pequeño').onPressed, isNull);
      expect(button('Texto más grande').onPressed, isNotNull);
    });

    testWidgets('elegir un tema lo aplica, lo marca y lo anuncia', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
      expect(announced(tester), contains('Tema Oscuro activado'));
      final tile = find.ancestor(
        of: find.text('Oscuro'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(of: tile, matching: find.byIcon(Icons.check_circle)),
        findsOneWidget,
      );

      await tester.tap(find.text('Escala de grises'));
      await tester.pumpAndSettle();
      expect(ThemeManager.themeNotifier.value, AppThemeMode.achromatopsia);
      // Solo hay un tema marcado a la vez.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  group('franja «Escuchar»', () {
    Future<void> pumpToolbar(WidgetTester tester, {String? spokenText}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode: AppThemeMode.light),
          home: Scaffold(
            body: Column(
              children: [
                AccessibilityToolbar(spokenText: spokenText),
                const Text('Las variables guardan valores.'),
              ],
            ),
          ),
        ),
      );
      announced(tester);
    }

    testWidgets('con un guion propio lee ese guion y no la pantalla', (
      tester,
    ) async {
      await pumpToolbar(tester, spokenText: '  Bienvenida al módulo uno.  ');

      await tester.tap(find.text('Escuchar'));
      await tester.pump();

      expect(spoken, ['Bienvenida al módulo uno.']);
      expect(accessibilityReadingState.status.value, ReadingStatus.speaking);
      expect(find.text('Pausar'), findsOneWidget);
    });

    testWidgets('sin guion lee lo que hay escrito en la pantalla', (
      tester,
    ) async {
      await pumpToolbar(tester);

      await tester.tap(find.text('Escuchar'));
      await tester.pump();

      expect(spoken.single, contains('Las variables guardan valores.'));
    });

    testWidgets('un guion vacío no cuenta: se lee la pantalla', (tester) async {
      await pumpToolbar(tester, spokenText: '   ');

      await tester.tap(find.text('Escuchar'));
      await tester.pump();

      expect(spoken.single, contains('Las variables guardan valores.'));
    });

    testWidgets('«Reanudar» sigue la lectura pausada y lo anuncia', (
      tester,
    ) async {
      await pumpToolbar(tester, spokenText: 'Uno. Dos. Tres.');

      await tester.tap(find.text('Escuchar'));
      await tester.pump();
      await tester.tap(find.text('Pausar'));
      await tester.pump();
      expect(find.text('Reanudar'), findsOneWidget);
      announced(tester);

      await tester.tap(find.text('Reanudar'));
      await tester.pump();

      expect(accessibilityReadingState.status.value, ReadingStatus.speaking);
      expect(find.text('Pausar'), findsOneWidget);
      expect(announced(tester), contains('Lectura reanudada'));
      // Se vuelve a mandar hablar: en móvil reanudar es leer desde donde iba.
      expect(spoken, hasLength(2));
    });
  });
}
