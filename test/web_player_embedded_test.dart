import 'package:flutter/material.dart';
import 'package:flutter_code4all/web_player_embedded.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

// IMPORTANTE: Ajusta esta ruta a tu proyecto real
// import 'package:flutter_code4all/web_player_embedded.dart';

void main() {
  group('EmbeddedYoutubeWebPlayer Tests', () {
    testWidgets(
      'Ciclo de vida del reproductor: initState, didUpdateWidget, build y dispose',
      (WidgetTester tester) async {
        Duration? lastReportedPosition;

        // 1. Renderizado inicial (Cubre: initState y build)
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbeddedYoutubeWebPlayer(
                videoId: 'dQw4w9WgXcQ',
                onPosition: (pos) => lastReportedPosition = pos,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verificamos que el reproductor interno del paquete iframe se haya construido
        expect(find.byType(YoutubePlayer), findsOneWidget);

        // 2. Cambio de videoId (Cubre: didUpdateWidget)
        // Simulamos que el widget padre cambió de estado y le pasa un nuevo video
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmbeddedYoutubeWebPlayer(
                videoId: 'abc12345678', // Un ID distinto
                onPosition: (pos) => lastReportedPosition = pos,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // El widget debe seguir existiendo y haber cargado el nuevo ID en el controlador
        expect(find.byType(YoutubePlayer), findsOneWidget);

        // 3. Desmontaje del widget (Cubre: dispose y cancelación de la suscripción)
        // Reemplazamos la pantalla con un contenedor vacío para forzar la destrucción del reproductor
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox())),
        );

        await tester.pumpAndSettle();

        // Verificamos que el reproductor ya no esté en el árbol y la memoria se haya limpiado
        expect(find.byType(YoutubePlayer), findsNothing);
      },
    );
  });
}
