import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';

/// Ejecuta el cuerpo usando un cliente nuevo para cada petición HTTP de nivel superior.
/// TeacherModuleEditor utiliza http.get/http.post directamente, por eso se simulan
/// mediante runWithClient en vez de inyectar un cliente al widget.
typedef _RequestHandler = Future<http.Response> Function(http.Request request);

Future<T> _withMockHttp<T>(Future<T> Function() body, _RequestHandler handler) {
  return http.runWithClient(body, () => MockClient(handler));
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
  description: 'TextField con etiqueta "$label"',
);

Future<void> _mountEditor(WidgetTester tester, {String? moduleId}) async {
  await tester.pumpWidget(
    MaterialApp(home: TeacherModuleEditor(moduleId: moduleId)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterModuleName(WidgetTester tester, String name) async {
  final field = _field('Nombre del módulo');
  await tester.ensureVisible(field);
  await tester.enterText(field, name);
  await tester.pump();
}

void _setAuthenticatedStorage() {
  // AuthStorage puede usar una de estas claves según la versión del servicio.
  // Se preparan en memoria; no se accede al almacenamiento real del equipo.
  FlutterSecureStorage.setMockInitialValues({
    'token': 'test-token',
    'auth_token': 'test-token',
    'access_token': 'test-token',
    'accessToken': 'test-token',
    'authToken': 'test-token',
    'jwt': 'test-token',
    'user_token': 'test-token',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('TeacherModuleEditor: carga del módulo', () {
    testWidgets(
      'muestra el formulario y usa el título del catálogo cuando el módulo no existe',
      (tester) async {
        await _withMockHttp(() async {
          await _mountEditor(tester);

          expect(find.text('Nombre del módulo'), findsOneWidget);
          expect(find.text('Temas'), findsOneWidget);
          expect(find.text('Agregar tema'), findsOneWidget);
          expect(find.text('Guardar información del módulo'), findsOneWidget);
          expect(
            tester
                .widget<TextField>(_field('Nombre del módulo'))
                .controller!
                .text,
            PythonCourseCatalog.moduleByNumber(1)?.title ?? '',
          );
          expect(find.byType(CircularProgressIndicator), findsNothing);
        }, (request) async => http.Response('', 404));
      },
    );

    testWidgets('carga nombre y temas cuando el backend responde 200', (
      tester,
    ) async {
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '3');

          expect(
            tester
                .widget<TextField>(_field('Nombre del módulo'))
                .controller!
                .text,
            'Estructuras de datos',
          );
          expect(
            tester.widget<TextField>(_field('Tema 1')).controller!.text,
            'Listas',
          );
          expect(
            tester.widget<TextField>(_field('Tema 2')).controller!.text,
            'Diccionarios',
          );
        },
        (request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/api/modules/3'));
          return http.Response(
            jsonEncode({
              'name': 'Estructuras de datos',
              'topics': ['Listas', 'Diccionarios'],
            }),
            200,
          );
        },
      );
    });

    testWidgets(
      'muestra un aviso cuando el backend devuelve un error al cargar',
      (tester) async {
        await _withMockHttp(() async {
          await _mountEditor(tester, moduleId: '2');
          expect(find.text('No se pudo cargar el módulo'), findsOneWidget);
        }, (request) async => http.Response('Error', 500));
      },
    );

    testWidgets('muestra un aviso si falla la petición de carga', (
      tester,
    ) async {
      await _withMockHttp(() async {
        await _mountEditor(tester, moduleId: '2');
        expect(find.textContaining('Error:'), findsOneWidget);
      }, (request) async => throw http.ClientException('Fallo de red'));
    });
  });

  group('TeacherModuleEditor: edición de temas', () {
    testWidgets('permite agregar y eliminar temas', (tester) async {
      await _withMockHttp(() async {
        await _mountEditor(tester, moduleId: '1');

        expect(find.byIcon(Icons.delete), findsOneWidget);
        await _tapVisible(tester, find.text('Agregar tema'));
        expect(find.byIcon(Icons.delete), findsNWidgets(2));
        expect(_field('Tema 2'), findsOneWidget);

        await _tapVisible(tester, find.byIcon(Icons.delete).first);
        expect(find.byIcon(Icons.delete), findsOneWidget);
        expect(_field('Tema 1'), findsOneWidget);
      }, (request) async => http.Response('', 404));
    });
  });

  group('TeacherModuleEditor: validación y guardado', () {
    testWidgets('no guarda si el nombre del módulo está vacío', (tester) async {
      var postCount = 0;
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '1');
          await _enterModuleName(tester, '   ');
          await _tapVisible(
            tester,
            find.text('Guardar información del módulo'),
          );

          expect(
            find.text('El nombre del módulo es requerido'),
            findsOneWidget,
          );
          expect(postCount, 0);
        },
        (request) async {
          if (request.method == 'POST') postCount++;
          return http.Response('', 404);
        },
      );
    });

    testWidgets('avisa si no hay una sesión iniciada', (tester) async {
      var postCount = 0;
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '1');
          await _enterModuleName(tester, 'Mi módulo');
          await _tapVisible(
            tester,
            find.text('Guardar información del módulo'),
          );

          expect(
            find.text('Tu sesión no está iniciada. Vuelve a entrar.'),
            findsOneWidget,
          );
          expect(postCount, 0);
        },
        (request) async {
          if (request.method == 'POST') postCount++;
          return http.Response('', 404);
        },
      );
    });

    testWidgets('muestra un aviso si el servidor devuelve 401 al guardar', (
      tester,
    ) async {
      _setAuthenticatedStorage();
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '4');
          await _enterModuleName(tester, 'Módulo de prueba');
          await _tapVisible(
            tester,
            find.text('Guardar información del módulo'),
          );

          expect(
            find.text('Tu sesión caducó. Vuelve a entrar.'),
            findsOneWidget,
          );
          expect(find.byType(TeacherModuleEditor), findsOneWidget);
        },
        (request) async {
          if (request.method == 'POST') return http.Response('', 401);
          return http.Response('', 404);
        },
      );
    });

    testWidgets('muestra un aviso si la cuenta no tiene permiso para guardar', (
      tester,
    ) async {
      _setAuthenticatedStorage();
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '4');
          await _enterModuleName(tester, 'Módulo de prueba');
          await _tapVisible(
            tester,
            find.text('Guardar información del módulo'),
          );

          expect(
            find.text('Tu cuenta no puede editar el contenido del curso.'),
            findsOneWidget,
          );
        },
        (request) async {
          if (request.method == 'POST') return http.Response('', 403);
          return http.Response('', 404);
        },
      );
    });

    testWidgets(
      'muestra un aviso cuando el servidor rechaza el guardado con otro código',
      (tester) async {
        _setAuthenticatedStorage();
        await _withMockHttp(
          () async {
            await _mountEditor(tester, moduleId: '4');
            await _enterModuleName(tester, 'Módulo de prueba');
            await _tapVisible(
              tester,
              find.text('Guardar información del módulo'),
            );

            expect(find.text('Error al guardar módulo'), findsOneWidget);
          },
          (request) async {
            if (request.method == 'POST') return http.Response('', 500);
            return http.Response('', 404);
          },
        );
      },
    );

    testWidgets(
      'guarda el nombre y solo los temas no vacíos; devuelve el ID guardado',
      (tester) async {
        _setAuthenticatedStorage();
        final requests = <http.Request>[];
        late Future<String?> navigationResult;

        await _withMockHttp(
          () async {
            await tester.pumpWidget(
              MaterialApp(
                home: Builder(
                  builder: (context) => Scaffold(
                    body: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          navigationResult = Navigator.of(context).push<String>(
                            MaterialPageRoute<String>(
                              builder: (_) =>
                                  const TeacherModuleEditor(moduleId: '5'),
                            ),
                          );
                        },
                        child: const Text('Abrir editor'),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('Abrir editor'));
            await tester.pumpAndSettle();

            await _enterModuleName(tester, '  Módulo nuevo  ');
            await tester.enterText(_field('Tema 1'), '  Variables  ');
            await _tapVisible(tester, find.text('Agregar tema'));
            await tester.enterText(_field('Tema 2'), '   ');
            await _tapVisible(
              tester,
              find.text('Guardar información del módulo'),
            );

            expect(await navigationResult, '99');
            final post = requests.singleWhere(
              (request) => request.method == 'POST',
            );
            expect(post.url.path, endsWith('/api/modules/'));
            expect(post.headers['authorization'], 'Bearer test-token');
            final payload = jsonDecode(post.body) as Map<String, dynamic>;
            expect(payload['module_id'], '5');
            expect(payload['name'], 'Módulo nuevo');
            expect(payload['topics'], ['Variables']);
          },
          (request) async {
            requests.add(request);
            if (request.method == 'POST') {
              return http.Response(jsonEncode({'id': 99}), 201);
            }
            return http.Response('', 404);
          },
        );
      },
    );

    testWidgets('muestra un aviso si se produce una excepción al guardar', (
      tester,
    ) async {
      _setAuthenticatedStorage();
      await _withMockHttp(
        () async {
          await _mountEditor(tester, moduleId: '4');
          await _enterModuleName(tester, 'Módulo de prueba');
          await _tapVisible(
            tester,
            find.text('Guardar información del módulo'),
          );

          expect(find.textContaining('Error:'), findsOneWidget);
        },
        (request) async {
          if (request.method == 'POST') {
            throw http.ClientException('Fallo al guardar');
          }
          return http.Response('', 404);
        },
      );
    });
  });
}
