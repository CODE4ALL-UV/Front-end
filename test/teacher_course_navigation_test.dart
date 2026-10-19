import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';
import 'package:flutter_code4all/ui/teacher/teacher_stats_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
}

/// Moverse por el curso que edita el docente.
///
/// El temario es un árbol: se abre un módulo, se elige una sección y se
/// edita. En pantalla ancha la sección se abre al lado; en una estrecha, en
/// otra pantalla. Aquí se comprueba ese recorrido, que el código para que
/// entren los estudiantes esté a mano, que lo editado se distinga de lo
/// original y que, si el servidor no responde, el docente lo sepa en vez de
/// creer que perdió sus cambios.
void main() {
  final content = CourseContentStore.instance;
  final analytics = CourseAnalyticsStore.instance;
  late List<http.Request> sent;

  /// Un servidor que responde [items] como ediciones del temario, o
  /// [status] si no es 200.
  void serve({List<Map<String, Object?>> items = const [], int status = 200}) {
    sent = [];
    content.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((request) async {
        sent.add(request);
        if (status != 200) return http.Response('fallo', status);
        return http.Response(
          jsonEncode({'version': 'v', 'count': items.length, 'items': items}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      auth: _FakeAuth(),
    );
  }

  setUp(() {
    content.debugReset();
    analytics.debugReset();
    // Las pestañas de cifras no deben salir a la red en estas pruebas.
    analytics.debugSeed(totalAnswers: 0);
  });

  tearDown(() {
    content.debugReset();
    analytics.debugReset();
  });

  Future<void> mount(
    WidgetTester tester, {
    double width = 420,
    CourseInfo? course,
  }) async {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: TeacherCourseScreen(course: course)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  final course = CourseInfo.fromJson({
    'id': 7,
    'title': 'Python 2026-1',
    'is_general': false,
    'teacher': {'id': 30, 'nombre': 'Laura'},
    'is_owner': true,
    'can_edit': true,
    'join_code': 'ABC234',
    'students': 3,
  });

  group('el curso que se edita', () {
    testWidgets('su nombre va en la barra y su código está a un toque', (
      tester,
    ) async {
      serve();
      final copied = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await mount(tester, course: course);
      expect(find.text('Python 2026-1'), findsOneWidget);

      await tester.tap(find.byTooltip('Código para inscribirse'));
      await settle(tester);

      expect(find.text('Código de Python 2026-1'), findsOneWidget);
      expect(find.text('ABC234'), findsOneWidget);
      // Por voz se deletrea, que es como se dicta en clase.
      expect(find.bySemanticsLabel('Código: A B C 2 3 4'), findsOneWidget);

      await tester.tap(find.text('Copiar'));
      await settle(tester);

      expect(copied, ['ABC234']);
      expect(find.text('Código de Python 2026-1'), findsNothing);

      await tester.tap(find.byTooltip('Código para inscribirse'));
      await settle(tester);
      await tester.tap(find.text('Cerrar'));
      await settle(tester);

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('sin código (el servidor de antes) no hay botón de código', (
      tester,
    ) async {
      serve();
      await mount(tester);

      expect(find.text('CODE4ALL'), findsOneWidget);
      expect(find.byTooltip('Código para inscribirse'), findsNothing);
    });

    testWidgets('el botón de recargar vuelve a pedir lo guardado', (
      tester,
    ) async {
      serve();
      await mount(tester);
      final before = sent.length;

      await tester.tap(
        find.byTooltip('Volver a consultar los cambios guardados'),
      );
      await settle(tester);

      expect(sent.length, before + 1);
      expect(sent.last.url.path, '/api/course/overrides');
    });
  });

  group('sin servidor', () {
    testWidgets('en pantalla estrecha avisa de que ve el contenido original', (
      tester,
    ) async {
      serve(status: 500);
      await mount(tester);

      expect(
        find.textContaining('tus cambios guardados podrían no aparecer'),
        findsOneWidget,
      );
    });

    testWidgets('en pantalla ancha avisa junto a la sección abierta', (
      tester,
    ) async {
      serve(status: 503);
      await mount(tester, width: 1300);

      expect(
        find.text(
          'No se pudo consultar el servidor. Estás viendo el contenido '
          'original.',
        ),
        findsOneWidget,
      );
      // Aun así se puede editar: la sección de fábrica está abierta.
      expect(find.byType(TeacherSectionDetail), findsOneWidget);
    });
  });

  group('el temario', () {
    testWidgets('lo editado se marca en el módulo y en la sección', (
      tester,
    ) async {
      serve(
        items: [
          {
            'scope': 'module',
            'target_id': '1',
            'content': {'title': 'Primeros pasos con Laura'},
          },
          {
            'scope': 'section',
            'target_id': 'm1-s1',
            'content': {'title': 'Conociendo Python'},
          },
        ],
      );
      await mount(tester);

      expect(find.text('Primeros pasos con Laura'), findsOneWidget);
      // El módulo lleva su punto; la sección lo dice con palabras.
      expect(find.byType(EditedDot), findsOneWidget);
      expect(find.textContaining('Editada'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Módulo 1, Primeros pasos con Laura, 3 secciones',
        ),
        findsOneWidget,
      );
      // Por voz, la sección dice que tiene cambios del docente.
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Sección 1, Conociendo Python\..* Con cambios tuyos\.$'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('cada sección enseña lo que editó el docente', (tester) async {
      serve(
        items: [
          {
            'scope': 'section',
            'target_id': 'm1-s1',
            'content': {'title': 'Hola, Python', 'videos': <Object>[]},
          },
        ],
      );
      await mount(tester);

      expect(find.text('Hola, Python'), findsOneWidget);
      // Sin el video que quitó, y con su título nuevo también por voz.
      expect(
        find.bySemanticsLabel(
          'Sección 1, Hola, Python. 4 páginas, 6 preguntas, '
          'Cápsula, Ejemplo, Ejercicio, Laboratorio. Con cambios tuyos.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('cada sección dice qué contiene y cuánto', (tester) async {
      serve();
      await mount(tester);

      // Módulo 1, sección 1: cuatro páginas, un video, 2 + 4 preguntas...
      expect(
        find.bySemanticsLabel(
          'Sección 1, Conociendo Python. 4 páginas, 1 video, 6 preguntas, '
          'Cápsula, Ejemplo, Ejercicio, Laboratorio.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('una sección sin material lo dice en vez de quedar en blanco', (
      tester,
    ) async {
      serve();
      await mount(tester);

      // Se cierra el módulo 1 y se abre el 6, que aún no tiene contenido.
      await tester.tap(find.text('Preparación'));
      await settle(tester);
      expect(find.text('Conociendo Python'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Especialización y futuro'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Especialización y futuro'));
      await settle(tester);

      expect(find.text('Sin contenido'), findsWidgets);
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'^Sección 1, Diseño de interfaces de usuario\. '
            r'Sin contenido todavía\.$',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('en pantalla estrecha la sección se abre en otra pantalla', (
      tester,
    ) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Conociendo Python'));
      await settle(tester);

      expect(find.byType(TeacherSectionDetail), findsOneWidget);
      expect(find.text('Módulo 1 · Sección 1'), findsOneWidget);
    });

    testWidgets('en pantalla ancha la sección elegida se abre al lado', (
      tester,
    ) async {
      serve();
      await mount(tester, width: 1300);
      expect(find.text('Módulo 1 · Sección 1'), findsOneWidget);

      await tester.tap(find.text('Fundamentos de Python'));
      await settle(tester);
      await tester.tap(find.text('Sintaxis').first);
      await settle(tester);

      // Sigue en la misma pantalla, con el temario a la vista.
      expect(find.text('Módulo 2 · Sección 1'), findsOneWidget);
      expect(find.text('Preparación'), findsOneWidget);
      expect(
        tester
            .widget<TeacherSectionDetail>(find.byType(TeacherSectionDetail))
            .moduleNumber,
        2,
      );
    });
  });

  group('salir con cambios sin guardar', () {
    String titleText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).first).controller!.text;

    testWidgets('en pantalla estrecha la flecha de atrás pide confirmar', (
      tester,
    ) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Conociendo Python'));
      await settle(tester);

      // Sin cambios se vuelve sin preguntar nada.
      await tester.tap(find.byTooltip('Volver'));
      await settle(tester);
      expect(find.byType(TeacherSectionDetail), findsNothing);
      expect(find.text('¿Salir sin guardar?'), findsNothing);

      await tester.tap(find.text('Conociendo Python'));
      await settle(tester);
      await tester.enterText(find.byType(TextField).first, 'Mi borrador');
      await settle(tester);

      await tester.tap(find.byTooltip('Volver'));
      await settle(tester);
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await settle(tester);
      expect(find.byType(TeacherSectionDetail), findsOneWidget);
      expect(titleText(tester), 'Mi borrador');

      await tester.tap(find.byTooltip('Volver'));
      await settle(tester);
      await tester.tap(find.text('Salir sin guardar'));
      await settle(tester);
      expect(find.byType(TeacherSectionDetail), findsNothing);
      expect(find.text('Preparación'), findsOneWidget);
    });

    testWidgets('en pantalla ancha cambiar de sección pide confirmar', (
      tester,
    ) async {
      serve();
      await mount(tester, width: 1300);

      await tester.enterText(find.byType(TextField).first, 'Mi borrador');
      await settle(tester);

      await tester.tap(find.text('Fundamentos de Python'));
      await settle(tester);
      await tester.tap(find.text('Sintaxis').first);
      await settle(tester);
      expect(find.text('¿Salir sin guardar?'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await settle(tester);
      expect(find.text('Módulo 1 · Sección 1'), findsOneWidget);
      expect(titleText(tester), 'Mi borrador');

      await tester.tap(find.text('Sintaxis').first);
      await settle(tester);
      await tester.tap(find.text('Salir sin guardar'));
      await settle(tester);
      expect(find.text('Módulo 2 · Sección 1'), findsOneWidget);

      // La sección nueva empieza limpia: elegir otra no vuelve a preguntar.
      await tester.tap(find.text('Conociendo Python'));
      await settle(tester);
      expect(find.text('¿Salir sin guardar?'), findsNothing);
      expect(find.text('Módulo 1 · Sección 1'), findsOneWidget);
    });
  });

  group('las pestañas', () {
    testWidgets('llevan a las estadísticas y a los estudiantes', (
      tester,
    ) async {
      serve();
      await mount(tester);

      await tester.tap(find.text('Estadísticas'));
      await settle(tester);
      expect(find.byType(TeacherStatsScreen), findsOneWidget);
      expect(find.text('Todavía no hay actividad'), findsOneWidget);

      await tester.tap(find.text('Estudiantes'));
      await settle(tester);
      expect(find.byType(TeacherStudentsScreen), findsOneWidget);
      expect(find.textContaining('ningún estudiante'), findsOneWidget);
    });
  });
}
