import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/courses/student_courses_screen.dart';
import 'package:flutter_code4all/ui/courses/teacher_courses_screen.dart';
import 'package:flutter_code4all/ui/director/director_content_screen.dart';
import 'package:flutter_code4all/ui/director/director_home_screen.dart';
import 'package:flutter_code4all/ui/director/director_teachers_screen.dart';
import 'package:flutter_code4all/ui/director/teacher_detail_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/module_chapters_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_capsule_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_example_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_exercise_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_quiz_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_reading_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_video_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_camera_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/capsule_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/example_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/exercise_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/quiz_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/reading_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/videos_editor_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';
import 'package:flutter_code4all/ui/teacher/teacher_stats_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_students_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/form_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/reset_password_screen.dart';

import 'support/text_contrast.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';

/// Toda la aplicación, pantalla por pantalla, en los tamaños donde se usa.
///
/// Celular pequeño y normal (también en horizontal), tablet en las dos
/// orientaciones, portátil y escritorio. Y con la letra al doble, que es lo
/// que pide quien tiene baja visión: si algo se desborda ahí, a esa persona
/// le tapa el texto o el botón que necesita.
///
/// Un desbordamiento en Flutter es la franja amarilla y negra en pantalla: se
/// recoge aquí y la prueba dice en qué pantalla y en qué tamaño pasó.
///
/// Para mirar cómo queda, además de comprobar que nada se sale, se pueden
/// guardar capturas de cada pantalla en celular, tablet y portátil:
///
///     flutter test test/responsive_matrix_test.dart --dart-define=SHOTS_DIR=C:/capturas
class _Viewport {
  const _Viewport(this.name, this.width, this.height, [this.textScale = 1.0]);

  final String name;
  final double width;
  final double height;
  final double textScale;

  @override
  String toString() =>
      '$name ${width.toInt()}x${height.toInt()}'
      '${textScale == 1.0 ? '' : ' letra ${(textScale * 100).round()}%'}';
}

const _viewports = [
  _Viewport('celular pequeño', 320, 568),
  _Viewport('celular', 390, 844),
  _Viewport('celular horizontal', 844, 390),
  _Viewport('tablet', 768, 1024),
  _Viewport('tablet horizontal', 1024, 768),
  _Viewport('portátil', 1366, 768),
  _Viewport('escritorio', 1920, 1080),
  // Con la letra al doble, en los tres tamaños de siempre.
  _Viewport('celular', 390, 844, 2.0),
  _Viewport('tablet', 768, 1024, 2.0),
  _Viewport('portátil', 1366, 768, 2.0),
];

/// Carpeta donde guardar capturas. Vacía: no se guarda nada.
const _shotsDir = String.fromEnvironment('SHOTS_DIR');

/// Archivo donde apuntar los textos con poco contraste en vez de fallar,
/// para revisarlos todos de una vez:
///
///     flutter test test/responsive_matrix_test.dart --dart-define=CONTRAST_REPORT=contraste.txt
const _contrastReport = String.fromEnvironment('CONTRAST_REPORT');

/// Los tamaños que se fotografían: con más serían demasiadas para revisar.
bool _photographed(_Viewport v) =>
    (v.width == 390 || v.width == 768 || v.width == 1366) &&
    (v.textScale == 1.0 || v.width == 390);

final _shotKey = GlobalKey();

/// Con capturas hace falta la letra de verdad: en las pruebas, sin cargarla,
/// todo el texto sale como bloques.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Roboto', [
    'assets/fonts/Roboto/Roboto-Regular.ttf',
    'assets/fonts/Roboto/Roboto-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter';
  await load('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  ]);
}

Future<void> _shot(WidgetTester tester, String name, _Viewport viewport) async {
  final file =
      '${name.replaceAll(RegExp(r'[^\wáéíóúñ]+'), '_')}'
      '__${viewport.width.toInt()}'
      '${viewport.textScale == 1.0 ? '' : '_letra200'}.png';
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_shotsDir/$file').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

class _FakeAuth extends AuthStorage {
  @override
  Future<String?> getToken() async => 'token';
  @override
  Future<String?> getName() async => 'María Fernanda Rodríguez';
  @override
  Future<String?> getRole() async => 'docente';
  @override
  Future<String?> getEmail() async => 'maria.fernanda@correounivalle.edu.co';
  @override
  Future<String?> getPhotoUrl() async => null;
  @override
  Future<int?> getUserId() async => 3;
}

// Nombres largos a propósito: son los que rompen las filas.
const _longTeacher = 'María Fernanda Rodríguez Castañeda';
const _courses = [
  {
    'id': 1,
    'title': 'Curso general de Code4All',
    'description': 'El curso de Python de Code4All para todos los estudiantes.',
    'is_general': true,
    'teacher': null,
  },
  {
    'id': 7,
    'title': 'Fundamentos de programación en Python — grupo nocturno 2026-1',
    'description':
        'Lunes y miércoles de 6 a 9 p. m. Trae tu portátil cargado y las '
        'dudas de la semana anterior anotadas.',
    'is_general': false,
    'teacher': {'id': 3, 'nombre': _longTeacher},
    'is_owner': true,
    'can_edit': true,
    'join_code': 'K7M3QX',
    'students': 23,
  },
];

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _client = MockClient((request) async {
  final path = request.url.path;
  if (path == '/api/courses/mine') {
    return _json({'general_course_id': 1, 'courses': _courses});
  }
  if (path.endsWith('/overrides')) {
    return _json({'version': '', 'count': 0, 'items': []});
  }
  if (path == '/api/oversight/teachers') {
    return _json({
      'teachers': [
        {
          'user_id': 3,
          'nombre': _longTeacher,
          'correo': 'maria.fernanda.rodriguez@correounivalle.edu.co',
          'edits': 12,
          'reviews': 0,
          'courses': 2,
          'last_edit': DateTime.now().toIso8601String(),
        },
      ],
    });
  }
  if (path == '/api/oversight/content') {
    return _json({
      'items': [
        {
          'course_id': 7,
          'section_id': 'm1-s1',
          'status': 'observado',
          'comment':
              'Falta un ejemplo con print() y la explicación de la sangría.',
          'outdated': false,
        },
      ],
    });
  }
  if (path == '/api/oversight/courses') {
    return _json({
      'courses': [
        {..._courses[0], 'students': 9, 'edited_sections': []},
        {
          ..._courses[1],
          'edited_sections': [
            {'section_id': 'm1-s1'},
            {'section_id': 'm2-s1'},
          ],
        },
      ],
    });
  }
  if (path.contains('/activity')) {
    return _json({
      'items': [
        {
          'scope': 'section',
          'target_id': 'm1-s1',
          'course_id': 7,
          'course_title': 'Python nocturno',
          'updated_at': DateTime.now().toIso8601String(),
        },
      ],
    });
  }
  if (path.contains('/reviews/')) return _json({'reviews': []});
  if (path == '/api/signs/status') return _json({'available': true});
  return http.Response('{}', 404);
});

void _seedStats() {
  CourseAnalyticsStore.instance.debugSeed(
    sections: const [
      SectionStats(
        sectionId: 'm1-s1',
        answered: 40,
        correct: 31,
        students: 12,
        avgSeconds: 18,
      ),
      SectionStats(
        sectionId: 'm1-s2',
        answered: 30,
        correct: 12,
        students: 10,
        avgSeconds: 42,
      ),
      SectionStats(sectionId: 'm2-s1', answered: 22, correct: 6, students: 8),
    ],
    questions: const [
      QuestionStats(
        sectionId: 'm1-s2',
        activity: 'quiz',
        questionIndex: 3,
        prompt:
            '¿Qué imprime print(type(3 / 2)) en Python 3 y por qué no es '
            'lo mismo que la división entera con //?',
        answered: 14,
        correct: 3,
        avgSeconds: 71,
      ),
    ],
    students: const [
      StudentStats(
        userId: 5,
        name: 'Juan Sebastián Martínez de la Torre',
        email: 'juan.sebastian@correounivalle.edu.co',
        answered: 20,
        correct: 9,
        sectionsTouched: 3,
        activitiesDone: 14,
      ),
      StudentStats(
        userId: 6,
        name: 'Ana',
        email: 'ana@x.co',
        answered: 0,
        correct: 0,
        sectionsTouched: 0,
        activitiesDone: 0,
      ),
    ],
    completions: const [
      ActivityCompletionStats(
        sectionId: 'm1-s1',
        activity: 'lectura',
        students: 12,
      ),
      ActivityCompletionStats(
        sectionId: 'm1-s1',
        activity: 'video',
        students: 9,
      ),
      ActivityCompletionStats(
        sectionId: 'm1-s1',
        activity: 'quiz',
        students: 7,
      ),
      ActivityCompletionStats(
        sectionId: 'm1-s1',
        activity: 'laboratorio',
        students: 2,
      ),
    ],
    totalAnswers: 92,
    totalCompletions: 30,
  );
}

/// Una sección con todas las actividades, para probarlas todas.
CourseSection _fullSection() {
  for (final module in PythonCourseCatalog.modules) {
    for (final section in module.sections) {
      if (section.reading != null &&
          section.capsule != null &&
          section.example != null &&
          section.exercise != null &&
          section.videos.isNotEmpty &&
          section.quiz.isNotEmpty &&
          section.finalEvaluation.isNotEmpty) {
        return section;
      }
    }
  }
  return PythonCourseCatalog.modules.first.sections.first;
}

CourseModule _moduleOf(CourseSection section) =>
    PythonCourseCatalog.moduleByNumber(section.moduleNumber)!;

final _teacher = TeacherSummary(
  userId: 3,
  name: _longTeacher,
  email: 'maria.fernanda.rodriguez@correounivalle.edu.co',
  edits: 12,
  reviews: 2,
  lastScore: 4,
  avgScore: 4.5,
  courses: 2,
  lastEdit: DateTime.now(),
);

/// Las pantallas, cada una como la ve quien la usa.
final Map<String, Widget Function()> _screens = {
  // --- entrada ---
  'login': () => const LoginScreen(),
  'registro': () => const FormScreen(),
  // Un correo largo: es lo que se desborda en un celular estrecho.
  'recuperar contraseña': () => const ForgotPasswordScreen(
    initialEmail: 'estudiante.con.un.correo.largo@correounivalle.edu.co',
  ),
  'contraseña nueva': () => ResetPasswordScreen(token: 't', onDone: () {}),
  'teclado Braille': () => const BrailleKeyboardScreen(),
  // --- estudiante ---
  'estudiante: mis cursos': () => StudentCoursesScreen(
    userName: 'Ana',
    courseHome: (_) => const SizedBox(),
  ),
  'estudiante: módulo 1': () =>
      const LearningModuleScreen(moduleId: 1, userName: 'Ana'),
  'estudiante: módulo 6': () =>
      const LearningModuleScreen(moduleId: 6, userName: 'Ana'),
  'estudiante: capítulos del módulo': () =>
      const ModuleChaptersScreen(moduleId: 1, sectionNumber: 1),
  'estudiante: ruta de la sección': () {
    final section = _fullSection();
    return ChapterSectionScreen(module: _moduleOf(section), section: section);
  },
  'actividad: lectura': () {
    final section = _fullSection();
    return SectionReadingScreen(module: _moduleOf(section), section: section);
  },
  'actividad: cápsula': () {
    final section = _fullSection();
    return SectionCapsuleScreen(module: _moduleOf(section), section: section);
  },
  'actividad: ejemplo': () {
    final section = _fullSection();
    return SectionExampleScreen(module: _moduleOf(section), section: section);
  },
  'actividad: ejercicio': () {
    final section = _fullSection();
    return SectionExerciseScreen(module: _moduleOf(section), section: section);
  },
  'actividad: video': () {
    final section = _fullSection();
    return SectionVideoScreen(module: _moduleOf(section), section: section);
  },
  'actividad: quiz': () {
    final section = _fullSection();
    return SectionQuizScreen(
      module: _moduleOf(section),
      section: section,
      questions: section.quiz,
      activityKind: CourseActivityKind.quiz,
      activityLabel: 'Quiz',
      activityIcon: Icons.help_outline,
      introTitle: 'Quiz de repaso',
      introBody: 'Responde para comprobar qué recuerdas de la lectura.',
    );
  },
  'actividad: laboratorio': () => const LaboratoryConsoleScreen(),
  'actividad: cámara de señas': () => SignCameraScreen(
    targetLetter: 'A',
    service: SignRecognitionService(
      api: ApiService(baseUrl: 'http://srv'),
      client: _client,
    ),
  ),
  // El aviso de cuando el servidor no puede: era azul sobre rojo.
  'actividad: cámara de señas sin servidor': () => SignCameraScreen(
    service: SignRecognitionService(
      api: ApiService(baseUrl: 'http://srv'),
      client: MockClient(
        (_) async => _json({
          'available': false,
          'reason': 'El servidor no puede crear el detector de manos',
        }),
      ),
    ),
  ),
  // --- docente ---
  'docente: mis cursos': () => TeacherCoursesScreen(
    userName: 'María',
    courseEditor: (_, _) => const SizedBox(),
  ),
  'docente: temario': () => const TeacherCourseScreen(userName: 'María'),
  'editor: lectura': () {
    final section = _fullSection();
    return ReadingEditorScreen(reading: section.reading, section: section);
  },
  'editor: quiz': () =>
      QuizEditorScreen(questions: _fullSection().quiz, title: 'Quiz'),
  'editor: videos': () => VideosEditorScreen(videos: _fullSection().videos),
  'editor: cápsula': () => CapsuleEditorScreen(capsule: _fullSection().capsule),
  'editor: ejemplo': () => ExampleEditorScreen(example: _fullSection().example),
  'editor: ejercicio': () =>
      ExerciseEditorScreen(exercise: _fullSection().exercise),
  // --- coordinación ---
  'coordinación: inicio': () => const DirectorHomeScreen(userName: 'Dirección'),
  'coordinación: ficha del docente': () =>
      TeacherDetailScreen(teacher: _teacher),
};

/// Lo que hay que pulsar para llegar al estado que se quiere probar.
typedef _Act = Future<void> Function(WidgetTester tester);

Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first, warnIfMissed: false);
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Pantallas en un estado concreto: con un menú, un diálogo o una pestaña
/// abiertos. Es donde más se rompen los diseños, porque nadie los mira en
/// todos los tamaños.
final Map<String, (Widget Function(), _Act)> _states = {
  'estudiante: menú «?» abierto': (
    () => const LearningModuleScreen(moduleId: 1, userName: 'Ana'),
    (tester) => _tapAndSettle(tester, find.byIcon(Icons.question_mark)),
  ),
  'estudiante: menú «?» con el modo visual': (
    () => const LearningModuleScreen(moduleId: 1, userName: 'Ana'),
    (tester) async {
      await _tapAndSettle(tester, find.byIcon(Icons.question_mark));
      await _tapAndSettle(tester, find.byIcon(Icons.help));
      await _tapAndSettle(tester, find.byIcon(Icons.brightness_4));
    },
  ),
  'estudiante: menú «?» con preferencias': (
    () => const LearningModuleScreen(moduleId: 1, userName: 'Ana'),
    (tester) async {
      await _tapAndSettle(tester, find.byIcon(Icons.question_mark));
      await _tapAndSettle(tester, find.byIcon(Icons.psychology));
      await _tapAndSettle(tester, find.byIcon(Icons.build_circle));
    },
  ),
  'estudiante: unirse a un curso': (
    () => StudentCoursesScreen(
      userName: 'Ana',
      courseHome: (_) => const SizedBox(),
    ),
    (tester) => _tapAndSettle(tester, find.text('Unirme a un curso')),
  ),
  'actividad: lectura, segunda página': (
    () {
      final section = _fullSection();
      return SectionReadingScreen(module: _moduleOf(section), section: section);
    },
    (tester) => _tapAndSettle(tester, find.text('Siguiente')),
  ),
  'docente: crear curso': (
    () => TeacherCoursesScreen(
      userName: 'María',
      courseEditor: (_, _) => const SizedBox(),
    ),
    (tester) => _tapAndSettle(tester, find.text('Crear curso')),
  ),
  'docente: renombrar curso': (
    () => TeacherCoursesScreen(
      userName: 'María',
      courseEditor: (_, _) => const SizedBox(),
    ),
    (tester) => _tapAndSettle(tester, find.text('Renombrar')),
  ),
  'docente: panel de accesibilidad': (
    () => TeacherCoursesScreen(
      userName: 'María',
      courseEditor: (_, _) => const SizedBox(),
    ),
    (tester) => _tapAndSettle(
      tester,
      find.byTooltip('Accesibilidad: colores y tamaño del texto'),
    ),
  ),
  'docente: sección abierta': (
    () => const Scaffold(
      body: TeacherSectionDetail(moduleNumber: 1, sectionNumber: 1),
    ),
    (_) async {},
  ),
  'docente: estadísticas': (
    () => const Scaffold(body: TeacherStatsScreen()),
    (_) async {},
  ),
  'docente: estudiantes': (
    () => const Scaffold(body: TeacherStudentsScreen()),
    (_) async {},
  ),
  'coordinación: docentes': (
    () => const Scaffold(body: DirectorTeachersScreen()),
    (_) async {},
  ),
  'coordinación: contenido': (
    () => const Scaffold(body: DirectorContentScreen()),
    (_) async {},
  ),
  'coordinación: revisar una sección': (
    () => const Scaffold(body: DirectorContentScreen()),
    (tester) => _tapAndSettle(tester, find.text('Cambiar')),
  ),
  'coordinación: valorar a un docente': (
    () => TeacherDetailScreen(teacher: _teacher),
    (tester) => _tapAndSettle(tester, find.text('Valorar')),
  ),
};

void main() {
  final api = ApiService(baseUrl: 'http://srv');

  setUpAll(() async {
    if (_shotsDir.isNotEmpty) await _loadFonts();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Los complementos nativos no existen en una prueba: se contestan con
    // valores neutros para que las pantallas se dibujen como sin datos.
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => call.method == 'readAll' ? <String, String>{} : null,
    );
    for (final channel in [
      'flutter_tts',
      'plugin.csdcorp.com/speech_to_text',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(channel),
        (_) async => null,
      );
    }
  });

  setUp(() async {
    CourseContentStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client, auth: _FakeAuth());
    CourseAnalyticsStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client, auth: _FakeAuth());
    _seedStats();
    DirectorOversightStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client, auth: _FakeAuth());
    MyCoursesStore.instance
      ..debugReset()
      ..debugUse(api: api, client: _client, auth: _FakeAuth());
    await MyCoursesStore.instance.refresh();
  });

  final cases = <String, (Widget Function(), _Act)>{
    for (final entry in _screens.entries)
      entry.key: (entry.value, (_) async {}),
    ..._states,
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} se adapta a todos los tamaños', (tester) async {
      final problems = <String>[];
      final previous = FlutterError.onError;
      _Viewport? current;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        // Lo que falta en una prueba (cámara, voz, almacenamiento) no es un
        // problema de diseño.
        if (text.contains('MissingPluginException') ||
            text.contains('PlatformException')) {
          return;
        }
        // Dónde: la fila o columna que se desborda, con su archivo y línea.
        final where = RegExp(
          r'lib/[\w/]+\.dart:\d+',
        ).firstMatch(details.toString())?.group(0);
        problems.add('$current: ${text.split('\n').first} (${where ?? '?'})');
      };

      try {
        for (final viewport in _viewports) {
          current = viewport;
          tester.view.physicalSize = Size(viewport.width, viewport.height);
          tester.view.devicePixelRatio = 1.0;
          // Igual que en la aplicación: el control A−/A+ es el que manda, y
          // algunas piezas (el menú «?») escalan con él y no solo con la letra.
          AccessibilityTextScaleController.global.setScale(viewport.textScale);

          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            RepaintBoundary(
              key: _shotKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.getTheme(mode: AppThemeMode.light),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(viewport.textScale)),
                  child: child!,
                ),
                home: entry.value.$1(),
              ),
            ),
          );
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 120));
          }
          await entry.value.$2(tester);
          if (_shotsDir.isNotEmpty && _photographed(viewport)) {
            await _shot(tester, entry.key, viewport);
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = previous;
        AccessibilityTextScaleController.global.reset();
        tester.view.reset();
      }

      expect(problems, isEmpty, reason: problems.toSet().join('\n'));
    });
  }

  // Que el texto se lea. Un botón con la letra del mismo color que el fondo
  // pasa todas las pruebas de tamaño: no se sale de nada, simplemente no se
  // ve. Se mira en los seis temas, porque cada uno tiene sus colores.
  for (final entry in cases.entries) {
    testWidgets('${entry.key}: el texto se lee en los seis temas', (
      tester,
    ) async {
      final problems = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {};

      try {
        tester.view.physicalSize = const Size(1366, 900);
        tester.view.devicePixelRatio = 1.0;

        for (final mode in AppThemeMode.values) {
          ThemeManager.changeTheme(mode);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(mode: mode),
              home: entry.value.$1(),
            ),
          );
          for (var i = 0; i < 5; i++) {
            await tester.pump(const Duration(milliseconds: 120));
          }
          await entry.value.$2(tester);

          for (final problem in lowContrastTexts(tester)) {
            problems.add('${mode.name}: $problem [${entry.key}]');
          }
          if (_contrastReport.isNotEmpty && problems.isNotEmpty) {
            File(_contrastReport).writeAsStringSync(
              '${problems.join('\n')}\n',
              mode: FileMode.append,
            );
            problems.clear();
          }
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      } finally {
        FlutterError.onError = previous;
        ThemeManager.changeTheme(AppThemeMode.light);
        tester.view.reset();
      }

      expect(problems, isEmpty, reason: problems.toSet().join('\n'));
    });
  }
}
