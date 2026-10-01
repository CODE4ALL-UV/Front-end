import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/braille_translation_service.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';

/// El teclado Braille para escribir sin ver: toda la pantalla es la celda, la
/// letra se confirma sola al levantar los dedos y lo demás son gestos.
///
/// La traducción es del backend, así que aquí se sustituye por un servidor de
/// mentira que sólo sabe unas pocas letras. Lo que se comprueba es lo que hace
/// la pantalla: qué manda, qué enseña y, sobre todo, qué dice en voz alta,
/// porque quien la usa normalmente no ve.
void main() {
  const letters = {
    '1': 'a',
    '1,2': 'b',
    '1,2,3': 'l',
    '1,2,5': 'h',
    '1,3,5': 'o',
    '5': '@',
  };

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
        for (var i = 0; i < cells.length; i++)
          if (cells[i].isEmpty)
            {
              'index': i,
              'dots': [],
              'kind': 'space',
              'value': ' ',
              'spoken': 'espacio',
            }
          else if (letters[cells[i].join(',')] case final letter?)
            {
              'index': i,
              'dots': cells[i],
              'kind': 'letter',
              'value': letter,
              'spoken': letter,
            }
          else
            {
              'index': i,
              'dots': cells[i],
              'kind': 'unknown',
              'value': '',
              'spoken': 'combinación no reconocida',
            },
      ];
      return http.Response(
        jsonEncode({
          'text': readings.map((r) => r['value']).join(),
          'cells': readings,
          'unrecognized': [
            for (final r in readings)
              if (r['kind'] == 'unknown') r['index'],
          ],
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

  late List<String> spoken;

  const delay = Duration(milliseconds: 500);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool offline = false,
    Size size = const Size(600, 1000),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: BrailleKeyboardScreen(
          service: fakeService(offline: offline),
          speak: spoken.add,
          commitDelay: delay,
        ),
      ),
    );
    await tester.pump();
  }

  Offset zone(WidgetTester tester, int dot) =>
      tester.getCenter(find.byKey(ValueKey('braille-dot-$dot')));

  /// Toca los puntos uno detrás de otro, con un dedo.
  Future<void> tapDots(WidgetTester tester, List<int> dots) async {
    for (final dot in dots) {
      await tester.tapAt(zone(tester, dot));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Apoya varios dedos a la vez y los levanta.
  Future<void> chord(WidgetTester tester, List<int> dots) async {
    final fingers = <TestGesture>[];
    for (var i = 0; i < dots.length; i++) {
      fingers.add(
        await tester.startGesture(zone(tester, dots[i]), pointer: 10 + i),
      );
    }
    for (final finger in fingers) {
      await finger.up();
    }
    await tester.pump();
  }

  /// Espera a que la letra se dé por terminada y llegue la traducción.
  Future<void> waitForLetter(WidgetTester tester) async {
    await tester.pump(delay);
    await tester.pumpAndSettle();
  }

  Future<void> swipe(WidgetTester tester, Offset direction) async {
    await tester.dragFrom(zone(tester, 2), direction);
    await tester.pumpAndSettle();
  }

  String output(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const ValueKey('braille-output'))).data!;

  setUp(() {
    requests = [];
    spoken = [];
  });

  testWidgets('al abrirse lee las instrucciones en voz alta', (tester) async {
    await pumpScreen(tester);
    expect(spoken, [BrailleKeyboardScreen.instructions]);
  });

  testWidgets('las seis zonas llenan la pantalla: 1-2-3 a la izquierda y '
      '4-5-6 a la derecha', (tester) async {
    await pumpScreen(tester);

    for (final (left, right) in [(1, 4), (2, 5), (3, 6)]) {
      expect(zone(tester, left).dx, lessThan(zone(tester, right).dx));
      expect(zone(tester, left).dy, zone(tester, right).dy);
    }
    expect(zone(tester, 1).dy, lessThan(zone(tester, 2).dy));
    expect(zone(tester, 2).dy, lessThan(zone(tester, 3).dy));

    // Cada zona es enorme: media pantalla de ancho.
    final size = tester.getSize(find.byKey(const ValueKey('braille-dot-1')));
    expect(size.width, 300);
    expect(size.height, greaterThan(200));
  });

  testWidgets('las zonas se anuncian al lector de pantalla como botones', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpScreen(tester);

    expect(
      tester.getSemantics(find.byKey(const ValueKey('braille-dot-1'))),
      matchesSemantics(
        label: 'Punto 1',
        hint: 'mitad izquierda, arriba',
        isButton: true,
        hasToggledState: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('con un dedo: tocar los puntos y esperar escribe la letra sola', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapDots(tester, [1, 2, 5]);
    expect(spoken.last, '5');
    expect(requests, isEmpty, reason: 'todavía no ha pasado la espera');

    await waitForLetter(tester);
    expect(requests.last, [
      [1, 2, 5],
    ]);
    expect(output(tester), 'h');
    expect(spoken.last, 'h');
  });

  testWidgets('con varios dedos a la vez también', (tester) async {
    await pumpScreen(tester);

    await chord(tester, [1, 3, 5]);
    await waitForLetter(tester);

    expect(requests.last, [
      [1, 3, 5],
    ]);
    expect(spoken.last, 'o');
  });

  testWidgets('mientras haya un dedo apoyado la letra no se cierra', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tapDots(tester, [1]);

    final finger = await tester.startGesture(zone(tester, 2));
    // Más que la espera para cerrar la letra, menos que la de hablar.
    await tester.pump(const Duration(milliseconds: 800));
    expect(requests, isEmpty);

    await finger.up();
    await waitForLetter(tester);
    expect(requests.last, [
      [1, 2],
    ]);
  });

  testWidgets('tocar otra vez un punto lo quita', (tester) async {
    await pumpScreen(tester);
    await tapDots(tester, [1, 1]);
    expect(spoken.last, '1 quitado');
  });

  testWidgets('deslizar a la derecha es espacio y repite la palabra', (
    tester,
  ) async {
    await pumpScreen(tester);
    for (final letter in [
      [1, 2, 5],
      [1, 3, 5],
      [1, 2, 3],
      [1],
    ]) {
      await chord(tester, letter);
      await waitForLetter(tester);
    }

    await swipe(tester, const Offset(200, 0));
    expect(requests.last.last, isEmpty);
    expect(spoken.last, 'hola, espacio');
  });

  testWidgets('deslizar confirma también la letra que quedaba a medias', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tapDots(tester, [1]);
    await swipe(tester, const Offset(200, 0));

    // El deslizar no cuenta como punto: sólo la «a» y el espacio.
    expect(requests.last, [
      [1],
      [],
    ]);
    expect(output(tester), 'a ');
  });

  testWidgets('deslizar a la izquierda borra y dice qué', (tester) async {
    await pumpScreen(tester);
    await chord(tester, [1]);
    await waitForLetter(tester);
    await chord(tester, [1, 2]);
    await waitForLetter(tester);
    expect(output(tester), 'ab');

    await swipe(tester, const Offset(-200, 0));
    expect(spoken.last, 'Borrado: b');
    expect(output(tester), 'a');
  });

  testWidgets('deslizar hacia abajo lee todo el texto', (tester) async {
    await pumpScreen(tester);
    await chord(tester, [1, 2, 5]);
    await waitForLetter(tester);
    await chord(tester, [1, 3, 5]);
    await waitForLetter(tester);

    await swipe(tester, const Offset(0, 200));
    expect(spoken.last, 'Texto traducido: ho.');
  });

  testWidgets('deslizar hacia arriba repite las instrucciones', (tester) async {
    await pumpScreen(tester);
    spoken.clear();
    await tester.dragFrom(zone(tester, 3), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(spoken.last, BrailleKeyboardScreen.instructions);
  });

  testWidgets('los botones de la barra siguen para quien ve', (tester) async {
    await pumpScreen(tester);
    await tapDots(tester, [1]);
    await tester.tap(find.byKey(const ValueKey('braille-action-Enviar')));
    await tester.pumpAndSettle();

    expect(spoken.last, 'Texto traducido: a.');
    expect(output(tester), 'a');
  });

  testWidgets('avisa de las combinaciones que no se entienden', (tester) async {
    await pumpScreen(tester);
    await chord(tester, [4]);
    await waitForLetter(tester);
    await swipe(tester, const Offset(0, 200));
    expect(spoken.last, contains('una combinación no reconocida'));
  });

  testWidgets('sin servidor lo dice en voz alta y en pantalla', (tester) async {
    await pumpScreen(tester, offline: true);
    await chord(tester, [1]);
    await waitForLetter(tester);

    expect(spoken.last, contains('no hay conexión con el servidor'));
    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
  });

  testWidgets('con teclado físico funciona como una Perkins', (tester) async {
    await pumpScreen(tester);

    // F + D + K a la vez = puntos 1, 2 y 5 = «h».
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);
    expect(requests, isEmpty, reason: 'hasta soltar todas no hay letra');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyK);
    await tester.pumpAndSettle();

    expect(requests.last, [
      [1, 2, 5],
    ]);
    expect(output(tester), 'h');
  });

  testWidgets('cabe en un móvil pequeño sin desbordarse', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
  });

  group('rellenar el correo y la contraseña', () {
    late TextEditingController email;
    late TextEditingController password;
    bool? popped;

    Future<void> pumpFields(WidgetTester tester) async {
      email = TextEditingController();
      password = TextEditingController();
      addTearDown(email.dispose);
      addTearDown(password.dispose);
      popped = null;

      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => BrailleKeyboardScreen(
                      fields: [
                        BrailleField(label: 'Correo', controller: email),
                        BrailleField(
                          label: 'Contraseña',
                          controller: password,
                          obscure: true,
                        ),
                      ],
                      service: fakeService(),
                      speak: spoken.add,
                      commitDelay: delay,
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('las instrucciones explican los campos y la arroba', (
      tester,
    ) async {
      await pumpFields(tester);
      expect(spoken.first, contains('correo y contraseña'));
      expect(spoken.first, contains('arroba'));
    });

    testWidgets('lo escrito aparece en el campo según se escribe', (
      tester,
    ) async {
      await pumpFields(tester);
      for (final letter in [
        [1],
        [5],
        [1, 2],
      ]) {
        await chord(tester, letter);
        await waitForLetter(tester);
      }

      expect(email.text, 'a@b');
      expect(spoken.last, 'b');
    });

    testWidgets('deslizar abajo pasa a la contraseña y al final envía', (
      tester,
    ) async {
      await pumpFields(tester);
      await chord(tester, [1]);
      await waitForLetter(tester);

      await swipe(tester, const Offset(0, 200));
      expect(spoken.last, 'Correo: a. Ahora escribe contraseña.');

      await chord(tester, [1, 2]);
      await waitForLetter(tester);
      await chord(tester, [1]);
      await waitForLetter(tester);
      expect(password.text, 'ba');
      expect(email.text, 'a', reason: 'el correo no se toca');

      // En pantalla la contraseña va tapada.
      expect(find.text('••'), findsOneWidget);

      await swipe(tester, const Offset(0, 200));
      // No la lee entera: sólo cuántos caracteres tiene.
      expect(spoken.last, 'Contraseña: 2 caracteres. Enviando.');
      expect(popped, isTrue);
    });

    testWidgets('borrar con el campo vacío vuelve al anterior', (tester) async {
      await pumpFields(tester);
      await chord(tester, [1]);
      await waitForLetter(tester);
      await swipe(tester, const Offset(0, 200));

      await swipe(tester, const Offset(-200, 0));
      expect(spoken.last, contains('Ahora escribe correo'));

      await swipe(tester, const Offset(-200, 0));
      expect(spoken.last, 'Borrado: a');
      expect(email.text, isEmpty);
    });
  });
}
