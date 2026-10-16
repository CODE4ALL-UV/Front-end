import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/director/director_content_screen.dart';
import 'package:flutter_code4all/ui/director/director_home_screen.dart';
import 'package:flutter_code4all/ui/director/director_teachers_screen.dart';
import 'package:flutter_code4all/ui/director/director_widgets.dart';
import 'package:flutter_code4all/ui/director/teacher_detail_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';

/// Respuesta JSON en UTF-8, como la manda el servidor.
http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// La sesión de la dirección, sin tocar el almacenamiento del dispositivo.
class _DirectorSession extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token-de-direccion';
}

/// El servidor del seguimiento: docentes, revisiones, valoraciones y cursos.
class _OversightServer {
  List<Map<String, Object?>> teachers = [];
  List<Map<String, Object?>> verdicts = [];

  /// Nulo: el servidor de antes, sin cursos por docente.
  List<Map<String, Object?>>? courses;

  /// Lo editado en el curso único de antes, como lo guarda el servidor.
  List<Map<String, Object?>> overrides = [];

  Map<int, List<Map<String, Object?>>> activity = {};
  Map<int, List<Map<String, Object?>>> reviews = {};

  int teachersStatus = 200;
  int activityStatus = 200;

  /// Lo que contesta al guardar una valoración o una revisión.
  http.Response saveAnswer = _json({'ok': true}, 201);

  final List<http.Request> requests = [];

  Iterable<http.Request> where(String method, String pathStart) => requests
      .where((r) => r.method == method && r.url.path.startsWith(pathStart));

  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;

    if (request.method != 'GET') return saveAnswer;

    if (path == '/api/oversight/teachers') {
      return _json({'teachers': teachers}, teachersStatus);
    }
    if (path == '/api/oversight/content') {
      return _json({'items': verdicts}, 200);
    }
    if (path == '/api/oversight/courses') {
      final list = courses;
      return list == null
          ? _json({'detail': 'Not Found'}, 404)
          : _json({'courses': list}, 200);
    }
    final activityMatch = RegExp(
      r'^/api/oversight/teachers/(\d+)/activity$',
    ).firstMatch(path);
    if (activityMatch != null) {
      final id = int.parse(activityMatch.group(1)!);
      return _json({'items': activity[id] ?? []}, activityStatus);
    }
    final reviewsMatch = RegExp(
      r'^/api/oversight/reviews/(\d+)$',
    ).firstMatch(path);
    if (reviewsMatch != null) {
      final id = int.parse(reviewsMatch.group(1)!);
      return _json({'reviews': reviews[id] ?? []}, 200);
    }
    if (path == '/api/course/overrides') {
      return _json({'version': '1', 'items': overrides}, 200);
    }
    if (path.startsWith('/api/courses/') && path.endsWith('/overrides')) {
      return _json({'version': '1', 'items': []}, 200);
    }
    if (path == '/api/courses/mine') {
      return _json({
        'courses': [
          {'id': 1, 'title': 'Curso general', 'is_general': true},
          {
            'id': 5,
            'title': 'Python de la tarde',
            'teacher': {'id': 3, 'nombre': 'Laura'},
          },
        ],
        'general_course_id': 1,
      }, 200);
    }
    return _json({'detail': 'Not Found'}, 404);
  }
}

/// Lo que la dirección hace con lo que ve: valorar a un docente, aprobar u
/// observar una sección, abrir la ficha de un docente o el curso general.
///
/// Las pruebas de las pantallas miran que no se escondan los avisos; aquí
/// se mira que cada acción mande al servidor lo que debe, que los errores
/// se vean donde se está escribiendo y que la pantalla se ponga al día al
/// guardar.
void main() {
  final store = DirectorOversightStore.instance;
  final content = CourseContentStore.instance;
  final myCourses = MyCoursesStore.instance;
  final stats = CourseAnalyticsStore.instance;

  late _OversightServer server;

  setUp(() {
    server = _OversightServer();
    final api = ApiService(baseUrl: 'http://servidor.de.prueba');
    final client = MockClient(server.handle);
    final auth = _DirectorSession();
    store
      ..debugReset()
      ..debugUse(api: api, client: client, auth: auth);
    content
      ..debugReset()
      ..debugUse(api: api, client: client, auth: auth);
    myCourses
      ..debugReset()
      ..debugUse(api: api, client: client, auth: auth);
    stats
      ..debugReset()
      ..debugUse(api: api, client: client, auth: auth);
  });

  tearDown(() {
    store.debugReset();
    content.debugReset();
    myCourses.debugReset();
    stats.debugReset();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    bool scaffold = true,
  }) async {
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: scaffold ? Scaffold(body: screen) : screen,
      ),
    );
    await settle(tester);
  }

  /// Desmonta la pantalla para que no queden temporizadores vivos.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  const mateo = TeacherSummary(
    userId: 12,
    name: 'Mateo',
    email: 'mateo@example.com',
    edits: 3,
    reviews: 1,
    lastScore: 3,
    avgScore: 3.0,
  );

  final now = DateTime.now();
  String ago(Duration d) => now.subtract(d).toIso8601String();

  group('ficha del docente', () {
    testWidgets('muestra cada edición con el estado de su revisión', (
      tester,
    ) async {
      server.activity[12] = [
        {'scope': 'module', 'target_id': '2', 'review_outdated': false},
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'updated_at': ago(const Duration(hours: 2)),
          'review_status': 'aprobado',
          'review_outdated': false,
        },
        {
          'scope': 'section',
          'target_id': 'm1-s2',
          'review_status': 'aprobado',
          'review_outdated': true,
        },
        {
          'scope': 'section',
          'target_id': 'm2-s1',
          'review_status': 'observado',
          'review_comment': 'Falta el ejemplo con listas.',
          'review_outdated': false,
        },
      ];
      server.reviews[12] = [
        {
          'score': 3,
          'comment': 'Buen ritmo, revisa los ejercicios.',
          'created_at': ago(const Duration(days: 3)),
        },
        {'score': 5, 'comment': ''},
      ];

      await pump(
        tester,
        const TeacherDetailScreen(teacher: mateo),
        scaffold: false,
      );

      expect(find.text('Módulo 2 (nombre)'), findsOneWidget);
      expect(
        find.text(PythonCourseCatalog.sectionById('m1-s1')!.title),
        findsOneWidget,
      );
      expect(find.text('hace 2 horas'), findsOneWidget);
      expect(find.text('Sin revisar'), findsOneWidget);
      expect(find.text('Aprobado'), findsOneWidget);
      expect(find.text('Revisado antes de este cambio'), findsOneWidget);
      expect(find.text('Con observaciones'), findsOneWidget);
      expect(find.text('Falta el ejemplo con listas.'), findsOneWidget);

      // Las valoraciones, con su nota en número y en estrellas.
      expect(find.text('Buen ritmo, revisa los ejercicios.'), findsOneWidget);
      expect(find.text('hace 3 días'), findsOneWidget);
      // La nota va siempre en número al lado de las estrellas.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Todavía no se le ha valorado.'), findsNothing);

      // Se pidió lo de este docente y no lo de otro.
      expect(
        server.where('GET', '/api/oversight/teachers/12/activity'),
        hasLength(1),
      );
      expect(server.where('GET', '/api/oversight/reviews/12'), hasLength(1));
      await unmount(tester);
    });

    testWidgets('sin ediciones ni valoraciones lo dice', (tester) async {
      await pump(
        tester,
        const TeacherDetailScreen(
          teacher: TeacherSummary(
            userId: 30,
            name: '',
            email: 'nuevo@example.com',
            edits: 0,
            reviews: 0,
          ),
        ),
        scaffold: false,
      );

      expect(
        find.text('Todavía no ha editado nada del temario.'),
        findsOneWidget,
      );
      expect(find.text('Todavía no se le ha valorado.'), findsOneWidget);
      // Sin nombre, la barra dice qué es.
      expect(find.text('Docente'), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('si el servidor falla se puede volver a intentar', (
      tester,
    ) async {
      server.activityStatus = 500;

      await pump(
        tester,
        const TeacherDetailScreen(teacher: mateo),
        scaffold: false,
      );
      expect(
        find.text('No se pudo consultar su actividad (500).'),
        findsOneWidget,
      );

      server.activityStatus = 200;
      await tester.tap(find.text('Volver a intentarlo'));
      await settle(tester);

      expect(find.textContaining('No se pudo consultar'), findsNothing);
      expect(
        find.text('Todavía no ha editado nada del temario.'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('sin conexión dice que no se pudo consultar', (tester) async {
      store.debugUse(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((_) async => throw http.ClientException('sin red')),
        auth: _DirectorSession(),
      );

      await pump(
        tester,
        const TeacherDetailScreen(teacher: mateo),
        scaffold: false,
      );

      expect(find.text('No se pudo consultar.'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('valorar a un docente', () {
    Future<void> openSheet(WidgetTester tester) async {
      await pump(
        tester,
        const TeacherDetailScreen(teacher: mateo),
        scaffold: false,
      );
      await tester.tap(find.text('Valorar'));
      await settle(tester);
      expect(find.text('Valorar a Mateo'), findsOneWidget);
    }

    testWidgets('sin comentario no se guarda y lo explica', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Guardar'));
      await settle(tester);

      expect(
        find.text('Escribe un comentario: la nota sola no explica nada.'),
        findsOneWidget,
      );
      expect(server.where('POST', '/api/oversight/reviews'), isEmpty);

      // Al escribir, el aviso se quita.
      await tester.enterText(find.byType(TextField), 'Algo');
      await tester.pump();
      expect(
        find.text('Escribe un comentario: la nota sola no explica nada.'),
        findsNothing,
      );
      await unmount(tester);
    });

    testWidgets('guarda la nota elegida con el comentario y recarga la ficha', (
      tester,
    ) async {
      await openSheet(tester);
      expect(find.text('Buen trabajo'), findsOneWidget, reason: 'empieza en 4');

      await tester.tap(
        find.bySemanticsLabel('2 de 5, Por debajo de lo esperado'),
      );
      await tester.pump();
      expect(find.text('Por debajo de lo esperado'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        '  Las lecturas nuevas tienen errores de código.  ',
      );
      await tester.tap(find.text('Guardar'));
      await settle(tester);

      final saved = server.where('POST', '/api/oversight/reviews').single;
      expect(saved.headers['Authorization'], 'Bearer token-de-direccion');
      expect(jsonDecode(saved.body), {
        'docente_id': 12,
        'score': 2,
        'comment': 'Las lecturas nuevas tienen errores de código.',
      });

      // La hoja se cierra y la ficha vuelve a pedir su historial.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Valorar a Mateo'), findsNothing);
      expect(
        server.where('GET', '/api/oversight/teachers/12/activity'),
        hasLength(2),
      );
      // Y el resumen de todos los docentes se pone al día.
      expect(server.where('GET', '/api/oversight/teachers'), isNotEmpty);
      await unmount(tester);
    });

    testWidgets('si el servidor no la acepta, el motivo se ve en la hoja', (
      tester,
    ) async {
      server.saveAnswer = _json({
        'detail': 'Solo la dirección puede valorar docentes.',
      }, 403);
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), 'Muy bien.');
      await tester.tap(find.text('Guardar'));
      await settle(tester);

      expect(
        find.text('Solo la dirección puede valorar docentes.'),
        findsOneWidget,
      );
      expect(find.text('Valorar a Mateo'), findsOneWidget);
      // Se puede volver a intentar.
      expect(find.text('Guardar'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('cancelar no guarda nada', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Cancelar'));
      await settle(tester);

      expect(find.text('Valorar a Mateo'), findsNothing);
      expect(server.where('POST', '/api/oversight/reviews'), isEmpty);
      await unmount(tester);
    });
  });

  group('lista de docentes', () {
    testWidgets('a igualdad de urgencia, primero el peor valorado', (
      tester,
    ) async {
      store.debugSeed(
        teachers: const [
          TeacherSummary(
            userId: 1,
            name: 'Bea',
            email: 'bea@example.com',
            edits: 4,
            reviews: 2,
            lastScore: 5,
            avgScore: 4.5,
          ),
          TeacherSummary(
            userId: 2,
            name: 'carlos',
            email: 'carlos@example.com',
            edits: 4,
            reviews: 2,
            lastScore: 2,
            avgScore: 2.5,
          ),
          TeacherSummary(
            userId: 3,
            name: 'Alba',
            email: 'alba@example.com',
            edits: 4,
            reviews: 2,
            lastScore: 5,
            avgScore: 4.5,
          ),
        ],
      );

      await pump(tester, const DirectorTeachersScreen());

      double top(String name) => tester.getTopLeft(find.text(name)).dy;
      // Carlos tiene la media más baja; Alba y Bea empatan y van por nombre.
      expect(top('carlos'), lessThan(top('Alba')));
      expect(top('Alba'), lessThan(top('Bea')));
      await unmount(tester);
    });

    testWidgets('cuenta a todos los que esperan respuesta', (tester) async {
      store.debugSeed(
        teachers: [
          const TeacherSummary(
            userId: 1,
            name: '',
            email: 'sin-nombre@example.com',
            edits: 1,
            reviews: 0,
            courses: 1,
          ),
          TeacherSummary(
            userId: 2,
            name: 'Zoe',
            email: 'zoe@example.com',
            edits: 6,
            reviews: 0,
            courses: 2,
            lastEdit: now.subtract(const Duration(days: 1)),
          ),
        ],
      );

      await pump(tester, const DirectorTeachersScreen());

      expect(find.text('2 docentes esperan tu respuesta'), findsOneWidget);
      // Sin nombre se le reconoce por el correo.
      expect(find.text('sin-nombre@example.com'), findsNWidgets(2));
      expect(find.text('1 edición'), findsOneWidget);
      expect(find.text('6 ediciones'), findsOneWidget);
      expect(find.text('1 curso'), findsOneWidget);
      expect(find.text('2 cursos'), findsOneWidget);
      expect(find.text('ayer'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tocar un docente abre su ficha', (tester) async {
      store.debugSeed(teachers: const [mateo]);

      await pump(tester, const DirectorTeachersScreen());
      await tester.tap(find.text('Mateo'));
      await settle(tester);

      final detail = tester.widget<TeacherDetailScreen>(
        find.byType(TeacherDetailScreen),
      );
      expect(detail.teacher.userId, 12);
      expect(find.text('Valorar'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('si el servidor falla lo dice y se puede reintentar', (
      tester,
    ) async {
      server.teachersStatus = 500;

      await pump(tester, const DirectorTeachersScreen());
      expect(
        find.text('El servidor no devolvió los datos (500).'),
        findsOneWidget,
      );

      server
        ..teachersStatus = 200
        ..teachers = [
          {'user_id': 12, 'nombre': 'Mateo', 'correo': 'mateo@example.com'},
        ];
      await tester.tap(find.text('Volver a intentarlo'));
      await settle(tester);

      expect(find.text('Mateo'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('mientras carga por primera vez se ve el indicador', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const DirectorTeachersScreen())),
      );
      // Sin dejar que llegue la respuesta.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await settle(tester);
      expect(find.text('No hay docentes registrados'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('revisión del contenido', () {
    final m1s1 = PythonCourseCatalog.sectionById('m1-s1')!;
    final m1s2 = PythonCourseCatalog.sectionById('m1-s2')!;
    final m2s1 = PythonCourseCatalog.sectionById('m2-s1')!;

    void twoCourses() {
      server.courses = [
        {
          'id': 1,
          'title': 'Curso general',
          'is_general': true,
          'edited_sections': [
            {'section_id': 'm1-s1'},
          ],
        },
        {
          'id': 5,
          'title': 'Python de la tarde',
          'teacher': {'nombre': 'Laura'},
          'edited_sections': [
            {'section_id': 'm1-s1'},
            {'section_id': 'm2-s1'},
            {'section_id': 'no-existe'},
          ],
        },
        {
          'id': 6,
          'title': 'Python sin docente',
          'edited_sections': [
            {'section_id': 'm1-s2'},
          ],
        },
      ];
    }

    testWidgets('cada sección se revisa en su curso y con su estado', (
      tester,
    ) async {
      twoCourses();
      server.verdicts = [
        {
          'course_id': 1,
          'section_id': 'm1-s1',
          'status': 'aprobado',
          'comment': '',
          'outdated': false,
        },
        {
          'course_id': 5,
          'section_id': 'm1-s1',
          'status': 'aprobado',
          'comment': '',
          'outdated': true,
        },
        {
          'course_id': 5,
          'section_id': 'm2-s1',
          'status': 'observado',
          'comment': 'El video no corresponde al tema.',
          'outdated': false,
        },
      ];

      await pump(tester, const DirectorContentScreen());

      // La misma sección sale dos veces: una por curso.
      expect(find.text(m1s1.title), findsNWidgets(2));
      expect(find.text('Curso general'), findsOneWidget);
      expect(find.text('Python de la tarde · Laura'), findsNWidgets(2));
      expect(find.text('Python sin docente · Docente'), findsOneWidget);
      // Una sección que ya no existe en el temario no se muestra.
      expect(find.textContaining('no-existe'), findsNothing);

      expect(find.text('Aprobado'), findsOneWidget);
      expect(find.text('Revisado antes del último cambio'), findsOneWidget);
      expect(find.text('Con observaciones'), findsOneWidget);
      expect(find.text('Sin revisar'), findsOneWidget);
      expect(find.text('El video no corresponde al tema.'), findsOneWidget);

      expect(find.text('Una aprobación se quedó vieja'), findsOneWidget);
      expect(find.text('Una sección con observaciones'), findsOneWidget);
      // Lo que ya tiene revisión se cambia; lo que no, se revisa.
      expect(find.text('Cambiar'), findsNWidgets(3));
      expect(find.text('Revisar'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('con varias se cuentan en plural', (tester) async {
      store.debugSeed(
        courses: [
          OversightCourse.fromJson({
            'id': 5,
            'title': 'Python de la tarde',
            'edited_sections': [
              {'section_id': 'm1-s1'},
            ],
          }),
        ],
        verdicts: const [
          ContentVerdict(
            sectionId: 'm1-s1',
            status: 'aprobado',
            comment: '',
            outdated: true,
          ),
          ContentVerdict(
            sectionId: 'm1-s2',
            status: 'aprobado',
            comment: '',
            outdated: true,
          ),
          ContentVerdict(
            sectionId: 'm2-s1',
            status: 'observado',
            comment: 'a',
            outdated: false,
          ),
          ContentVerdict(
            sectionId: 'm2-s2',
            status: 'observado',
            comment: 'b',
            outdated: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const DirectorContentScreen())),
      );
      await tester.pump();

      expect(find.text('2 aprobaciones se quedaron viejas'), findsOneWidget);
      expect(find.text('2 secciones con observaciones'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('con el servidor de antes salen las secciones editadas', (
      tester,
    ) async {
      server.overrides = [
        {
          'scope': 'section',
          'target_id': 'm1-s2',
          'content': {'title': 'Tipos de datos, versión revisada'},
        },
      ];

      await pump(tester, const DirectorContentScreen());

      expect(find.text('Tipos de datos, versión revisada'), findsOneWidget);
      expect(
        find.text('Módulo ${m1s2.moduleNumber} · Sección ${m1s2.number}'),
        findsOneWidget,
      );
      expect(find.text('Revisar'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('si el servidor falla se puede volver a intentar', (
      tester,
    ) async {
      server.teachersStatus = 500;

      await pump(tester, const DirectorContentScreen());
      expect(
        find.text('El servidor no devolvió los datos (500).'),
        findsOneWidget,
      );

      server.teachersStatus = 200;
      await tester.tap(find.text('Volver a intentarlo'));
      await settle(tester);
      expect(find.text('No hay nada que revisar'), findsOneWidget);
      await unmount(tester);
    });

    group('la hoja de revisión', () {
      Future<void> openJudge(WidgetTester tester) async {
        twoCourses();
        server.courses = [server.courses![1]];
        await pump(tester, const DirectorContentScreen());
        await tester.tap(find.text('Revisar').first);
        await settle(tester);
      }

      testWidgets('observar sin explicar qué está mal no se guarda', (
        tester,
      ) async {
        await openJudge(tester);
        expect(find.text('Revisar "${m1s1.title}"'), findsOneWidget);
        expect(find.text('Comentario (opcional)'), findsOneWidget);

        await tester.tap(find.text('Con observaciones').last);
        await tester.pump();
        expect(find.text('Qué hay que corregir'), findsOneWidget);

        await tester.tap(find.text('Guardar'));
        await tester.pump();
        expect(
          find.text('Si pones observaciones, explica cuáles.'),
          findsOneWidget,
        );
        expect(server.where('PUT', '/api/oversight/content'), isEmpty);

        // Volver a «Aprobado» quita el aviso: aprobar no exige comentario.
        await tester.tap(find.text('Aprobado').last);
        await tester.pump();
        expect(
          find.text('Si pones observaciones, explica cuáles.'),
          findsNothing,
        );
        await unmount(tester);
      });

      testWidgets('guarda la observación en el curso de esa sección', (
        tester,
      ) async {
        await openJudge(tester);

        await tester.tap(find.text('Con observaciones').last);
        await tester.pump();
        await tester.tap(find.text('Guardar'));
        await tester.pump();
        await tester.enterText(
          find.byType(TextField),
          ' Falta explicar los índices negativos. ',
        );
        await tester.pump();
        expect(
          find.text('Si pones observaciones, explica cuáles.'),
          findsNothing,
        );

        await tester.tap(find.text('Guardar'));
        await settle(tester);

        final saved = server
            .where('PUT', '/api/oversight/content/m1-s1')
            .single;
        expect(jsonDecode(saved.body), {
          'section_id': 'm1-s1',
          'status': 'observado',
          'comment': 'Falta explicar los índices negativos.',
          'course_id': 5,
        });
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Revisar "${m1s1.title}"'), findsNothing);
        await unmount(tester);
      });

      testWidgets('si el servidor no la acepta, el motivo se ve en la hoja', (
        tester,
      ) async {
        server.saveAnswer = _json({'detail': 'La sección no existe.'}, 404);
        await openJudge(tester);

        await tester.tap(find.text('Guardar'));
        await settle(tester);

        expect(find.text('La sección no existe.'), findsOneWidget);
        expect(find.text('Revisar "${m1s1.title}"'), findsOneWidget);
        await unmount(tester);
      });

      testWidgets('cancelar no guarda nada', (tester) async {
        await openJudge(tester);

        await tester.tap(find.text('Cancelar'));
        await settle(tester);

        expect(find.text('Revisar "${m1s1.title}"'), findsNothing);
        expect(server.where('PUT', '/api/oversight/content'), isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('«Ver» abre la sección como la ve el estudiante de ese curso', (
      tester,
    ) async {
      twoCourses();
      server.courses = [server.courses![1]];

      await pump(tester, const DirectorContentScreen());
      await tester.tap(find.text('Ver').last);
      await settle(tester);

      final section = tester.widget<ChapterSectionScreen>(
        find.byType(ChapterSectionScreen),
      );
      expect(section.section.id, m2s1.id);
      expect(section.module.number, m2s1.moduleNumber);
      // El temario que se carga es el del curso de ese docente.
      expect(server.where('GET', '/api/courses/5/overrides'), isNotEmpty);
      await unmount(tester);
    });

    testWidgets('«Ver» con el servidor de antes abre la sección editada', (
      tester,
    ) async {
      server.overrides = [
        {
          'scope': 'section',
          'target_id': 'm1-s2',
          'content': {'title': 'Tipos de datos, versión revisada'},
        },
      ];

      await pump(tester, const DirectorContentScreen());
      await tester.tap(find.text('Ver'));
      await settle(tester);

      final section = tester.widget<ChapterSectionScreen>(
        find.byType(ChapterSectionScreen),
      );
      expect(section.section.title, 'Tipos de datos, versión revisada');
      await unmount(tester);
    });
  });

  group('inicio de la dirección', () {
    testWidgets('las pestañas cuentan lo que espera respuesta', (tester) async {
      server
        ..teachers = [
          {'user_id': 1, 'nombre': 'Zoe', 'edits': 4, 'reviews': 0},
        ]
        ..verdicts = [
          {'section_id': 'm1-s1', 'status': 'observado', 'comment': 'x'},
          {'section_id': 'm1-s2', 'status': 'aprobado', 'outdated': true},
        ];

      await pump(tester, const DirectorHomeScreen(), scaffold: false);

      expect(find.text('Docentes (1 pendiente)'), findsOneWidget);
      expect(find.text('Contenido (2 pendientes)'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('editar el curso general lo abre y al volver lo suelta', (
      tester,
    ) async {
      stats.useCourse(5);
      var loggedOut = 0;

      await pump(
        tester,
        DirectorHomeScreen(userName: 'Marta', onLogout: () => loggedOut++),
        scaffold: false,
      );

      await tester.tap(find.byTooltip('Editar el curso general'));
      await settle(tester);

      final editor = tester.widget<TeacherCourseScreen>(
        find.byType(TeacherCourseScreen),
      );
      expect(editor.course?.isGeneral, isTrue);
      expect(editor.userName, 'Marta');
      expect(myCourses.active?.id, 1);

      await tester.tap(find.byTooltip('Volver'));
      await settle(tester);

      expect(find.byType(TeacherCourseScreen), findsNothing);
      // Al volver no queda ningún curso abierto, y las estadísticas siguen
      // en el curso que se estaba mirando.
      expect(myCourses.active, isNull);
      expect(stats.courseId, 5);
      expect(loggedOut, 0);
      await unmount(tester);
    });
  });

  group('piezas de la dirección', () {
    testWidgets('la nota se colorea según lo buena que sea', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode: AppThemeMode.light),
          home: const Scaffold(
            body: Column(
              children: [
                ScoreStars(score: 5),
                ScoreStars(score: 3),
                ScoreStars(score: 1),
              ],
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(Column).first);
      final colors = context.messageColors;
      Color toneOf(int score) => tester
          .widgetList<Icon>(
            find.descendant(
              of: find.bySemanticsLabel('Nota $score de 5'),
              matching: find.byIcon(Icons.star_rounded),
            ),
          )
          .first
          .color!;

      expect(toneOf(5), colors.successForeground);
      expect(toneOf(3), colors.warningForeground);
      expect(toneOf(1), colors.dangerForeground);
      // Y el número siempre al lado.
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('el aviso de problema llama a reintentar', (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode: AppThemeMode.light),
          home: Scaffold(
            body: DirectorProblem(
              message: 'No hay conexión.',
              onRetry: () => retries++,
            ),
          ),
        ),
      );

      expect(find.text('No hay conexión.'), findsOneWidget);
      await tester.tap(find.text('Volver a intentarlo'));
      expect(retries, 1);
    });

    test('las fechas lejanas se dicen en meses y años', () {
      expect(
        relativeDate(now.subtract(const Duration(hours: 1))),
        'hace 1 hora',
      );
      expect(
        relativeDate(now.subtract(const Duration(days: 35))),
        'hace 1 mes',
      );
      expect(
        relativeDate(now.subtract(const Duration(days: 400))),
        'hace 1 año',
      );
      expect(
        relativeDate(now.subtract(const Duration(days: 800))),
        'hace 2 años',
      );
    });
  });
}
