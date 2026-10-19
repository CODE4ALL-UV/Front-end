import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/dactylology_floating_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_scaffold.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_quiz_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_reading_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_language_panel.dart';

/// Lo que el estudiante elige en el menú de ayuda tiene que notarse dentro de
/// cada actividad, no solo quedarse guardado.
///
/// Aquí se comprueba en las pantallas de la ruta: el manual interactivo
/// explica la pantalla al abrirla (una sola vez), preferir «Audios» hace que
/// la pantalla se lea sola, el apoyo en señas añade el panel de deletreo y
/// las pistas aparecen solo si se pidieron. Y lo contrario: sin tocar nada,
/// ninguna de esas ayudas aparece.
void main() {
  final prefs = LearningPreferences.instance;
  const ttsChannel = MethodChannel('flutter_tts');
  final spoken = <String>[];
  var stops = 0;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    spoken.clear();
    stops = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
          if (call.method == 'speak') spoken.add('${call.arguments}');
          if (call.method == 'stop') stops++;
          return 1;
        });
  });

  tearDown(() async {
    // Son globales: una prueba que las deje puestas envenena la siguiente.
    await prefs.setSignSupport(SignSupportLevel.off);
    await prefs.setContentPreference(ContentPreference.none);
    await prefs.setHintsEnabled(false);
    await prefs.setManualEnabled(false);
    SignAssetIndex.instance.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: child,
  );

  Widget scaffold({
    String activityLabel = 'Ejemplo',
    String? signText,
    String spokenText = 'Guardamos un nombre y lo mostramos.',
  }) => SectionActivityScaffold(
    moduleLabel: 'Módulo 2. Fundamentos de Python',
    sectionTitle: 'Capítulo 1: Sintaxis',
    activityLabel: activityLabel,
    activityIcon: Icons.terminal,
    spokenText: spokenText,
    signText: signText,
    child: const Text('contenido de la actividad'),
  );

  group('el manual interactivo', () {
    testWidgets('explica la lectura al abrirla, y una sola vez', (
      tester,
    ) async {
      bigScreen(tester);
      await prefs.setManualEnabled(true);
      final module = PythonCourseCatalog.moduleByNumber(1)!;
      final section = PythonCourseCatalog.section(1, 1)!;

      await tester.pumpWidget(
        app(SectionReadingScreen(module: module, section: section)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cómo usar esta pantalla'), findsOneWidget);
      expect(
        find.text('Lectura · ${section.displayTitle}'),
        findsNWidgets(2), // la cabecera de la pantalla y la de la guía
      );
      expect(
        find.text('El contenido va por páginas: avanza con el botón de abajo.'),
        findsOneWidget,
      );
      // Los pasos van numerados.
      for (final number in ['1', '2', '3']) {
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(number),
          ),
          findsOneWidget,
        );
      }

      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Cómo usar esta pantalla'), findsNothing);

      // Pasar de página redibuja la pantalla, pero la guía no vuelve.
      await tester.ensureVisible(find.text('Siguiente'));
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Cómo usar esta pantalla'), findsNothing);
    });

    testWidgets('una actividad sin guía propia recibe la general', (
      tester,
    ) async {
      await prefs.setManualEnabled(true);

      await tester.pumpWidget(app(scaffold(activityLabel: 'Laboratorio')));
      await tester.pumpAndSettle();

      expect(find.text('Cómo usar esta pantalla'), findsOneWidget);
      expect(
        find.text(
          'El botón morado de ayuda abre los ajustes de aprendizaje y '
          'accesibilidad.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin activarlo no aparece ninguna guía', (tester) async {
      await tester.pumpWidget(app(scaffold()));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('contenido de la actividad'), findsOneWidget);
    });
  });

  group('preferir «Audios»', () {
    testWidgets('la actividad empieza a leerse sola, en orden', (tester) async {
      await prefs.setContentPreference(ContentPreference.audios);

      await tester.pumpWidget(app(scaffold()));
      await tester.pumpAndSettle();

      expect(spoken, isNotEmpty);
      expect(
        spoken.last,
        'Ejemplo. Capítulo 1: Sintaxis. Guardamos un nombre y lo mostramos.',
      );

      // Al salir de la pantalla, la voz se calla.
      final stopsBefore = stops;
      await tester.pumpWidget(app(const SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(stops, greaterThan(stopsBefore));
    });

    testWidgets('sin esa preferencia no suena nada hasta pedirlo', (
      tester,
    ) async {
      await tester.pumpWidget(app(scaffold()));
      await tester.pumpAndSettle();

      expect(spoken, isEmpty);
    });
  });

  group('apoyo en lengua de señas', () {
    testWidgets('en «Básico» se deletrea, sin la mitad de la palabra', (
      tester,
    ) async {
      bigScreen(tester);
      await prefs.setSignSupport(SignSupportLevel.basic);

      await tester.pumpWidget(app(scaffold(signText: 'hola')));
      await tester.pump();

      final panel = tester.widget<SignLanguagePanel>(
        find.byType(SignLanguagePanel),
      );
      expect(panel.text, 'hola');
      expect(panel.showWordSigns, isFalse);
      expect(find.text('Lengua de señas'), findsNothing);
      expect(find.text('H'), findsOneWidget);

      // Y el lector flotante, plegado hasta que se pida.
      expect(find.byType(DactylologyFloatingWidget), findsOneWidget);
      expect(find.byTooltip('Mostrar lector de dactilología'), findsOneWidget);

      await tester.pumpWidget(app(const SizedBox.shrink()));
    });

    testWidgets('en «Avanzado» también se muestra la seña de la palabra', (
      tester,
    ) async {
      bigScreen(tester);
      await prefs.setSignSupport(SignSupportLevel.advanced);

      await tester.pumpWidget(app(scaffold(signText: 'hola')));
      await tester.pump();

      expect(find.text('Lengua de señas'), findsOneWidget);
      expect(find.text('HOLA'), findsOneWidget);

      // Al desplegar el lector flotante aparece el lector del manual, que
      // recibe el mismo nivel que el panel.
      await tester.tap(find.byTooltip('Mostrar lector de dactilología'));
      await tester.pump();
      expect(find.text('Palabra 1 de 1'), findsOneWidget);
      expect(
        tester.widget<SignLanguagePanel>(find.byType(SignLanguagePanel)),
        isA<SignLanguagePanel>().having((p) => p.showWordSigns, 'seña', true),
      );
      expect(
        tester.widget<DactylologyFloatingWidget>(
          find.byType(DactylologyFloatingWidget),
        ),
        isA<DactylologyFloatingWidget>().having(
          (w) => w.showWordSigns,
          'seña',
          true,
        ),
      );

      await tester.pumpWidget(app(const SizedBox.shrink()));
    });

    testWidgets('sin texto que deletrear no hay panel', (tester) async {
      await prefs.setSignSupport(SignSupportLevel.advanced);

      await tester.pumpWidget(app(scaffold(signText: '   ')));
      await tester.pump();

      expect(find.byType(SignLanguagePanel), findsNothing);
      expect(find.byType(DactylologyFloatingWidget), findsNothing);
    });

    testWidgets('desactivado, el contenido se ve como siempre', (tester) async {
      await tester.pumpWidget(app(scaffold(signText: 'hola')));
      await tester.pump();

      expect(find.byType(SignLanguagePanel), findsNothing);
      expect(find.byType(DactylologyFloatingWidget), findsNothing);
    });
  });

  group('las pistas del quiz', () {
    const section = CourseSection(
      id: 'prueba-pistas',
      moduleNumber: 1,
      number: 1,
      title: 'Pistas',
      summary: 'Sección para probar las pistas.',
      objectives: [],
    );
    const module = CourseModule(
      number: 1,
      title: 'Preparación',
      sections: [section],
    );

    Future<void> pumpQuiz(
      WidgetTester tester,
      List<QuizQuestion> questions,
    ) async {
      bigScreen(tester);
      await tester.pumpWidget(
        app(
          SectionQuizScreen(
            module: module,
            section: section,
            questions: questions,
            activityKind: CourseActivityKind.quiz,
            activityLabel: 'Quiz',
            activityIcon: Icons.quiz,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    const withExplanation = QuizQuestion(
      prompt: '¿Qué hace print?',
      options: ['Muestra un texto', 'Borra un archivo'],
      correctIndex: 0,
      explanation: 'print escribe en la pantalla lo que le pases.',
    );

    tearDown(() async {
      await CourseProgressStore.instance.resetSection(section.id, [
        CourseActivityKind.quiz,
      ]);
    });

    testWidgets('si se activaron, se ofrecen y se muestran al pedirlas', (
      tester,
    ) async {
      await prefs.setHintsEnabled(true);
      await pumpQuiz(tester, const [withExplanation]);

      expect(find.text('Ver una pista'), findsOneWidget);
      expect(
        find.text('print escribe en la pantalla lo que le pases.'),
        findsNothing,
      );

      await tester.tap(find.text('Ver una pista'));
      await tester.pumpAndSettle();

      expect(find.text('Idea clave · Pista'), findsOneWidget);
      expect(
        find.text('print escribe en la pantalla lo que le pases.'),
        findsOneWidget,
      );
      expect(find.text('Ver una pista'), findsNothing);

      // Al responder, la pista deja su sitio a la explicación de la respuesta.
      await tester.tap(find.text('Muestra un texto'));
      await tester.pumpAndSettle();
      expect(find.text('Idea clave · Pista'), findsNothing);
    });

    testWidgets('una pregunta sin explicación no ofrece una pista vacía', (
      tester,
    ) async {
      await prefs.setHintsEnabled(true);
      await pumpQuiz(tester, const [
        QuizQuestion(prompt: '¿2 + 2?', options: ['4', '5'], correctIndex: 0),
      ]);

      expect(find.text('Ver una pista'), findsNothing);
    });

    testWidgets('sin activarlas no hay botón de pista', (tester) async {
      await pumpQuiz(tester, const [withExplanation]);

      expect(find.text('Ver una pista'), findsNothing);
    });
  });

  group('la pantalla de la sección', () {
    testWidgets('cambia la ruta y los objetivos sin salir de ella', (
      tester,
    ) async {
      bigScreen(tester);
      addTearDown(() => prefs.setLevel(LearningLevel.medium));
      final section = PythonCourseCatalog.section(1, 1)!;
      expect(section.objectives, isNotEmpty);

      await tester.pumpWidget(
        app(
          ChapterSectionScreen(
            module: PythonCourseCatalog.moduleByNumber(1)!,
            section: section,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 · Lectura'), findsOneWidget);
      expect(find.text('Objetivos de la sección'), findsOneWidget);

      // Se cambian desde el menú de ayuda, con la sección abierta.
      await prefs.setContentPreference(ContentPreference.videos);
      await prefs.setLevel(LearningLevel.advanced);
      await tester.pumpAndSettle();

      expect(find.text('Paso 1 · Video'), findsOneWidget);
      expect(find.text('Paso 1 · Lectura'), findsNothing);
      expect(find.text('Objetivos de la sección'), findsNothing);
    });
  });
}
