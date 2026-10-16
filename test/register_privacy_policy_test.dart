import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/users_management/widgets/form_screen.dart';

/// En el registro se acepta la política de tratamiento de datos, y se puede
/// leer antes de aceptarla.
void main() {
  late UrlLauncherPlatform original;
  late _FakeLauncher launcher;

  setUp(() {
    original = UrlLauncherPlatform.instance;
    launcher = _FakeLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() => UrlLauncherPlatform.instance = original);

  Future<void> pumpForm(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light),
        home: const FormScreen(),
      ),
    );
    await tester.pump();
  }

  bool checked(WidgetTester tester) =>
      tester.widget<Checkbox>(find.byType(Checkbox)).value!;

  testWidgets('la casilla dice que se acepta la política', (tester) async {
    await pumpForm(tester, const Size(700, 2200));

    expect(
      find.text('He leído y acepto la política de tratamiento de datos'),
      findsOneWidget,
    );
  });

  testWidgets('el enlace abre la política y no marca la casilla', (
    tester,
  ) async {
    await pumpForm(tester, const Size(700, 2200));

    final link = find.byKey(const ValueKey('register-privacy-policy'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pump();

    expect(launcher.opened.single, contains('privacidad.html'));
    expect(checked(tester), isFalse);
  });

  testWidgets('si no se puede abrir, dice dónde está', (tester) async {
    launcher.result = false;
    await pumpForm(tester, const Size(700, 2200));

    final link = find.byKey(const ValueKey('register-privacy-policy'));
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pump();

    expect(
      find.textContaining('code4all-web.onrender.com/privacidad.html'),
      findsOneWidget,
    );
  });

  for (final size in const [Size(320, 640), Size(360, 640), Size(390, 844)]) {
    testWidgets('en ${size.width.round()} × ${size.height.round()} el enlace '
        'cabe de ancho sin desbordar', (tester) async {
      await pumpForm(tester, size);

      final link = find.byKey(const ValueKey('register-privacy-policy'));
      await tester.ensureVisible(link);
      await tester.pump();
      final rect = tester.getRect(link);
      expect(
        rect.left >= 0 && rect.right <= size.width,
        isTrue,
        reason: '$rect',
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _FakeLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool result = true;
  final opened = <String>[];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    opened.add(url);
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
