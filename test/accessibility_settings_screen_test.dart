import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_settings_screen.dart';

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: AccessibilitySettingsScreen()),
  );
  await tester.pump();
}

Future<void> _disposeScreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('AccessibilitySettingsScreen Tests', () {
    testWidgets('Muestra el título, encabezado y secciones principales', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.text('Configuración de Accesibilidad'), findsOneWidget);
      expect(find.text('Personaliza tu experiencia'), findsOneWidget);
      expect(
        find.text('Ajusta las opciones según tus necesidades'),
        findsOneWidget,
      );
      expect(find.text('Tamaño de texto'), findsOneWidget);
      expect(find.text('Modo visual'), findsOneWidget);
      expect(find.text('Asistencia auditiva'), findsOneWidget);
      expect(find.text('Lengua de señas'), findsOneWidget);

      expect(find.byType(Switch), findsNWidgets(4));

      await _disposeScreen(tester);
    });

    testWidgets('Permite activar y desactivar el tamaño de texto', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester);

      final textSizeSwitch = find.byType(Switch).at(0);
      // El estado inicial depende de si la pantalla recibe un
      // AccessibilityTextScaleScope. Probamos el cambio en ambos sentidos
      // sin asumir que el Scope está presente en esta prueba.
      final initialValue = tester.widget<Switch>(textSizeSwitch).value;

      await tester.ensureVisible(textSizeSwitch);
      await tester.tap(textSizeSwitch);
      await tester.pump();

      final valueAfterFirstTap = !initialValue;
      expect(tester.widget<Switch>(textSizeSwitch).value, valueAfterFirstTap);
      expect(
        find.text(
          valueAfterFirstTap
              ? 'El contenido aparecerá con letra más grande.'
              : 'La lectura seguirá en el tamaño normal.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          valueAfterFirstTap
              ? 'Texto grande activado'
              : 'Texto grande desactivado',
        ),
        findsOneWidget,
      );

      // Dejamos desaparecer el SnackBar antes de la siguiente interacción.
      await _dismissSnackBar(tester);
      await tester.ensureVisible(textSizeSwitch);
      await tester.tap(textSizeSwitch);
      await tester.pump();

      expect(tester.widget<Switch>(textSizeSwitch).value, initialValue);
      expect(
        find.text(
          initialValue
              ? 'El contenido aparecerá con letra más grande.'
              : 'La lectura seguirá en el tamaño normal.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          initialValue ? 'Texto grande activado' : 'Texto grande desactivado',
        ),
        findsOneWidget,
      );

      await _disposeScreen(tester);
    });

    testWidgets('Permite activar el contraste mejorado y elegir modo visual', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester);

      final contrastSwitch = find.byType(Switch).at(1);
      await tester.ensureVisible(contrastSwitch);
      await tester.tap(contrastSwitch);
      await tester.pump();

      expect(tester.widget<Switch>(contrastSwitch).value, isTrue);
      expect(
        find.text('La interfaz usará un contraste más fuerte.'),
        findsOneWidget,
      );
      expect(find.text('Contraste mejorado activado'), findsOneWidget);

      await _dismissSnackBar(tester);
      final darkModeButton = find.byIcon(Icons.brightness_2);
      await tester.ensureVisible(darkModeButton);
      await tester.tap(darkModeButton);
      await tester.pump();

      expect(find.text('Modo Oscuro seleccionado'), findsOneWidget);

      await _disposeScreen(tester);
    });

    testWidgets('Permite cambiar la asistencia auditiva y su velocidad', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester);

      final audioSwitch = find.byType(Switch).at(2);
      expect(tester.widget<Switch>(audioSwitch).value, isTrue);

      await tester.ensureVisible(audioSwitch);
      await tester.tap(audioSwitch);
      await tester.pump();

      expect(tester.widget<Switch>(audioSwitch).value, isFalse);
      expect(
        find.text('El asistente de voz está desactivado.'),
        findsOneWidget,
      );
      expect(find.text('Asistencia auditiva desactivada'), findsOneWidget);

      await _dismissSnackBar(tester);
      final fastSpeedButton = find.text('Rápida');
      await tester.ensureVisible(fastSpeedButton);
      await tester.tap(fastSpeedButton);
      await tester.pump();

      expect(find.text('Velocidad Rápida seleccionada'), findsOneWidget);

      await _disposeScreen(tester);
    });

    testWidgets('Permite activar apoyos visuales y elegir nivel de señas', (
      WidgetTester tester,
    ) async {
      await _pumpScreen(tester);

      final signLanguageSwitch = find.byType(Switch).at(3);
      expect(tester.widget<Switch>(signLanguageSwitch).value, isFalse);

      await tester.ensureVisible(signLanguageSwitch);
      await tester.tap(signLanguageSwitch);
      await tester.pump();

      expect(tester.widget<Switch>(signLanguageSwitch).value, isTrue);
      expect(find.text('Se mostrarán señales de contexto.'), findsOneWidget);
      expect(find.text('Lengua de señas activada'), findsOneWidget);

      await _dismissSnackBar(tester);
      final advancedLevelButton = find.text('Avanzado');
      await tester.ensureVisible(advancedLevelButton);
      await tester.tap(advancedLevelButton);
      await tester.pump();

      expect(find.text('Nivel Avanzado seleccionado'), findsOneWidget);

      await _disposeScreen(tester);
    });
  });
}

Future<void> _dismissSnackBar(WidgetTester tester) async {
  // Esperar a que termine la animación de entrada.
  await tester.pump(const Duration(milliseconds: 300));

  // Dejar transcurrir los 2 segundos de duración.
  await tester.pump(const Duration(seconds: 2));

  // Esperar a que termine la animación de salida.
  await tester.pump(const Duration(milliseconds: 300));
}
