import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_progress.dart';

/// Comprueba que el porcentaje de las circunferencias del mapa sale del
/// progreso real y no de un número escrito a mano.
///
/// El almacén de progreso es un único objeto compartido por toda la app, así
/// que cada prueba limpia lo que ensucia. Si no, una prueba dejaría la sección
/// completada y la siguiente vería un progreso que no puso.
void main() {
  final store = CourseProgressStore.instance;

  List<CourseActivityKind> activitiesOf(int module, int section) =>
      SectionActivityLauncher.activitiesFor(
        PythonCourseCatalog.section(module, section)!,
      );

  String idOf(int module, int section) =>
      PythonCourseCatalog.section(module, section)!.id;

  Future<void> reset(int module, int section) =>
      store.resetSection(idOf(module, section), activitiesOf(module, section));

  group('el porcentaje refleja lo que se ha hecho', () {
    tearDown(() => reset(1, 1));

    test('sin nada hecho, cero', () async {
      await reset(1, 1);
      expect(sectionProgress(1, 1), 0);
    });

    test('completar una actividad sube el porcentaje en su parte', () async {
      await reset(1, 1);
      final total = activitiesOf(1, 1).length;

      await store.markCompleted(idOf(1, 1), CourseActivityKind.lectura);

      expect(sectionProgress(1, 1), closeTo(1 / total, 0.0001));
    });

    test('completarlas todas da el cien por cien', () async {
      await reset(1, 1);
      for (final kind in activitiesOf(1, 1)) {
        await store.markCompleted(idOf(1, 1), kind);
      }

      expect(sectionProgress(1, 1), 1.0);
    });

    test('cada sección cuenta sobre sus propias actividades', () async {
      // La sección 3 del módulo 1 no tiene ejemplo, así que tiene una
      // actividad menos. Completar una debe valer más que en una de ocho.
      await reset(1, 1);
      await reset(1, 3);

      await store.markCompleted(idOf(1, 1), CourseActivityKind.lectura);
      await store.markCompleted(idOf(1, 3), CourseActivityKind.lectura);

      expect(activitiesOf(1, 3).length, lessThan(activitiesOf(1, 1).length));
      expect(sectionProgress(1, 3), greaterThan(sectionProgress(1, 1)));

      await reset(1, 3);
    });

    test('el progreso de una sección no contamina a otra', () async {
      await reset(1, 1);
      await reset(1, 2);

      await store.markCompleted(idOf(1, 1), CourseActivityKind.lectura);

      expect(sectionProgress(1, 2), 0);
    });
  });

  group('secciones sin contenido', () {
    test('el módulo 6 no inventa avance: todavía no tiene actividades', () {
      // Es lo honesto. Enseñar un 30% de algo que no se puede hacer sería
      // mentirle al estudiante.
      for (var section = 1; section <= 3; section++) {
        expect(sectionProgress(6, section), 0);
      }
    });

    test('una sección que no existe da cero en lugar de reventar', () {
      expect(sectionProgress(99, 99), 0);
    });
  });

  group('lo que oye quien navega por voz', () {
    tearDown(() => reset(2, 1));

    test('dice qué sección es, no solo un porcentaje suelto', () async {
      await reset(2, 1);
      final label = sectionProgressLabel(2, 1);

      expect(label, contains('Sección 1'));
      expect(label, contains(PythonCourseCatalog.section(2, 1)!.boxTitle));
    });

    test('dice cuántas actividades van de cuántas', () async {
      await reset(2, 1);
      final total = activitiesOf(2, 1).length;

      await store.markCompleted(idOf(2, 1), CourseActivityKind.lectura);

      expect(sectionProgressLabel(2, 1), contains('1 de $total actividades'));
    });

    test('avisa cuando la sección todavía no tiene actividades', () {
      expect(sectionProgressLabel(6, 1), contains('sin actividades'));
    });

    test('dos secciones distintas no suenan igual', () {
      expect(sectionProgressLabel(2, 1), isNot(sectionProgressLabel(2, 2)));
    });
  });

  group('la circunferencia se entera sola', () {
    tearDown(() => reset(3, 1));

    // La circunferencia se redibuja porque un ListenableBuilder escucha al
    // almacén. Aquí se comprueba la mitad que es nuestra —que el almacén
    // avise— sin montar un árbol de widgets: al hacerlo, el almacenamiento
    // seguro intenta su llamada nativa y tumba el proceso de pruebas.
    test(
      'el almacén avisa a quien escuche al completar una actividad',
      () async {
        await reset(3, 1);

        var avisos = 0;
        void escucha() => avisos++;
        store.addListener(escucha);
        addTearDown(() => store.removeListener(escucha));

        final antes = sectionProgress(3, 1);
        await store.markCompleted(idOf(3, 1), CourseActivityKind.lectura);

        expect(avisos, greaterThan(0), reason: 'sin aviso, nada se redibuja');
        expect(sectionProgress(3, 1), greaterThan(antes));
      },
    );

    test('completar lo ya completado no avisa dos veces', () async {
      await reset(3, 1);
      await store.markCompleted(idOf(3, 1), CourseActivityKind.lectura);

      var avisos = 0;
      void escucha() => avisos++;
      store.addListener(escucha);
      addTearDown(() => store.removeListener(escucha));

      await store.markCompleted(idOf(3, 1), CourseActivityKind.lectura);

      expect(avisos, 0, reason: 'redibujar sin cambios es trabajo tirado');
    });
  });
}
