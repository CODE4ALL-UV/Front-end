import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/youtube_translator_player_new.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;

void main() {
  group('YoutubeTranslatorPlayer (Real File) Tests', () {
    test('extractVideoId extrae correctamente diferentes formatos', () {
      expect(
        extractVideoId('https://www.youtube.com/watch?v=12345678901'),
        '12345678901',
      );
      expect(extractVideoId('https://youtu.be/09876543210'), '09876543210');
      expect(extractVideoId('invalid_url'), null);
      expect(extractVideoId('https://google.com'), null);
    });

    testWidgets(
      'Muestra error si la URL no es de YouTube o no tiene ID válido',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: YoutubeTranslatorPlayer(videoUrl: 'https://google.com'),
          ),
        );
        await tester.pump(const Duration(seconds: 3));

        expect(
          find.text('No se pudo detectar el ID del video de YouTube.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Muestra el reproductor interno al presionar "Reproducir dentro de la app"',
      (WidgetTester tester) async {
        // Simulamos una pantalla móvil en orientación vertical.
        await tester.binding.setSurfaceSize(const Size(430, 932));

        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        final mockClient = MockClient(
          (request) async => http.Response(jsonEncode({'cues': []}), 200),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: YoutubeTranslatorPlayer(
              videoUrl: 'https://youtu.be/video1',
              httpClient: mockClient,
              backendUrl: 'https://backend.test',
            ),
          ),
        );

        // Procesamos los frames sin esperar a que todas las
        // animaciones de la interfaz terminen.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        final playButton = find.text('Reproducir dentro de la app');
        expect(playButton, findsOneWidget);

        // Presionamos el botón para abrir el reproductor.
        await tester.tap(playButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Comprobamos que el widget del reproductor esté en el árbol.
        expect(find.byType(ypf.YoutubePlayer), findsOneWidget);

        // Desmontamos la pantalla para ejecutar la limpieza.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );

    testWidgets('Muestra error si el backend falla (status 500)', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient(
        (request) async => http.Response('Error', 500),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: YoutubeTranslatorPlayer(
            videoUrl: 'https://youtu.be/abc12345678',
            httpClient: mockClient,
            backendUrl: 'https://backend.test',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text('No se pudieron cargar los subtítulos.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Muestra error si ocurre una excepción de red al cargar subtítulos',
      (WidgetTester tester) async {
        final mockClient = MockClient(
          (request) async => throw Exception('Fallo de red'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: YoutubeTranslatorPlayer(
              videoUrl: 'https://youtu.be/abc12345678',
              httpClient: mockClient,
              backendUrl: 'https://backend.test',
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(
          find.textContaining('Error al cargar subtítulos'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Maneja didUpdateWidget al cambiar la URL en caliente', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'cues': []}), 200);
      });

      // Renderiza con la primera URL
      await tester.pumpWidget(
        MaterialApp(
          home: YoutubeTranslatorPlayer(
            videoUrl: 'https://youtu.be/video1',
            httpClient: mockClient,
            backendUrl: 'https://backend.test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Forzamos actualización reconstruyendo el widget con una nueva URL
      await tester.pumpWidget(
        MaterialApp(
          home: YoutubeTranslatorPlayer(
            videoUrl: 'https://youtu.be/video2',
            httpClient: mockClient,
            backendUrl: 'https://backend.test',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Si no crasheó y terminó, el didUpdateWidget ejecutó _loadCaptions para video2.
      expect(find.byType(YoutubeTranslatorPlayer), findsOneWidget);
    });

    testWidgets(
      'Controles de sincronización externa funcionan (Start, Re-sync, Stop)',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'cues': [
                {'start': 0.0, 'duration': 100.0, 'text': 'Sincronizado'},
              ],
            }),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: YoutubeTranslatorPlayer(
              videoUrl: 'https://youtu.be/video1',
              httpClient: mockClient,
              backendUrl: 'https://backend.test',
            ),
          ),
        );

        await tester.pumpAndSettle();

        final openBtn = find.text('Abrir y sincronizar');
        final stopBtn = find.text('Detener sincronía');
        final resyncBtn = find.text('Re-sincronizar ahora');

        // 1. Abrir y sincronizar (inicia el timer)
        await tester.tap(openBtn);
        await tester.pumpAndSettle(); // Procesa el future del onTap

        // Avanzamos el reloj de Flutter 1 segundo para que el Timer dispare el subtítulo
        await tester.pump(const Duration(seconds: 1));

        // El cuadro de Live Subtitle debe aparecer con el texto activo
        expect(
          find.text('Sincronizado'),
          findsWidgets,
        ); // findsWidgets porque también está en la lista

        // 2. Re-sincronizar ahora (resetea el tiempo)
        await tester.tap(resyncBtn);
        await tester.pump(const Duration(seconds: 3));

        // 3. Detener sincronía (cancela el timer y oculta el subtítulo)
        await tester.tap(stopBtn);
        await tester.pump(const Duration(seconds: 3));

        // El contenedor del Live subtitle desaparece (ya solo queda el texto en la lista)
        expect(find.text('Sincronizado'), findsOneWidget);
      },
    );
  });
}
