import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_json.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';

class _FakeAuth extends AuthStorage {
  _FakeAuth([this.token = 'token-del-docente']);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

/// Lo que el docente cambia del temario viaja al servidor y vuelve al
/// estudiante; aquí se comprueba la ida.
///
/// Importa qué se pide (método y dirección, en el curso correcto), qué ve la
/// pantalla en cuanto se guarda y, sobre todo, qué se le dice al docente
/// cuando no se pudo: su texto no se puede perder en silencio. También se
/// comprueba que una edición ilegible no deja al estudiante sin sección.
void main() {
  final store = CourseContentStore.instance;
  final api = ApiService(baseUrl: 'http://servidor.de.prueba');

  late List<http.Request> sent;

  void serve(
    Future<http.Response> Function(http.Request request) handler, {
    AuthStorage? auth,
  }) {
    sent = [];
    store.debugUse(
      api: api,
      auth: auth ?? _FakeAuth(),
      client: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
    );
  }

  http.Response ok([Object body = const {}]) =>
      http.Response(jsonEncode(body), 200);

  final noEdits = {'version': '', 'count': 0, 'items': <Object>[]};

  setUp(store.debugReset);
  tearDown(store.debugReset);

  group('guardar y deshacer', () {
    test(
      'cambiar el nombre de un módulo se guarda y se ve al momento',
      () async {
        serve((_) async => ok());
        var avisos = 0;
        void escucha() => avisos++;
        store.addListener(escucha);
        addTearDown(() => store.removeListener(escucha));

        await store.saveModuleTitle(2, 'Fundamentos, según Laura');

        final put = sent.single;
        expect(put.method, 'PUT');
        expect(put.url.path, '/api/course/overrides/module/2');
        expect(put.headers['Authorization'], 'Bearer token-del-docente');
        expect(put.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(put.body), {
          'content': {'title': 'Fundamentos, según Laura'},
        });

        expect(store.moduleTitle(2, 'de fábrica'), 'Fundamentos, según Laura');
        expect(store.isModuleEdited(2), isTrue);
        expect(store.editCount, 1);
        expect(avisos, greaterThan(0));
      },
    );

    test('devolver una sección a la de fábrica quita la edición', () async {
      serve((_) async => http.Response('', 204));
      final original = PythonCourseCatalog.section(1, 1)!;
      store.debugSeed({
        CourseContentStore.sectionKey(original.id): {
          'title': 'Editada por el docente',
          '__updated_by': 'Laura',
        },
      });
      expect(store.section(1, 1)!.title, 'Editada por el docente');
      expect(
        store.editedBy(CourseContentStore.sectionKey(original.id)),
        'Laura',
      );

      await store.revertSection(original.id);

      final delete = sent.single;
      expect(delete.method, 'DELETE');
      expect(delete.url.path, '/api/course/overrides/section/${original.id}');
      // Un DELETE no lleva cuerpo, así que no dice que manda JSON.
      expect(delete.headers.containsKey('Content-Type'), isFalse);
      expect(store.section(1, 1)!.title, original.title);
      expect(store.isSectionEdited(original.id), isFalse);
      expect(
        store.editedBy(CourseContentStore.sectionKey(original.id)),
        isNull,
      );
    });

    test('devolver el nombre de un módulo al de fábrica', () async {
      serve((_) async => http.Response('', 204));
      store.debugSeed({
        CourseContentStore.moduleKey(3): {'title': 'Control, versión Laura'},
      });

      await store.revertModuleTitle(3);

      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/api/course/overrides/module/3');
      expect(
        store.moduleTitle(3, 'Estructuras de control'),
        'Estructuras de control',
      );
      expect(store.hasEdits, isFalse);
    });

    test('en un curso de docente se guarda en ese curso', () async {
      serve((request) async => request.method == 'GET' ? ok(noEdits) : ok());
      await store.useCourse(7);
      expect(store.courseId, 7);
      expect(store.isLoaded, isTrue);

      await store.saveModuleTitle(1, 'Primeros pasos');
      await store.revertModuleTitle(1);

      final writes = sent.where((r) => r.method != 'GET').toList();
      expect(writes.map((r) => '${r.method} ${r.url.path}'), [
        'PUT /api/courses/7/overrides/module/1',
        'DELETE /api/courses/7/overrides/module/1',
      ]);
    });
  });

  group('cuando no se puede guardar, se dice por qué', () {
    Future<void> expectMessage(
      Future<void> Function() action,
      String message,
    ) async {
      await expectLater(
        action(),
        throwsA(
          isA<CourseEditException>()
              .having((e) => e.message, 'message', message)
              .having((e) => e.toString(), 'toString', message),
        ),
      );
    }

    test('sin sesión no se llega a enviar nada', () async {
      serve((_) async => ok(), auth: _FakeAuth(null));

      await expectMessage(
        () => store.saveModuleTitle(1, 'Nuevo'),
        'Tu sesión no está iniciada. Vuelve a entrar para poder editar.',
      );
      expect(sent, isEmpty);
      expect(store.isModuleEdited(1), isFalse);
    });

    test('sesión caducada', () async {
      serve((_) async => http.Response('', 401));

      await expectMessage(
        () => store.revertSection('m1-s1'),
        'Tu sesión caducó. Vuelve a iniciar sesión para seguir editando.',
      );
    });

    test('el curso general solo lo edita la coordinación', () async {
      serve((_) async => http.Response('', 403));

      await expectMessage(
        () => store.saveModuleTitle(1, 'Nuevo'),
        'El curso general solo lo edita la coordinación. Edita uno de tus '
        'cursos.',
      );
      // Lo que no se guardó no se muestra como si estuviera guardado.
      expect(store.isModuleEdited(1), isFalse);
    });

    test('el curso de otro docente no se puede editar', () async {
      serve(
        (request) async =>
            request.method == 'GET' ? ok(noEdits) : http.Response('', 403),
      );
      await store.useCourse(9);

      await expectMessage(
        () => store.revertModuleTitle(1),
        'Solo el docente de este curso puede editarlo.',
      );
    });

    test('una sección demasiado grande', () async {
      serve((_) async => http.Response('', 413));

      await expectMessage(
        () => store.saveSection(PythonCourseCatalog.section(1, 1)!),
        'Esta sección es demasiado grande para guardarla. Acorta algún texto.',
      );
    });

    test('cualquier otro error del servidor trae su código', () async {
      serve((_) async => http.Response('', 500));

      await expectMessage(
        () => store.saveModuleTitle(1, 'Nuevo'),
        'No se pudo guardar (error 500).',
      );
    });

    test('sin servidor, el texto sigue en pantalla', () async {
      serve((_) async => throw http.ClientException('sin red'));

      await expectMessage(
        () => store.revertModuleTitle(1),
        'No se pudo guardar: el servidor no responde. '
        'Tu texto sigue en pantalla, vuelve a intentarlo.',
      );
    });
  });

  group('cargar una sola vez', () {
    test('ensureLoaded pide lo editado la primera vez y nada más', () async {
      serve((_) async => ok(noEdits));

      await store.ensureLoaded();
      await store.ensureLoaded();

      expect(sent, hasLength(1));
      expect(store.isLoaded, isTrue);
    });

    test('un almacén para pruebas usa el cliente que se le da', () async {
      final requests = <Uri>[];
      final own = CourseContentStore.forTest(
        api: api,
        client: MockClient((request) async {
          requests.add(request.url);
          return ok(noEdits);
        }),
      );

      await own.refresh();

      expect(requests.single.path, '/api/course/overrides');
      expect(own.isLoaded, isTrue);
      expect(own.problem, isNull);
      // Es otro almacén: el de toda la aplicación no se entera.
      expect(store.isLoaded, isFalse);
    });

    test('un almacén nuevo, sin nada cargado, enseña el curso de fábrica', () {
      final fresh = CourseContentStore.forTest();

      expect(fresh.isLoaded, isFalse);
      expect(fresh.courseId, isNull);
      expect(fresh.hasEdits, isFalse);
      expect(
        fresh.section(1, 1)!.title,
        PythonCourseCatalog.section(1, 1)!.title,
      );
    });
  });

  test('una edición ilegible deja ver la sección de fábrica', () {
    final original = PythonCourseCatalog.section(2, 1)!;
    store.debugSeed({
      CourseContentStore.sectionKey(original.id): {
        // Un mapa con claves que no son texto no se puede leer como sección.
        'reading': {1: 'basura'},
      },
    });

    final shown = store.section(2, 1)!;

    expect(shown.title, original.title);
    expect(shown.reading?.pages.length, original.reading?.pages.length);
  });

  test('el número de actividades de cada sección coincide con su ruta', () {
    // La portada cuenta las actividades con `activityCount` y la ruta las
    // arma el lanzador: si no coinciden, el porcentaje miente.
    for (final module in PythonCourseCatalog.modules) {
      for (final section in module.sections) {
        expect(
          section.activityCount,
          SectionActivityLauncher.activitiesFor(section).length,
          reason: section.id,
        );
        if (section.exercise != null) {
          expect(
            section.exercise!.hasPairs || section.exercise!.hasQuestions,
            !section.exercise!.isEmpty,
            reason: section.id,
          );
        }
      }
    }
  });

  test('un bloque de código sin descripción se nombra al leerlo', () {
    final block = readingBlockFromJson({
      'kind': 'code',
      'title': 'Suma',
      'code': 'print(1 + 1)',
    });

    expect(block.codeCaption, isNull);
    expect(block.spokenText, 'Suma\nEjemplo de código en Python.');
  });
}
