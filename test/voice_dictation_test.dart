import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/braille_translation_service.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/login_screen.dart';

/// Un micrófono de mentira: «oye» lo que se le diga en [reply].
class FakeDictation implements VoiceDictation {
  String? reply;
  bool unavailable = false;

  /// Si es true, no termina de escuchar hasta que se le pide parar.
  bool waitForStop = false;

  int listens = 0;
  final List<bool> cues = [];
  Completer<String?>? _pending;

  @override
  Future<String?> listen({void Function(String partial)? onPartial}) async {
    listens++;
    if (unavailable) {
      throw DictationUnavailableException('No hay micrófono.');
    }
    onPartial?.call(reply ?? '');
    if (!waitForStop) return reply;
    return (_pending = Completer<String?>()).future;
  }

  @override
  Future<void> stop() async {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(reply);
  }

  @override
  Future<void> cue({required bool start}) async => cues.add(start);
}

/// Hablar en vez de escribir: limpiar lo que se oye y ponerlo donde toca.
void main() {
  group('lo dictado se limpia según el campo', () {
    String email(String heard) =>
        VoiceDictation.normalize(heard, DictationKind.email);

    test('el correo dicho con palabras', () {
      expect(email('Sebastián arroba gmail punto com'), 'sebastian@gmail.com');
    });

    test('el correo que el reconocedor ya escribe bien se respeta', () {
      expect(email('sebastian@gmail.com'), 'sebastian@gmail.com');
    });

    test('guiones y guion bajo', () {
      expect(
        email('ana guion bajo pérez guion uno arroba x punto co'),
        'ana_perez-uno@x.co',
      );
    });

    test('la contraseña pierde los espacios entre cifras', () {
      expect(
        VoiceDictation.normalize('1 2 3 4 5 6 7 8 9', DictationKind.password),
        '123456789',
      );
    });

    test('el texto libre se queda como está', () {
      expect(
        VoiceDictation.normalize('  Hola, mundo ', DictationKind.text),
        'Hola, mundo',
      );
    });
  });

  group('en el teclado Braille', () {
    late FakeDictation mic;
    late List<String> spoken;

    BrailleTranslationService service() => BrailleTranslationService(
      api: ApiService(baseUrl: 'http://servidor.test'),
      client: MockClient((request) async {
        final cells = jsonDecode(request.body)['cells'] as List;
        // Sólo sabe la «a».
        final readings = [
          for (var i = 0; i < cells.length; i++)
            {
              'index': i,
              'dots': cells[i],
              'kind': 'letter',
              'value': 'a',
              'spoken': 'a',
            },
        ];
        return http.Response(
          jsonEncode({
            'text': 'a' * cells.length,
            'cells': readings,
            'unrecognized': [],
          }),
          200,
        );
      }),
    );

    setUp(() {
      mic = FakeDictation();
      spoken = [];
    });

    Future<void> pump(WidgetTester tester, {List<BrailleField>? fields}) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: BrailleKeyboardScreen(
            fields: fields,
            service: service(),
            speak: spoken.add,
            dictation: mic,
            commitDelay: const Duration(milliseconds: 300),
          ),
        ),
      );
      await tester.pump();
    }

    Offset zone(WidgetTester tester, int dot) =>
        tester.getCenter(find.byKey(ValueKey('braille-dot-$dot')));

    /// Mantiene un dedo apoyado hasta que empieza a escuchar.
    Future<TestGesture> holdToTalk(WidgetTester tester) async {
      final finger = await tester.startGesture(zone(tester, 2));
      await tester.pump(
        BrailleKeyboardScreen.holdToTalk + const Duration(milliseconds: 50),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return finger;
    }

    String output(WidgetTester tester) =>
        tester.widget<Text>(find.byKey(const ValueKey('braille-output'))).data!;

    testWidgets('mantener un dedo apoyado escucha y escribe lo dicho', (
      tester,
    ) async {
      mic.reply = 'hola mundo';
      await pump(tester);

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pumpAndSettle();

      expect(mic.listens, 1);
      expect(mic.cues, [true, false], reason: 'pitido al empezar y al acabar');
      expect(output(tester), 'hola mundo');
      expect(spoken.last, 'Escrito: hola mundo');
    });

    testWidgets('mantener el dedo no marca ningún punto', (tester) async {
      mic.reply = 'hola';
      await pump(tester);

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      expect(spoken, isNot(contains('2')));
      expect(output(tester), 'hola');
    });

    testWidgets('un toque corto sigue siendo un punto', (tester) async {
      await pump(tester);
      await tester.tapAt(zone(tester, 1));
      await tester.pump(const Duration(seconds: 1));
      expect(mic.listens, 0);
      expect(spoken, contains('1'));
    });

    testWidgets('lo dictado va detrás de lo escrito en Braille', (
      tester,
    ) async {
      mic.reply = 'hola';
      await pump(tester);

      await tester.tapAt(zone(tester, 1));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(output(tester), 'a');

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pumpAndSettle();
      expect(output(tester), 'a hola');

      // Y se borra carácter a carácter.
      await tester.dragFrom(zone(tester, 2), const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(output(tester), 'a hol');
      expect(spoken.last, 'Borrado: a');
    });

    testWidgets('tocar la pantalla mientras escucha deja de escuchar', (
      tester,
    ) async {
      mic
        ..reply = 'hola'
        ..waitForStop = true;
      await pump(tester);

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pump();
      expect(find.byKey(const ValueKey('braille-listening')), findsOneWidget);

      await tester.tapAt(zone(tester, 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('braille-listening')), findsNothing);
      expect(output(tester), 'hola');
      expect(spoken, isNot(contains('5')), reason: 'ese toque era para parar');
    });

    testWidgets('el botón del micrófono de la barra también dicta', (
      tester,
    ) async {
      mic.reply = 'hola';
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pumpAndSettle();
      expect(output(tester), 'hola');
    });

    testWidgets('sin micrófono lo dice en voz alta', (tester) async {
      mic.unavailable = true;
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pumpAndSettle();
      expect(spoken.last, 'No hay micrófono.');
    });

    testWidgets('si no se oyó nada lo dice', (tester) async {
      mic.reply = null;
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('braille-action-Hablar')));
      await tester.pumpAndSettle();
      expect(spoken.last, startsWith('No te he entendido'));
    });

    testWidgets('en el correo, «arroba» y «punto» se convierten', (
      tester,
    ) async {
      final email = TextEditingController();
      addTearDown(email.dispose);
      mic.reply = 'sebastián arroba gmail punto com';
      await pump(
        tester,
        fields: [BrailleField(label: 'Correo', controller: email, email: true)],
      );

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pumpAndSettle();

      expect(email.text, 'sebastian@gmail.com');
      expect(spoken.last, 'Escrito: sebastian@gmail.com');
    });

    testWidgets('la contraseña dictada no se repite en voz alta', (
      tester,
    ) async {
      final password = TextEditingController();
      addTearDown(password.dispose);
      mic.reply = '1 2 3 4';
      await pump(
        tester,
        fields: [
          BrailleField(
            label: 'Contraseña',
            controller: password,
            obscure: true,
          ),
        ],
      );

      final finger = await holdToTalk(tester);
      await finger.up();
      await tester.pumpAndSettle();

      expect(password.text, '1234');
      expect(spoken.last, 'Escrito. Contraseña: 4 caracteres');
    });
  });

  group('en el login', () {
    testWidgets('el micrófono del correo escribe el correo dictado', (
      tester,
    ) async {
      final mic = FakeDictation()..reply = 'ana arroba x punto co';
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.getTheme(mode: AppThemeMode.light),
          home: LoginScreen(dictation: mic),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Dictar con el micrófono').first);
      // Callar la voz pasa por el canal del motor de voz, que en pruebas
      // responde de forma asíncrona de verdad.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller!.text, 'ana@x.co');
    });
  });
}
