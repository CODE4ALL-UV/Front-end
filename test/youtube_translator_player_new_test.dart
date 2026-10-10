import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/youtube_translator_player_new.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as ypf;

// IMPORTANTE: Ajusta esta ruta al nombre real de tu archivo
// import 'package:flutter_code4all/ui/widgets/youtube_translator_player.dart';

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
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo detectar el ID del video de YouTube.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Carga subtítulos exitosamente y muestra la lista (status 200)',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'cues': [
                {
                  'start': 0.0,
                  'duration': 5.0,
                  'text': 'Hola Mundo',
                  'translated': 'Hello World',
                },
                {
                  'timestamp': 5.5,
                  'duration': 2.0,
                  'text': 'Test',
                }, // Prueba el mapeo de 'timestamp'
              ],
            }),
            200,
          );
        });

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

        // Debe mostrar los subtítulos en la lista (ListTile)
        expect(
          find.text('Hello World'),
          findsOneWidget,
        ); // Usa el traducido si existe
        expect(
          find.text('Test'),
          findsOneWidget,
        ); // Usa el original si no hay traducido
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
      'Muestra el reproductor interno al presionar "Reproducir dentro de la app"',
      (WidgetTester tester) async {
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

        await tester.pumpAndSettle();

        // Al inicio debe estar la miniatura y el botón
        final playButton = find.text('Reproducir dentro de la app');
        expect(playButton, findsOneWidget);

        // Lo presionamos
        await tester.tap(playButton);
        await tester.pumpAndSettle();

        // Ahora debe mostrarse el YoutubePlayer
        expect(find.byType(ypf.YoutubePlayer), findsOneWidget);
      },
    );

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
        await tester.pump();

        // 3. Detener sincronía (cancela el timer y oculta el subtítulo)
        await tester.tap(stopBtn);
        await tester.pumpAndSettle();

        // El contenedor del Live subtitle desaparece (ya solo queda el texto en la lista)
        expect(find.text('Sincronizado'), findsOneWidget);
      },
    );
  });
}
