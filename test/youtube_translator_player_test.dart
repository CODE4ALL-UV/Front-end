import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/youtube_translator_player.dart'; // LE FALTO EL _new MI PAPACHO, VEA ESO jaja
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// IMPORTANTE: Ajusta esta ruta a tu proyecto
// import 'package:flutter_code4all/ui/widgets/youtube_translator_player.dart';

void main() {
  group('YoutubeTranslatorPlayer Tests', () {
    testWidgets('Muestra error de UI si la URL o ID es inválido', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: YoutubeTranslatorPlayer(videoUrl: 'url_invalida_sin_formato'),
          ),
        ),
      );

      // Verificamos que se muestre el mensaje de error definido en el build()
      expect(
        find.textContaining('URL o ID de YouTube no válido'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets(
      'Extrae ID desde URL estándar y carga subtítulos exitosamente (200 OK)',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['video_id'], 'abc12345678');
          return http.Response(
            jsonEncode({
              'cues': [
                {
                  'start': 1.0,
                  'duration': 2.0,
                  'text': 'Hola',
                  'translated': 'Hello',
                },
                {
                  'start': 4.0,
                  'duration': 1.5,
                  'text': 'Mundo',
                }, // Sin traducir
              ],
            }),
            200,
          );
        });

        int cuesCargados = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: YoutubeTranslatorPlayer(
                videoUrl:
                    'https://www.youtube.com/watch?v=abc12345678', // URL Estándar
                httpClient: mockClient,
                onCuesLoaded: (count) => cuesCargados = count,
              ),
            ),
          ),
        );

        // Esperamos a que los Futures internos terminen
        await tester.pumpAndSettle();

        // Verificamos que parseó el array de 2 elementos
        expect(cuesCargados, 2);
      },
    );

    testWidgets(
      'Extrae ID desde URL corta (youtu.be) y maneja error del backend (500)',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['video_id'], 'xyz09876543');
          return http.Response('Error interno', 500);
        });

        int cuesCargados = -1;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: YoutubeTranslatorPlayer(
                videoUrl: 'https://youtu.be/xyz09876543', // URL Corta
                httpClient: mockClient,
                onCuesLoaded: (count) => cuesCargados = count,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        // Si el backend falla, la lista de cues se limpia (queda en 0)
        expect(cuesCargados, 0);
      },
    );

    testWidgets('Extrae ID desde URL embed y maneja Timeout/Exception', (
      WidgetTester tester,
    ) async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['video_id'], 'embed123456');
        throw Exception('Sin conexión');
      });

      int cuesCargados = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: YoutubeTranslatorPlayer(
              videoUrl:
                  'https://www.youtube.com/embed/embed123456', // URL Embed
              httpClient: mockClient,
              onCuesLoaded: (count) => cuesCargados = count,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // Al fallar por excepción, debe reportar 0 subtítulos
      expect(cuesCargados, 0);
    });

    testWidgets(
      'Acepta ID directo (11 caracteres) y renderiza widget sin overlay si se pide',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['video_id'], '12345678901');
          return http.Response(jsonEncode({'cues': []}), 200);
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: YoutubeTranslatorPlayer(
                videoUrl: '12345678901', // Exactamente 11 caracteres (Regex)
                httpClient: mockClient,
                showOverlayCaption: false, // Probamos la rama false del overlay
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Aseguramos que no renderice el overlay oscuro
        // Buscamos un Container que no debería estar si showOverlayCaption es false
        expect(find.byType(AnimatedOpacity), findsNothing);
      },
    );
  });
}
