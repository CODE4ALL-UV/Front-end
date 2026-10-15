import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';

http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Pedir el enlace para cambiar la contraseña, de principio a fin.
///
/// Además de lo que ya mira la prueba de recuperación: el campo vacío, enviar
/// con la tecla del teclado, el mensaje por defecto si el servidor no dice
/// nada, volver al login y pedir el enlace otra vez si no llegó.
void main() {
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) server;

  ApiService api() => ApiService(
    baseUrl: 'http://servidor.de.prueba',
    client: MockClient((request) {
      requests.add(request);
      return server(request);
    }),
  );

  setUp(() {
    requests = [];
    server = (_) async => _json({'detail': ''}, 200);
  });

  /// Pone la pantalla encima de otra, como cuando se abre desde el login.
  Future<void> pumpOverLogin(WidgetTester tester, {String email = ''}) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ForgotPasswordScreen(initialEmail: email, api: api()),
                  ),
                ),
                child: const Text('EL LOGIN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('EL LOGIN'));
    await tester.pumpAndSettle();
  }

  testWidgets('con el campo vacío pide el correo y no envía', (tester) async {
    await pumpOverLogin(tester);

    await tester.tap(find.text('ENVIAR ENLACE'));
    await tester.pump();

    expect(find.text('Escribe tu correo electrónico.'), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('se puede enviar con la tecla de enviar del teclado', (
    tester,
  ) async {
    await pumpOverLogin(tester);

    await tester.enterText(
      find.byKey(const ValueKey('forgot-email')),
      'ana@example.com',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(jsonDecode(requests.single.body), {'correo': 'ana@example.com'});
    // El servidor no dijo nada: se explica igualmente qué pasa ahora.
    expect(
      find.textContaining('te enviamos un enlace para cambiar la contraseña'),
      findsOneWidget,
    );
  });

  testWidgets('si no llegó, se puede pedir otra vez', (tester) async {
    await pumpOverLogin(tester, email: 'ana@example.com');

    await tester.tap(find.text('ENVIAR ENLACE'));
    await tester.pumpAndSettle();
    expect(find.text('ENVIAR ENLACE'), findsNothing);

    await tester.tap(find.text('No me llegó: enviarlo otra vez'));
    await tester.pumpAndSettle();

    // Vuelve el formulario con el correo de antes.
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('forgot-email')),
    );
    expect(field.controller!.text, 'ana@example.com');
    await tester.tap(find.text('ENVIAR ENLACE'));
    await tester.pumpAndSettle();
    expect(requests, hasLength(2));
  });

  testWidgets('«Volver al inicio de sesión» cierra la pantalla', (
    tester,
  ) async {
    await pumpOverLogin(tester, email: 'ana@example.com');

    await tester.tap(find.text('ENVIAR ENLACE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VOLVER AL INICIO DE SESIÓN'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsNothing);
    expect(find.text('EL LOGIN'), findsOneWidget);
  });

  testWidgets('con el servidor de antes dice que aún no está disponible', (
    tester,
  ) async {
    server = (_) async => _json({'detail': 'Not Found'}, 404);
    await pumpOverLogin(tester, email: 'ana@example.com');

    await tester.tap(find.text('ENVIAR ENLACE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('todavía no está disponible'), findsOneWidget);
    // Se puede volver a intentar.
    expect(find.text('ENVIAR ENLACE'), findsOneWidget);
  });
}
