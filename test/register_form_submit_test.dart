import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/form_screen.dart';

/// Respuesta JSON en UTF-8, como la manda el servidor.
http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Lo que devuelve el servidor al crear la cuenta de [rol].
Map<String, Object?> _created(String rol) => {
  'id_usuario': 9,
  'nombre': 'Ana',
  'correo': 'ana@example.com',
  'tipo_discapacidad': null,
  'fecha_registro': '2026-10-15T10:00:00Z',
  'rol': rol,
};

/// Enviar el formulario de registro.
///
/// La validación va antes que el servidor, en el orden en que se rellena el
/// formulario, y cada aviso dice qué falta. Docente y director solo pueden
/// registrarse con el código de invitación de la coordinación: el código
/// viaja limpio y el estudiante nunca lo manda. Los códigos de estas
/// pruebas son de mentira.
void main() {
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) server;

  setUp(() {
    requests = [];
    server = (_) async => _json(_created('estudiante'), 201);
  });

  /// El formulario usa `http.Client()` sin que se lo pasen: todo lo que pida
  /// dentro de esta zona llega a [server].
  Future<void> withServer(Future<void> Function() body) => http.runWithClient(
    body,
    () => MockClient((request) {
      requests.add(request);
      return server(request);
    }),
  );

  Finder textFields() => find.byType(TextField);

  Future<void> pumpForm(WidgetTester tester, {VoidCallback? onSuccess}) async {
    tester.view.physicalSize = const Size(700, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: FormScreen(onSuccess: onSuccess),
      ),
    );
    await tester.pump();
  }

  Future<void> fill(
    WidgetTester tester, {
    String name = 'Ana',
    String email = 'ana@example.com',
    String password = 'clave-de-prueba',
  }) async {
    await tester.enterText(textFields().at(0), name);
    await tester.enterText(textFields().at(1), email);
    await tester.enterText(textFields().at(2), password);
  }

  Future<void> chooseRole(WidgetTester tester, String role) async {
    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(role).last);
    await tester.pumpAndSettle();
  }

  Future<void> acceptTerms(WidgetTester tester) async {
    await tester.tap(find.text('Acepto términos y condiciones'));
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.text('Registrarse'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('validación antes de llamar al servidor', () {
    testWidgets('sin nombre lo pide', (tester) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester, name: '   ');
        await acceptTerms(tester);
        await submit(tester);

        expect(find.text('Ingresa tu nombre'), findsOneWidget);
        expect(requests, isEmpty);
      });
    });

    testWidgets('un correo sin arroba no vale', (tester) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester, email: 'ana.example.com');
        await acceptTerms(tester);
        await submit(tester);

        expect(
          find.text('Ingresa un correo electrónico válido'),
          findsOneWidget,
        );
        expect(requests, isEmpty);
      });
    });

    testWidgets('la contraseña necesita al menos 6 caracteres', (tester) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester, password: '12345');
        await acceptTerms(tester);
        await submit(tester);

        expect(
          find.text('La contraseña debe tener al menos 6 caracteres'),
          findsOneWidget,
        );
        expect(requests, isEmpty);
      });
    });

    testWidgets('docente sin código de invitación no se envía', (tester) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester);
        await chooseRole(tester, 'Docente');
        await acceptTerms(tester);
        await submit(tester);

        expect(
          find.text(
            'Para registrarte como docente escribe el código de invitación '
            'que te dio la coordinación.',
          ),
          findsOneWidget,
        );
        expect(requests, isEmpty);
      });
    });

    testWidgets('sin aceptar los términos no se envía', (tester) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester);
        await submit(tester);

        expect(
          find.text('Debes aceptar los términos y condiciones'),
          findsOneWidget,
        );
        expect(requests, isEmpty);
      });
    });

    testWidgets('la casilla de los términos se marca y se desmarca', (
      tester,
    ) async {
      await pumpForm(tester);

      bool checked() => tester.widget<Checkbox>(find.byType(Checkbox)).value!;

      expect(checked(), isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(checked(), isTrue);
      // Toda la fila se puede pulsar, no solo la casilla.
      await tester.tap(find.text('Aviso'));
      await tester.pump();
      expect(checked(), isFalse);
    });
  });

  group('envío al servidor', () {
    testWidgets('el estudiante se registra sin código y vuelve al login', (
      tester,
    ) async {
      var done = 0;

      await withServer(() async {
        await pumpForm(tester, onSuccess: () => done++);
        await fill(tester, email: '  ana@example.com ');

        await tester.tap(find.text('No especificar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tipo 1').last);
        await tester.pumpAndSettle();

        await acceptTerms(tester);
        await submit(tester);

        final request = requests.single;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/register');
        expect(jsonDecode(request.body), {
          'nombre': 'Ana',
          'correo': 'ana@example.com',
          'password': 'clave-de-prueba',
          'tipo_discapacidad': 1,
          'rol': 'estudiante',
        });
        expect(
          find.text('Registro exitoso: Ana. Rol asignado: estudiante'),
          findsOneWidget,
        );
        expect(done, 1);
      });
    });

    testWidgets('el docente manda su código sin espacios', (tester) async {
      server = (_) async => _json(_created('docente'), 201);
      var done = 0;

      await withServer(() async {
        await pumpForm(tester, onSuccess: () => done++);
        await fill(tester);
        await chooseRole(tester, 'Docente');
        await tester.enterText(textFields().at(3), '  CODIGO-DOCENTE-PRUEBA ');
        await acceptTerms(tester);
        await submit(tester);

        final body = jsonDecode(requests.single.body) as Map;
        expect(body['rol'], 'docente');
        expect(body['codigo_invitacion'], 'CODIGO-DOCENTE-PRUEBA');
        expect(body['tipo_discapacidad'], isNull);
        expect(
          find.text('Registro exitoso: Ana. Rol asignado: docente'),
          findsOneWidget,
        );
        expect(done, 1);
      });
    });

    testWidgets('con un código que no vale se ve lo que dice el servidor', (
      tester,
    ) async {
      server = (_) async =>
          _json({'detail': 'El código de invitación no es válido.'}, 403);
      var done = 0;

      await withServer(() async {
        await pumpForm(tester, onSuccess: () => done++);
        await fill(tester);
        await chooseRole(tester, 'Director');
        await tester.enterText(textFields().at(3), 'CODIGO-EQUIVOCADO');
        await acceptTerms(tester);
        await submit(tester);

        expect(jsonDecode(requests.single.body)['rol'], 'director');
        expect(
          find.text('El código de invitación no es válido.'),
          findsOneWidget,
        );
        expect(done, 0);
        // Se puede corregir y volver a intentar.
        expect(find.text('Registrarse'), findsOneWidget);
      });
    });

    testWidgets('volver a estudiante quita el código del formulario', (
      tester,
    ) async {
      await withServer(() async {
        await pumpForm(tester);
        await fill(tester);
        await chooseRole(tester, 'Docente');
        await tester.enterText(textFields().at(3), 'CODIGO-DOCENTE-PRUEBA');

        await tester.tap(find.text('Docente'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Estudiante').last);
        await tester.pumpAndSettle();
        expect(find.text('Código de invitación'), findsNothing);

        await acceptTerms(tester);
        await submit(tester);

        final body = jsonDecode(requests.single.body) as Map;
        expect(body['rol'], 'estudiante');
        expect(body.containsKey('codigo_invitacion'), isFalse);
      });
    });

    testWidgets('con el servidor caído explica que no hay conexión', (
      tester,
    ) async {
      server = (_) async => throw http.ClientException('sin red');

      await withServer(() async {
        await pumpForm(tester);
        await fill(tester);
        await acceptTerms(tester);
        await submit(tester);

        expect(
          find.textContaining('No se pudo conectar con el servidor'),
          findsOneWidget,
        );
      });
    });

    testWidgets('mientras espera no se puede enviar dos veces', (tester) async {
      final answer = Completer<http.Response>();
      server = (_) => answer.future;

      await withServer(() async {
        await pumpForm(tester);
        await fill(tester);
        await acceptTerms(tester);
        await tester.tap(find.text('Registrarse'));
        await tester.pump();

        expect(find.text('Registrarse'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        answer.complete(
          _json({'detail': 'Ese correo ya está registrado.'}, 400),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Ese correo ya está registrado.'), findsOneWidget);
        expect(requests, hasLength(1));
      });
    });
  });

  testWidgets('con el tema oscuro el formulario sigue en claro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.dark),
        home: const FormScreen(),
      ),
    );
    await tester.pump();

    // Los desplegables y sus flechas se ven sobre el fondo blanco.
    final context = tester.element(find.text('Rol de acceso'));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}
