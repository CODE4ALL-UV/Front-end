import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
// La interfaz de url_launcher llega con el propio paquete; se importa para
// sustituir el navegador del sistema por uno simulado.
// ignore: depend_on_referenced_packages
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;

import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_video_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_camera_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_language_panel.dart';

/// Lo que se puede hacer en la pantalla de videos de una sección.
///
/// Las pruebas que ya existían montan el primer video del catálogo y miran
/// qué aparece. Aquí se usa una sección hecha a medida, con varios videos y
/// transcripciones conocidas, para recorrer lo que hace el estudiante: elegir
/// otro video, dejar que la transcripción avance sola, seguir los subtítulos
/// reales del reproductor, copiar el enlace, abrirlo en el navegador, marcar
/// los videos como vistos, ir a practicar con la cámara y ver el apoyo en
/// señas cuando lo pidió.
///
/// El reproductor pide los subtítulos al backend con un cliente HTTP que la
/// pantalla no deja inyectar; por eso cada prueba corre dentro de
/// `http.runWithClient`, que sustituye ese cliente por uno simulado.
void main() {
  late List<Uri> requests;

  // El progreso, las preferencias y la guía de señas se guardan en el
  // almacenamiento seguro. Se simula para que contestar no dependa del
  // dispositivo; la guía consta como ya ofrecida para no tapar la cámara.
  const storage = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    requests = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, (call) async {
          final key = (call.arguments as Map?)?['key'];
          if (call.method == 'read' && key == 'sign_guide_offered') return '1';
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storage, null),
  );

  /// Backend simulado: subtítulos por video y un reconocimiento de señas
  /// apagado (para la pantalla de la cámara).
  http.Client backend({
    Map<String, List<Map<String, Object>>> cues = const {},
  }) {
    return MockClient((request) async {
      requests.add(request.url);
      if (request.url.path == '/api/signs/status') {
        return http.Response(jsonEncode({'available': false}), 200);
      }
      final id = request.url.queryParameters['video_id'];
      return http.Response(jsonEncode({'cues': cues[id] ?? const []}), 200);
    });
  }

  group('SectionVideoScreen: varios videos', () {
    testWidgets('permite elegir otro video y reinicia los subtítulos', (
      tester,
    ) async {
      await http.runWithClient(() async {
        await _open(tester, _section([_install, _firstProgram]));

        expect(find.text('2 videos en esta sección'), findsOneWidget);
        expect(
          find.text(
            '${_install.description}  ·  Duración ${_install.duration}',
          ),
          findsOneWidget,
        );
        expect(find.text('Frase 1 de 3'), findsOneWidget);

        await _tapTooltip(tester, 'Frase siguiente');
        expect(find.text('Frase 2 de 3'), findsOneWidget);
        tester.takeAnnouncements();

        // El segundo video no tiene duración: se enseña solo la descripción.
        await _tapText(tester, _firstProgram.title);

        expect(find.text(_firstProgram.title), findsNWidgets(2));
        expect(find.text(_firstProgram.description), findsOneWidget);
        expect(find.text('Frase 1 de 2'), findsOneWidget);
        expect(find.text('Abre el editor.'), findsOneWidget);
        expect(
          _announced(tester),
          contains('Video 2 de 2: ${_firstProgram.title}'),
        );

        // Volver a pulsar el que ya está elegido no cambia nada ni lo anuncia.
        await _tapText(tester, _firstProgram.title, index: 0);
        expect(_announced(tester), isEmpty);

        // Cada video pide sus propios subtítulos al backend.
        expect(requests.map((url) => url.queryParameters['video_id']), [
          _install.youtubeId,
          _firstProgram.youtubeId,
        ]);
        expect(requests.first.queryParameters['target'], 'es');

        await _close(tester);
      }, backend);
    });
  });

  group('SectionVideoScreen: subtítulos de la transcripción', () {
    testWidgets('avanzan solos frase a frase y se detienen al final', (
      tester,
    ) async {
      await http.runWithClient(() async {
        await _open(tester, _section([_install]));

        expect(find.text('Primero abre la página oficial.'), findsWidgets);
        expect(_tooltipEnabled(tester, 'Frase anterior'), isFalse);

        await _tapTooltip(tester, 'Reproducir los subtítulos');
        expect(find.byTooltip('Pausar los subtítulos'), findsOneWidget);

        await tester.pump(const Duration(seconds: 6));
        expect(find.text('Frase 2 de 3'), findsOneWidget);
        expect(find.text('Después descarga el instalador.'), findsWidgets);

        await tester.pump(const Duration(seconds: 6));
        expect(find.text('Frase 3 de 3'), findsOneWidget);
        expect(_tooltipEnabled(tester, 'Frase siguiente'), isFalse);

        // En la última frase se para solo y vuelve a ofrecer reproducir.
        await tester.pump(const Duration(seconds: 6));
        expect(find.text('Frase 3 de 3'), findsOneWidget);
        expect(find.byTooltip('Reproducir los subtítulos'), findsOneWidget);

        await _tapTooltip(tester, 'Frase anterior');
        expect(find.text('Frase 2 de 3'), findsOneWidget);
        expect(find.text('Después descarga el instalador.'), findsWidgets);

        // Sin subtítulos del backend, el aviso explica de dónde sale el texto.
        expect(
          find.text('Idea clave · Subtítulos desde la transcripción'),
          findsOneWidget,
        );

        await _close(tester);
      }, backend);
    });

    testWidgets('un video sin transcripción lo dice y no ofrece controles', (
      tester,
    ) async {
      await http.runWithClient(() async {
        await _open(tester, _section([_silent]));

        expect(
          find.text('Pulsa reproducir para seguir el texto.'),
          findsOneWidget,
        );
        expect(find.byTooltip('Reproducir los subtítulos'), findsNothing);
        expect(find.textContaining('Frase '), findsNothing);
        expect(find.text('Transcripción completa'), findsNothing);
        expect(
          find.text('Idea clave · Subtítulos desde la transcripción'),
          findsOneWidget,
        );
        // Un solo video: no hace falta selector.
        expect(find.textContaining('videos en esta sección'), findsNothing);

        await _close(tester);
      }, backend);
    });
  });

  group('SectionVideoScreen: subtítulos del reproductor', () {
    testWidgets('cuando el video emite subtítulos el cuadro los sigue en vivo', (
      tester,
    ) async {
      final cues = {
        _install.youtubeId: [
          {
            'start': 1.0,
            'duration': 2.0,
            'text': 'First open the official page.',
            'translated': 'Primero, la página oficial de Python.',
          },
          {
            'start': 4.0,
            'duration': 2.0,
            'text': 'Ahora el instalador para tu sistema.',
          },
        ],
      };

      await http.runWithClient(() async {
        await _open(tester, _section([_install]));

        // Hay subtítulos, pero hasta que suene el video manda la transcripción.
        expect(
          find.text('Idea clave · Dale al play para sincronizar'),
          findsOneWidget,
        );
        expect(find.text('En vivo'), findsNothing);

        await _tapTooltip(tester, 'Reproducir los subtítulos');

        await _seek(tester, const Duration(milliseconds: 1500));

        expect(
          find.text('Primero, la página oficial de Python.'),
          findsOneWidget,
        );
        expect(find.text('En vivo'), findsOneWidget);
        expect(
          find.text('Idea clave · Subtítulos del propio video'),
          findsOneWidget,
        );
        // Los botones de frase desaparecen: el ritmo lo lleva el video.
        expect(find.byTooltip('Frase siguiente'), findsNothing);

        // El avance manual quedó parado: pasados 6 s no salta de frase.
        await tester.pump(const Duration(seconds: 6));
        expect(
          find.text('Primero, la página oficial de Python.'),
          findsOneWidget,
        );

        // Un silencio entre subtítulos no borra el último texto.
        await _seek(tester, const Duration(milliseconds: 3500));
        expect(
          find.text('Primero, la página oficial de Python.'),
          findsOneWidget,
        );

        await _seek(tester, const Duration(milliseconds: 4500));
        expect(
          find.text('Ahora el instalador para tu sistema.'),
          findsOneWidget,
        );

        await _close(tester);
      }, () => backend(cues: cues));
    });
  });

  group('SectionVideoScreen: enlace del video', () {
    late UrlLauncherPlatform originalLauncher;
    late _FakeUrlLauncher launcher;

    setUp(() {
      originalLauncher = UrlLauncherPlatform.instance;
      launcher = _FakeUrlLauncher();
      UrlLauncherPlatform.instance = launcher;
    });

    tearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    testWidgets('copiar el enlace lo deja en el portapapeles y lo confirma', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await http.runWithClient(() async {
        await _open(tester, _section([_install]));
        tester.takeAnnouncements();

        await _tapText(tester, 'Copiar enlace');

        expect(copied, 'https://www.youtube.com/watch?v=${_install.youtubeId}');
        expect(find.text('Enlace copiado al portapapeles'), findsOneWidget);
        expect(_announced(tester), contains('Enlace copiado al portapapeles'));

        await _close(tester);
      }, backend);
    });

    testWidgets('ver en YouTube abre el navegador y lo confirma', (
      tester,
    ) async {
      final pending = Completer<bool>();
      launcher.answer = pending.future;

      await http.runWithClient(() async {
        await _open(tester, _section([_install]));

        await _tapText(tester, 'Ver en YouTube');

        // Mientras el sistema abre el navegador no se puede pulsar otra vez.
        expect(find.text('Abriendo…'), findsOneWidget);
        expect(find.text('Ver en YouTube'), findsNothing);
        expect(launcher.urls, [
          'https://www.youtube.com/watch?v=${_install.youtubeId}',
        ]);
        expect(launcher.modes, [PreferredLaunchMode.externalApplication]);

        pending.complete(true);
        await tester.pump();

        expect(find.text('Ver en YouTube'), findsOneWidget);
        expect(find.text('Video abierto en tu navegador'), findsOneWidget);

        await _close(tester);
      }, backend);
    });

    testWidgets('si el navegador no abre propone copiar el enlace', (
      tester,
    ) async {
      launcher.answer = Future.value(false);

      await http.runWithClient(() async {
        await _open(tester, _section([_install]));
        tester.takeAnnouncements();

        await _tapText(tester, 'Ver en YouTube');

        const message =
            'No se pudo abrir el video. Copia el enlace y ábrelo manualmente.';
        expect(find.text(message), findsOneWidget);
        expect(_announced(tester), contains(message));

        await _close(tester);
      }, backend);
    });
  });

  group('SectionVideoScreen: terminar y practicar', () {
    final section = _section([_install]);

    tearDown(
      () => CourseProgressStore.instance.resetSection(section.id, const [
        CourseActivityKind.video,
      ]),
    );

    testWidgets('marcar como visto guarda el avance y vuelve con éxito', (
      tester,
    ) async {
      bool? result;

      await http.runWithClient(() async {
        _useTallView(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () async {
                      result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => SectionVideoScreen(
                            module: _module(section),
                            section: section,
                          ),
                        ),
                      );
                    },
                    child: const Text('Abrir los videos'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir los videos'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          CourseProgressStore.instance.isCompleted(
            section.id,
            CourseActivityKind.video,
          ),
          isFalse,
        );
        tester.takeAnnouncements();

        await _tapText(tester, 'Marcar como visto');
        await tester.pump(const Duration(seconds: 1));

        expect(
          CourseProgressStore.instance.isCompleted(
            section.id,
            CourseActivityKind.video,
          ),
          isTrue,
        );
        expect(result, isTrue);
        expect(find.byType(SectionVideoScreen), findsNothing);
        expect(_announced(tester), contains('Videos marcados como vistos.'));

        await _close(tester);
      }, backend);
    });

    testWidgets('el botón de práctica abre la cámara de señas', (tester) async {
      await http.runWithClient(() async {
        await _open(tester, section);

        await _tapText(tester, 'Practicar el alfabeto con la cámara');
        await tester.pump(const Duration(seconds: 1));

        expect(find.byType(SignCameraScreen), findsOneWidget);
        expect(find.text('Lee mi mano'), findsOneWidget);
        // La cámara pregunta al backend antes de pedir permiso a nadie.
        expect(requests.map((url) => url.path), contains('/api/signs/status'));
        expect(
          find.textContaining('no tiene activo el reconocimiento'),
          findsOneWidget,
        );

        await _close(tester);
      }, backend);
    });
  });

  group('SectionVideoScreen: apoyo en señas', () {
    tearDown(
      () => LearningPreferences.instance.setSignSupport(SignSupportLevel.off),
    );

    testWidgets('sin pedirlo no ocupa sitio', (tester) async {
      await LearningPreferences.instance.setSignSupport(SignSupportLevel.off);
      await http.runWithClient(() async {
        await _open(tester, _section([_install]));
        expect(find.byType(SignLanguagePanel), findsNothing);
        await _close(tester);
      }, backend);
    });

    testWidgets('en básico deletrea el subtítulo, sin señas de palabra', (
      tester,
    ) async {
      await LearningPreferences.instance.setSignSupport(SignSupportLevel.basic);
      await http.runWithClient(() async {
        await _open(tester, _section([_install]));

        var panel = tester.widget<SignLanguagePanel>(
          find.byType(SignLanguagePanel),
        );
        expect(panel.text, 'Primero abre la página oficial.');
        expect(panel.showWordSigns, isFalse);
        expect(panel.isPlaying, isFalse);

        // Al reproducir la transcripción, el panel también se pone en marcha.
        await _tapTooltip(tester, 'Reproducir los subtítulos');
        panel = tester.widget<SignLanguagePanel>(
          find.byType(SignLanguagePanel),
        );
        expect(panel.isPlaying, isTrue);

        await _tapTooltip(tester, 'Pausar los subtítulos');
        await _close(tester);
      }, backend);
    });

    testWidgets('en avanzado añade la seña de la palabra, también en móvil', (
      tester,
    ) async {
      await LearningPreferences.instance.setSignSupport(
        SignSupportLevel.advanced,
      );
      await http.runWithClient(() async {
        await _open(tester, _section([_install]), width: 390);

        final panel = tester.widget<SignLanguagePanel>(
          find.byType(SignLanguagePanel),
        );
        expect(panel.showWordSigns, isTrue);
        expect(tester.takeException(), isNull);

        // En pantalla estrecha el panel va debajo del cuadro de subtítulos.
        final caption = tester.getTopLeft(find.text('Subtítulos'));
        final signs = tester.getTopLeft(find.byType(SignLanguagePanel));
        expect(signs.dy, greaterThan(caption.dy));

        await _close(tester);
      }, backend);
    });
  });
}

// --- Datos de prueba -----------------------------------------------------

const _install = SectionVideo(
  title: 'Instalar Python paso a paso',
  youtubeId: 'abcdefghijk',
  description: 'Cómo descargar el instalador oficial.',
  duration: '4:10',
  transcript:
      'Primero abre la página oficial. Después descarga el instalador. '
      'Por último ejecútalo.',
);

const _firstProgram = SectionVideo(
  title: 'Tu primer programa',
  youtubeId: 'zyxwvutsrqp',
  description: 'Escribe y ejecuta un saludo.',
  transcript: 'Abre el editor. Escribe un saludo con print.',
);

const _silent = SectionVideo(
  title: 'Repaso visual',
  youtubeId: 'qwertyuiopa',
  description: 'Solo imágenes, sin narración.',
);

CourseSection _section(List<SectionVideo> videos) => CourseSection(
  id: 'prueba-videos-${videos.map((video) => video.youtubeId).join('-')}',
  moduleNumber: 1,
  number: 9,
  title: 'Videos de prueba',
  summary: 'Sección hecha a medida para las pruebas.',
  objectives: const [],
  videos: videos,
);

CourseModule _module(CourseSection section) =>
    CourseModule(number: 1, title: 'Preparación', sections: [section]);

// --- Pasos comunes -------------------------------------------------------

void _useTallView(WidgetTester tester, {double width = 900}) {
  tester.view.physicalSize = Size(width, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _open(
  WidgetTester tester,
  CourseSection section, {
  double width = 900,
}) async {
  _useTallView(tester, width: width);
  await tester.pumpWidget(
    MaterialApp(
      home: SectionVideoScreen(module: _module(section), section: section),
    ),
  );
  // Deja que el reproductor reciba los subtítulos del backend simulado.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _tapText(WidgetTester tester, String text, {int? index}) async {
  final finder = index == null ? find.text(text) : find.text(text).at(index);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byTooltip(tooltip);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

bool _tooltipEnabled(WidgetTester tester, String tooltip) {
  final button = tester.widget<IconButton>(
    find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    ),
  );
  return button.onPressed != null;
}

/// Mueve el reproductor a [position] y espera a que el reproductor revise qué
/// subtítulo toca (lo hace cada 200 ms).
Future<void> _seek(WidgetTester tester, Duration position) async {
  final controller = tester
      .widget<ypf.YoutubePlayer>(find.byType(ypf.YoutubePlayer))
      .controller;
  controller.updateValue(controller.value.copyWith(position: position));
  await tester.pump(const Duration(milliseconds: 250));
}

/// Desmonta la pantalla: así se cancelan los temporizadores del reproductor y
/// de los subtítulos antes de que acabe la prueba.
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

List<String> _announced(WidgetTester tester) =>
    tester.takeAnnouncements().map((a) => a.message).toList();

/// Navegador de mentira: guarda qué se le pide abrir y contesta lo indicado.
class _FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  Future<bool> answer = Future.value(true);
  final List<String> urls = [];
  final List<PreferredLaunchMode> modes = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) {
    urls.add(url);
    modes.add(options.mode);
    return answer;
  }

  // El resto de la interfaz (enlaces incrustados, etc.) no se usa aquí.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
