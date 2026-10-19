import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_settings_screen.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';

/// La pantalla que abre «Configuración» en el menú de ayuda.
///
/// Antes era una maqueta: sus interruptores solo cambiaban su propio dibujo.
/// Estas pruebas comprueban que cada control cambia el ajuste de verdad —el
/// tema de la app, el tamaño de la letra, las preferencias guardadas— y que
/// subir la letra no rompe la pantalla.
void main() {
  final prefs = LearningPreferences.instance;
  final textScale = AccessibilityTextScaleController.global;
  const storage = FlutterSecureStorage();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  tearDown(() async {
    textScale.reset();
    ThemeManager.changeTheme(AppThemeMode.light);
    await prefs.setPace(SpeechPace.medium);
    await prefs.setClearSpeech(false);
    await prefs.setSignSupport(SignSupportLevel.off);
    await prefs.setContentPreference(ContentPreference.none);
    await prefs.setLevel(LearningLevel.medium);
    await prefs.setHintsEnabled(false);
    await prefs.setManualEnabled(false);
  });

  /// Como la monta la app: con el Scope de la letra y el tema del manager.
  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(420, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AccessibilityTextScaleScope(
        controller: textScale,
        child: ValueListenableBuilder<AppThemeMode>(
          valueListenable: ThemeManager.themeNotifier,
          builder: (context, mode, _) => MaterialApp(
            theme: AppTheme.getTheme(mode: mode),
            home: const AccessibilitySettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  SwitchListTile switchTile(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text(title),
          matching: find.byType(SwitchListTile),
        ),
      );

  bool chipSelected(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(
        find.ancestor(of: find.text(label), matching: find.byType(ChoiceChip)),
      )
      .selected;

  testWidgets('muestra el título, el encabezado y todas las secciones', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Configuración de Accesibilidad'), findsOneWidget);
    expect(find.text('Personaliza tu experiencia'), findsOneWidget);
    for (final section in [
      'Tamaño de texto',
      'Modo visual',
      'Asistencia auditiva',
      'Lengua de señas',
      'Ajustes de aprendizaje',
      'Apoyo',
    ]) {
      await tester.scrollUntilVisible(find.text(section), 200);
      expect(find.text(section), findsOneWidget, reason: section);
    }
  });

  testWidgets(
    'el texto grande y los botones + y − cambian la letra de la app',
    (tester) async {
      await pumpScreen(tester);
      expect(switchTile(tester, 'Texto grande').value, isFalse);
      expect(find.text('100 %'), findsOneWidget);

      await tapText(tester, 'Texto grande');
      expect(textScale.scale, closeTo(1.2, 0.001));
      expect(switchTile(tester, 'Texto grande').value, isTrue);
      expect(find.text('120 %'), findsOneWidget);
      expect(find.text('Texto grande activado'), findsOneWidget);
      // La pantalla sigue en pie tras cambiar la letra: antes, al volver a
      // llamarse didChangeDependencies, reventaba con un late final reasignado.
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Agrandar el texto'));
      await tester.pumpAndSettle();
      expect(textScale.scale, closeTo(1.3, 0.001));

      await tester.tap(find.byTooltip('Reducir el texto'));
      await tester.tap(find.byTooltip('Reducir el texto'));
      await tester.pumpAndSettle();
      expect(textScale.scale, closeTo(1.1, 0.001));

      await tapText(tester, 'Texto grande');
      expect(textScale.scale, 1.0);
      expect(find.text('Texto grande desactivado'), findsOneWidget);
    },
  );

  testWidgets('el modo visual cambia el tema de toda la aplicación', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapText(tester, 'Oscuro');
    expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    expect(chipSelected(tester, 'Oscuro'), isTrue);

    await tapText(tester, 'Protanopía');
    expect(ThemeManager.themeNotifier.value, AppThemeMode.protanopia);
    expect(chipSelected(tester, 'Protanopía'), isTrue);
    expect(chipSelected(tester, 'Ninguno'), isFalse);
    expect(find.text('No distingo bien el rojo'), findsOneWidget);

    await tapText(tester, 'Ninguno');
    expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
    expect(chipSelected(tester, 'Claro'), isTrue);
  });

  testWidgets('«Según el sistema» sigue el brillo del sistema', (tester) async {
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await pumpScreen(tester);

    await tapText(tester, 'Según el sistema');
    expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
  });

  testWidgets('la voz se guarda: más pausada y su velocidad', (tester) async {
    await pumpScreen(tester);

    await tapText(tester, 'Voz más clara y pausada');
    expect(prefs.clearSpeech, isTrue);
    expect(await storage.read(key: 'learning_clear_speech'), 'true');

    await tapText(tester, 'Rápida');
    expect(prefs.pace, SpeechPace.fast);
    expect(await storage.read(key: 'learning_speech_pace'), 'Rápida');
    expect(chipSelected(tester, 'Rápida'), isTrue);
    expect(chipSelected(tester, 'Media'), isFalse);
  });

  testWidgets('el nivel de señas se guarda y explica qué cambia', (
    tester,
  ) async {
    await pumpScreen(tester);

    // «Avanzado» también es un nivel de aprendizaje: el de señas va antes.
    await tester.scrollUntilVisible(find.text('Nivel de apoyo'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanzado').first);
    await tester.pumpAndSettle();

    expect(prefs.signSupport, SignSupportLevel.advanced);
    expect(await storage.read(key: 'learning_sign_support'), 'Avanzado');
    expect(
      find.textContaining('la seña de la palabra completa'),
      findsOneWidget,
    );
  });

  testWidgets('los ajustes de aprendizaje y el apoyo se guardan', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapText(tester, 'Videos');
    expect(prefs.contentPreference, ContentPreference.videos);

    await tester.scrollUntilVisible(find.text('Nivel de aprendizaje'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Básico').last);
    await tester.pumpAndSettle();
    expect(prefs.level, LearningLevel.basic);

    await tapText(tester, 'Pistas');
    expect(prefs.hintsEnabled, isTrue);
    expect(switchTile(tester, 'Pistas').value, isTrue);

    await tapText(tester, 'Manual interactivo');
    expect(prefs.manualEnabled, isTrue);
    expect(await storage.read(key: 'learning_manual'), 'true');
  });

  testWidgets('lo que se cambia fuera de la pantalla se ve en ella', (
    tester,
  ) async {
    await pumpScreen(tester);

    // Por ejemplo desde el menú «?», que escribe en el mismo sitio.
    await prefs.setHintsEnabled(true);
    ThemeManager.changeTheme(AppThemeMode.dark);
    await tester.pumpAndSettle();

    expect(switchTile(tester, 'Pistas').value, isTrue);
    expect(chipSelected(tester, 'Oscuro'), isTrue);
  });

  testWidgets('«Restablecer ajustes» vuelve a los valores de fábrica', (
    tester,
  ) async {
    await pumpScreen(tester);
    textScale.setScale(1.5);
    ThemeManager.changeTheme(AppThemeMode.tritanopia);
    await prefs.setPace(SpeechPace.slow);
    await prefs.setSignSupport(SignSupportLevel.basic);
    await prefs.setHintsEnabled(true);
    await tester.pumpAndSettle();

    await tapText(tester, 'Restablecer ajustes');

    expect(textScale.scale, 1.0);
    expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
    expect(prefs.pace, SpeechPace.medium);
    expect(prefs.signSupport, SignSupportLevel.off);
    expect(prefs.hintsEnabled, isFalse);
    expect(
      find.text('Ajustes restablecidos a los de fábrica.'),
      findsOneWidget,
    );
  });

  testWidgets('en pantalla ancha las tarjetas van en dos columnas', (
    tester,
  ) async {
    await pumpScreen(tester, size: const Size(1280, 900));

    final text = tester.getTopLeft(find.text('Tamaño de texto'));
    final voice = tester.getTopLeft(find.text('Asistencia auditiva'));
    expect(voice.dx, greaterThan(text.dx + 300));
    expect(voice.dy, closeTo(text.dy, 1));
  });
}
