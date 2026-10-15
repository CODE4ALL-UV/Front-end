import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_capsule_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_example_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_exercise_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_quiz_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_reading_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_video_screen.dart';

const _question = QuizQuestion(
  prompt: '¿Qué imprime print(2 + 2)?',
  options: ['4', '22'],
  correctIndex: 0,
  explanation: 'Python suma los dos números.',
);

/// Una sección pequeña, con una actividad de cada tipo, para recorrer la ruta
/// entera sin depender de cuánto material tenga el catálogo.
const _section = CourseSection(
  id: 'prueba-ruta',
  moduleNumber: 1,
  number: 1,
  title: 'Variables',
  summary: 'Guardar valores con nombre.',
  objectives: ['Crear una variable', 'Mostrar su valor'],
  reading: SectionReading(
    title: 'Variables en Python',
    intro: 'Una variable guarda un valor con un nombre.',
    pages: [
      ReadingPage(
        title: 'Qué es una variable',
        summary: 'Un nombre para un valor.',
        blocks: [
          ReadingBlock.paragraph(
            title: 'La idea',
            body: 'Una variable es una caja con etiqueta.',
          ),
          ReadingBlock.bullets(
            title: 'Reglas',
            items: ['Sin espacios', 'Sin empezar por número'],
          ),
        ],
      ),
      ReadingPage(
        title: 'Cuidado con los nombres',
        summary: 'Errores comunes al nombrar.',
        blocks: [
          ReadingBlock.callout(
            title: 'Así se hace',
            body: 'edad = 20 es un buen nombre.',
            tone: CalloutTone.success,
          ),
          ReadingBlock.callout(
            title: 'Mayúsculas',
            body: 'Edad y edad son variables distintas.',
            tone: CalloutTone.warning,
          ),
          ReadingBlock.callout(
            title: 'Nombre inválido',
            body: '2edad no es un nombre válido.',
            tone: CalloutTone.danger,
          ),
          ReadingBlock.code(
            title: 'En código',
            body: 'Guardamos un valor y lo mostramos.',
            code: 'edad = 20\nprint(edad)',
            codeCaption: 'Guarda 20 en edad y lo imprime',
          ),
          ReadingBlock.steps(
            title: 'Pasos',
            items: ['Elige un nombre', 'Asigna un valor'],
          ),
        ],
      ),
    ],
  ),
  capsule: KnowledgeCapsule(
    title: 'Tip rápido',
    headline: 'Nombres que se entienden',
    intro: 'Un buen nombre ahorra comentarios.',
    tips: [CapsuleTip(title: 'Sé claro', body: 'edad mejor que x.')],
    closing: 'El nombre cuenta qué guarda.',
  ),
  example: CodeExample(
    title: 'Saludar',
    description: 'Guardar un nombre y saludar.',
    code: 'nombre = "Ana"\nprint(nombre)',
    output: 'Ana',
  ),
  exercise: SectionExercise(
    title: 'Practica la suma',
    instructions: 'Elige la respuesta correcta.',
    questions: [_question],
  ),
  videos: [
    SectionVideo(
      title: 'Variables en 3 minutos',
      youtubeId: 'abcdefghijk',
      description: 'Qué es una variable.',
      transcript: 'Una variable guarda un valor.',
      duration: '3:00',
    ),
  ],
  quiz: [_question],
  finalEvaluation: [_question],
);

const _module = CourseModule(
  number: 1,
  title: 'Preparación',
  sections: [_section],
);

/// Recorre la ruta de actividades de un capítulo como lo hace el estudiante.
///
/// Comprueba que cada tipo de actividad abre su propia pantalla, que al
/// terminarla el avance queda guardado y la ruta lo refleja («Hecho», la
/// barra de progreso, «Sección completada»), y que volver sin terminar no
/// cuenta como hecho. Es el corazón de la aplicación: si una actividad no
/// guarda su avance, el porcentaje del mapa miente.
void main() {
  final progress = CourseProgressStore.instance;
  const ttsChannel = MethodChannel('flutter_tts');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (_) async => 1);
  });

  tearDown(() async {
    await progress.resetSection(_section.id, CourseActivityKind.values);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// Una pantalla con un botón que abre la actividad con el lanzador y
  /// guarda lo que este devuelve.
  Future<List<bool>> pumpLauncher(
    WidgetTester tester,
    CourseActivityKind kind, {
    bool settle = true,
  }) async {
    final results = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await SectionActivityLauncher.open(
                  context,
                  _module,
                  _section,
                  kind,
                ),
              ),
              child: const Text('abrir actividad'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir actividad'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // La pantalla de video sigue animando mientras busca los subtítulos:
      // se avanza un rato fijo en lugar de esperar a que se quede quieta.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
    return results;
  }

  void goBack(WidgetTester tester, Type screen) {
    Navigator.of(tester.element(find.byType(screen))).pop();
  }

  group('cada actividad abre su pantalla', () {
    testWidgets('el ejemplo se marca como revisado y vuelve a la ruta', (
      tester,
    ) async {
      bigScreen(tester);
      final results = await pumpLauncher(tester, CourseActivityKind.ejemplo);

      expect(find.byType(SectionExampleScreen), findsOneWidget);
      expect(find.text('Saludar'), findsWidgets);

      await tapText(tester, 'Marcar ejemplo como revisado');

      expect(results, [true]);
      expect(find.text('abrir actividad'), findsOneWidget);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.ejemplo),
        isTrue,
      );
    });

    testWidgets('la cápsula se marca como vista y vuelve a la ruta', (
      tester,
    ) async {
      bigScreen(tester);
      final results = await pumpLauncher(tester, CourseActivityKind.capsula);

      expect(find.byType(SectionCapsuleScreen), findsOneWidget);
      expect(find.text('Nombres que se entienden'), findsOneWidget);

      await tapText(tester, 'Entendido, marcar como vista');

      expect(results, [true]);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.capsula),
        isTrue,
      );
    });

    testWidgets('los videos se marcan como vistos', (tester) async {
      bigScreen(tester);
      final results = await pumpLauncher(
        tester,
        CourseActivityKind.video,
        settle: false,
      );

      expect(find.byType(SectionVideoScreen), findsOneWidget);

      await tester.ensureVisible(find.text('Marcar como visto'));
      await tester.tap(find.text('Marcar como visto'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(results, [true]);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.video),
        isTrue,
      );
    });

    testWidgets('el laboratorio cuenta como hecho al volver de él', (
      tester,
    ) async {
      bigScreen(tester);
      final results = await pumpLauncher(
        tester,
        CourseActivityKind.laboratorio,
      );

      expect(find.byType(LaboratoryConsoleScreen), findsOneWidget);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.laboratorio),
        isFalse,
      );

      // Es una consola libre: no hay respuesta que comprobar, así que se da
      // por hecha al salir, aunque no se pulse «Terminar».
      goBack(tester, LaboratoryConsoleScreen);
      await tester.pumpAndSettle();

      expect(results, [true]);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.laboratorio),
        isTrue,
      );
    });

    testWidgets('salir de la lectura sin terminarla no cuenta como hecha', (
      tester,
    ) async {
      bigScreen(tester);
      final results = await pumpLauncher(tester, CourseActivityKind.lectura);

      expect(find.byType(SectionReadingScreen), findsOneWidget);
      goBack(tester, SectionReadingScreen);
      await tester.pumpAndSettle();

      expect(results, [false]);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.lectura),
        isFalse,
      );
    });

    for (final (kind, intro, label) in [
      (CourseActivityKind.quiz, 'Quiz de repaso', 'Quiz'),
      (
        CourseActivityKind.evaluacion,
        'Evaluación final de la sección',
        'Evaluación final',
      ),
      (CourseActivityKind.ejercicio, 'Practica la suma', 'Ejercicio'),
    ]) {
      testWidgets('$label: aprobar guarda el avance y devuelve que se hizo', (
        tester,
      ) async {
        bigScreen(tester);
        final results = await pumpLauncher(tester, kind);

        expect(find.byType(SectionQuizScreen), findsOneWidget);
        if (kind == CourseActivityKind.ejercicio) {
          expect(find.byType(SectionExerciseScreen), findsOneWidget);
        }
        expect(find.text('Idea clave · $intro'), findsOneWidget);
        expect(find.text('$label · Capítulo 1: Variables'), findsOneWidget);

        await tapText(tester, '4');
        await tapText(tester, 'Ver resultado');
        await tapText(tester, 'Volver');

        expect(results, [true]);
        expect(progress.isCompleted(_section.id, kind), isTrue);
      });
    }

    testWidgets('suspender el quiz devuelve que no se hizo', (tester) async {
      bigScreen(tester);
      final results = await pumpLauncher(tester, CourseActivityKind.quiz);

      await tapText(tester, '22');
      await tapText(tester, 'Ver resultado');
      await tapText(tester, 'Volver');

      expect(results, [false]);
      expect(
        progress.isCompleted(_section.id, CourseActivityKind.quiz),
        isFalse,
      );
    });
  });

  group('la lectura', () {
    testWidgets('se recorre página a página y al final queda completada', (
      tester,
    ) async {
      bigScreen(tester);
      final results = await pumpLauncher(tester, CourseActivityKind.lectura);

      // Primera página: la presentación y lo que se va a aprender.
      expect(find.text('Variables en Python'), findsOneWidget);
      expect(find.text('Al terminar esta lectura podrás:'), findsOneWidget);
      expect(find.text('Página 1 de 2'), findsWidgets);
      // En la primera página «Anterior» no hace nada, y se dice por qué.
      final previous = tester.widget<ButtonStyleButton>(
        find.ancestor(
          of: find.text('Anterior'),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        ),
      );
      expect(previous.onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.hint == 'Ya estás en la primera página',
        ),
        findsOneWidget,
      );

      await tapText(tester, 'Siguiente');

      // Segunda página: los avisos dicen su tono con palabras, no solo color.
      expect(find.text('Cuidado con los nombres'), findsOneWidget);
      expect(find.text('Bien hecho · Así se hace'), findsOneWidget);
      expect(find.text('Atención · Mayúsculas'), findsOneWidget);
      expect(find.text('Cuidado · Nombre inválido'), findsOneWidget);
      expect(
        find.text('Qué hace este código: Guarda 20 en edad y lo imprime'),
        findsOneWidget,
      );
      expect(find.text('Elige un nombre'), findsOneWidget);
      expect(find.text('Variables en Python'), findsNothing);

      // Se puede volver atrás y otra vez adelante.
      await tapText(tester, 'Anterior');
      expect(find.text('Qué es una variable'), findsOneWidget);
      await tapText(tester, 'Siguiente');

      expect(
        progress.isCompleted(_section.id, CourseActivityKind.lectura),
        isFalse,
      );
      await tapText(tester, 'Finalizar');

      expect(
        progress.isCompleted(_section.id, CourseActivityKind.lectura),
        isTrue,
      );
      expect(find.text('Idea clave · Lectura completada'), findsOneWidget);

      await tapText(tester, 'Volver a la ruta de actividades');
      expect(results, [true]);
    });
  });

  group('la ruta del capítulo', () {
    Future<void> pumpChapter(WidgetTester tester, {Widget? trailing}) async {
      bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode: AppThemeMode.light),
          home: ChapterSectionScreen(
            module: _module,
            section: _section,
            trailingAction: trailing,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('terminar una actividad la marca hecha y sube el progreso', (
      tester,
    ) async {
      await pumpChapter(tester);
      final total = SectionActivityLauncher.activitiesFor(_section).length;

      expect(
        find.text('Progreso: 0 de $total actividades completadas'),
        findsOneWidget,
      );
      expect(find.text('Hecho'), findsNothing);

      await tapText(tester, 'Paso 3 · Ejemplo');
      await tapText(tester, 'Marcar ejemplo como revisado');

      expect(find.byType(ChapterSectionScreen), findsOneWidget);
      expect(
        find.text('Progreso: 1 de $total actividades completadas'),
        findsOneWidget,
      );
      expect(find.text('Hecho'), findsOneWidget);

      // Quien navega por voz oye que ya la hizo y que puede repasarla.
      final tile = tester.getSemantics(
        find.bySemanticsLabel(RegExp(r'^Paso 3\. Ejemplo\.')),
      );
      expect(tile.hint, 'Ya completada. Púlsala para repasarla');
      expect(
        tile.label,
        'Paso 3. Ejemplo. Código comentado línea por línea. '
        'Código explicado línea por línea',
      );
    });

    testWidgets('volver sin terminar no cambia nada', (tester) async {
      await pumpChapter(tester);

      await tapText(tester, 'Paso 1 · Lectura');
      goBack(tester, SectionReadingScreen);
      await tester.pumpAndSettle();

      expect(find.text('Hecho'), findsNothing);
    });

    testWidgets('con todas hechas se felicita al estudiante', (tester) async {
      for (final kind in SectionActivityLauncher.activitiesFor(_section)) {
        await progress.markCompleted(_section.id, kind);
      }
      await pumpChapter(tester);

      final total = SectionActivityLauncher.activitiesFor(_section).length;
      expect(find.text('Hecho'), findsNWidgets(total));
      expect(find.text('Idea clave · Sección completada'), findsOneWidget);
      expect(
        find.text(
          '¡Felicitaciones! Terminaste las $total actividades de "Variables".',
        ),
        findsOneWidget,
      );
    });

    testWidgets('la acción extra de la cabecera se muestra junto al título', (
      tester,
    ) async {
      await pumpChapter(
        tester,
        trailing: IconButton(
          tooltip: 'Editar capítulo',
          onPressed: () {},
          icon: const Icon(Icons.edit_outlined),
        ),
      );

      expect(find.byTooltip('Editar capítulo'), findsOneWidget);
      // Sin capítulo anterior ni siguiente no hay barra de navegación.
      expect(find.text('Anterior'), findsNothing);
    });
  });
}
