import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/user_manual.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  late UrlLauncherPlatform originalPlatform;
  late FakeUrlLauncherPlatform fakePlatform;

  setUp(() {
    originalPlatform = UrlLauncherPlatform.instance;
    fakePlatform = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  group('userManualUri', () {
    test('genera la URL pública con la sección de estudiante', () {
      expect(
        userManualUri(role: 'estudiante'),
        Uri.parse('https://code4all-web.onrender.com/manual.html#estudiante'),
      );
    });

    test('genera la sección de docente', () {
      expect(
        userManualUri(role: 'docente'),
        Uri.parse('https://code4all-web.onrender.com/manual.html#docente'),
      );
    });

    test('genera la sección de director', () {
      expect(
        userManualUri(role: 'director'),
        Uri.parse('https://code4all-web.onrender.com/manual.html#director'),
      );
    });

    test('normaliza espacios y mayúsculas del rol', () {
      expect(userManualUri(role: '  DOCENTE  ').fragment, 'docente');
    });

    test('usa inicio cuando el rol es nulo, vacío o desconocido', () {
      expect(userManualUri().fragment, 'inicio');
      expect(userManualUri(role: '   ').fragment, 'inicio');
      expect(userManualUri(role: 'administrador').fragment, 'inicio');
    });
  });

  group('openUserManual', () {
    test('devuelve true cuando el enlace se abre correctamente', () async {
      fakePlatform.result = true;

      final result = await openUserManual(role: 'docente');

      expect(result, isTrue);
      expect(
        fakePlatform.lastUrl,
        'https://code4all-web.onrender.com/manual.html#docente',
      );
      expect(
        fakePlatform.lastOptions?.mode,
        PreferredLaunchMode.externalApplication,
      );
      expect(fakePlatform.lastOptions?.webOnlyWindowName, '_blank');
    });

    test(
      'devuelve false si la plataforma no consigue abrir el enlace',
      () async {
        fakePlatform.result = false;

        expect(await openUserManual(role: 'estudiante'), isFalse);
      },
    );

    test('devuelve false si la plataforma lanza una excepción', () async {
      fakePlatform.throwOnLaunch = true;

      expect(await openUserManual(role: 'director'), isFalse);
    });
  });
}

class FakeUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool result = true;
  bool throwOnLaunch = false;
  String? lastUrl;
  LaunchOptions? lastOptions;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    lastOptions = options;

    if (throwOnLaunch) {
      throw Exception('Error simulado al abrir el manual');
    }

    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
