import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_info.dart';
import 'package:flutter_code4all/ui/courses/active_course_banner.dart';
import 'package:flutter_code4all/ui/courses/courses_gate.dart';
import 'package:flutter_code4all/ui/courses/student_courses_screen.dart';

class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-prueba';
}

const _general = {
  'id': 1,
  'title': 'Curso general de Code4All',
  'is_general': true,
  'teacher': null,
};

const _laura = {
  'id': 7,
  'title': 'Python 2026-1',
  'description': 'Grupo de la mañana',
  'is_general': false,
  'teacher': {'id': 30, 'nombre': 'Laura'},
};

const _pedro = {
  'id': 9,
  'title': 'Python nocturno',
  'is_general': false,
  'teacher': {'id': 31, 'nombre': 'Pedro'},
};

/// La ruta del estudiante empieza aquí: elegir en qué curso estudiar.
///
/// Se comprueba lo que vive el estudiante cuando las cosas no salen bien
/// —el servidor falla, no hay red, el código está vacío, no le dejan
/// salir— y lo que viaja al servidor cuando sí salen: a qué curso se une,
/// de cuál sale y que la lista se pide otra vez al volver. Si algo de esto
/// se rompe, el estudiante se queda sin poder entrar a estudiar.
void main() {
  final courses = MyCoursesStore.instance;
  final content = CourseContentStore.instance;
  final api = ApiService(baseUrl: 'http://servidor.de.prueba');

  late List<http.Request> sent;

  void serve(Future<http.Response> Function(http.Request request) handler) {
    sent = [];
    final client = MockClient((request) {
      sent.add(request);
      return handler(request);
    });
    courses.debugUse(api: api, client: client, auth: _FakeAuth());
    content.debugUse(api: api, client: client, auth: _FakeAuth());
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  final noEdits = {'version': '', 'count': 0, 'items': <Object>[]};

  Iterable<http.Request> requestsTo(String path, [String method = 'GET']) =>
      sent.where((r) => r.url.path == path && r.method == method);

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    courses.debugReset();
    content.debugReset();
    CourseAnalyticsStore.instance.debugReset();
  });

  tearDown(() async {
    await courses.select(null);
    courses.debugReset();
    content.debugReset();
    CourseAnalyticsStore.instance.debugReset();
  });

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(700, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget gate({WidgetBuilder? courseHome}) => MaterialApp(
    home: CoursesGate(
      withoutCourses: (_) => const Text('curso único'),
      withCourses: (_) => StudentCoursesScreen(
        courseHome:
            courseHome ?? (_) => const Scaffold(body: Text('ruta de módulos')),
      ),
    ),
  );

  group('la puerta de entrada', () {
    testWidgets('si el servidor falla, lo explica y deja volver a intentar', (
      tester,
    ) async {
      var failing = true;
      serve((request) async {
        if (failing) return http.Response('Error', 500);
        return json({
          'general_course_id': 1,
          'courses': [_general],
        });
      });

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      expect(
        find.text('El servidor no devolvió tus cursos (500).'),
        findsOneWidget,
      );
      expect(find.text('curso único'), findsNothing);
      expect(find.text('Mis cursos'), findsNothing);

      failing = false;
      await tester.tap(find.text('Volver a intentarlo'));
      await tester.pumpAndSettle();

      expect(find.text('Mis cursos'), findsOneWidget);
      expect(find.text('Curso general de Code4All'), findsOneWidget);
      expect(requestsTo('/api/courses/mine'), hasLength(2));
    });

    testWidgets('sin conexión se puede seguir en el curso general', (
      tester,
    ) async {
      serve((_) async => throw const _SinRed());

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo consultar tus cursos. Revisa tu conexión.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Entrar al curso general'));
      await tester.pumpAndSettle();

      expect(find.text('curso único'), findsOneWidget);
    });

    testWidgets('mientras llegan los cursos se avisa que está cargando', (
      tester,
    ) async {
      serve((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return json({'general_course_id': 1, 'courses': <Object>[]});
      });

      await tester.pumpWidget(gate());
      await tester.pump();

      expect(find.bySemanticsLabel('Cargando tus cursos'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Sin cursos todavía: se ve la lista vacía con la forma de unirse.
      expect(find.text('Mis cursos'), findsOneWidget);
      expect(find.text('Unirme a un curso'), findsOneWidget);
    });
  });

  group('unirse a un curso', () {
    testWidgets('con el código correcto entra y la lista lo muestra', (
      tester,
    ) async {
      var joined = false;
      serve((request) async {
        if (request.url.path == '/api/courses/join') {
          joined = true;
          return json(_laura);
        }
        return json({
          'general_course_id': 1,
          'courses': [_general, if (joined) _laura],
        });
      });
      bigScreen(tester);

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();
      expect(find.text('Python 2026-1'), findsNothing);

      await tester.tap(find.text('Unirme a un curso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  abc234 ');
      // Enviar desde el teclado, sin buscar el botón.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final join = requestsTo('/api/courses/join', 'POST').single;
      expect(jsonDecode(join.body), {'code': 'abc234'});
      expect(join.headers['Authorization'], 'Bearer token-de-prueba');

      // El diálogo se cierra, se confirma con texto y el curso aparece.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Te uniste a Python 2026-1.'), findsOneWidget);
      expect(find.text('Python 2026-1'), findsOneWidget);
      expect(find.text('Docente: Laura'), findsOneWidget);
      expect(find.text('Grupo de la mañana'), findsOneWidget);
    });

    testWidgets('sin código no se envía nada y se dice qué falta', (
      tester,
    ) async {
      serve(
        (_) async => json({
          'general_course_id': 1,
          'courses': [_general],
        }),
      );

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unirme a un curso'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Unirme'));
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe el código que te dio tu docente.'),
        findsOneWidget,
      );
      expect(requestsTo('/api/courses/join', 'POST'), isEmpty);

      // Cancelar cierra sin anunciar ningún curso nuevo.
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'mientras se envía el código, el botón dice que está entrando',
      (tester) async {
        serve((request) async {
          if (request.url.path == '/api/courses/join') {
            await Future<void>.delayed(const Duration(milliseconds: 300));
            return json(_laura);
          }
          return json({
            'general_course_id': 1,
            'courses': [_general],
          });
        });

        await tester.pumpWidget(gate());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Unirme a un curso'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ABC234');
        await tester.tap(find.text('Unirme'));
        await tester.pump();

        expect(find.text('Entrando…'), findsOneWidget);
        // No se puede cancelar ni enviar dos veces a mitad de camino.
        final cancel = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Cancelar'),
        );
        expect(cancel.onPressed, isNull);

        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();
        expect(find.text('Te uniste a Python 2026-1.'), findsOneWidget);
      },
    );
  });

  group('salir de un curso', () {
    testWidgets('pide confirmación y, al confirmar, sale y lo quita', (
      tester,
    ) async {
      var left = false;
      serve((request) async {
        if (request.method == 'DELETE') {
          left = true;
          return json({'left': true});
        }
        return json({
          'general_course_id': 1,
          'courses': [_general, if (!left) _laura],
        });
      });
      bigScreen(tester);

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      // Del curso general no se sale: es de todos.
      expect(
        find.byTooltip('Salir de Curso general de Code4All'),
        findsNothing,
      );

      // Primero se arrepiente.
      await tester.tap(find.byTooltip('Salir de Python 2026-1'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de Python 2026-1?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(requestsTo('/api/courses/7/enrollment', 'DELETE'), isEmpty);
      expect(find.text('Python 2026-1'), findsOneWidget);

      // Luego sí sale.
      await tester.tap(find.byTooltip('Salir de Python 2026-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir del curso'));
      await tester.pumpAndSettle();

      expect(requestsTo('/api/courses/7/enrollment', 'DELETE'), hasLength(1));
      expect(find.text('Python 2026-1'), findsNothing);
      expect(find.text('Curso general de Code4All'), findsOneWidget);
    });

    testWidgets('si el servidor no lo deja, se dice por qué', (tester) async {
      serve((request) async {
        if (request.method == 'DELETE') {
          return json({
            'detail': 'No puedes salir de un curso con una evaluación abierta.',
          }, 409);
        }
        return json({
          'general_course_id': 1,
          'courses': [_general, _laura],
        });
      });
      bigScreen(tester);

      await tester.pumpWidget(gate());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Salir de Python 2026-1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir del curso'));
      await tester.pumpAndSettle();

      expect(
        find.text('No puedes salir de un curso con una evaluación abierta.'),
        findsOneWidget,
      );
      // Sigue en la lista: no salió.
      expect(find.text('Python 2026-1'), findsOneWidget);
    });
  });

  testWidgets('al volver de estudiar, la lista se pide otra vez', (
    tester,
  ) async {
    var title = 'Python 2026-1';
    serve((request) async {
      if (request.url.path == '/api/courses/mine') {
        return json({
          'general_course_id': 1,
          'courses': [
            _general,
            {..._laura, 'title': title},
          ],
        });
      }
      return json(noEdits);
    });
    bigScreen(tester);

    await tester.pumpWidget(gate());
    await tester.pumpAndSettle();
    final before = requestsTo('/api/courses/mine').length;

    await tester.tap(find.text('Python 2026-1'));
    await tester.pumpAndSettle();
    expect(find.text('ruta de módulos'), findsOneWidget);
    expect(courses.active?.id, 7);

    // Mientras estudiaba, el docente le cambió el nombre al curso.
    title = 'Python 2026-1 (renovado)';
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(requestsTo('/api/courses/mine').length, before + 1);
    expect(find.text('Python 2026-1 (renovado)'), findsOneWidget);
    // El curso abierto queda con su versión nueva.
    expect(courses.active?.title, 'Python 2026-1 (renovado)');
  });

  group('la franja del curso abierto', () {
    Widget stack() => MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Text('Mis cursos (inicio)'),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Scaffold(
                              body: Column(
                                children: [
                                  ActiveCourseBanner(),
                                  Text('capítulo'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        child: const Text('abrir capítulo'),
                      ),
                    ),
                  ),
                ),
                child: const Text('abrir módulo'),
              ),
            ],
          ),
        ),
      ),
    );

    testWidgets('sin curso abierto no ocupa sitio', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActiveCourseBanner())),
      );

      expect(find.text('Mis cursos'), findsNothing);
      expect(tester.getSize(find.byType(ActiveCourseBanner)), Size.zero);
    });

    testWidgets('dice en qué curso se está y lleva de vuelta a «Mis cursos»', (
      tester,
    ) async {
      serve((_) async => json(noEdits));
      await courses.select(CourseInfo.fromJson(Map.of(_laura)));

      await tester.pumpWidget(stack());
      await tester.tap(find.text('abrir módulo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('abrir capítulo'));
      await tester.pumpAndSettle();

      expect(find.text('Python 2026-1 · Docente: Laura'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Estás en el curso Python 2026-1. Docente: Laura.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);

      await tester.tap(find.text('Mis cursos'));
      await tester.pumpAndSettle();

      // Vuelve hasta el principio, no solo una pantalla atrás.
      expect(find.text('Mis cursos (inicio)'), findsOneWidget);
      expect(find.text('abrir capítulo'), findsNothing);
      expect(find.text('capítulo'), findsNothing);
    });

    testWidgets('en el curso general se dice que es para todos', (
      tester,
    ) async {
      serve((_) async => json(noEdits));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ActiveCourseBanner())),
      );

      // Se redibuja sola al cambiar de curso.
      await courses.select(CourseInfo.fromJson(Map.of(_general)));
      await tester.pump();

      expect(
        find.text('Curso general de Code4All · Para todos los estudiantes'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.public), findsOneWidget);
    });
  });

  group('lo que el almacén de cursos manda al servidor', () {
    test('renovar el código lo pide al curso y devuelve el nuevo', () async {
      serve((request) async {
        if (request.url.path == '/api/courses/7/join-code') {
          return json({..._laura, 'join_code': 'NUEVO9'});
        }
        return json({
          'general_course_id': 1,
          'courses': [_laura],
        });
      });

      final renewed = await courses.renewCode(
        CourseInfo.fromJson(Map.of(_laura)),
      );

      expect(renewed.joinCode, 'NUEVO9');
      expect(requestsTo('/api/courses/7/join-code', 'POST'), hasLength(1));
      // Después se vuelve a pedir la lista, que ya trae el código nuevo.
      expect(requestsTo('/api/courses/mine'), hasLength(1));
    });

    test('borrar el curso abierto deja de mostrarlo como abierto', () async {
      serve((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.url.path == '/api/courses/mine') {
          return json({'general_course_id': 1, 'courses': <Object>[]});
        }
        return json(noEdits);
      });
      final course = CourseInfo.fromJson(Map.of(_pedro));
      await courses.select(course);
      expect(courses.active?.id, 9);

      await courses.delete(course);

      expect(requestsTo('/api/courses/9', 'DELETE'), hasLength(1));
      expect(courses.active, isNull);
      expect(content.courseId, isNull);
    });

    test('borrar otro curso no cierra el que se está usando', () async {
      serve((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        if (request.url.path == '/api/courses/mine') {
          return json({
            'general_course_id': 1,
            'courses': [_laura],
          });
        }
        return json(noEdits);
      });
      await courses.select(CourseInfo.fromJson(Map.of(_laura)));

      await courses.delete(CourseInfo.fromJson(Map.of(_pedro)));

      expect(courses.active?.id, 7);
    });

    test(
      'si el curso abierto desaparece de la lista, deja de estar abierto',
      () async {
        serve((request) async {
          if (request.url.path == '/api/courses/mine') {
            return json({
              'general_course_id': 1,
              'courses': [_general],
            });
          }
          return json(noEdits);
        });
        await courses.select(CourseInfo.fromJson(Map.of(_laura)));

        await courses.refresh();

        expect(courses.active, isNull);
      },
    );

    test('sin servidor la acción dice que no responde', () async {
      serve((_) async => throw const _SinRed());

      await expectLater(
        courses.join('ABC234'),
        throwsA(
          isA<CourseActionException>()
              .having(
                (e) => e.message,
                'message',
                'El servidor no responde. Vuelve a intentarlo en un momento.',
              )
              .having(
                (e) => e.toString(),
                'toString',
                'El servidor no responde. Vuelve a intentarlo en un momento.',
              ),
        ),
      );
    });

    test(
      'sin detalle del servidor se explica con el código de error',
      () async {
        serve((request) async {
          if (request.url.path == '/api/courses/join') {
            return http.Response('Unauthorized', 401);
          }
          return http.Response('<html>Bad gateway</html>', 502);
        });

        await expectLater(
          courses.join('ABC234'),
          throwsA(
            isA<CourseActionException>().having(
              (e) => e.message,
              'message',
              'Tu sesión caducó. Vuelve a iniciar sesión.',
            ),
          ),
        );
        await expectLater(
          courses.create(title: 'Python'),
          throwsA(
            isA<CourseActionException>().having(
              (e) => e.message,
              'message',
              'No se pudo completar (error 502).',
            ),
          ),
        );
      },
    );

    test('una respuesta sin curso no se hace pasar por uno', () async {
      serve((request) async {
        if (request.method == 'DELETE') return json({'removed': true});
        return json({'general_course_id': 1, 'courses': <Object>[]});
      });

      // Sacar a un estudiante no devuelve un curso, y no debe fallar por eso.
      await courses.removeStudent(CourseInfo.fromJson(Map.of(_laura)), 5);

      expect(requestsTo('/api/courses/7/students/5', 'DELETE'), hasLength(1));
    });

    test('un curso sin nombre de docente se presenta igual', () {
      final course = CourseInfo.fromJson({
        'id': 3,
        'teacher': {'id': 4, 'nombre': '  '},
      });

      expect(course.title, 'Curso');
      expect(course.ownerLabel, 'Curso de un docente');
      expect(course.teacherId, 4);
    });
  });
}

/// Lo que lanza el cliente cuando no hay red. No hace falta la excepción de
/// `dart:io`: al almacén le basta con que la petición falle.
class _SinRed implements Exception {
  const _SinRed();
}
