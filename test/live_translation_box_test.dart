import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/users_management/widgets/live_translation_box.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('LiveTranslationBox Tests', () {
    testWidgets('renderiza correctamente y carga subtítulos con éxito', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/youtube/captions')) {
          return http.Response(
            jsonEncode({
              'cues': [
                {
                  'start': 0.0,
                  'duration': 3.0,
                  'text': 'Hello',
                  'translated': 'Hola',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveTranslationBox(
                  videoUrl: 'https://www.youtube.com/watch?v=abc123',
                  backendUrl: 'http://127.0.0.1:8000',
                ),
              ),
            ),
          ),
        );

        // Esperar a que se resuelva la carga asíncrona de subtítulos
        await tester.pumpAndSettle();

        expect(find.text('Traducción en tiempo real'), findsOneWidget);
        expect(find.text('Subtítulos: 1'), findsOneWidget);
      }, () => mockClient);
    });

    testWidgets(
      'muestra mensaje de error cuando falla la carga de subtítulos',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response('Error interno', 500);
        });

        await http.runWithClient(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: LiveTranslationBox(
                    videoUrl: 'https://www.youtube.com/watch?v=abc123',
                    backendUrl: 'http://127.0.0.1:8000',
                  ),
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          expect(
            find.textContaining('No se pudieron cargar subtítulos'),
            findsOneWidget,
          );
        }, () => mockClient);
      },
    );

    testWidgets('permite interactuar con los botones de sincronización', (
      tester,
    ) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'cues': [
              {
                'start': 0.0,
                'duration': 5.0,
                'text': 'Test',
                'translated': 'Prueba',
              },
            ],
          }),
          200,
        );
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LiveTranslationBox(
                  videoUrl: 'https://www.youtube.com/watch?v=abc123',
                  backendUrl: 'http://127.0.0.1:8000',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificar y pulsar el botón de abrir y sincronizar
        expect(find.text('Abrir y sincronizar'), findsOneWidget);
        await tester.tap(find.text('Abrir y sincronizar'));
        await tester.pump();

        // Verificar que el botón de detener aparece y se puede pulsar
        expect(find.text('Detener'), findsOneWidget);
        await tester.tap(find.text('Detener'));
        await tester.pump();
      }, () => mockClient);
    });
  });
}
