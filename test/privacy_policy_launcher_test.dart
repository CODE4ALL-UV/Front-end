import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/privacy_policy.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// La política de tratamiento de datos se abre en una pestaña nueva, en la
/// dirección pública de `web/privacidad.html`.
void main() {
  late UrlLauncherPlatform originalPlatform;
  late _FakeUrlLauncherPlatform fakePlatform;

  setUp(() {
    originalPlatform = UrlLauncherPlatform.instance;
    fakePlatform = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakePlatform;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalPlatform;
  });

  test('fuera del navegador usa la dirección pública', () {
    expect(
      privacyPolicyUri(),
      Uri.parse('https://code4all-web.onrender.com/privacidad.html'),
    );
  });

  test('se abre fuera de la app, en una pestaña nueva', () async {
    expect(await openPrivacyPolicy(), isTrue);
    expect(
      fakePlatform.lastUrl,
      'https://code4all-web.onrender.com/privacidad.html',
    );
    expect(
      fakePlatform.lastOptions?.mode,
      PreferredLaunchMode.externalApplication,
    );
    expect(fakePlatform.lastOptions?.webOnlyWindowName, '_blank');
  });

  test('devuelve false si la plataforma no consigue abrirla', () async {
    fakePlatform.result = false;

    expect(await openPrivacyPolicy(), isFalse);
  });

  test('devuelve false si la plataforma lanza una excepción', () async {
    fakePlatform.throwOnLaunch = true;

    expect(await openPrivacyPolicy(), isFalse);
  });
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool result = true;
  bool throwOnLaunch = false;
  String? lastUrl;
  LaunchOptions? lastOptions;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastUrl = url;
    lastOptions = options;
    if (throwOnLaunch) throw Exception('Error simulado al abrir la política');
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
