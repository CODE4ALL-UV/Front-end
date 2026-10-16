import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/braille_translation_service.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';

/// Los casos del teclado Braille que no son escribir una letra bien escrita:
/// borrar cuando no hay nada, enviar en vacío, quedarse sin servidor, copiar,
/// borrarlo todo, usar las teclas de un teclado normal, el lector de pantalla
/// y el micrófono cuando lo escrito no se pudo traducir.
///
/// Quien usa este teclado normalmente no ve la pantalla, así que en cada caso
/// se comprueba sobre todo **qué se le dice en voz alta**: un borrado
/// silencioso o un error mudo lo deja sin saber qué ha pasado.
void main() {
  const letters = {'1': 'a', '1,2': 'b', '1,4': 'c'};

  late List<String> spoken;
  late List<List<List<int>>> requests;

  BrailleTranslationService fakeService({bool offline = false}) {
    final client = MockClient((request) async {
      if (offline) throw http.ClientException('sin red');
      final cells = [
        for (final cell in jsonDecode(request.body)['cells'] as List)
          [for (final dot in cell as List) dot as int],
      ];
      requests.add(cells);
      final readings = [
        for (final cell in cells)
          if (cell.isEmpty)
            {'dots': [], 'kind': 'space', 'value': ' ', 'spoken': 'espacio'}
          else if (letters[cell.join(',')] case final letter?)
            {'dots': cell, 'kind': 'letter', 'value': letter, 'spoken': letter}
          else
            {
              'dots': cell,
              'kind': 'unknown',
              'value': '',
              'spoken': 'combinación no reconocida',
            },
      ];
      return http.Response(
        jsonEncode({
          'text': readings.map((r) => r['value']).join(),
          'cells': readings,
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    return BrailleTranslationService(
      api: ApiService(baseUrl: 'http://servidor.test'),
      client: client,
    );
  }

  const delay = Duration(milliseconds: 500);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool offline = false,
    Duration? commitDelay = delay,
    VoiceDictation? dictation,
  }) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BrailleKeyboardScreen(
          service: fakeService(offline: offline),
          speak: spoken.add,
          commitDelay: commitDelay,
          dictation: dictation ?? _SilentDictation(),
        ),
      ),
    );
    await tester.pump();
    spoken.clear(); // las instrucciones de bienvenida
  }

  Offset zone(WidgetTester tester, int dot) =>
      tester.getCenter(find.byKey(ValueKey('braille-dot-$dot')));

  Future<void> tapDots(WidgetTester tester, List<int> dots) async {
    for (final dot in dots) {
      await tester.tapAt(zone(tester, dot));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitForLetter(WidgetTester tester) async {
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  String output(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('braille-output'))).data!;

  setUp(() {
    spoken = [];
    requests = [];
  });

  group('borrar y enviar sin nada', () {
    testWidgets('borrar los puntos a medias no escribe ninguna letra', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tapDots(tester, [1, 2]);

      await tester.tap(find.byKey(const ValueKey('braille-action-Atrás')));
      await tester.pump();

      expect(spoken.last, 'Puntos de la letra borrados');
      await waitForLetter(tester);
      expect(requests, isEmpty, reason: 'la letra a medias se descartó');
      expect(output(tester), '—');
    });

    testWidgets('borrar con todo vacío lo dice en vez de callar', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('braille-action-Atrás')));
      await tester.pump();

      expect(spoken, ['No hay nada que borrar']);
    });

    testWidgets('enviar sin haber escrito nada lo avisa', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('braille-action-Enviar')));
      await tester.pumpAndSettle();

      expect(spoken, ['Todavía no has escrito nada.']);
      expect(requests, isEmpty);
    });
  });

  group('sin servidor', () {
    testWidgets('lo escrito se guarda y al borrarlo se dicen sus puntos', (
      tester,
    ) async {
      await pumpScreen(tester, offline: true);
      await tapDots(tester, [1, 2]);
      await waitForLetter(tester);

      expect(
        spoken.last,
        'puntos 1 y 2. Guardado, pero no se pudo traducir: '
        'no hay conexión con el servidor.',
      );

      await tester.tap(find.byKey(const ValueKey('braille-action-Espacio')));
      await tester.pumpAndSettle();
      expect(spoken.last, startsWith('espacio. Guardado'));

      // Sin traducción no se sabe qué letra era: se dice qué se borra.
      await tester.tap(find.byKey(const ValueKey('braille-action-Atrás')));
      await tester.pumpAndSettle();
      expect(spoken, contains('Borrado: espacio'));

      await tester.tap(find.byKey(const ValueKey('braille-action-Atrás')));
      await tester.pumpAndSettle();
      expect(spoken, contains('Borrado: puntos 1 y 2'));
    });

    testWidgets('enviar sin servidor dice por qué no se puede leer', (
      tester,
    ) async {
      await pumpScreen(tester, offline: true);
      await tapDots(tester, [1]);
      await waitForLetter(tester);

      await tester.tap(find.byKey(const ValueKey('braille-action-Enviar')));
      await tester.pumpAndSettle();

      const error =
          'No se pudo conectar con el servidor para traducir el Braille.';
      expect(spoken.last, error);
      expect(find.text(error), findsOneWidget);
    });

    testWidgets('el micrófono no se abre si lo escrito está sin traducir', (
      tester,
    ) async {
      final dictation = _SilentDictation();
      await pumpScreen(tester, offline: true, dictation: dictation);
      await tapDots(tester, [1]);
      await waitForLetter(tester);

      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pumpAndSettle();

      expect(spoken.last, startsWith('Antes de hablar hace falta traducir'));
      expect(dictation.listens, 0);
    });
  });

  group('botones del texto escrito', () {
    testWidgets('copiar deja el texto en el portapapeles', (tester) async {
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

      await pumpScreen(tester);
      await tapDots(tester, [1, 4]);
      await waitForLetter(tester);
      expect(output(tester), 'c');

      await tester.tap(find.byTooltip('Copiar texto'));
      await tester.pumpAndSettle();

      expect(copied, 'c');
      expect(spoken.last, 'Texto copiado');
    });

    testWidgets('borrar todo vacía el texto y lo dice', (tester) async {
      await pumpScreen(tester);
      await tapDots(tester, [1]);
      await waitForLetter(tester);
      expect(output(tester), 'a');

      await tester.tap(find.byTooltip('Borrar todo el texto'));
      await tester.pumpAndSettle();

      expect(output(tester), '—');
      expect(spoken.last, 'Texto borrado');
      // Sin texto ya no se ofrecen copiar ni borrar.
      expect(find.byTooltip('Copiar texto'), findsNothing);
    });

    testWidgets('el botón de ayuda repite las instrucciones', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Ayuda: escuchar las instrucciones'));
      await tester.pump();

      expect(spoken, [BrailleKeyboardScreen.instructions]);
    });
  });

  group('teclado físico', () {
    testWidgets('espacio, retroceso e intro hacen lo mismo que los gestos', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(spoken.last, 'Todavía no has escrito nada.');

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(spoken.last, 'No hay nada que borrar');

      // Una tecla que no es del teclado Braille no hace nada.
      final before = spoken.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pumpAndSettle();
      expect(spoken.length, before);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(requests.last, [
        <int>[],
      ], reason: 'el espacio se manda a traducir');

      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await tester.pumpAndSettle();
      expect(spoken.last, startsWith('No se reconoció ningún texto'));
    });
  });

  group('lector de pantalla', () {
    testWidgets('cada zona se activa con doble toque y da la letra', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpScreen(tester);

      tester.semantics.tap(find.semantics.byLabel('Punto 1'));
      await tester.pump();
      expect(spoken.last, '1');

      await waitForLetter(tester);
      expect(output(tester), 'a');
      semantics.dispose();
    });

    testWidgets('con el lector encendido se espera más para cerrar la letra', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpScreen(tester, commitDelay: null);

      await tapDots(tester, [1]);
      // Con el tiempo normal la letra ya se habría cerrado.
      await tester.pump(BrailleKeyboardScreen.defaultCommitDelay);
      expect(requests, isEmpty);

      await tester.pump(BrailleKeyboardScreen.screenReaderCommitDelay);
      await tester.pumpAndSettle();
      expect(requests, isNotEmpty);
      expect(output(tester), 'a');
    });
  });

  group('gestos interrumpidos y micrófono', () {
    testWidgets('un toque cancelado por el sistema no marca ningún punto', (
      tester,
    ) async {
      await pumpScreen(tester);

      final finger = await tester.startGesture(zone(tester, 1));
      await finger.cancel();
      await tester.pump(delay * 2);

      expect(spoken, isEmpty);
      expect(requests, isEmpty);

      // Después se sigue escribiendo con normalidad.
      await tapDots(tester, [1]);
      await waitForLetter(tester);
      expect(output(tester), 'a');
    });

    testWidgets('el botón de hablar, pulsado otra vez, deja de escuchar', (
      tester,
    ) async {
      final dictation = _SilentDictation()..waitForStop = true;
      await pumpScreen(tester, dictation: dictation);

      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const ValueKey('braille-listening')), findsOneWidget);
      expect(find.byIcon(Icons.mic_off), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pumpAndSettle();

      expect(dictation.stops, greaterThanOrEqualTo(1));
      expect(find.byKey(const ValueKey('braille-listening')), findsNothing);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });
  });

  group('icono de celda', () {
    testWidgets('solo se vuelve a pintar si cambian los puntos o el color', (
      tester,
    ) async {
      CustomPainter painterFor(Set<int> dots, Color color) {
        return tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(BrailleCellIcon),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!;
      }

      Future<CustomPainter> pumpIcon(Set<int> dots, Color color) async {
        await tester.pumpWidget(
          Center(
            child: BrailleCellIcon(dots: dots, color: color),
          ),
        );
        return painterFor(dots, color);
      }

      final first = await pumpIcon({1, 2, 4}, Colors.black);
      final same = await pumpIcon({4, 2, 1}, Colors.black);
      final otherDots = await pumpIcon({1}, Colors.black);
      final otherColor = await pumpIcon({1}, Colors.red);

      expect(same.shouldRepaint(first), isFalse);
      expect(otherDots.shouldRepaint(same), isTrue);
      expect(otherColor.shouldRepaint(otherDots), isTrue);
    });
  });

  group('servicio de traducción', () {
    test(
      'si el servidor responde con error se explica con su código',
      () async {
        final service = BrailleTranslationService(
          api: ApiService(baseUrl: 'http://servidor.test'),
          client: MockClient((_) async => http.Response('caído', 503)),
        );

        await expectLater(
          service.translate([
            {1},
          ]),
          throwsA(
            isA<BrailleTranslationException>().having(
              (e) => e.toString(),
              'mensaje',
              'El servidor no pudo traducir el Braille (error 503).',
            ),
          ),
        );
      },
    );

    test('manda cada celda ordenada a la ruta de traducción', () async {
      late http.Request sent;
      final service = BrailleTranslationService(
        api: ApiService(baseUrl: 'http://servidor.test'),
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'text': 'b',
              'cells': [
                {
                  'dots': [1, 2],
                  'kind': 'letter',
                  'value': 'b',
                  'spoken': 'be',
                },
              ],
            }),
            200,
          );
        }),
      );

      final result = await service.translate([
        {2, 1},
      ]);

      expect(sent.url.toString(), 'http://servidor.test/api/braille/translate');
      expect(jsonDecode(sent.body), {
        'cells': [
          [1, 2],
        ],
      });
      expect(result.text, 'b');
      expect(result.cells.single.spoken, 'be');
      expect(result.unrecognizedCount, 0);
    });

    test('sin cliente propio usa el servidor configurado de la app', () {
      // No hace ninguna petición: solo que se pueda crear sin dependencias.
      expect(BrailleTranslationService(), isA<BrailleTranslationService>());
      expect(BrailleTranslationService.timeout, const Duration(seconds: 8));
    });
  });
}

/// Un micrófono que no oye nada. Puede quedarse escuchando hasta que se le
/// pida parar.
class _SilentDictation implements VoiceDictation {
  bool waitForStop = false;
  int listens = 0;
  int stops = 0;
  Completer<String?>? _pending;

  @override
  Future<String?> listen({void Function(String partial)? onPartial}) async {
    listens++;
    if (!waitForStop) return null;
    return (_pending = Completer<String?>()).future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(null);
  }

  @override
  Future<void> cue({required bool start}) async {}
}
