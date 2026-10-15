import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/teacher/editors/quiz_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
}

/// Abre cada actividad desde el detalle de la sección, la cambia y vuelve.
///
/// Cada editor devuelve lo escrito al pulsar «Listo». Lo que importa aquí es
/// el viaje de vuelta: que la tarjeta de la actividad cuente lo nuevo, que el
/// detalle avise de que hay cambios sin guardar y que, al guardar, eso mismo
/// llegue al servidor. Salir de un editor sin «Listo» no puede cambiar nada.
void main() {
  final store = CourseContentStore.instance;
  late List<http.Request> sent;

  setUp(() {
    store.debugReset();
    sent = [];
    store.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((request) async {
        sent.add(request);
        return http.Response('{}', 200);
      }),
      auth: _FakeAuth(),
    );
  });

  tearDown(store.debugReset);

  Future<void> mount(
    WidgetTester tester, {
    int module = 1,
    int section = 1,
  }) async {
    // Alto de sobra: los editores son largos y lo que no está dibujado no se
    // puede pulsar.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherSectionDetail(
            moduleNumber: module,
            sectionNumber: section,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// El campo de texto que va debajo de una etiqueta del editor.
  Finder field(String label) => find.descendant(
    of: find.ancestor(
      of: find.text(label),
      matching: find.byType(TeacherField),
    ),
    matching: find.byType(TextField),
  );

  /// «Listo» del editor que está encima de todo.
  Future<void> done(WidgetTester tester) =>
      tap(tester, find.text('Listo').last);

  final section = PythonCourseCatalog.section(1, 1)!;

  testWidgets('añadir un video lo cuenta en la tarjeta y viaja al guardar', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('${section.videos.length} video'), findsOneWidget);

    await tap(tester, find.text('Videos'));
    await tap(tester, find.text('Añadir video'));
    expect(find.text('Nuevo video'), findsOneWidget);

    await tester.enterText(field('Título').last, 'Listas en Python');
    await tester.enterText(
      field('Enlace de YouTube'),
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    );
    await tester.enterText(field('Duración'), '4:20');
    await tester.pumpAndSettle();
    await done(tester);

    // De vuelta en la lista: el video nuevo dice que le falta transcripción.
    expect(find.text('Listas en Python'), findsOneWidget);
    expect(find.text('dQw4w9WgXcQ · 4:20 · sin transcripción'), findsOneWidget);

    await done(tester);

    expect(find.text('${section.videos.length + 1} videos'), findsOneWidget);
    expect(find.text('Tienes cambios sin guardar'), findsOneWidget);

    await tap(tester, find.text('Guardar'));

    final put = sent.singleWhere((r) => r.method == 'PUT');
    final videos = jsonDecode(put.body)['content']['videos'] as List;
    expect(videos, hasLength(section.videos.length + 1));
    expect(videos.last['youtubeId'], 'dQw4w9WgXcQ');
    expect(videos.last['title'], 'Listas en Python');
    expect(videos.last['duration'], '4:20');
  });

  testWidgets('salir de un editor sin «Listo» no cambia la sección', (
    tester,
  ) async {
    await mount(tester);

    await tap(tester, find.text('Videos'));
    await tap(tester, find.text('Añadir video'));
    await tester.enterText(field('Título').last, 'A medio escribir');
    await tester.pumpAndSettle();

    // Se sale dos veces hacia atrás, como haría el botón del sistema.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('A medio escribir'), findsNothing);
    navigator.pop();
    await tester.pumpAndSettle();

    expect(find.text('${section.videos.length} video'), findsOneWidget);
    expect(find.text('Sin cambios'), findsOneWidget);
  });

  testWidgets('borrar una pregunta del quiz deja la tarjeta en singular', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('${section.quiz.length} preguntas'), findsWidgets);

    await tap(tester, find.text('Quiz'));
    expect(
      tester.widget<QuizEditorScreen>(find.byType(QuizEditorScreen)).title,
      'Quiz de la sección',
    );

    await tap(tester, find.byIcon(Icons.delete_outline).first);
    expect(find.text('¿Borrar la pregunta 1?'), findsOneWidget);
    await tap(tester, find.widgetWithText(FilledButton, 'Borrar'));
    await done(tester);

    expect(find.text('1 pregunta'), findsOneWidget);
    expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
  });

  testWidgets('una pregunta nueva en la evaluación final suma en la tarjeta', (
    tester,
  ) async {
    await mount(tester);
    final before = section.finalEvaluation.length;
    expect(find.text('$before preguntas'), findsOneWidget);

    await tap(tester, find.text('Evaluación final'));
    await tap(tester, find.text('Añadir pregunta'));
    expect(find.text('Nueva pregunta'), findsOneWidget);

    await tester.enterText(field('Enunciado'), '¿Qué imprime print(2 + 2)?');
    final options = find.descendant(
      of: find.byType(RadioGroup<int>),
      matching: find.byType(TextField),
    );
    await tester.enterText(options.at(0), '22');
    await tester.enterText(options.at(1), '4');
    await tester.pumpAndSettle();
    // La correcta es la segunda.
    await tap(tester, find.byType(Radio<int>).at(1));
    await done(tester);

    expect(find.text('¿Qué imprime print(2 + 2)?'), findsOneWidget);
    expect(find.text('2 opciones · correcta: 4'), findsOneWidget);

    await done(tester);
    expect(find.text('${before + 1} preguntas'), findsOneWidget);

    await tap(tester, find.text('Guardar'));
    final put = sent.singleWhere((r) => r.method == 'PUT');
    final evaluation =
        jsonDecode(put.body)['content']['finalEvaluation'] as List;
    expect(evaluation, hasLength(before + 1));
    expect(evaluation.last['prompt'], '¿Qué imprime print(2 + 2)?');
  });

  testWidgets('un consejo nuevo en la cápsula suma en la tarjeta', (
    tester,
  ) async {
    await mount(tester);
    final tips = section.capsule!.tips.length;
    expect(find.text('$tips consejos'), findsOneWidget);

    await tap(tester, find.text('Cápsula de conocimiento'));
    await tap(tester, find.text('Añadir consejo'));
    await tester.enterText(field('Título').last, 'Nombres claros');
    await tester.enterText(field('Explicación').last, 'Mejor edad que e.');
    await tester.pumpAndSettle();
    await done(tester);

    expect(find.text('${tips + 1} consejos'), findsOneWidget);
    expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
  });

  testWidgets('un paso nuevo en el ejemplo suma en la tarjeta', (tester) async {
    await mount(tester);
    final steps = section.example!.steps.length;
    expect(find.text('$steps pasos explicados'), findsOneWidget);

    await tap(tester, find.text('Ejemplo comentado'));
    await tap(tester, find.text('Añadir paso'));
    await tester.enterText(field('Trozo de código').last, 'print(x)');
    await tester.enterText(field('Qué hace').last, 'Muestra x.');
    await tester.pumpAndSettle();
    await done(tester);

    expect(find.text('${steps + 1} pasos explicados'), findsOneWidget);
  });

  testWidgets('una pareja nueva en el ejercicio suma en la tarjeta', (
    tester,
  ) async {
    await mount(tester);
    final exercise = section.exercise!;
    final pairs = exercise.pairs.length;
    final questions = exercise.questions.length;

    await tap(tester, find.text('Ejercicio'));
    await tap(tester, find.text('Añadir pareja'));
    await tester.enterText(field('Concepto').last, 'int');
    await tester.enterText(field('Definición').last, 'Número entero.');
    await tester.pumpAndSettle();
    await done(tester);

    expect(
      find.text('${pairs + 1} parejas · $questions preguntas'),
      findsOneWidget,
    );
  });

  testWidgets('una página nueva en la lectura suma en la tarjeta', (
    tester,
  ) async {
    await mount(tester);
    final reading = section.reading!;
    final blocks = reading.pages.fold<int>(0, (n, p) => n + p.blocks.length);

    await tap(tester, find.text('Lectura'));
    await tap(tester, find.text('Añadir página'));
    await done(tester);

    expect(
      find.text('${reading.pages.length + 1} páginas · $blocks bloques'),
      findsOneWidget,
    );
  });

  testWidgets('quitar una actividad desde su editor la quita de la sección', (
    tester,
  ) async {
    await mount(tester);

    /// Abre la tarjeta, quita la actividad, confirma y pulsa «Listo».
    Future<void> remove(String card, String tooltip) async {
      await tap(tester, find.text(card));
      await tap(tester, find.byTooltip(tooltip));
      await tap(tester, find.widgetWithText(FilledButton, 'Borrar'));
      await done(tester);
    }

    await remove('Cápsula de conocimiento', 'Quitar de la sección');
    expect(find.text('Sin cápsula'), findsOneWidget);
    expect(find.text('Tienes cambios sin guardar'), findsOneWidget);

    await remove('Ejemplo comentado', 'Quitar de la sección');
    expect(find.text('Sin ejemplo'), findsOneWidget);

    await remove('Ejercicio', 'Quitar de la sección');
    expect(find.text('Sin ejercicio'), findsOneWidget);

    await remove('Lectura', 'Quitar la lectura de la sección');
    expect(find.text('Sin lectura'), findsOneWidget);

    await tap(tester, find.text('Guardar'));

    // Lo quitado viaja en nulo: si no, volvería a aparecer al recargar.
    final put = sent.singleWhere((r) => r.method == 'PUT');
    final content = jsonDecode(put.body)['content'] as Map<String, dynamic>;
    expect(content['capsule'], isNull);
    expect(content['example'], isNull);
    expect(content['exercise'], isNull);
    expect(content['reading'], isNull);
  });

  group('una sección sin contenido', () {
    // El módulo 6 todavía no tiene material: sus secciones están vacías.
    testWidgets('cada tarjeta dice qué le falta', (tester) async {
      await mount(tester, module: 6, section: 1);

      expect(find.text('Sin lectura'), findsOneWidget);
      expect(find.text('Sin cápsula'), findsOneWidget);
      expect(find.text('Sin videos'), findsOneWidget);
      expect(find.text('Sin preguntas'), findsNWidgets(2));
      expect(find.text('Sin ejemplo'), findsOneWidget);
      expect(find.text('Sin ejercicio'), findsOneWidget);
      expect(find.text('Esta sección no ofrece laboratorio'), findsOneWidget);
    });

    testWidgets('crear la lectura desde el detalle la deja con una página', (
      tester,
    ) async {
      await mount(tester, module: 6, section: 1);

      await tap(tester, find.text('Lectura'));
      await tap(tester, find.text('Crear la lectura'));
      await done(tester);

      expect(find.text('1 páginas · 0 bloques'), findsOneWidget);
      expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
    });

    testWidgets('crear la cápsula, el ejemplo y el ejercicio', (tester) async {
      await mount(tester, module: 6, section: 1);

      await tap(tester, find.text('Cápsula de conocimiento'));
      await tap(tester, find.text('Crear la cápsula'));
      await tester.enterText(field('Título').last, 'Primer consejo');
      await tester.pumpAndSettle();
      await done(tester);
      expect(find.text('1 consejos'), findsOneWidget);

      await tap(tester, find.text('Ejemplo comentado'));
      await tap(tester, find.text('Crear el ejemplo'));
      await done(tester);
      expect(find.text('0 pasos explicados'), findsOneWidget);

      await tap(tester, find.text('Ejercicio'));
      await tap(tester, find.text('Crear el ejercicio'));
      await tester.enterText(field('Concepto').last, 'str');
      await tester.pumpAndSettle();
      await done(tester);
      expect(find.text('1 parejas · 0 preguntas'), findsOneWidget);
    });

    testWidgets('el primer video se cuenta en singular', (tester) async {
      await mount(tester, module: 6, section: 1);

      await tap(tester, find.text('Videos'));
      await tap(tester, find.text('Añadir el primer video'));
      await tester.enterText(field('Título').last, 'Bienvenida');
      await tester.enterText(field('Enlace de YouTube'), 'dQw4w9WgXcQ');
      await tester.enterText(field('Transcripción'), 'Hola a todos.');
      await tester.pumpAndSettle();
      await done(tester);
      // Con transcripción y sin duración, solo se ve el código del video.
      expect(find.text('dQw4w9WgXcQ'), findsOneWidget);
      await done(tester);

      expect(find.text('1 video'), findsOneWidget);
    });
  });
}
