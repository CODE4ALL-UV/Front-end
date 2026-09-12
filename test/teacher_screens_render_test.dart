import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/editors/capsule_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/example_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/exercise_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/quiz_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/videos_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';

/// Dibuja de verdad todas las pantallas del docente, con todo el curso.
///
/// Las pruebas de lógica que había antes pasaban mientras la pantalla se
/// llenaba de recuadros rojos: nunca dibujaban nada. Estas sí, y recorren el
/// curso entero —dieciocho secciones— porque cada una tiene una combinación
/// distinta de actividades y basta con que una traiga un campo raro para que
/// reviente solo esa.
///
/// No se prueba guardar: al guardar entra el almacenamiento seguro, que dentro
/// de una prueba de widgets intenta su llamada nativa y tumba el proceso.
void main() {
  final store = CourseContentStore.instance;

  setUp(() {
    store.debugReset();
    store.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'version': '', 'count': 0, 'items': []}),
          200,
        ),
      ),
    );
  });

  tearDown(store.debugReset);

  Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );

  /// Dibuja y deja que se asienten los fotogramas, sin esperar animaciones
  /// que no terminan nunca (los indicadores de carga giran para siempre).
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  CourseSection sectionOf(int module, int number) =>
      PythonCourseCatalog.section(module, number)!;

  group('el temario del docente', () {
    testWidgets('se dibuja con los seis módulos', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const TeacherCourseScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('CODE4ALL'), findsOneWidget);
      // El modulo lleva su etiqueta y su nombre en lineas separadas.
      expect(find.text('Módulo 1'), findsOneWidget);
      expect(find.text('Preparación'), findsOneWidget);
    });

    testWidgets('en pantalla ancha enseña temario y sección a la vez', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const TeacherCourseScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      // El detalle de la primera sección se abre solo.
      expect(find.text('Actividades'), findsOneWidget);
    });

    testWidgets('cabe con el texto al doble', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(const TeacherCourseScreen(), textScale: 2.0),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('el detalle de cada sección del curso', () {
    // Las dieciocho, porque cada una combina actividades de forma distinta.
    for (final module in PythonCourseCatalog.modules) {
      for (final section in module.sections) {
        testWidgets('módulo ${module.number}, sección ${section.number}', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(420, 1400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            wrap(
              Scaffold(
                body: TeacherSectionDetail(
                  moduleNumber: module.number,
                  sectionNumber: section.number,
                ),
              ),
            ),
          );
          await settle(tester);

          expect(tester.takeException(), isNull);
          expect(find.text('Actividades'), findsOneWidget);
        });
      }
    }

    testWidgets('cabe en 320 px con el texto grande', (tester) async {
      tester.view.physicalSize = const Size(320, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: TeacherSectionDetail(moduleNumber: 1, sectionNumber: 1),
          ),
          textScale: 1.6,
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('los editores con contenido de verdad', () {
    testWidgets('lectura', (tester) async {
      final section = sectionOf(1, 1);
      await tester.pumpWidget(
        wrap(
          ReadingEditorScreen(reading: section.reading, section: section),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Páginas'), findsOneWidget);
    });

    testWidgets('quiz', (tester) async {
      await tester.pumpWidget(
        wrap(
          QuizEditorScreen(questions: sectionOf(1, 1).quiz, title: 'Quiz'),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('cápsula', (tester) async {
      await tester.pumpWidget(
        wrap(CapsuleEditorScreen(capsule: sectionOf(1, 1).capsule)),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Consejos'), findsOneWidget);
    });

    testWidgets('videos', (tester) async {
      await tester.pumpWidget(
        wrap(VideosEditorScreen(videos: sectionOf(1, 1).videos)),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('ejemplo', (tester) async {
      await tester.pumpWidget(
        wrap(ExampleEditorScreen(example: sectionOf(1, 1).example)),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('ejercicio', (tester) async {
      await tester.pumpWidget(
        wrap(ExerciseEditorScreen(exercise: sectionOf(1, 1).exercise)),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('los editores cuando la actividad no existe', () {
    // El estado vacío es el que menos se mira y el que más se rompe.
    testWidgets('lectura vacía ofrece crearla', (tester) async {
      await tester.pumpWidget(
        wrap(
          ReadingEditorScreen(reading: null, section: sectionOf(6, 1)),
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Crear la lectura'), findsOneWidget);
    });

    testWidgets('cápsula vacía', (tester) async {
      await tester.pumpWidget(wrap(const CapsuleEditorScreen(capsule: null)));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Crear la cápsula'), findsOneWidget);
    });

    testWidgets('ejemplo vacío', (tester) async {
      await tester.pumpWidget(wrap(const ExampleEditorScreen(example: null)));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('ejercicio vacío', (tester) async {
      await tester.pumpWidget(wrap(const ExerciseEditorScreen(exercise: null)));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('videos vacíos', (tester) async {
      await tester.pumpWidget(wrap(const VideosEditorScreen(videos: [])));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Añadir el primer video'), findsOneWidget);
    });

    testWidgets('quiz vacío', (tester) async {
      await tester.pumpWidget(
        wrap(const QuizEditorScreen(questions: [], title: 'Quiz')),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Añadir la primera pregunta'), findsOneWidget);
    });
  });

  group('crear una actividad desde cero', () {
    testWidgets('crear la lectura deja una página lista para escribir', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ReadingEditorScreen(reading: null, section: sectionOf(6, 1))),
      );
      await settle(tester);

      await tester.tap(find.text('Crear la lectura'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Páginas'), findsOneWidget);
    });

    testWidgets('crear la cápsula deja un consejo en blanco', (tester) async {
      await tester.pumpWidget(wrap(const CapsuleEditorScreen(capsule: null)));
      await settle(tester);

      await tester.tap(find.text('Crear la cápsula'));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Consejo 1'), findsOneWidget);
    });
  });

  group('escribir en los editores', () {
    testWidgets('cambiar el título de la sección lo marca sin guardar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: TeacherSectionDetail(moduleNumber: 1, sectionNumber: 1),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Sin cambios'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, sectionOf(1, 1).title),
        'Un título nuevo',
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
    });

    testWidgets('añadir una opción a una pregunta', (tester) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          QuizEditorScreen(questions: sectionOf(1, 1).quiz, title: 'Quiz'),
        ),
      );
      await settle(tester);

      // Se abre la primera pregunta.
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await settle(tester);

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Añadir opción'));
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('en la pantalla mas pequena y con el texto al doble', () {
    // 320 px con el texto al 200 por ciento es como navega alguien con baja
    // vision en un telefono pequeno. Si algo se desborda, se desborda ahi.
    Future<void> stress(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(screen, textScale: 2.0));
      await settle(tester);

      expect(tester.takeException(), isNull);
    }

    testWidgets('editor de lectura', (tester) async {
      final section = sectionOf(1, 1);
      await stress(
        tester,
        ReadingEditorScreen(reading: section.reading, section: section),
      );
    });

    testWidgets('editor de quiz', (tester) async {
      await stress(
        tester,
        QuizEditorScreen(questions: sectionOf(1, 1).quiz, title: 'Quiz'),
      );
    });

    testWidgets('editor de capsula', (tester) async {
      await stress(tester, CapsuleEditorScreen(capsule: sectionOf(1, 1).capsule));
    });

    testWidgets('editor de videos', (tester) async {
      await stress(tester, VideosEditorScreen(videos: sectionOf(1, 1).videos));
    });

    testWidgets('editor de ejemplo', (tester) async {
      await stress(tester, ExampleEditorScreen(example: sectionOf(1, 1).example));
    });

    testWidgets('editor de ejercicio', (tester) async {
      await stress(
        tester,
        ExerciseEditorScreen(exercise: sectionOf(1, 1).exercise),
      );
    });

    testWidgets('temario del docente', (tester) async {
      await stress(tester, const TeacherCourseScreen());
    });

    testWidgets('detalle con una seccion sin contenido', (tester) async {
      // El modulo 6 no tiene nada: todas las tarjetas salen vacias a la vez.
      await stress(
        tester,
        const Scaffold(
          body: TeacherSectionDetail(moduleNumber: 6, sectionNumber: 1),
        ),
      );
    });
  });
}
