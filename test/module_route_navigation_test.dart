import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/circle_progress_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/lesson_box_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/module_row_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/module_chapters_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_language_panel.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart';

/// Moverse por el mapa del curso: de un módulo a otro, de la portada del
/// módulo a un capítulo y de un capítulo al siguiente.
///
/// Se comprueba que cada camino lleva a donde dice (y avisa a la aplicación
/// del módulo en el que se está, que es lo que cambia la paleta), que el
/// gesto de deslizar y los botones hacen lo mismo, que el avance guardado se
/// ve en las circunferencias, y que el docente ve su lápiz y, al volver del
/// editor, el temario se pide otra vez.
void main() {
  final content = CourseContentStore.instance;
  final prefs = LearningPreferences.instance;
  const ttsChannel = MethodChannel('flutter_tts');

  late List<http.Request> sent;

  void useRole(String role) {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'token-de-prueba',
      'auth_role': role,
    });
  }

  setUp(() {
    useRole('estudiante');
    sent = [];
    content.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((request) async {
        sent.add(request);
        return http.Response(
          jsonEncode({'version': '', 'count': 0, 'items': <Object>[]}),
          200,
        );
      }),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (_) async => 1);
  });

  tearDown(() async {
    content.debugReset();
    await prefs.setSignSupport(SignSupportLevel.off);
    SignAssetIndex.instance.debugReset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  Iterable<http.Request> overrideRequests() =>
      sent.where((r) => r.url.path == '/api/course/overrides');

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: child,
  );

  String titleOf(int module) =>
      PythonCourseCatalog.moduleByNumber(module)!.title;

  group('de un módulo a otro', () {
    testWidgets(
      'el aviso de abajo lleva al módulo anterior y avisa del cambio',
      (tester) async {
        phone(tester);
        final changes = <int>[];

        await tester.pumpWidget(
          host(LearningModuleScreen(moduleId: 2, onModuleChanged: changes.add)),
        );
        await tester.pumpAndSettle();
        expect(changes, [2]);
        expect(find.text(titleOf(2)), findsOneWidget);

        await tester.tap(
          find.text('Desliza hacia abajo para volver al Módulo 1'),
        );
        await tester.pumpAndSettle();

        expect(find.text(titleOf(1)), findsOneWidget);
        expect(changes, [2, 1]);
        // En el módulo 1 no hay anterior.
        expect(find.textContaining('volver al Módulo'), findsNothing);

        // Al volver atrás, la paleta vuelve a ser la del módulo 2.
        Navigator.of(tester.element(find.text(titleOf(1)))).pop();
        await tester.pumpAndSettle();
        expect(changes, [2, 1, 2]);
        expect(find.text(titleOf(2)), findsOneWidget);
      },
    );

    testWidgets('el aviso de arriba lleva al módulo siguiente', (tester) async {
      phone(tester);
      final changes = <int>[];

      await tester.pumpWidget(
        host(LearningModuleScreen(moduleId: 5, onModuleChanged: changes.add)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Desliza hacia arriba para ir al Módulo 6'));
      await tester.pumpAndSettle();

      expect(find.text(titleOf(6)), findsOneWidget);
      // En el último módulo no se ofrece un siguiente que no existe.
      expect(find.textContaining('ir al Módulo 7'), findsNothing);
      expect(changes, [5, 6]);

      // Al volver atrás, la paleta vuelve a ser la del módulo 5.
      Navigator.of(tester.element(find.text(titleOf(6)))).pop();
      await tester.pumpAndSettle();
      expect(changes, [5, 6, 5]);
    });

    testWidgets('deslizar hacia abajo desde arriba vuelve al módulo anterior', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 3)));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 300),
      );
      await tester.pumpAndSettle();

      expect(find.text(titleOf(2)), findsOneWidget);
      expect(find.text(titleOf(3)), findsNothing);
    });

    testWidgets('deslizar hacia arriba desde abajo pasa al siguiente', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 3)));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(find.text(titleOf(4)), findsOneWidget);

      // El gesto avisa muchas veces mientras dura, pero abre un solo módulo:
      // una vez atrás se vuelve al 3, no a otra copia del 4.
      Navigator.of(tester.element(find.text(titleOf(4)))).pop();
      await tester.pumpAndSettle();
      expect(find.text(titleOf(3)), findsOneWidget);
    });
  });

  group('la portada del módulo', () {
    tearDown(() async {
      final section = PythonCourseCatalog.section(1, 1)!;
      await CourseProgressStore.instance.resetSection(
        section.id,
        SectionActivityLauncher.activitiesFor(section),
      );
    });

    testWidgets('la circunferencia muestra el avance guardado', (tester) async {
      phone(tester);
      final section = PythonCourseCatalog.section(1, 1)!;
      final total = SectionActivityLauncher.activitiesFor(section).length;
      await CourseProgressStore.instance.markCompleted(
        section.id,
        CourseActivityKind.lectura,
      );

      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
      await tester.pumpAndSettle();

      final percentage = (100 / total).round();
      expect(find.text('$percentage%'), findsOneWidget);
      // Quien navega por voz oye de qué sección es y cuánto lleva.
      final label = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label ?? '').startsWith('Sección 1, ') &&
            w.properties.label!.contains(
              '1 de $total actividades completadas, $percentage por ciento',
            ),
      );
      expect(label, findsOneWidget);
      // Lo pinta: con avance, el arco lleno se dibuja sobre el vacío.
      final painted = find.descendant(
        of: find.byType(CircleProgressWidget).first,
        matching: find.byType(CustomPaint),
      );
      expect(painted, findsWidgets);
    });

    testWidgets('tocar una sección abre su capítulo', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
      await tester.pumpAndSettle();

      final section = PythonCourseCatalog.section(1, 2)!;
      final box = find.byWidgetPredicate(
        (w) => w is LessonBoxWidget && w.number == 2,
      );
      expect(tester.widget<LessonBoxWidget>(box).title, section.boxTitle);
      await tester.tap(box);
      await tester.pumpAndSettle();

      final chapter = tester.widget<ModuleChaptersScreen>(
        find.byType(ModuleChaptersScreen),
      );
      expect(chapter.moduleId, 1);
      expect(chapter.sectionNumber, 2);
      expect(find.text(section.displayTitle), findsOneWidget);
    });

    testWidgets('con apoyo en señas se puede deletrear la portada', (
      tester,
    ) async {
      phone(tester);
      await prefs.setSignSupport(SignSupportLevel.basic);

      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
      await tester.pump();

      await tester.tap(find.byTooltip('Mostrar lector de dactilología'));
      await tester.pump();

      final titles = [
        for (var number = 1; number <= 3; number++)
          PythonCourseCatalog.section(1, number)!.boxTitle,
      ];
      final panel = tester.widget<SignLanguagePanel>(
        find.byType(SignLanguagePanel),
      );
      expect(panel.text, '${titleOf(1)}. ${titles.join('. ')}.');
      expect(panel.showWordSigns, isFalse);

      await tester.pumpWidget(host(const SizedBox.shrink()));
    });

    testWidgets('una fila sin sección en el catálogo sigue teniendo nombre', (
      tester,
    ) async {
      // Sin ancho fijo, la fila calcula su tamaño a partir del círculo.
      await tester.pumpWidget(
        host(
          const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ModuleRowWidget(
                moduleId: 99,
                sectionNumber: 2,
                isCircleLeft: true,
                icon: Icons.code,
                iconColor: Colors.indigo,
                bgColor: Colors.white,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sección 2'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('el docente edita el módulo y al volver se pide lo editado', (
      tester,
    ) async {
      useRole('docente');
      phone(tester);

      await http.runWithClient(() async {
        await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
        await tester.pumpAndSettle();
        final before = overrideRequests().length;

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();
        expect(find.byType(TeacherModuleEditor), findsOneWidget);

        Navigator.of(tester.element(find.byType(TeacherModuleEditor))).pop();
        await tester.pumpAndSettle();

        expect(overrideRequests().length, before + 1);
      }, () => MockClient((_) async => http.Response('Not Found', 404)));
    });

    testWidgets('el estudiante no ve el lápiz de edición', (tester) async {
      phone(tester);
      await tester.pumpWidget(host(const LearningModuleScreen(moduleId: 1)));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsNothing);
    });
  });

  group('de un capítulo a otro', () {
    testWidgets('«Siguiente» y «Anterior» cambian de capítulo sin apilar', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModuleChaptersScreen(
                      moduleId: 2,
                      sectionNumber: 1,
                    ),
                  ),
                ),
                child: const Text('abrir capítulo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir capítulo'));
      await tester.pumpAndSettle();

      final first = PythonCourseCatalog.section(2, 1)!;
      final second = PythonCourseCatalog.section(2, 2)!;
      expect(find.text(first.displayTitle), findsOneWidget);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text(second.displayTitle), findsOneWidget);
      expect(find.text(first.displayTitle), findsNothing);

      await tester.tap(find.text('Anterior'));
      await tester.pumpAndSettle();
      expect(find.text(first.displayTitle), findsOneWidget);

      // Se reemplaza el capítulo, no se apila: atrás vuelve a donde se entró.
      Navigator.of(tester.element(find.text(first.displayTitle))).pop();
      await tester.pumpAndSettle();
      expect(find.text('abrir capítulo'), findsOneWidget);
    });

    testWidgets('el docente edita el capítulo y al volver se ve lo nuevo', (
      tester,
    ) async {
      useRole('docente');
      phone(tester);

      await http.runWithClient(() async {
        await tester.pumpWidget(
          host(
            const ModuleChaptersScreen(
              moduleId: 1,
              sectionNumber: 1,
              enableTeacherEditor: true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = overrideRequests().length;

        await tester.tap(find.byTooltip('Editar capítulo'));
        await tester.pumpAndSettle();
        final editor = tester.widget<TeacherModuleEditor>(
          find.byType(TeacherModuleEditor),
        );
        expect(editor.moduleId, '1');

        Navigator.of(tester.element(find.byType(TeacherModuleEditor))).pop();
        await tester.pumpAndSettle();

        expect(overrideRequests().length, before + 1);
      }, () => MockClient((_) async => http.Response('Not Found', 404)));
    });

    testWidgets('sin rol docente no aparece el lápiz aunque se permita', (
      tester,
    ) async {
      phone(tester);
      await tester.pumpWidget(
        host(
          const ModuleChaptersScreen(
            moduleId: 1,
            sectionNumber: 1,
            enableTeacherEditor: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Editar capítulo'), findsNothing);
    });

    testWidgets('un capítulo que no existe tiene botón para volver', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ModuleChaptersScreen(
                      moduleId: 1,
                      sectionNumber: 9,
                    ),
                  ),
                ),
                child: const Text('abrir capítulo'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir capítulo'));
      await tester.pumpAndSettle();

      expect(find.text('Capítulo no disponible'), findsOneWidget);
      expect(
        find.text(
          'No encontramos el capítulo 9 del módulo 1 en el catálogo del '
          'curso.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('abrir capítulo'), findsOneWidget);
    });
  });
}
