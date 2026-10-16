// Las interfaces de plataforma del selector de fotos y del abridor de enlaces
// llegan con image_picker y url_launcher; se importan solo para fingirlas.
// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:flutter_code4all/data/services/session_controller.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_settings.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

/// Lo que hace cada opción del menú de la cuenta, más allá de dibujarse.
///
/// El menú de perfil es lo único común a todas las pantallas, así que es
/// también por donde se llega a ayudas que no están en ningún otro sitio: el
/// teclado de dactilología (solo estudiantes), el teclado Braille, el manual
/// de uso y la foto de perfil. Aquí se comprueba que cada opción hace lo que
/// promete, qué se guarda en el dispositivo y qué se envía al servidor, y que
/// cuando algo falla la persona se entera de por qué.
void main() {
  late Directory tempDir;
  late File photo;

  setUpAll(() {
    // Una foto de verdad en disco: en móvil la subida lee el archivo.
    tempDir = Directory.systemTemp.createTempSync('code4all_perfil_');
    photo = File('${tempDir.path}${Platform.pathSeparator}mi_foto.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  late UrlLauncherPlatform originalLauncher;
  late _FakeUrlLauncher launcher;
  late ImagePickerPlatform originalPicker;
  late _FakeImagePicker picker;
  const storage = FlutterSecureStorage();
  const tts = MethodChannel('flutter_tts');

  setUp(() {
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;

    originalPicker = ImagePickerPlatform.instance;
    picker = _FakeImagePicker();
    ImagePickerPlatform.instance = picker;

    // El teclado Braille habla al abrirse; aquí no hay motor de voz.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, (_) async => 1);
  });

  tearDown(() async {
    UrlLauncherPlatform.instance = originalLauncher;
    ImagePickerPlatform.instance = originalPicker;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(tts, null);
    SessionController.instance.debugReset();
    await SignKeyboardSettings.instance.setEnabled(false);
  });

  /// Lo que hay guardado de la sesión, como lo deja el login.
  void signedInAs({
    String? role,
    String? name,
    String? email,
    String? photoUrl,
    int? userId,
    String? token,
  }) {
    FlutterSecureStorage.setMockInitialValues({
      'auth_role': ?role,
      'auth_name': ?name,
      'auth_email': ?email,
      'auth_photo_url': ?photoUrl,
      'auth_user_id': ?userId?.toString(),
      'auth_token': ?token,
    });
  }

  Widget menuApp({
    String? name = 'Mateo',
    String? photoUrl,
    VoidCallback? onLogout,
  }) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          actions: [
            UserProfileMenu(
              userName: name,
              userPhotoUrl: photoUrl,
              onLogout: onLogout,
            ),
          ],
        ),
        body: const Text('Pantalla de inicio'),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pump(); // carga del perfil guardado
    await tester.tap(find.byType(UserProfileMenu));
    await tester.pumpAndSettle();
  }

  /// La subida en móvil lee la foto del disco, y eso es E/S de verdad: no
  /// avanza con el reloj falso de la prueba. Se le deja tiempo real a trozos
  /// hasta que aparezca lo esperado (como mucho unos segundos, para que una
  /// máquina cargada no la haga fallar).
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 250 && finder.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> tapUploadPhoto(
    WidgetTester tester, {
    http.Client? server,
  }) async {
    await openMenu(tester);
    await tester.tap(find.text('Mi perfil'));
    await tester.pumpAndSettle();

    Future<void> tap() => tester.tap(find.text('Subir foto'));
    if (server != null) {
      // La subida crea su propio cliente HTTP; dentro de esta zona ese
      // cliente es el servidor de mentira.
      await http.runWithClient(tap, () => server);
    } else {
      await tap();
    }
    await tester.pump();
  }

  group('teclado con dactilología', () {
    testWidgets('solo el estudiante lo ve en el menú', (tester) async {
      signedInAs(role: 'docente');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      expect(find.text('Teclado con dactilología'), findsNothing);
      // Lo demás sí es para todos los roles.
      expect(find.text('Teclado Braille'), findsOneWidget);
      expect(find.text('Manual de uso'), findsOneWidget);
    });

    testWidgets('activarlo se guarda en el dispositivo y se avisa', (
      tester,
    ) async {
      signedInAs(role: 'estudiante');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      expect(find.byIcon(Icons.check_box_outline_blank), findsOneWidget);
      await tester.tap(find.text('Teclado con dactilología'));
      await tester.pumpAndSettle();

      expect(SignKeyboardSettings.instance.isEnabled, isTrue);
      expect(await storage.read(key: 'sign_keyboard_enabled'), 'true');
      expect(
        find.text('Teclado con dactilología activado. Aparecerá al escribir.'),
        findsOneWidget,
      );

      // Al volver a abrir el menú la casilla aparece marcada.
      ScaffoldMessenger.of(
        tester.element(find.byType(UserProfileMenu)),
      ).removeCurrentSnackBar();
      await openMenu(tester);
      expect(find.byIcon(Icons.check_box), findsOneWidget);

      await tester.tap(find.text('Teclado con dactilología'));
      await tester.pumpAndSettle();

      expect(SignKeyboardSettings.instance.isEnabled, isFalse);
      expect(await storage.read(key: 'sign_keyboard_enabled'), 'false');
      expect(
        find.text('Teclado con dactilología desactivado.'),
        findsOneWidget,
      );
    });
  });

  group('teclado Braille y manual', () {
    testWidgets('«Teclado Braille» abre el teclado a pantalla completa', (
      tester,
    ) async {
      signedInAs(role: 'docente');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      await tester.tap(find.text('Teclado Braille'));
      await tester.pumpAndSettle();

      expect(find.byType(BrailleKeyboardScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('braille-dot-1')), findsOneWidget);
    });

    testWidgets('el manual se abre en la sección del rol de quien lo pide', (
      tester,
    ) async {
      signedInAs(role: 'docente');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      await tester.tap(find.text('Manual de uso'));
      await tester.pumpAndSettle();

      expect(launcher.lastUrl, endsWith('manual.html#docente'));
      expect(find.textContaining('No se pudo abrir el manual'), findsNothing);
    });

    testWidgets('si el manual no se puede abrir, se dice dónde está', (
      tester,
    ) async {
      launcher.result = false;
      signedInAs(role: 'estudiante');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      await tester.tap(find.text('Manual de uso'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'No se pudo abrir el manual. Está en '
          'code4all-web.onrender.com/manual.html',
        ),
        findsOneWidget,
      );
    });
  });

  group('perfil guardado', () {
    testWidgets('lo guardado en el login manda sobre lo que pasa la pantalla', (
      tester,
    ) async {
      signedInAs(
        role: 'docente',
        name: 'Ana Pérez',
        email: 'ana@code4all.test',
      );
      await tester.pumpWidget(menuApp(name: 'Otro nombre'));
      await tester.pump();

      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('Otro nombre'), findsNothing);

      await openMenu(tester);
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(
        find.descendant(of: dialog, matching: find.text('DOCENTE')),
        findsOneWidget,
      );
      expect(find.text('Correo: ana@code4all.test'), findsOneWidget);
    });

    testWidgets('sin ningún dato de perfil el menú no se dibuja', (
      tester,
    ) async {
      signedInAs();
      await tester.pumpWidget(menuApp(name: null));
      await tester.pump();

      expect(find.byType(PopupMenuButton<String>), findsNothing);
      expect(find.byType(CircleAvatar), findsNothing);
    });

    testWidgets('con foto válida se pide la imagen y, si falla, sale la '
        'inicial', (tester) async {
      signedInAs(role: 'estudiante');
      await tester.pumpWidget(
        menuApp(name: 'Laura', photoUrl: 'https://cdn.code4all.test/laura.jpg'),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://cdn.code4all.test/laura.jpg',
      );

      // En las pruebas la red responde con error: el avatar no se queda en
      // blanco, enseña la inicial.
      await pumpUntilFound(tester, find.text('L'));
      expect(find.text('L'), findsOneWidget);
    });

    testWidgets('si la pantalla pasa otra foto, el avatar la sigue', (
      tester,
    ) async {
      signedInAs(role: 'estudiante');
      await tester.pumpWidget(menuApp(name: 'Mateo'));
      await tester.pump();
      expect(find.byType(Image), findsNothing);

      // Mismo nombre, foto nueva: por ejemplo, recién subida en otra pantalla.
      await tester.pumpWidget(
        menuApp(name: 'Mateo', photoUrl: 'https://cdn.code4all.test/m.jpg'),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://cdn.code4all.test/m.jpg',
      );
    });

    testWidgets('una ruta relativa se resuelve contra el servidor', (
      tester,
    ) async {
      signedInAs(role: 'estudiante', photoUrl: '/media/fotos/7.jpg');
      await tester.pumpWidget(menuApp());
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as NetworkImage).url, endsWith('/media/fotos/7.jpg'));
      expect((image.image as NetworkImage).url, startsWith('http'));
    });

    testWidgets('las fotos de relleno no se piden: se ve la inicial', (
      tester,
    ) async {
      signedInAs(role: 'estudiante');
      for (final placeholder in [
        'https://cdn.code4all.test/avatar_default.png',
        'null',
        'https://cdn.code4all.test/fotos/',
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(menuApp(name: 'Mateo', photoUrl: placeholder));
        await tester.pump();

        expect(
          find.byType(Image),
          findsNothing,
          reason: '«$placeholder» no es una foto de verdad',
        );
        expect(find.text('M'), findsOneWidget);
      }
    });
  });

  group('cerrar sesión sin función propia', () {
    testWidgets('usa la salida que registró la aplicación', (tester) async {
      var logouts = 0;
      SessionController.instance.registerLogout(() => logouts++);
      signedInAs(role: 'estudiante', token: 'tok');
      await tester.pumpWidget(menuApp());
      await openMenu(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(logouts, 1);
      // La sesión guardada se borra.
      expect(await storage.read(key: 'auth_token'), isNull);
    });

    testWidgets('sin salida registrada vuelve a la primera pantalla', (
      tester,
    ) async {
      signedInAs(role: 'estudiante');
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: Text('Pantalla de inicio')),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(actions: const [UserProfileMenu(userName: 'Mateo')]),
            body: const Text('Una lectura'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Una lectura'), findsOneWidget);

      await openMenu(tester);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Una lectura'), findsNothing);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
    });
  });

  group('subir la foto de perfil', () {
    testWidgets('si se cancela el selector no pasa nada', (tester) async {
      picker.result = null;
      signedInAs(role: 'estudiante', userId: 7, token: 'tok');
      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester);
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('sin sesión guardada no se intenta subir', (tester) async {
      picker.result = XFile(photo.path);
      signedInAs(role: 'estudiante');
      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('No se encontró el usuario para subir la foto.'),
        findsOneWidget,
      );
    });

    testWidgets('sube la foto con la sesión y guarda la nueva dirección', (
      tester,
    ) async {
      picker.result = XFile(photo.path);
      signedInAs(role: 'estudiante', userId: 7, token: 'tok-123');
      http.Request? sent;
      final server = MockClient((request) async {
        sent = request;
        return http.Response(
          jsonEncode({'photo_url': 'https://cdn.code4all.test/7.jpg'}),
          200,
        );
      });

      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester, server: server);
      await pumpUntilFound(tester, find.text('Foto actualizada correctamente'));

      expect(find.text('Foto actualizada correctamente'), findsOneWidget);
      expect(sent, isNotNull);
      expect(sent!.method, 'POST');
      expect(sent!.url.path, '/api/user/upload-photo');
      // El servidor solo cambia la foto de quien tiene la sesión abierta.
      expect(sent!.headers['Authorization'], 'Bearer tok-123');
      final body = latin1.decode(sent!.bodyBytes);
      expect(body, contains('name="user_id"'));
      expect(body, contains('filename="mi_foto.jpg"'));
      expect(
        await storage.read(key: 'auth_photo_url'),
        'https://cdn.code4all.test/7.jpg',
      );
      // Y el avatar pasa a pedir la foto nueva.
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://cdn.code4all.test/7.jpg',
      );
    });

    testWidgets('con la sesión caducada se pide volver a entrar', (
      tester,
    ) async {
      picker.result = XFile(photo.path);
      signedInAs(role: 'estudiante', userId: 7, token: 'viejo');
      final server = MockClient(
        (_) async => http.Response('{"detail":"token"}', 401),
      );

      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester, server: server);
      final aviso = find.textContaining('Tu sesión caducó');
      await pumpUntilFound(tester, aviso);

      expect(aviso, findsOneWidget);
      expect(await storage.read(key: 'auth_photo_url'), isNull);
    });

    testWidgets('se enseña lo que explica el servidor, no el JSON entero', (
      tester,
    ) async {
      picker.result = XFile(photo.path);
      signedInAs(role: 'estudiante', userId: 7, token: 'tok');
      final server = MockClient(
        (_) async =>
            http.Response('{"detail":"La imagen pesa demasiado"}', 413),
      );

      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester, server: server);
      final aviso = find.textContaining('La imagen pesa demasiado');
      await pumpUntilFound(tester, aviso);

      expect(aviso, findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('si el servidor no explica nada se dice el código', (
      tester,
    ) async {
      picker.result = XFile(photo.path);
      signedInAs(role: 'estudiante', userId: 7, token: 'tok');
      final server = MockClient(
        (_) async => http.Response('<html>Bad gateway</html>', 502),
      );

      await tester.pumpWidget(menuApp());
      await tapUploadPhoto(tester, server: server);
      final aviso = find.textContaining('el servidor respondió 502');
      await pumpUntilFound(tester, aviso);

      expect(aviso, findsOneWidget);
    });
  });
}

/// Un abridor de enlaces que apunta qué se le pidió abrir.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool result = true;
  String? lastUrl;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Un selector de fotos que devuelve lo que diga la prueba.
class _FakeImagePicker extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  XFile? result;
  int calls = 0;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    calls++;
    return result;
  }
}
