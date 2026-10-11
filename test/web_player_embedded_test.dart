import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/web_player_embedded.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  setUpAll(() {
    WebViewPlatform.instance = FakeWebViewPlatform();
  });

  group('EmbeddedYoutubeWebPlayer Tests', () {
    testWidgets(
      'Ciclo de vida del reproductor: initState, didUpdateWidget, build y dispose',
      (WidgetTester tester) async {
        // 1. Renderizamos el widget embebido
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmbeddedYoutubeWebPlayer(videoId: 'dQw4w9WgXcQ'),
            ),
          ),
        );

        // Verificamos que se haya montado correctamente
        expect(find.byType(EmbeddedYoutubeWebPlayer), findsOneWidget);

        // 2. Probamos actualización (didUpdateWidget) cambiando el videoId
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmbeddedYoutubeWebPlayer(videoId: 'abc12345678'),
            ),
          ),
        );

        expect(find.byType(EmbeddedYoutubeWebPlayer), findsOneWidget);

        // 3. Avanzamos el reloj virtual 35 segundos para expirar y limpiar el timer interno de youtube_player_iframe
        await tester.pump(const Duration(seconds: 35));
      },
    );
  });
}

class FakeWebViewPlatform extends WebViewPlatform
    with MockPlatformInterfaceMixin {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return FakePlatformNavigationDelegate();
  }

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return FakePlatformWebViewController();
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
    return FakePlatformWebViewWidget();
  }
}

class FakePlatformNavigationDelegate
    with MockPlatformInterfaceMixin
    implements PlatformNavigationDelegate {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakePlatformWebViewController
    with MockPlatformInterfaceMixin
    implements PlatformWebViewController {
  final Map<String, JavaScriptChannelParams> _channels = {};

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {
    _channels[javaScriptChannelParams.name] = javaScriptChannelParams;
  }

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    // Simula que YouTube terminó de inicializarse.
    for (final channel in _channels.values) {
      channel.onMessageReceived(
        JavaScriptMessage(
          message: jsonEncode({'playerId': channel.name, 'Ready': null}),
        ),
      );
    }
  }

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {
    _channels.remove(javaScriptChannelName);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #runJavaScriptReturningResult ||
        invocation.memberName == #runJavaScript) {
      return Future<Object>.value('true');
    }

    return Future<void>.value();
  }
}

class FakePlatformWebViewWidget
    with MockPlatformInterfaceMixin
    implements PlatformWebViewWidget {
  @override
  Widget build(BuildContext context) => const SizedBox();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
