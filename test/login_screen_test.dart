import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/ui/core/themes/module_theme.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/social_auth_block.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
  description: 'TextField con etiqueta "$label"',
);

class _TestModuleCardThemeColors implements ModuleTheme {
  @override
  Color get headerBackground => const Color(0xFF5E35B1);

  @override
  Color get headerForeground => Colors.white;

  @override
  Type get type => ModuleTheme;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ttsChannel = MethodChannel('flutter_tts');

  setUpAll(() {
    // Las pruebas verifican la pantalla, no reproducen audio real.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async => 1);
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    accessibilityReadingState.clearHighlight();
    accessibilityReadingState.currentText.value = null;
  });

  Widget buildApp({
    VoidCallback? onRegister,
    void Function(String role)? onSuccess,
  }) {
    return MaterialApp(
      theme: ThemeData.light().copyWith(
        extensions: <ThemeExtension<dynamic>>[_TestModuleCardThemeColors()],
      ),
      home: LoginScreen(onRegister: onRegister, onSuccess: onSuccess),
    );
  }

  Future<void> mountLogin(
    WidgetTester tester, {
    VoidCallback? onRegister,
    void Function(String role)? onSuccess,
  }) async {
    await tester.pumpWidget(
      buildApp(onRegister: onRegister, onSuccess: onSuccess),
    );
    // La pantalla inicia el aviso accesible desde un post-frame callback.
    await tester.pump();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      accessibilityReadingState.clearHighlight();
      accessibilityReadingState.currentText.value = null;
      await tester.pump();
    });
  }

  Future<void> submitLogin(WidgetTester tester) async {
    final button = find.text('INICIAR SESIÓN');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('LoginScreen: renderizado y accesibilidad', () {
    testWidgets('muestra los campos, botones principales y aviso Braille', (
      tester,
    ) async {
      await mountLogin(tester);

      expect(find.text('CODE4ALL v0.1.'), findsOneWidget);
      expect(_field('Correo electrónico'), findsOneWidget);
      expect(_field('Contraseña'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('REGISTRARSE'), findsOneWidget);
      expect(find.text('¿Cómo se usa Code4All? Ver el manual'), findsOneWidget);
      expect(find.byKey(const ValueKey('braille-login-hint')), findsOneWidget);
      expect(find.byTooltip('Teclado Braille'), findsOneWidget);
      expect(find.byType(SocialAuthBlock), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el campo de contraseña oculta el contenido', (tester) async {
      await mountLogin(tester);

      final password = tester.widget<TextField>(_field('Contraseña'));
      expect(password.obscureText, isTrue);
      expect(password.controller, isNotNull);
    });

    testWidgets('se registra al pulsar REGISTRARSE', (tester) async {
      var called = 0;
      await mountLogin(tester, onRegister: () => called++);

      final register = find.text('REGISTRARSE');
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pump();

      expect(called, 1);
    });
  });

  group('LoginScreen: validación del formulario', () {
    testWidgets('rechaza un correo vacío', (tester) async {
      await mountLogin(tester);
      await tester.enterText(_field('Contraseña'), 'clave123');
      await submitLogin(tester);

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
    });

    testWidgets('rechaza un correo que no contiene arroba', (tester) async {
      await mountLogin(tester);
      await tester.enterText(_field('Correo electrónico'), 'correo-invalido');
      await tester.enterText(_field('Contraseña'), 'clave123');
      await submitLogin(tester);

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
    });

    testWidgets('rechaza una contraseña de menos de seis caracteres', (
      tester,
    ) async {
      await mountLogin(tester);
      await tester.enterText(
        _field('Correo electrónico'),
        'persona@example.com',
      );
      await tester.enterText(_field('Contraseña'), '12345');
      await submitLogin(tester);

      expect(
        find.text('La contraseña debe tener al menos 6 caracteres'),
        findsOneWidget,
      );
    });

    testWidgets('un correo inválido no llama a onSuccess', (tester) async {
      var successCalls = 0;
      await mountLogin(tester, onSuccess: (_) => successCalls++);
      await tester.enterText(_field('Correo electrónico'), 'sin-arroba');
      await tester.enterText(_field('Contraseña'), 'clave123');
      await submitLogin(tester);

      expect(successCalls, 0);
    });
  });

  group('LoginScreen: navegación', () {
    testWidgets('abre la pantalla de recuperación de contraseña', (
      tester,
    ) async {
      await mountLogin(tester);
      await tester.enterText(
        _field('Correo electrónico'),
        'persona@example.com',
      );

      final forgotButton = find.byKey(const ValueKey('forgot-password'));
      await tester.ensureVisible(forgotButton);
      await tester.tap(forgotButton);
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('mantiene visible el acceso al manual desde el login', (
      tester,
    ) async {
      await mountLogin(tester);

      final manualButton = find.byKey(const ValueKey('user-manual'));
      expect(manualButton, findsOneWidget);
      expect(find.text('¿Cómo se usa Code4All? Ver el manual'), findsOneWidget);
    });

    testWidgets(
      'el acceso directo al teclado Braille tiene etiqueta accesible',
      (tester) async {
        await mountLogin(tester);

        expect(find.byTooltip('Teclado Braille'), findsOneWidget);
        expect(find.bySemanticsLabel('Teclado Braille'), findsWidgets);
      },
    );
  });

  group('LoginScreen: tamaños de pantalla', () {
    testWidgets('se construye en una pantalla estrecha sin errores', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await mountLogin(tester);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('usa un diseño amplio sin errores en escritorio', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1100, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await mountLogin(tester);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(find.text('REGISTRARSE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
