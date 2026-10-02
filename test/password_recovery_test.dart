import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/launch_link.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/reset_password_screen.dart';
import 'package:flutter_code4all/utils/browser_port_stub.dart';

/// Un servidor de mentira que apunta lo que se le pidió.
class _FakeApi extends ApiService {
  _FakeApi({this.failWith});

  final ApiException? failWith;
  final List<String> asked = [];
  final List<(String, String)> resets = [];

  @override
  Future<String> requestPasswordReset(String email) async {
    asked.add(email);
    if (failWith != null) throw failWith!;
    return 'Si hay una cuenta con ese correo, te enviamos un enlace.';
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    resets.add((token, password));
    if (failWith != null) throw failWith!;
    return 'Listo. Ya puedes iniciar sesión con tu contraseña nueva.';
  }
}

/// Recuperar la contraseña: el enlace que llega al correo, pedirlo y elegir
/// la nueva.
void main() {
  setUp(LaunchLink.debugReset);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: screen,
      ),
    );
    await tester.pump();
  }

  group('el enlace del correo', () {
    test('se lee al abrir la app y la dirección queda limpia', () {
      final browser = MemoryBrowserPort(
        Uri.parse('https://code4all-web.onrender.com/?restablecer=abc.def.ghi'),
      );

      LaunchLink.capture(browser);

      // Que el token no se quede en la barra ni en el historial.
      expect(browser.current.toString(), 'https://code4all-web.onrender.com/');
      expect(LaunchLink.takeResetToken(), 'abc.def.ghi');
      // Se usa una vez.
      expect(LaunchLink.takeResetToken(), isNull);
    });

    test('una dirección normal no se toca', () {
      final browser = MemoryBrowserPort(
        Uri.parse('https://code4all-web.onrender.com/#/'),
      );

      LaunchLink.capture(browser);

      expect(
        browser.current.toString(),
        'https://code4all-web.onrender.com/#/',
      );
      expect(LaunchLink.takeResetToken(), isNull);
    });
  });

  group('pedir el enlace', () {
    testWidgets('el login lo ofrece y lleva el correo ya escrito', (
      tester,
    ) async {
      await pump(tester, const LoginScreen());

      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.tap(find.byKey(const ValueKey('forgot-password')));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('forgot-email')),
      );
      expect(field.controller!.text, 'ana@example.com');
    });

    testWidgets('con un correo incompleto lo dice y no envía nada', (
      tester,
    ) async {
      final api = _FakeApi();
      await pump(tester, ForgotPasswordScreen(initialEmail: 'ana@', api: api));

      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pump();

      expect(find.textContaining('no parece completo'), findsOneWidget);
      expect(api.asked, isEmpty);
    });

    testWidgets('con un correo válido lo pide y avisa de que se envió', (
      tester,
    ) async {
      final api = _FakeApi();
      await pump(
        tester,
        ForgotPasswordScreen(initialEmail: ' ana@example.com ', api: api),
      );

      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(api.asked, ['ana@example.com']);
      expect(find.textContaining('te enviamos un enlace'), findsOneWidget);
      expect(find.textContaining('30 minutos'), findsOneWidget);
      expect(find.text('VOLVER AL INICIO DE SESIÓN'), findsOneWidget);
    });

    testWidgets('si el servidor no puede, se ve por qué', (tester) async {
      final api = _FakeApi(
        failWith: ApiException(
          statusCode: 503,
          message:
              'La recuperación de contraseña no está configurada en el servidor.',
        ),
      );
      await pump(
        tester,
        ForgotPasswordScreen(initialEmail: 'ana@example.com', api: api),
      );

      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no está configurada'), findsOneWidget);
    });
  });

  group('elegir la contraseña nueva', () {
    Future<void> fill(WidgetTester tester, String a, String b) async {
      await tester.enterText(find.byKey(const ValueKey('reset-password')), a);
      await tester.enterText(find.byKey(const ValueKey('reset-repeat')), b);
      await tester.tap(find.text('GUARDAR CONTRASEÑA'));
      await tester.pumpAndSettle();
    }

    testWidgets('las dos tienen que coincidir', (tester) async {
      final api = _FakeApi();
      await pump(
        tester,
        ResetPasswordScreen(token: 't', onDone: () {}, api: api),
      );

      await fill(tester, 'clave-nueva', 'clave-nuev');

      expect(find.textContaining('no coinciden'), findsOneWidget);
      expect(api.resets, isEmpty);
    });

    testWidgets('al menos 6 caracteres, como al registrarse', (tester) async {
      final api = _FakeApi();
      await pump(
        tester,
        ResetPasswordScreen(token: 't', onDone: () {}, api: api),
      );

      await fill(tester, 'corta', 'corta');

      expect(find.textContaining('al menos 6'), findsOneWidget);
      expect(api.resets, isEmpty);
    });

    testWidgets('se guarda con el token del enlace y lleva al login', (
      tester,
    ) async {
      final api = _FakeApi();
      var done = false;
      await pump(
        tester,
        ResetPasswordScreen(
          token: 'token-del-correo',
          onDone: () => done = true,
          api: api,
        ),
      );

      await fill(tester, 'clave-nueva', 'clave-nueva');

      expect(api.resets, [('token-del-correo', 'clave-nueva')]);
      expect(find.textContaining('Ya puedes iniciar sesión'), findsOneWidget);

      await tester.tap(find.text('IR A INICIAR SESIÓN'));
      expect(done, isTrue);
    });

    testWidgets('con un enlace caducado ofrece pedir otro', (tester) async {
      final api = _FakeApi(
        failWith: ApiException(
          statusCode: 400,
          message: 'El enlace ya no sirve: caducó o ya se usó. Pide uno nuevo.',
        ),
      );
      await pump(
        tester,
        ResetPasswordScreen(token: 'viejo', onDone: () {}, api: api),
      );

      await fill(tester, 'clave-nueva', 'clave-nueva');

      expect(find.textContaining('caducó'), findsOneWidget);
      await tester.tap(find.text('PEDIR UN ENLACE NUEVO'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('el botón del ojo deja ver lo escrito', (tester) async {
      await pump(
        tester,
        ResetPasswordScreen(token: 't', onDone: () {}, api: _FakeApi()),
      );

      TextField field() => tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const ValueKey('reset-password')),
          matching: find.byType(TextField),
        ),
      );

      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña').first);
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });
}
