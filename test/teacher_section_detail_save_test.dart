import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/course/course_content_store.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/chapter_section_screen.dart';
import 'package:flutter_code4all/ui/teacher/teacher_section_detail.dart';

/// Una sesión con o sin token, sin tocar el almacenamiento seguro real.
class _FakeAuth extends AuthStorage {
  _FakeAuth([this.token = 'token-de-prueba']);

  final String? token;

  @override
  Future<String?> getToken() async => token;
}

/// Guardar, deshacer y previsualizar una sección desde la pantalla del docente.
///
/// Lo escrito en el detalle de una sección no llega al estudiante hasta que el
/// docente pulsa «Guardar». Aquí se comprueba lo que viaja al servidor (qué
/// ruta, con qué cuerpo y con qué sesión), lo que el docente lee cuando sale
/// bien y cuando no, y que «Volver al original» pide confirmación antes de
/// tirar su trabajo. Si algo de esto falla, el docente cree que guardó y no.
void main() {
  final store = CourseContentStore.instance;
  late List<http.Request> sent;

  /// Conecta el almacén del temario a un servidor falso.
  void serve(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'token-de-prueba',
  }) {
    sent = [];
    store.debugUse(
      api: ApiService(baseUrl: 'http://servidor.de.prueba'),
      client: MockClient((request) {
        sent.add(request);
        return handler(request);
      }),
      auth: _FakeAuth(token),
    );
  }

  http.Response ok([Object body = const {'ok': true}]) =>
      http.Response(jsonEncode(body), 200);

  setUp(() {
    store.debugReset();
    serve((_) async => ok());
  });

  tearDown(store.debugReset);

  Future<void> mount(
    WidgetTester tester, {
    int module = 1,
    int section = 1,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TeacherSectionDetail(
            moduleNumber: module,
            sectionNumber: section,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // El título es siempre el primer campo de la tarjeta de identidad.
  Finder titleField() => find.byType(TextField).at(0);

  String titleText(WidgetTester tester) =>
      tester.widget<TextField>(titleField()).controller!.text;

  FilledButton saveButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
  }

  final original = PythonCourseCatalog.section(1, 1)!;

  group('guardar una sección', () {
    testWidgets(
      'envía la sección editada al servidor con la sesión del docente',
      (tester) async {
        await mount(tester);

        await tester.enterText(titleField(), '  Python desde cero  ');
        await tester.pumpAndSettle();
        await tapSave(tester);

        final put = sent.singleWhere((r) => r.method == 'PUT');
        expect(put.url.path, '/api/course/overrides/section/${original.id}');
        expect(put.headers['Authorization'], 'Bearer token-de-prueba');

        final content = jsonDecode(put.body)['content'] as Map;
        // El texto viaja recortado: los espacios sobrantes no son contenido.
        expect(content['title'], 'Python desde cero');
        // Lo que no se tocó viaja igual que estaba.
        expect(content['summary'], original.summary);
        expect((content['quiz'] as List).length, original.quiz.length);

        // El docente sabe que ya está: lo lee y el botón deja de pedirle nada.
        expect(
          find.text('Guardado. Los estudiantes ya lo ven.'),
          findsOneWidget,
        );
        expect(
          find.text('Guardado. Los estudiantes lo ven así.'),
          findsOneWidget,
        );
        expect(find.text('Editada'), findsOneWidget);
        expect(find.text('Volver al original'), findsOneWidget);
        expect(saveButton(tester).onPressed, isNull);
        expect(store.isSectionEdited(original.id), isTrue);
        expect(store.section(1, 1)!.title, 'Python desde cero');
      },
    );

    testWidgets('un título corto vacío se guarda como «sin título corto»', (
      tester,
    ) async {
      await mount(tester);

      await tester.enterText(find.byType(TextField).at(1), '   ');
      await tester.pumpAndSettle();
      expect(find.text('Tienes cambios sin guardar'), findsOneWidget);

      await tapSave(tester);

      final put = sent.singleWhere((r) => r.method == 'PUT');
      expect(jsonDecode(put.body)['content']['shortTitle'], isNull);
    });

    testWidgets(
      'si el servidor falla, avisa con palabras y no da por guardado',
      (tester) async {
        serve((_) async => http.Response('boom', 500));
        await mount(tester);

        await tester.enterText(titleField(), 'Título que no se guarda');
        await tester.pumpAndSettle();
        await tapSave(tester);

        expect(find.text('No se pudo guardar (error 500).'), findsOneWidget);
        // Lo escrito sigue ahí y se puede volver a intentar.
        expect(titleText(tester), 'Título que no se guarda');
        expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
        expect(saveButton(tester).onPressed, isNotNull);
        expect(store.isSectionEdited(original.id), isFalse);
        expect(find.text('Editada'), findsNothing);
      },
    );

    testWidgets('en el curso general explica que solo edita la coordinación', (
      tester,
    ) async {
      serve((_) async => http.Response('{"detail":"no"}', 403));
      await mount(tester);

      await tester.enterText(titleField(), 'Otro título');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(
        find.textContaining('El curso general solo lo edita la coordinación'),
        findsOneWidget,
      );
    });

    testWidgets('sin conexión le dice que su texto sigue en pantalla', (
      tester,
    ) async {
      serve((_) async => throw http.ClientException('sin red'));
      await mount(tester);

      await tester.enterText(titleField(), 'Escrito sin conexión');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(find.textContaining('el servidor no responde'), findsOneWidget);
      expect(titleText(tester), 'Escrito sin conexión');
    });

    testWidgets('sin sesión no se envía nada y se pide volver a entrar', (
      tester,
    ) async {
      serve((_) async => ok(), token: null);
      await mount(tester);

      await tester.enterText(titleField(), 'Sin sesión');
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(sent, isEmpty);
      expect(
        find.text(
          'Tu sesión no está iniciada. Vuelve a entrar para poder editar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'volver a escribir tras un error quita el aviso al cambiar algo',
      (tester) async {
        serve((_) async => http.Response('', 413));
        await mount(tester);

        await tester.enterText(titleField(), 'Muy largo');
        await tester.pumpAndSettle();
        await tapSave(tester);
        expect(find.textContaining('demasiado grande'), findsOneWidget);

        // Cambiar una actividad pasa por _update, que limpia el aviso anterior.
        await tester.ensureVisible(find.byType(SwitchListTile));
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();

        expect(find.textContaining('demasiado grande'), findsNothing);
      },
    );
  });

  group('volver a la versión original', () {
    void seedEdited() {
      store.debugSeed({
        CourseContentStore.sectionKey(original.id): {
          'title': 'Versión del profe',
        },
      });
    }

    testWidgets('una sección editada se marca y ofrece volver al original', (
      tester,
    ) async {
      seedEdited();
      await mount(tester);

      expect(titleText(tester), 'Versión del profe');
      expect(find.text('Editada'), findsOneWidget);
      expect(
        find.text('Guardado. Los estudiantes lo ven así.'),
        findsOneWidget,
      );
      expect(find.text('Volver al original'), findsOneWidget);
    });

    testWidgets('cancelar la confirmación no borra nada', (tester) async {
      seedEdited();
      await mount(tester);

      await tester.tap(find.text('Volver al original'));
      await tester.pumpAndSettle();

      expect(find.text('¿Borrar tus cambios en esta sección?'), findsOneWidget);
      expect(
        find.textContaining('volverá al contenido original del curso'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(sent, isEmpty);
      expect(titleText(tester), 'Versión del profe');
      expect(store.isSectionEdited(original.id), isTrue);
    });

    testWidgets('confirmar quita la edición en el servidor y en pantalla', (
      tester,
    ) async {
      seedEdited();
      await mount(tester);

      await tester.tap(find.text('Volver al original'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();

      final delete = sent.singleWhere((r) => r.method == 'DELETE');
      expect(delete.url.path, '/api/course/overrides/section/${original.id}');
      expect(titleText(tester), original.title);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).controller!.text,
        original.summary,
      );
      expect(
        find.text('Sección devuelta a su versión original.'),
        findsOneWidget,
      );
      expect(find.text('Editada'), findsNothing);
      expect(find.text('Sin cambios'), findsOneWidget);
      expect(store.isSectionEdited(original.id), isFalse);
    });

    testWidgets('si el servidor no lo permite, la edición sigue y se avisa', (
      tester,
    ) async {
      seedEdited();
      serve((_) async => http.Response('', 401));
      await mount(tester);

      await tester.tap(find.text('Volver al original'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tu sesión caducó'), findsOneWidget);
      expect(titleText(tester), 'Versión del profe');
      expect(store.isSectionEdited(original.id), isTrue);
    });
  });

  group('ver como estudiante', () {
    testWidgets('enseña lo escrito aunque todavía no esté guardado', (
      tester,
    ) async {
      store.debugSeed({
        CourseContentStore.moduleKey(1): {'title': 'Primeros pasos del profe'},
      });
      await mount(tester);

      await tester.enterText(titleField(), 'Borrador sin guardar');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ver como estudiante'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final preview = tester.widget<ChapterSectionScreen>(
        find.byType(ChapterSectionScreen),
      );
      expect(preview.section.title, 'Borrador sin guardar');
      expect(preview.section.id, original.id);
      // El módulo lleva el nombre que el docente le haya puesto.
      expect(preview.module.title, 'Primeros pasos del profe');
      // Previsualizar no guarda nada.
      expect(sent, isEmpty);
    });
  });
}
