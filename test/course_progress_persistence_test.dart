import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/services/course_progress_store.dart';

/// El avance del estudiante tiene que sobrevivir al cierre de la aplicación
/// y no mezclarse entre cursos.
///
/// Se comprueba que al abrir un curso se recupera lo que ya llevaba en él
/// —y solo en él—, que un avance guardado ilegible no impide seguir
/// estudiando, que lo nuevo se escribe en la clave de ese curso y que cada
/// actividad terminada se avisa una sola vez a quien lleva las estadísticas.
void main() {
  final store = CourseProgressStore.instance;
  const storage = FlutterSecureStorage();

  String key(String sectionId, CourseActivityKind kind) =>
      CourseProgressStore.activityKey(sectionId, kind);

  tearDown(() async {
    store.reportCompletionsTo(null);
    await store.useCourse(null);
    await store.resetSection('m1-s1', CourseActivityKind.values);
  });

  test('cada curso recupera su propio avance guardado', () async {
    FlutterSecureStorage.setMockInitialValues({
      'course_progress_completed': jsonEncode([
        key('m1-s1', CourseActivityKind.video),
      ]),
      'course_progress_completed_c42': jsonEncode([
        key('m1-s1', CourseActivityKind.lectura),
        key('m1-s1', CourseActivityKind.quiz),
        5, // lo que no es texto se ignora
      ]),
    });

    await store.useCourse(42);

    expect(store.courseId, 42);
    expect(store.isLoaded, isTrue);
    expect(store.isCompleted('m1-s1', CourseActivityKind.lectura), isTrue);
    expect(store.isCompleted('m1-s1', CourseActivityKind.quiz), isTrue);
    // Lo del curso general no se cuela en el del docente.
    expect(store.isCompleted('m1-s1', CourseActivityKind.video), isFalse);

    await store.useCourse(null);

    expect(store.isCompleted('m1-s1', CourseActivityKind.video), isTrue);
    expect(store.isCompleted('m1-s1', CourseActivityKind.lectura), isFalse);
  });

  test('un avance guardado ilegible no impide estudiar', () async {
    FlutterSecureStorage.setMockInitialValues({
      'course_progress_completed_c43': 'esto no es una lista',
    });

    await store.useCourse(43);

    expect(store.isLoaded, isTrue);
    expect(store.completedCount('m1-s1', CourseActivityKind.values), 0);

    // Y se puede seguir completando actividades con normalidad.
    await store.markCompleted('m1-s1', CourseActivityKind.capsula);
    expect(store.isCompleted('m1-s1', CourseActivityKind.capsula), isTrue);
  });

  test('lo completado se guarda en la clave del curso abierto', () async {
    FlutterSecureStorage.setMockInitialValues({});
    await store.useCourse(44);

    await store.markCompleted('m1-s1', CourseActivityKind.ejemplo);

    final saved = await storage.read(key: 'course_progress_completed_c44');
    expect(jsonDecode(saved!), [key('m1-s1', CourseActivityKind.ejemplo)]);
    expect(await storage.read(key: 'course_progress_completed'), isNull);
  });

  test('cada actividad terminada se registra una sola vez', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final reported = <String>[];
    store.reportCompletionsTo((sectionId, kind) async {
      reported.add('$sectionId:${kind.name}');
    });

    await store.markCompleted('m1-s1', CourseActivityKind.lectura);
    await store.markCompleted('m1-s1', CourseActivityKind.lectura);
    await store.markCompleted('m1-s1', CourseActivityKind.quiz);

    expect(reported, ['m1-s1:lectura', 'm1-s1:quiz']);

    // Sin nadie a quien avisar, completar sigue funcionando.
    store.reportCompletionsTo(null);
    await store.markCompleted('m1-s1', CourseActivityKind.video);
    expect(reported, hasLength(2));
    expect(store.isCompleted('m1-s1', CourseActivityKind.video), isTrue);
  });
}
