import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/director_oversight_store.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/director/director_home_screen.dart';
import 'package:flutter_code4all/ui/teacher/editors/editor_scaffold.dart';
import 'package:flutter_code4all/ui/teacher/teacher_course_screen.dart';

/// Lo que cada rol tiene que poder alcanzar desde su pantalla.
///
/// Nace de tres cosas que se perdieron al pasar a la barra común: las
/// pestañas del docente (sus estadísticas existían pero no había cómo
/// llegar), el «Listo» de los editores (lo escrito no volvía nunca a la
/// sección) y cualquier sitio donde el docente o la dirección pudieran
/// cambiar los colores o el tamaño del texto.
void main() {
  final content = CourseContentStore.instance;
  final stats = CourseAnalyticsStore.instance;
  final oversight = DirectorOversightStore.instance;

  setUp(() {
    content.debugReset();
    content.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'version': '', 'count': 0, 'items': []}),
          200,
        ),
      ),
    );
    stats.debugReset();
    stats.debugSeed();
    oversight.debugReset();
    oversight.debugSeed();
    ThemeManager.changeTheme(AppThemeMode.light);
  });

  tearDown(() {
    content.debugReset();
    stats.debugReset();
    oversight.debugReset();
    ThemeManager.changeTheme(AppThemeMode.light);
  });

  Widget app(Widget home) => ValueListenableBuilder<AppThemeMode>(
    valueListenable: ThemeManager.themeNotifier,
    builder: (_, mode, _) => MaterialApp(
      theme: AppTheme.getTheme(mode: mode),
      home: home,
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('el docente ve sus tres pestañas y llega a las estadísticas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const TeacherCourseScreen()));
    await settle(tester);

    expect(find.text('Temario'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Estudiantes'), findsOneWidget);

    await tester.tap(find.text('Estadísticas'));
    await settle(tester);
    expect(find.text('Todavía no hay actividad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('docente y dirección pueden cambiar colores y tamaño del texto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final screen in const [TeacherCourseScreen(), DirectorHomeScreen()]) {
      await tester.pumpWidget(app(screen));
      await settle(tester);
      expect(
        find.byTooltip('Accesibilidad: colores y tamaño del texto'),
        findsOneWidget,
        reason: '${screen.runtimeType} sin botón de accesibilidad',
      );
    }

    await tester.tap(
      find.byTooltip('Accesibilidad: colores y tamaño del texto'),
    );
    await settle(tester);
    await tester.tap(find.text('Oscuro'));
    await settle(tester);

    expect(ThemeManager.themeNotifier.value, AppThemeMode.dark);
  });

  test('la barra deja sitio a las pestañas', () {
    final bar = GlobalAppBarWidget(
      bottom: TabBar(
        tabs: const [
          Tab(text: 'Uno'),
          Tab(text: 'Dos'),
        ],
      ),
    );
    expect(bar.preferredSize.height, greaterThan(kToolbarHeight));
  });

  testWidgets('los editores tienen «Listo» y devuelven lo escrito', (
    tester,
  ) async {
    var done = false;
    var deleted = false;

    await tester.pumpWidget(
      app(
        EditorScaffold(
          title: 'Lectura',
          onDone: () => done = true,
          onDelete: () => deleted = true,
          child: const Text('contenido'),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Lectura'), findsOneWidget);
    await tester.tap(find.text('Listo'));
    await tester.tap(find.byTooltip('Quitar de la sección'));
    expect(done, isTrue);
    expect(deleted, isTrue);
  });
}
