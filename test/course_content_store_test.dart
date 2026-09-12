import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_json.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';

/// Comprueba que lo que el docente edita llega al estudiante, y que cuando el
/// servidor no está el curso se sigue viendo entero.
void main() {
  final store = CourseContentStore.instance;

  setUp(store.debugReset);
  tearDown(store.debugReset);

  void serverReturns(List<Map<String, dynamic>> items) {
    store.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'version': 'x', 'count': items.length, 'items': items}),
          200,
        ),
      ),
    );
  }

  group('sin nada editado', () {
    test('se ve el curso de fábrica, igual que siempre', () async {
      serverReturns([]);
      await store.refresh();

      final original = PythonCourseCatalog.section(1, 1)!;
      final shown = store.section(1, 1)!;

      expect(shown.title, original.title);
      expect(shown.reading?.pages.length, original.reading?.pages.length);
      expect(store.hasEdits, isFalse);
    });

    test('una sección que no existe sigue sin existir', () async {
      serverReturns([]);
      await store.refresh();

      expect(store.section(99, 99), isNull);
    });
  });

  group('lo que el docente cambia, el estudiante lo ve', () {
    test('cambiar el título de una sección', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'content': {'title': 'Python desde cero, por el profe'},
        },
      ]);
      await store.refresh();

      expect(store.section(1, 1)!.title, 'Python desde cero, por el profe');
      expect(store.isSectionEdited('m1-s1'), isTrue);
    });

    test('lo que no se toca se queda como estaba', () async {
      final original = PythonCourseCatalog.section(1, 1)!;

      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'content': {'title': 'Solo cambio el título'},
        },
      ]);
      await store.refresh();

      final shown = store.section(1, 1)!;
      expect(shown.title, 'Solo cambio el título');
      // La lectura, el quiz y los videos siguen intactos.
      expect(shown.reading?.pages.length, original.reading?.pages.length);
      expect(shown.quiz.length, original.quiz.length);
      expect(shown.videos.length, original.videos.length);
    });

    test('cambiar una lectura entera', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s2',
          'content': {
            'reading': {
              'title': 'Mi lectura',
              'intro': 'Escrita por el docente',
              'pages': [
                {
                  'title': 'Página única',
                  'summary': 'Resumen',
                  'blocks': [
                    {
                      'kind': 'paragraph',
                      'title': 'Un párrafo',
                      'body': 'El cuerpo del párrafo.',
                    },
                  ],
                },
              ],
            },
          },
        },
      ]);
      await store.refresh();

      final reading = store.section(1, 2)!.reading!;
      expect(reading.title, 'Mi lectura');
      expect(reading.pages.single.blocks.single.body, 'El cuerpo del párrafo.');
    });

    test('añadir una pregunta al quiz', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm2-s1',
          'content': {
            'quiz': [
              {
                'prompt': '¿Cuánto es 2+2?',
                'options': ['3', '4', '5'],
                'correctIndex': 1,
                'explanation': 'Suma básica',
              },
            ],
          },
        },
      ]);
      await store.refresh();

      final quiz = store.section(2, 1)!.quiz;
      expect(quiz.single.prompt, '¿Cuánto es 2+2?');
      expect(quiz.single.correctOption, '4');
    });

    test('cambiar el nombre de un módulo', () async {
      serverReturns([
        {
          'scope': 'module',
          'target_id': '1',
          'content': {'title': 'Arranque'},
        },
      ]);
      await store.refresh();

      expect(store.moduleTitle(1, 'Preparación'), 'Arranque');
      expect(store.moduleTitle(2, 'Fundamentos'), 'Fundamentos');
      expect(store.isModuleEdited(1), isTrue);
    });
  });

  group('una edición no puede hacer daño', () {
    test('no puede suplantar la identidad de otra sección', () async {
      // Aunque el JSON traiga otro id, otro módulo y otro número, la sección
      // sigue siendo la que es. Si no, una edición podría secuestrar otra.
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'content': {'id': 'm6-s3', 'moduleNumber': 6, 'number': 3},
        },
      ]);
      await store.refresh();

      final shown = store.section(1, 1)!;
      expect(shown.id, 'm1-s1');
      expect(shown.moduleNumber, 1);
      expect(shown.number, 1);
    });

    test('no puede inventar una sección que no está en el curso', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm9-s9',
          'content': {'title': 'Sección fantasma'},
        },
      ]);
      await store.refresh();

      expect(store.section(9, 9), isNull);
    });

    test('un contenido con basura no deja al estudiante sin sección', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'content': {
            'title': 12345,
            'objectives': 'esto debería ser una lista',
            'quiz': 'y esto también',
          },
        },
      ]);
      await store.refresh();

      final shown = store.section(1, 1)!;
      // El título no era texto, así que se queda el de fábrica.
      expect(shown.title, PythonCourseCatalog.section(1, 1)!.title);
      expect(shown.objectives, isEmpty);
      expect(shown.quiz, isEmpty);
    });

    test('una respuesta correcta fuera de rango no revienta el quiz', () async {
      serverReturns([
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'content': {
            'quiz': [
              {
                'prompt': 'Pregunta',
                'options': ['a', 'b'],
                'correctIndex': 7,
              },
            ],
          },
        },
      ]);
      await store.refresh();

      final question = store.section(1, 1)!.quiz.single;
      expect(question.correctIndex, 0);
      expect(() => question.correctOption, returnsNormally);
    });
  });

  group('cuando el servidor no está', () {
    test('el estudiante sigue viendo el curso completo', () async {
      store.debugUse(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async => throw const _SinRed()),
      );

      await store.refresh();

      // Este es el motivo de guardar solo los cambios y no el curso entero.
      final shown = store.section(1, 1)!;
      expect(shown.title, PythonCourseCatalog.section(1, 1)!.title);
      expect(shown.reading, isNotNull);
      expect(store.problem, isNotNull);
    });

    test('un error del servidor tampoco deja sin curso', () async {
      store.debugUse(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async => http.Response('boom', 500)),
      );

      await store.refresh();

      expect(store.section(3, 1), isNotNull);
      expect(store.problem, contains('500'));
    });
  });

  group('ida y vuelta', () {
    test('una sección convertida a JSON y de vuelta es la misma', () {
      final original = PythonCourseCatalog.section(1, 1)!;
      final copy = sectionFromJson(sectionToJson(original), original);

      expect(copy.title, original.title);
      expect(copy.summary, original.summary);
      expect(copy.objectives, original.objectives);
      expect(copy.reading?.pages.length, original.reading?.pages.length);
      expect(copy.quiz.length, original.quiz.length);
      expect(copy.videos.length, original.videos.length);
      expect(copy.hasLaboratory, original.hasLaboratory);
    });

    test('la ida y vuelta conserva el detalle de una lectura', () {
      final original = PythonCourseCatalog.section(1, 1)!;
      final copy = sectionFromJson(sectionToJson(original), original);

      final before = original.reading!.pages.first.blocks;
      final after = copy.reading!.pages.first.blocks;

      expect(after.length, before.length);
      for (var i = 0; i < before.length; i++) {
        expect(after[i].kind, before[i].kind);
        expect(after[i].title, before[i].title);
        expect(after[i].body, before[i].body);
        expect(after[i].items, before[i].items);
        expect(after[i].code, before[i].code);
      }
    });

    test('la ida y vuelta conserva las preguntas y su respuesta', () {
      // Una pregunta que pierda cuál es la correcta convierte el quiz en una
      // trampa, así que esto conviene comprobarlo de verdad.
      for (var module = 1; module <= 5; module++) {
        for (var number = 1; number <= 3; number++) {
          final original = PythonCourseCatalog.section(module, number);
          if (original == null || original.quiz.isEmpty) continue;

          final copy = sectionFromJson(sectionToJson(original), original);
          for (var i = 0; i < original.quiz.length; i++) {
            expect(copy.quiz[i].prompt, original.quiz[i].prompt);
            expect(copy.quiz[i].options, original.quiz[i].options);
            expect(copy.quiz[i].correctIndex, original.quiz[i].correctIndex);
          }
        }
      }
    });

    test('todo el curso sobrevive a la ida y vuelta', () {
      for (final module in PythonCourseCatalog.modules) {
        for (final section in module.sections) {
          expect(
            () => sectionFromJson(sectionToJson(section), section),
            returnsNormally,
            reason: 'falló en ${section.id}',
          );
        }
      }
    });
  });
}

class _SinRed implements Exception {
  const _SinRed();
}
