import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/ui/director/director_content_screen.dart';
import 'package:flutter_code4all/ui/director/director_teachers_screen.dart';
import 'package:flutter_code4all/ui/director/director_widgets.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';
import 'package:flutter_code4all/ui/director/teacher_detail_screen.dart';

/// Comprueba lo que ve la dirección.
///
/// Lo que más importa aquí es que la pantalla **no se calle lo incómodo**: un
/// docente que trabaja y al que nadie ha valorado, y una aprobación que el
/// docente dejó atrás al cambiar la sección. Las dos cosas son fáciles de
/// esconder en un panel bonito, y esconderlas lo vuelve inútil.
void main() {
  final store = DirectorOversightStore.instance;

  setUp(store.debugReset);
  tearDown(store.debugReset);

  TeacherSummary teacher(
    String name, {
    int edits = 0,
    int reviews = 0,
    int? lastScore,
    double? avgScore,
    DateTime? lastEdit,
  }) => TeacherSummary(
    userId: name.hashCode.abs() % 1000,
    name: name,
    email: '${name.toLowerCase()}@uv.edu.co',
    edits: edits,
    reviews: reviews,
    lastScore: lastScore,
    avgScore: avgScore,
    lastEdit: lastEdit,
  );

  ContentVerdict verdict(
    String sectionId, {
    required bool approved,
    bool outdated = false,
    String comment = '',
  }) => ContentVerdict(
    sectionId: sectionId,
    status: approved ? 'aprobado' : 'observado',
    comment: comment,
    outdated: outdated,
    reviewedAt: DateTime.now(),
  );

  Widget wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Scaffold(body: child),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('lista de docentes', () {
    testWidgets('sin docentes lo dice, no deja la pantalla en blanco', (
      tester,
    ) async {
      store.debugSeed(teachers: []);

      await tester.pumpWidget(wrap(const DirectorTeachersScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('No hay docentes registrados'), findsOneWidget);
    });

    testWidgets('avisa de quien trabaja sin recibir respuesta', (tester) async {
      tester.view.physicalSize = const Size(500, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      store.debugSeed(
        teachers: [
          teacher('Ana', edits: 12, reviews: 2, lastScore: 4, avgScore: 4.0),
          teacher('Mateo', edits: 20, reviews: 0),
        ],
      );

      await tester.pumpWidget(wrap(const DirectorTeachersScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('espera tu respuesta'), findsOneWidget);
      expect(find.text('Sin valorar'), findsWidgets);
    });

    testWidgets('quien espera respuesta sale antes que el resto', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      store.debugSeed(
        teachers: [
          teacher('Ana', edits: 5, reviews: 3, lastScore: 5, avgScore: 5.0),
          teacher('Zoe', edits: 9, reviews: 0),
        ],
      );

      await tester.pumpWidget(wrap(const DirectorTeachersScreen()));
      await settle(tester);

      // Zoe trabaja y nadie le ha dicho nada: va arriba aunque sea la ultima
      // por orden alfabetico.
      final zoe = tester.getTopLeft(find.text('Zoe')).dy;
      final ana = tester.getTopLeft(find.text('Ana')).dy;
      expect(zoe, lessThan(ana));
    });

    testWidgets('un docente sin editar nada también aparece', (tester) async {
      tester.view.physicalSize = const Size(500, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Es justo a quien hay que buscar: en una lista de "activos" no saldria.
      store.debugSeed(teachers: [teacher('Nuevo')]);

      await tester.pumpWidget(wrap(const DirectorTeachersScreen()));
      await settle(tester);

      expect(find.text('Nuevo'), findsOneWidget);
      expect(find.text('Sin editar nada'), findsOneWidget);
    });

    testWidgets('cabe a 320 px con el texto al doble', (tester) async {
      tester.view.physicalSize = const Size(320, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      store.debugSeed(
        teachers: [
          teacher('Ana', edits: 12, reviews: 2, lastScore: 4, avgScore: 4.0),
          teacher('Mateo', edits: 20, reviews: 0),
        ],
      );

      await tester.pumpWidget(
        wrap(const DirectorTeachersScreen(), textScale: 2.0),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
    });
  });

  group('revisión de contenido', () {
    testWidgets('sin nada editado no pide revisar el curso entero', (
      tester,
    ) async {
      // El material de fabrica no necesita revision: solo lo que alguien
      // cambio. Pedir revisar dieciocho secciones intactas seria absurdo.
      store.debugSeed(verdicts: []);

      await tester.pumpWidget(wrap(const DirectorContentScreen()));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('No hay nada que revisar'), findsOneWidget);
    });

    test('las aprobaciones que caducaron se distinguen de las buenas', () {
      store.debugSeed(
        verdicts: [
          verdict('m1-s1', approved: true),
          verdict('m1-s2', approved: true, outdated: true),
          verdict('m2-s1', approved: false, comment: 'Falta el video'),
        ],
      );

      expect(store.outdatedApprovals.length, 1);
      expect(store.outdatedApprovals.single.sectionId, 'm1-s2');

      // Y una observada no cuenta como aprobacion caducada, aunque las dos
      // pidan atencion: son problemas distintos.
      expect(store.flagged.single.sectionId, 'm2-s1');
    });
  });

  group('detalle y valoración del docente', () {
    testWidgets('la ficha se dibuja aunque no haya cargado el historial', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          TeacherDetailScreen(teacher: teacher('Mateo', edits: 7)),
        ),
      );
      await tester.pump();

      expect(find.text('mateo@uv.edu.co'), findsOneWidget);
      expect(find.text('Valorar'), findsOneWidget);
    });

    testWidgets('avisa en la ficha si nunca se le ha valorado', (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(TeacherDetailScreen(teacher: teacher('Mateo', edits: 7))),
      );
      await tester.pump();

      expect(find.text('Todavía no le has dicho nada'), findsOneWidget);
    });
  });

  group('cómo se dicen las cosas', () {
    test('las fechas se dicen en relativo, no en formato de base de datos', () {
      final now = DateTime.now();

      expect(relativeDate(now.subtract(const Duration(seconds: 20))), 'ahora mismo');
      expect(relativeDate(now.subtract(const Duration(minutes: 5))), 'hace 5 min');
      expect(relativeDate(now.subtract(const Duration(hours: 3))), 'hace 3 horas');
      expect(relativeDate(now.subtract(const Duration(days: 1))), 'ayer');
      expect(relativeDate(now.subtract(const Duration(days: 5))), 'hace 5 días');
      expect(relativeDate(now.subtract(const Duration(days: 70))), 'hace 2 meses');
    });

    testWidgets('sin nota se dice "sin valorar", no cinco estrellas vacías', (
      tester,
    ) async {
      // Cinco estrellas vacias se leen como un cero, que es lo contrario de
      // "todavia nadie le ha dicho nada".
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => ScoreStars(
              palette: Theme.of(context).brightness == Brightness.dark
                  ? SectionPalette.dark
                  : SectionPalette.light,
              score: null,
            ),
          ),
        ),
      );
      await settle(tester);

      expect(find.text('Sin valorar'), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });
  });
}
