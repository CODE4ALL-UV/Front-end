import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_settings_screen.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/centered_toast.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button_widget.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';

/// El menú de ayuda («?») es la puerta de entrada a todos los ajustes de
/// accesibilidad del estudiante: tamaño de letra, colores, voz, señas y
/// preferencias de aprendizaje.
///
/// Estas pruebas recorren cada panel y comprueban lo que de verdad importa a
/// quien lo usa: que cada toque cambia el ajuste, que se guarda en el
/// dispositivo, que se avisa en voz alta y en pantalla de en qué quedó, y que
/// el menú se puede abrir, recorrer y cerrar sin quedarse atascado, también
/// en un teléfono estrecho y con la letra al máximo.
void main() {
  final prefs = LearningPreferences.instance;
  final textScale = AccessibilityTextScaleController.global;
  const storage = FlutterSecureStorage();

  setUp(() {
    // Almacén en memoria: lo que el panel guarda se puede leer de vuelta.
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    // Todo esto es global: una prueba que lo deje cambiado envenena la
    // siguiente (y las de otros archivos que corran en el mismo proceso).
    CenteredToast.dismissNow();
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

  /// La aplicación tal como la monta `main`: el tema sigue al ThemeManager,
  /// así que cambiar el modo visual desde el panel se nota en toda la app.
  Future<void> pumpMenu(
    WidgetTester tester, {
    Size size = const Size(1200, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ValueListenableBuilder<AppThemeMode>(
        valueListenable: ThemeManager.themeNotifier,
        builder: (context, mode, _) => MaterialApp(
          theme: AppTheme.getTheme(mode: mode),
          home: const Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: HelpActionButton(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.question_mark));
    await tester.pumpAndSettle();
  }

  /// Abre el menú, la categoría y la opción, en ese orden.
  Future<void> openPanel(
    WidgetTester tester, {
    required IconData category,
    required IconData option,
  }) async {
    await openMenu(tester);
    await tester.tap(find.byIcon(category));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(option).first);
    await tester.pumpAndSettle();
  }

  /// Toca un texto del panel, desplazándolo antes a la vista si hace falta.
  Future<void> tapInPanel(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  List<String> announced(WidgetTester tester) =>
      tester.takeAnnouncements().map((a) => a.message).toList();

  /// El aviso centrado se va solo con un temporizador; se retira a mano para
  /// que la prueba no termine con un temporizador pendiente.
  Future<void> dismissToast(WidgetTester tester) async {
    CenteredToast.dismissNow();
    await tester.pump();
  }

  Finder panelCloseButton() => find.byWidgetPredicate(
    (widget) =>
        widget is Icon && widget.icon == Icons.close && widget.size == 22,
  );

  Finder optionPanel() => find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_OptionPanel',
  );

  group('abrir, recorrer y cerrar el menú', () {
    testWidgets('la categoría tocada pasa a ser la primera de la fila', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openMenu(tester);

      double x(IconData icon) => tester.getCenter(find.byIcon(icon)).dx;

      // Orden de partida: Ayuda, Ajustes de aprendizaje, Apoyo.
      expect(x(Icons.help), lessThan(x(Icons.psychology)));
      expect(x(Icons.psychology), lessThan(x(Icons.volunteer_activism)));

      await tester.tap(find.byIcon(Icons.volunteer_activism));
      await tester.pumpAndSettle();

      // «Apoyo» se pone delante y «Ayuda», que era la primera, va al final.
      expect(x(Icons.volunteer_activism), lessThan(x(Icons.psychology)));
      expect(x(Icons.psychology), lessThan(x(Icons.help)));
      // Y se despliegan sus opciones, no las de otra categoría.
      expect(find.byIcon(Icons.saved_search), findsOneWidget);
      expect(find.byIcon(Icons.menu_book), findsOneWidget);
      expect(find.byIcon(Icons.text_fields), findsNothing);

      await tester.tap(find.byIcon(Icons.psychology));
      await tester.pumpAndSettle();

      // «Ajustes» pasa delante y «Apoyo», el primero hasta ahora, al final.
      expect(x(Icons.psychology), lessThan(x(Icons.help)));
      expect(x(Icons.help), lessThan(x(Icons.volunteer_activism)));
      expect(find.byIcon(Icons.build_circle), findsOneWidget);
      expect(find.byIcon(Icons.stars), findsOneWidget);
    });

    testWidgets('tocar otra vez la categoría abierta pliega sus opciones', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openMenu(tester);

      await tester.tap(find.byIcon(Icons.help));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.hearing), findsOneWidget);

      await tester.tap(find.byIcon(Icons.help));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.hearing), findsNothing);
      // El menú sigue abierto: solo se plegó la columna.
      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('tocar el fondo atenuado cierra el menú entero', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openMenu(tester);
      expect(find.byIcon(Icons.question_mark), findsNothing);

      // Lejos de cualquier botón: es el fondo oscurecido.
      await tester.tapAt(const Offset(1100, 100));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.question_mark), findsOneWidget);
      expect(find.byIcon(Icons.help), findsNothing);
    });

    testWidgets('cerrar a media animación deja el menú cerrado del todo', (
      tester,
    ) async {
      await pumpMenu(tester);

      await tester.tap(find.byIcon(Icons.question_mark));
      // Un solo fotograma: la animación de apertura sigue en marcha.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.question_mark), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets(
      '«Configuración» cierra el menú y abre la pantalla de ajustes',
      (tester) async {
        await pumpMenu(tester);
        await openMenu(tester);
        await tester.tap(find.byIcon(Icons.help));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(find.byType(AccessibilitySettingsScreen), findsOneWidget);
        expect(find.text('Configuración de Accesibilidad'), findsOneWidget);

        // Al volver, el botón «?» está otra vez a mano y el menú, cerrado.
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.question_mark), findsOneWidget);
        expect(find.byIcon(Icons.help), findsNothing);
      },
    );

    testWidgets('la X del panel cierra el panel pero no el menú', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.hearing);
      expect(optionPanel(), findsOneWidget);

      await tester.tap(panelCloseButton());
      await tester.pumpAndSettle();

      expect(optionPanel(), findsNothing);
      // Se puede elegir otra opción sin volver a abrir el menú.
      expect(find.byIcon(Icons.hearing), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('cambiar de categoría cierra el panel que estaba abierto', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.hearing);
      expect(optionPanel(), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volunteer_activism));
      await tester.pumpAndSettle();

      expect(optionPanel(), findsNothing);
      expect(find.byIcon(Icons.saved_search), findsOneWidget);
    });
  });

  group('tamaño de texto', () {
    testWidgets('el interruptor, + y − cambian la letra de toda la app', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.text_fields);

      expect(find.text('Texto grande desactivado'), findsOneWidget);
      expect(find.text('1.00x'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(textScale.scale, closeTo(1.2, 0.001));
      expect(find.text('Texto grande activado'), findsOneWidget);
      expect(find.text('1.20x'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      expect(textScale.scale, closeTo(1.3, 0.001));
      expect(find.text('1.30x'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();
      expect(textScale.scale, closeTo(1.1, 0.001));
      expect(find.text('1.10x'), findsOneWidget);

      // Apagar el interruptor devuelve la letra a su tamaño normal.
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(textScale.scale, 1.0);
      expect(find.text('Texto grande desactivado'), findsOneWidget);
    });

    testWidgets('los botones del menú abierto crecen con la letra', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.text_fields);

      double helpIconSize() =>
          tester.widget<Icon>(find.byIcon(Icons.help)).size!;
      expect(helpIconSize(), 33);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // En una pantalla ancha cabe de sobra: crecen lo mismo que la letra.
      expect(helpIconSize(), closeTo(33 * 1.2, 0.01));
    });

    testWidgets('en un teléfono con la letra al 200 % la fila no se sale', (
      tester,
    ) async {
      textScale.setScale(2.0);
      await pumpMenu(tester, size: const Size(320, 640));
      await openMenu(tester);

      // Con el 200 % la fila de cuatro botones medía unos 400 px y el de
      // cerrar quedaba fuera. Ahora crecen solo hasta donde caben.
      final closeRight = tester.getRect(find.byIcon(Icons.close)).right;
      expect(closeRight, lessThanOrEqualTo(320));
      final iconSize = tester.widget<Icon>(find.byIcon(Icons.help)).size!;
      expect(iconSize, greaterThan(33));
      expect(iconSize, lessThan(33 * 2.0));
    });

    testWidgets('en un teléfono estrecho el panel ocupa todo el ancho', (
      tester,
    ) async {
      await pumpMenu(tester, size: const Size(320, 640));
      await openPanel(tester, category: Icons.help, option: Icons.hearing);

      // A la derecha de los botones no cabe con un ancho legible, así que
      // se pone por encima, de borde a borde con 12 px de margen.
      final rect = tester.getRect(optionPanel());
      expect(rect.left, 12);
      expect(rect.width, 320 - 24);
    });
  });

  group('modo visual', () {
    testWidgets('Oscuro y Claro cambian el tema de toda la aplicación', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.brightness_4);

      await tapInPanel(tester, 'Oscuro');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );
      // El panel es lila claro: dentro manda un tema claro para que sus
      // textos no salgan blancos sobre él.
      expect(
        Theme.of(tester.element(find.text('Apariencia'))).brightness,
        Brightness.light,
      );

      await tapInPanel(tester, 'Claro');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
    });

    testWidgets('Auto sigue el brillo del sistema', (tester) async {
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.brightness_4);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      await tapInPanel(tester, 'Auto');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      await tapInPanel(tester, 'Auto');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
    });

    testWidgets('cada filtro de daltonismo activa su propio tema', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.brightness_4);

      const filtros = {
        'Protanopía': AppThemeMode.protanopia,
        'Protanomalía': AppThemeMode.protanomalia,
        'Deuteranopía': AppThemeMode.deuteranopia,
        'Deuteranomalía': AppThemeMode.deuteranomalia,
        'Tritanopía': AppThemeMode.tritanopia,
        'Tritanomalía': AppThemeMode.tritanomalia,
        'Acromatopsia': AppThemeMode.achromatopsia,
      };

      for (final MapEntry(key: label, value: mode) in filtros.entries) {
        await tapInPanel(tester, label);
        expect(
          ThemeManager.themeNotifier.value,
          mode,
          reason: '«$label» debe activar $mode',
        );
        final chip = tester.widget<ChoiceChip>(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(chip.selected, isTrue, reason: '«$label» debe verse elegido');
      }
    });

    testWidgets('tocar otra vez el filtro activo lo quita y vuelve a claro', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.brightness_4);

      await tapInPanel(tester, 'Tritanomalía');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.tritanomalia);

      await tapInPanel(tester, 'Tritanomalía');
      expect(ThemeManager.themeNotifier.value, AppThemeMode.light);
    });
  });

  group('asistencia auditiva', () {
    testWidgets('«voz más pausada» se guarda y se avisa de en qué quedó', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.hearing);
      announced(tester); // descarta lo anterior

      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(prefs.clearSpeech, isTrue);
      expect(await storage.read(key: 'learning_clear_speech'), 'true');
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      const activada =
          'Voz más pausada activada.\n'
          'Se nota al pulsar «Escuchar» en cualquier pantalla del curso.';
      expect(announced(tester), contains(activada));
      // El aviso también se ve, centrado, por encima del menú.
      expect(find.text(activada), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(prefs.clearSpeech, isFalse);
      expect(await storage.read(key: 'learning_clear_speech'), 'false');
      expect(
        announced(tester),
        contains(
          'Voz más pausada desactivada.\nLa voz vuelve a su ritmo normal.',
        ),
      );
      // Solo queda un aviso: el nuevo sustituye al anterior.
      expect(find.text(activada), findsNothing);

      // Y el aviso se va solo pasados unos segundos.
      await tester.pump(const Duration(seconds: 7));
      expect(find.textContaining('Voz más pausada desactivada'), findsNothing);
    });

    testWidgets('cada pastilla de velocidad fija esa velocidad y la marca', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.hearing);
      announced(tester);

      for (final pace in SpeechPace.values) {
        await tapInPanel(tester, pace.label);

        expect(prefs.pace, pace);
        expect(await storage.read(key: 'learning_speech_pace'), pace.label);
        expect(
          announced(tester),
          contains(
            'Velocidad de la voz: ${pace.label.toLowerCase()}.\n'
            'Se nota al pulsar «Escuchar», arriba en cada pantalla.',
          ),
        );
        // La elegida lleva la marca; las otras no.
        expect(
          find.descendant(
            of: find
                .ancestor(
                  of: find.text(pace.label),
                  matching: find.byType(Container),
                )
                .first,
            matching: find.byIcon(Icons.check),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check), findsOneWidget);
      }

      await dismissToast(tester);
    });
  });

  group('lengua de señas', () {
    testWidgets('cada nivel de apoyo se guarda y explica qué cambia', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.help, option: Icons.language);
      announced(tester);

      const mensajes = {
        SignSupportLevel.basic: 'Apoyo en señas: básico.',
        SignSupportLevel.advanced: 'Apoyo en señas: avanzado.',
        SignSupportLevel.off: 'Apoyo en señas desactivado.',
      };

      for (final MapEntry(key: level, value: inicio) in mensajes.entries) {
        await tapInPanel(tester, level.label);

        expect(prefs.signSupport, level);
        expect(await storage.read(key: 'learning_sign_support'), level.label);
        expect(
          announced(tester).where((m) => m.startsWith(inicio)),
          hasLength(1),
          reason: 'al elegir ${level.label} se dice «$inicio…»',
        );
      }

      await dismissToast(tester);
    });
  });

  group('ajustes de aprendizaje', () {
    testWidgets('las preferencias de contenido se guardan una a una', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(
        tester,
        category: Icons.psychology,
        option: Icons.build_circle,
      );
      announced(tester);

      const mensajes = {
        ContentPreference.readings: 'Lecturas primero.',
        ContentPreference.videos: 'Videos primero.',
        ContentPreference.audios: 'Audios.',
        ContentPreference.none: 'Sin preferencia.',
      };

      for (final MapEntry(key: preference, value: inicio) in mensajes.entries) {
        await tapInPanel(tester, preference.label);

        expect(prefs.contentPreference, preference);
        expect(
          await storage.read(key: 'learning_content_preference'),
          preference.label,
        );
        expect(
          announced(tester).where((m) => m.startsWith(inicio)),
          hasLength(1),
        );
      }
      // «Audios» enciende la lectura en voz alta; «Sin preferencia», no.
      expect(prefs.autoReadAloud, isFalse);

      await dismissToast(tester);
    });

    testWidgets('el nivel de aprendizaje se guarda y avisa de lo que cambia', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(tester, category: Icons.psychology, option: Icons.stars);
      announced(tester);

      const mensajes = {
        LearningLevel.basic: 'Nivel básico.',
        LearningLevel.advanced: 'Nivel avanzado.',
        LearningLevel.medium: 'Nivel medio.',
      };

      for (final MapEntry(key: level, value: inicio) in mensajes.entries) {
        await tapInPanel(tester, level.label);

        expect(prefs.level, level);
        expect(await storage.read(key: 'learning_level'), level.label);
        expect(
          announced(tester).where((m) => m.startsWith(inicio)),
          hasLength(1),
        );
        if (level == LearningLevel.advanced) {
          expect(prefs.hidesScaffolding, isTrue);
        }
      }

      await dismissToast(tester);
    });
  });

  group('apoyo', () {
    testWidgets('el botón de pistas cambia de texto según su estado', (
      tester,
    ) async {
      await pumpMenu(tester);
      await openPanel(
        tester,
        category: Icons.volunteer_activism,
        option: Icons.saved_search,
      );
      announced(tester);

      await tapInPanel(tester, 'Activar pistas');
      expect(prefs.hintsEnabled, isTrue);
      expect(await storage.read(key: 'learning_hints'), 'true');
      expect(
        announced(tester),
        contains('Pistas activadas: aparecerán en los quiz.'),
      );
      expect(find.text('Desactivar pistas'), findsOneWidget);

      await tapInPanel(tester, 'Desactivar pistas');
      expect(prefs.hintsEnabled, isFalse);
      expect(announced(tester), contains('Pistas desactivadas.'));
      expect(find.text('Activar pistas'), findsOneWidget);

      await dismissToast(tester);
    });

    testWidgets('el manual interactivo se enciende y se apaga', (tester) async {
      await pumpMenu(tester);
      await openPanel(
        tester,
        category: Icons.volunteer_activism,
        option: Icons.menu_book,
      );
      announced(tester);

      await tapInPanel(tester, 'Activar manual interactivo');
      expect(prefs.manualEnabled, isTrue);
      expect(await storage.read(key: 'learning_manual'), 'true');
      expect(
        announced(
          tester,
        ).where((m) => m.startsWith('Manual interactivo activado.')),
        hasLength(1),
      );

      await tapInPanel(tester, 'Desactivar manual interactivo');
      expect(prefs.manualEnabled, isFalse);
      expect(
        announced(
          tester,
        ).where((m) => m.startsWith('Manual interactivo desactivado.')),
        hasLength(1),
      );
      expect(find.text('Activar manual interactivo'), findsOneWidget);

      await dismissToast(tester);
    });
  });
}
