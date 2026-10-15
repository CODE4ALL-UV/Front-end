import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/youtube_translator_player.dart';

/// Sincronización de subtítulos del reproductor de YouTube.
///
/// Las pruebas que ya existían comprueban que se extrae el identificador y que
/// se piden los subtítulos. Aquí se mueve el reproductor por el video para
/// comprobar lo que de verdad importa a un estudiante sordo: que en cada
/// momento se dibuja la frase que toca (traducida si la hay), que en los
/// silencios no se queda una frase vieja en pantalla y que quien contiene al
/// reproductor recibe cada cambio. También se cubren los enlaces que el
/// paquete del reproductor no sabe leer (por ejemplo, con `http`).
///
/// La posición se cambia en el controlador del reproductor, que es de donde
/// la lee el widget cada 200 ms en el móvil.
void main() {
  group('YoutubeTranslatorPlayer: enlaces poco habituales', () {
    testWidgets('un enlace http se lee por su parámetro v', (tester) async {
      final asked = <Uri>[];
      await _mount(
        tester,
        videoUrl: 'http://www.youtube.com/watch?v=abcdefghijk&t=10',
        client: _captions(asked, const []),
      );

      expect(asked.single.queryParameters['video_id'], 'abcdefghijk');
      expect(find.textContaining('no válido'), findsNothing);

      // Sin dirección propia, los subtítulos se piden al backend de la app.
      expect(
        asked.single.toString(),
        startsWith('${ApiService().baseUrl}/api/youtube/captions'),
      );

      await _unmount(tester);
    });

    testWidgets('un enlace embed con http también encuentra el video', (
      tester,
    ) async {
      final asked = <Uri>[];
      await _mount(
        tester,
        videoUrl: 'http://www.youtube.com/embed/abcdefghijk?rel=0',
        client: _captions(asked, const []),
      );

      expect(asked.single.queryParameters['video_id'], 'abcdefghijk');
      expect(find.textContaining('no válido'), findsNothing);

      await _unmount(tester);
    });
  });

  group('YoutubeTranslatorPlayer: subtítulos sincronizados', () {
    testWidgets('mientras llegan los subtítulos avisa de que se cargan', (
      tester,
    ) async {
      final answer = Completer<http.Response>();
      var loaded = -1;

      await _mount(
        tester,
        videoUrl: 'https://youtu.be/abcdefghijk',
        client: MockClient((request) => answer.future),
        onCuesLoaded: (count) => loaded = count,
      );

      expect(find.text('Cargando subtítulos...'), findsOneWidget);
      expect(loaded, -1);

      answer.complete(http.Response(jsonEncode({'cues': _cues}), 200));
      await tester.pump();

      expect(find.text('Cargando subtítulos...'), findsNothing);
      expect(loaded, 2);

      await _unmount(tester);
    });

    testWidgets('dibuja la frase de cada momento y la vacía en los silencios', (
      tester,
    ) async {
      final asked = <Uri>[];
      final changes = <String>[];

      await _mount(
        tester,
        videoUrl: 'https://www.youtube.com/watch?v=abcdefghijk',
        client: _captions(asked, _cues),
        backendUrl: 'http://servidor.de.prueba',
        targetLang: 'en',
        onCaptionChanged: changes.add,
      );

      expect(asked.single.host, 'servidor.de.prueba');
      expect(asked.single.queryParameters['target'], 'en');

      // Antes del primer subtítulo no hay nada que mostrar.
      await _seek(tester, const Duration(milliseconds: 500));
      expect(changes, isEmpty);
      expect(_overlayOpacity(tester), 0.0);

      // Si hay traducción, se muestra la traducción.
      await _seek(tester, const Duration(seconds: 2));
      expect(changes, ['Hola a todos']);
      expect(find.text('Hola a todos'), findsOneWidget);
      expect(_overlayOpacity(tester), 1.0);

      // En el hueco entre dos frases el cuadro se vacía y se avisa.
      await _seek(tester, const Duration(milliseconds: 3500));
      expect(changes, ['Hola a todos', '']);
      expect(find.text('Hola a todos'), findsNothing);
      expect(_overlayOpacity(tester), 0.0);

      // Sin traducción, el texto original.
      await _seek(tester, const Duration(seconds: 5));
      expect(changes.last, 'Vamos a programar');
      expect(find.text('Vamos a programar'), findsOneWidget);

      // Seguir en la misma frase no repite el aviso.
      await _seek(tester, const Duration(milliseconds: 5200));
      expect(changes, hasLength(3));

      // Pasado el último subtítulo, nada.
      await _seek(tester, const Duration(seconds: 30));
      expect(changes.last, '');

      await _unmount(tester);
    });
  });
}

/// Dos frases: la primera con traducción y la segunda sin ella.
const List<Map<String, Object>> _cues = [
  {
    'start': 1.0,
    'duration': 2.0,
    'text': 'Hello everyone',
    'translated': 'Hola a todos',
  },
  {'start': 4.0, 'duration': 1.5, 'text': 'Vamos a programar'},
];

http.Client _captions(List<Uri> asked, List<Map<String, Object>> cues) =>
    MockClient((request) async {
      asked.add(request.url);
      return http.Response(jsonEncode({'cues': cues}), 200);
    });

Future<void> _mount(
  WidgetTester tester, {
  required String videoUrl,
  required http.Client client,
  String? backendUrl,
  String targetLang = 'es',
  ValueChanged<String>? onCaptionChanged,
  ValueChanged<int>? onCuesLoaded,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: YoutubeTranslatorPlayer(
          videoUrl: videoUrl,
          backendUrl: backendUrl,
          targetLang: targetLang,
          httpClient: client,
          onCaptionChanged: onCaptionChanged,
          onCuesLoaded: onCuesLoaded,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Mueve el reproductor a [position] y espera a la siguiente revisión.
Future<void> _seek(WidgetTester tester, Duration position) async {
  final controller = tester
      .widget<ypf.YoutubePlayer>(find.byType(ypf.YoutubePlayer))
      .controller;
  controller.updateValue(controller.value.copyWith(position: position));
  await tester.pump(const Duration(milliseconds: 250));
}

double _overlayOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.byKey(const ValueKey('caption_overlay_opacity')),
    )
    .opacity;

/// Desmonta el reproductor, que cancela su temporizador de posición.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}
