import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/facebook_auth_service.dart';
import 'package:flutter_code4all/data/services/launch_link.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';
import 'package:flutter_code4all/utils/browser_port_stub.dart';

/// Respuesta JSON en UTF-8, como la manda el servidor.
http.Response _json(Object body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// Una sesión abierta por el servidor para [rol].
Map<String, Object?> _session(String rol, {String? photoUrl}) => {
  'access_token': 'token-de-prueba',
  'token_type': 'bearer',
  'user_id': 42,
  'email': 'ana@example.com',
  'nombre': 'Ana',
  'rol': rol,
  'photo_url': ?photoUrl,
};

/// Un micrófono de mentira que contesta lo que se le diga.
class _FakeDictation implements VoiceDictation {
  String? reply;
  bool unavailable = false;
  bool waitForStop = false;
  int stops = 0;
  Completer<String?>? _pending;

  @override
  Future<String?> listen({void Function(String partial)? onPartial}) async {
    if (unavailable) throw DictationUnavailableException('No hay micrófono.');
    if (!waitForStop) return reply;
    return (_pending = Completer<String?>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(reply);
  }

  @override
  Future<void> cue({required bool start}) async {}
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
  description: 'TextField con etiqueta "$label"',
);

/// Las formas de entrar desde el login y lo que pasa cuando algo falla.
///
/// Las pruebas de la pantalla ya miran la validación; aquí se mira lo que
/// viene después: qué se manda al servidor, qué se guarda de la sesión,
/// qué mensaje ve (u oye) la persona en cada error y a qué rol se entra,
/// con correo y contraseña, con Google, con Facebook y con el teclado
/// Braille.
void main() {
  const ttsChannel = MethodChannel('flutter_tts');
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  const googleChannel = MethodChannel('plugins.flutter.io/google_sign_in');
  const launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Lo que hay en el almacenamiento seguro del dispositivo.
  late Map<String, String> stored;

  /// Si es true, guardar en el almacenamiento seguro falla.
  late bool storageFails;

  /// Lo que devuelve la ventana de Google: null es que se cerró sin elegir.
  late Map<String, Object?>? googleAccount;

  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) server;

  setUp(() {
    stored = {};
    storageFails = false;
    googleAccount = null;
    requests = [];
    server = (_) async => _json({'detail': 'Not Found'}, 404);
    LaunchLink.debugReset();
    dotenv.testLoad(fileInput: 'GOOGLE_CLIENT_ID=cliente-de-prueba');

    messenger.setMockMethodCallHandler(ttsChannel, (call) async => 1);
    messenger.setMockMethodCallHandler(storageChannel, (call) async {
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
      final key = args['key']?.toString() ?? '';
      switch (call.method) {
        case 'write':
          if (storageFails) {
            throw PlatformException(code: 'sin-espacio', message: 'lleno');
          }
          stored[key] = args['value']?.toString() ?? '';
          return null;
        case 'read':
          return stored[key];
        case 'readAll':
          return stored;
        case 'delete':
          stored.remove(key);
          return null;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(googleChannel, (call) async {
      switch (call.method) {
        case 'signIn':
          return googleAccount;
        case 'getTokens':
          return {
            'accessToken': 'acceso-de-google',
            'idToken': 'identidad-de-google',
          };
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(ttsChannel, null);
    messenger.setMockMethodCallHandler(storageChannel, null);
    messenger.setMockMethodCallHandler(googleChannel, null);
    messenger.setMockMethodCallHandler(launcherChannel, null);
    LaunchLink.debugReset();
    dotenv.clean();
    accessibilityReadingState.clearHighlight();
    accessibilityReadingState.currentText.value = null;
  });

  /// El login usa `http.Client()` sin que se lo pasen: todo lo que pida
  /// dentro de esta zona llega a [server].
  Future<void> withServer(Future<void> Function() body) => http.runWithClient(
    body,
    () => MockClient((request) {
      requests.add(request);
      return server(request);
    }),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpLogin(
    WidgetTester tester, {
    void Function(String role)? onSuccess,
    FacebookAuthService? facebookAuth,
    VoiceDictation? dictation,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: LoginScreen(
          onSuccess: onSuccess,
          facebookAuth: facebookAuth,
          dictation: dictation,
        ),
      ),
    );
    await tester.pump();
  }

  /// Desmonta la pantalla para que no queden temporizadores vivos.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> signInWithEmail(WidgetTester tester) async {
    await tester.enterText(_field('Correo electrónico'), ' ana@example.com ');
    await tester.enterText(_field('Contraseña'), 'clave-de-prueba');
    await tester.tap(find.text('INICIAR SESIÓN'));
    await settle(tester);
  }

  group('con correo y contraseña', () {
    for (final (rol, welcome) in [
      ('estudiante', 'Tu rol es estudiante y puedes acceder a aprendizaje.'),
      ('docente', 'Tu rol es docente.'),
      ('director', 'Tu rol es director.'),
    ]) {
      testWidgets('entra como $rol, guarda la sesión y da la bienvenida', (
        tester,
      ) async {
        server = (_) async => _json(_session(rol), 200);
        final roles = <String>[];

        await withServer(() async {
          await pumpLogin(tester, onSuccess: roles.add);
          await signInWithEmail(tester);

          final login = requests.single;
          expect(login.method, 'POST');
          expect(login.url.path, '/api/auth/login');
          // El correo va sin los espacios que se colaron al escribirlo.
          expect(jsonDecode(login.body), {
            'email': 'ana@example.com',
            'password': 'clave-de-prueba',
          });

          expect(roles, [rol]);
          expect(
            find.textContaining('Bienvenido Ana. $welcome'),
            findsOneWidget,
          );
          expect(stored, {
            'auth_token': 'token-de-prueba',
            'auth_role': rol,
            'auth_name': 'Ana',
            'auth_email': 'ana@example.com',
            'auth_user_id': '42',
            'auth_photo_url': '',
          });
          await unmount(tester);
        });
      });
    }

    testWidgets('la foto nueva sustituye a la guardada', (tester) async {
      server = (_) async => _json(
        _session('estudiante', photoUrl: 'https://fotos.test/ana.png'),
        200,
      );
      stored['auth_photo_url'] = 'https://fotos.test/vieja.png';

      await withServer(() async {
        await pumpLogin(tester);
        await signInWithEmail(tester);

        expect(stored['auth_photo_url'], 'https://fotos.test/ana.png');
        await unmount(tester);
      });
    });

    testWidgets('sin foto nueva se conserva la que había', (tester) async {
      server = (_) async => _json(_session('estudiante'), 200);
      stored['auth_photo_url'] = 'https://fotos.test/vieja.png';

      await withServer(() async {
        await pumpLogin(tester);
        await signInWithEmail(tester);

        expect(stored['auth_photo_url'], 'https://fotos.test/vieja.png');
        await unmount(tester);
      });
    });

    testWidgets('con la contraseña mal dice lo que contesta el servidor', (
      tester,
    ) async {
      server = (_) async =>
          _json({'detail': 'Correo o contraseña incorrectos.'}, 401);
      final roles = <String>[];

      await withServer(() async {
        await pumpLogin(tester, onSuccess: roles.add);
        await signInWithEmail(tester);

        expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
        expect(roles, isEmpty);
        expect(stored, isEmpty, reason: 'no se guarda ninguna sesión');
        // Se puede volver a intentar.
        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'INICIAR SESIÓN'),
        );
        expect(button.onPressed, isNotNull);
        await unmount(tester);
      });
    });

    testWidgets('con el servidor caído explica que no hay conexión', (
      tester,
    ) async {
      server = (_) async => throw http.ClientException('sin red');

      await withServer(() async {
        await pumpLogin(tester);
        await signInWithEmail(tester);

        expect(
          find.textContaining('No se pudo conectar con el servidor'),
          findsOneWidget,
        );
        await unmount(tester);
      });
    });

    testWidgets('si no se puede guardar la sesión avisa del error', (
      tester,
    ) async {
      server = (_) async => _json(_session('estudiante'), 200);
      storageFails = true;
      final roles = <String>[];

      await withServer(() async {
        await pumpLogin(tester, onSuccess: roles.add);
        await signInWithEmail(tester);

        expect(find.text('Ocurrió un error inesperado'), findsOneWidget);
        expect(roles, isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('mientras espera al servidor el botón no se puede repetir', (
      tester,
    ) async {
      final answer = Completer<http.Response>();
      server = (_) => answer.future;

      await withServer(() async {
        await pumpLogin(tester);
        await tester.enterText(_field('Correo electrónico'), 'ana@example.com');
        await tester.enterText(_field('Contraseña'), 'clave-de-prueba');
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pump();

        expect(find.text('INICIAR SESIÓN'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        answer.complete(_json({'detail': 'Servicio no disponible'}, 503));
        await settle(tester);
        expect(find.text('INICIAR SESIÓN'), findsOneWidget);
        expect(find.text('Servicio no disponible'), findsOneWidget);
        await unmount(tester);
      });
    });
  });

  group('con Google', () {
    Future<void> tapGoogle(WidgetTester tester) async {
      final google = find.bySemanticsLabel('Iniciar sesión con Google');
      await tester.ensureVisible(google);
      await tester.tap(google);
      await settle(tester);
    }

    setUp(() {
      googleAccount = {
        'email': 'ana@example.com',
        'id': 'cuenta-de-google',
        'displayName': 'Ana',
      };
    });

    testWidgets('canjea los tokens de Google en el servidor y entra', (
      tester,
    ) async {
      server = (_) async => _json(
        _session('docente', photoUrl: 'https://fotos.test/ana.png'),
        200,
      );
      final roles = <String>[];

      await withServer(() async {
        await pumpLogin(tester, onSuccess: roles.add);
        await tapGoogle(tester);

        final google = requests.single;
        expect(google.url.path, '/api/auth/google');
        expect(jsonDecode(google.body), {
          'access_token': 'acceso-de-google',
          'id_token': 'identidad-de-google',
        });
        expect(roles, ['docente']);
        expect(stored['auth_token'], 'token-de-prueba');
        // La foto de la cuenta de Google se queda para el menú de perfil.
        expect(stored['auth_photo_url'], 'https://fotos.test/ana.png');
        expect(find.textContaining('Tu rol es docente'), findsOneWidget);
        await unmount(tester);
      });
    });

    testWidgets('si el servidor no tiene Google configurado (503) lo dice', (
      tester,
    ) async {
      server = (_) async => _json({
        'detail': 'El inicio con Google no está configurado en el servidor.',
      }, 503);
      final roles = <String>[];

      await withServer(() async {
        await pumpLogin(tester, onSuccess: roles.add);
        await tapGoogle(tester);

        expect(
          find.text('El inicio con Google no está configurado en el servidor.'),
          findsOneWidget,
        );
        expect(roles, isEmpty);
        expect(stored, isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('cerrar la ventana de Google sin elegir cuenta se avisa', (
      tester,
    ) async {
      googleAccount = null;

      await withServer(() async {
        await pumpLogin(tester);
        await tapGoogle(tester);

        expect(find.text('Inicio de sesión cancelado'), findsOneWidget);
        expect(requests, isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('sin el identificador de Google en .env lo explica', (
      tester,
    ) async {
      dotenv.testLoad(fileInput: '');

      await withServer(() async {
        await pumpLogin(tester);
        await tapGoogle(tester);

        expect(
          find.textContaining('Falta el Google Client ID'),
          findsOneWidget,
        );
        expect(requests, isEmpty);
        await unmount(tester);
      });
    });

    testWidgets('si falla algo inesperado lo cuenta con el detalle', (
      tester,
    ) async {
      server = (_) async => _json(_session('estudiante'), 200);
      storageFails = true;

      await withServer(() async {
        await pumpLogin(tester);
        await tapGoogle(tester);

        expect(
          find.textContaining('Error en autenticación con Google'),
          findsOneWidget,
        );
        await unmount(tester);
      });
    });
  });

  group('con Facebook', () {
    const web = 'https://code4all.test';
    late MemoryBrowserPort browser;

    FacebookAuthService facebook({bool available = true}) =>
        FacebookAuthService(
          apiService: ApiService(
            baseUrl: 'http://servidor.de.prueba',
            client: MockClient((request) {
              requests.add(request);
              return server(request);
            }),
          ),
          browser: browser,
          appId: 'app-de-prueba',
          isWeb: available,
          random: Random(3),
        );

    /// La app se abre de nuevo, de vuelta de Facebook, con [query].
    void comeBackWith(String query) {
      browser.current = Uri.parse('$web/?$query');
      LaunchLink.capture(browser);
    }

    setUp(() => browser = MemoryBrowserPort(Uri.parse('$web/')));

    Future<void> tapFacebook(WidgetTester tester) async {
      final button = find.bySemanticsLabel('Iniciar sesión con Facebook');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
    }

    testWidgets('sin la app de Facebook configurada lo dice al pulsar', (
      tester,
    ) async {
      await pumpLogin(tester, facebookAuth: facebook(available: false));
      await tapFacebook(tester);

      expect(
        find.textContaining('Facebook todavía no está disponible'),
        findsOneWidget,
      );
      expect(browser.opened, isEmpty);
      await unmount(tester);
    });

    testWidgets('con la app configurada va a Facebook y espera', (
      tester,
    ) async {
      await pumpLogin(tester, facebookAuth: facebook());
      await tapFacebook(tester);

      expect(find.text('Abriendo Facebook…'), findsOneWidget);
      expect(Uri.parse(browser.opened.single).host, 'www.facebook.com');
      // Mientras se va, el login queda ocupado.
      expect(find.text('INICIAR SESIÓN'), findsNothing);
      await unmount(tester);
    });

    testWidgets('a la vuelta, el servidor canjea el código y se entra', (
      tester,
    ) async {
      browser.write(FacebookAuthService.stateKey, 'estado-de-prueba');
      comeBackWith('code=codigo-de-facebook&state=estado-de-prueba');
      server = (_) async => _json(_session('estudiante'), 200);
      final roles = <String>[];

      await pumpLogin(tester, onSuccess: roles.add, facebookAuth: facebook());
      await settle(tester);

      final exchange = requests.single;
      expect(exchange.url.path, '/api/auth/facebook');
      expect(jsonDecode(exchange.body), {
        'code': 'codigo-de-facebook',
        'redirect_uri': '$web/',
      });
      expect(roles, ['estudiante']);
      expect(stored['auth_token'], 'token-de-prueba');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('si se canceló en Facebook se avisa y no se entra', (
      tester,
    ) async {
      browser.write(FacebookAuthService.stateKey, 'estado-de-prueba');
      comeBackWith('error=access_denied&error_reason=user_denied');
      final roles = <String>[];

      await pumpLogin(tester, onSuccess: roles.add, facebookAuth: facebook());
      await settle(tester);

      expect(
        find.text('Inicio de sesión con Facebook cancelado'),
        findsOneWidget,
      );
      expect(roles, isEmpty);
      expect(requests, isEmpty);
      await unmount(tester);
    });

    testWidgets('una vuelta que no empezó esta pestaña no entra', (
      tester,
    ) async {
      browser.write(FacebookAuthService.stateKey, 'estado-de-prueba');
      comeBackWith('code=codigo-ajeno&state=otro-estado');

      await pumpLogin(tester, facebookAuth: facebook());
      await settle(tester);

      expect(
        find.textContaining('No se pudo comprobar el inicio con Facebook'),
        findsOneWidget,
      );
      expect(requests, isEmpty);
      await unmount(tester);
    });

    testWidgets('si el servidor aún no conoce Facebook (404) lo explica', (
      tester,
    ) async {
      browser.write(FacebookAuthService.stateKey, 'estado-de-prueba');
      comeBackWith('code=codigo-de-facebook&state=estado-de-prueba');
      server = (_) async => _json({'detail': 'Not Found'}, 404);

      await pumpLogin(tester, facebookAuth: facebook());
      await settle(tester);

      expect(
        find.text(
          'El inicio con Facebook todavía no está disponible en el servidor.',
        ),
        findsOneWidget,
      );
      expect(stored, isEmpty);
      await unmount(tester);
    });
  });

  group('el manual', () {
    /// Lo que se pidió abrir, y si el sistema pudo abrirlo.
    late List<String> opened;
    late bool canOpen;

    setUp(() {
      opened = [];
      canOpen = true;
      messenger.setMockMethodCallHandler(launcherChannel, (call) async {
        if (call.method != 'launch') return null;
        opened.add((call.arguments as Map)['url'] as String);
        return canOpen;
      });
    });

    Future<void> tapManual(WidgetTester tester) async {
      final manual = find.byKey(const ValueKey('user-manual'));
      await tester.ensureVisible(manual);
      await tester.tap(manual);
      await settle(tester);
    }

    testWidgets('se abre en las guías de primeros pasos', (tester) async {
      await pumpLogin(tester);
      await tapManual(tester);

      expect(opened.single, contains('manual.html'));
      expect(find.textContaining('No se pudo abrir el manual'), findsNothing);
      await unmount(tester);
    });

    testWidgets('si no se puede abrir, dice dónde está', (tester) async {
      canOpen = false;
      await pumpLogin(tester);
      await tapManual(tester);

      expect(
        find.textContaining('code4all-web.onrender.com/manual.html'),
        findsOneWidget,
      );
      await unmount(tester);
    });
  });

  group('dictar con el micrófono', () {
    testWidgets('sin micrófono lo dice', (tester) async {
      final mic = _FakeDictation()..unavailable = true;
      await pumpLogin(tester, dictation: mic);

      await tester.tap(find.byTooltip('Dictar con el micrófono').first);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);

      expect(find.text('No hay micrófono.'), findsOneWidget);
      // El micrófono vuelve a estar disponible.
      expect(find.byTooltip('Dictar con el micrófono'), findsNWidgets(2));
      await unmount(tester);
    });

    testWidgets('pulsar otra vez mientras escucha deja de escuchar', (
      tester,
    ) async {
      final mic = _FakeDictation()
        ..reply = '1 2 3 4 5 6'
        ..waitForStop = true;
      await pumpLogin(tester, dictation: mic);

      await tester.tap(find.byTooltip('Dictar con el micrófono').last);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);

      // Escuchando: el botón cambia para poder pararlo.
      expect(find.byTooltip('Dejar de escuchar'), findsOneWidget);

      await tester.tap(find.byTooltip('Dejar de escuchar'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await settle(tester);

      expect(mic.stops, 1);
      expect(find.byTooltip('Dejar de escuchar'), findsNothing);
      final password = tester.widget<TextField>(_field('Contraseña'));
      expect(password.controller!.text, '123456');
      await unmount(tester);
    });
  });

  group('con el teclado Braille', () {
    Future<void> openBraille(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Teclado Braille'));
      await settle(tester);
      expect(find.byType(BrailleKeyboardScreen), findsOneWidget);
    }

    Future<void> finishField(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('braille-action-Enviar')));
      await settle(tester);
    }

    /// El teclado se cierra con una transición de pantalla completa.
    Future<void> waitClosed(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
    }

    testWidgets('al terminar la contraseña se inicia sesión y se oye', (
      tester,
    ) async {
      server = (_) async => _json(_session('estudiante'), 200);
      final roles = <String>[];

      await withServer(() async {
        await pumpLogin(tester, onSuccess: roles.add);
        await openBraille(tester);

        // Lo que se escribe en Braille va a parar a los campos del login.
        final fields = tester
            .widget<BrailleKeyboardScreen>(find.byType(BrailleKeyboardScreen))
            .fields!;
        fields[0].controller.text = 'ana@example.com';
        fields[1].controller.text = 'clave-de-prueba';

        // «Enviar» termina el campo y pasa al siguiente; en el último, entra.
        await finishField(tester);
        await finishField(tester);
        await waitClosed(tester);

        expect(find.byType(BrailleKeyboardScreen), findsNothing);
        expect(jsonDecode(requests.single.body), {
          'email': 'ana@example.com',
          'password': 'clave-de-prueba',
        });
        expect(roles, ['estudiante']);
        // Quien entró con el teclado Braille no ve la bienvenida: la oye.
        expect(
          accessibilityReadingState.currentText.value,
          contains('Bienvenido Ana'),
        );
        await unmount(tester);
      });
    });

    testWidgets(
      'cerrarlo sin terminar no envía nada, pero los avisos se oyen',
      (tester) async {
        await withServer(() async {
          await pumpLogin(tester);
          await openBraille(tester);

          await tester.tap(find.byType(CloseButton));
          await waitClosed(tester);
          expect(find.byType(BrailleKeyboardScreen), findsNothing);
          expect(requests, isEmpty);

          // Sigue en modo voz: el error de validación también se dice.
          await tester.tap(find.text('INICIAR SESIÓN'));
          await settle(tester);
          expect(
            accessibilityReadingState.currentText.value,
            'Ingresa un correo electrónico válido',
          );
          await unmount(tester);
        });
      },
    );

    testWidgets('arrastrar el dedo o pulsar teclas no cuenta como toque', (
      tester,
    ) async {
      await pumpLogin(tester);
      final spot = tester.getCenter(
        find.byKey(const ValueKey('braille-login-hint')),
      );

      // Dos arrastres seguidos no son un doble toque.
      await tester.dragFrom(spot, const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.dragFrom(spot, const Offset(0, 80));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await settle(tester);

      expect(find.byType(BrailleKeyboardScreen), findsNothing);
      await unmount(tester);
    });

    testWidgets('mantener el dedo apoyado tampoco', (tester) async {
      await pumpLogin(tester);
      final spot = tester.getCenter(
        find.byKey(const ValueKey('braille-login-hint')),
      );

      for (var i = 0; i < 2; i++) {
        final finger = await tester.startGesture(
          spot,
          kind: PointerDeviceKind.touch,
        );
        await tester.pump(const Duration(milliseconds: 600));
        await finger.up();
        await tester.pump(const Duration(milliseconds: 50));
      }
      await settle(tester);

      expect(find.byType(BrailleKeyboardScreen), findsNothing);
      await unmount(tester);
    });
  });
}
