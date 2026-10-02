import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_camera_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_guide.dart';

/// Comprueba la pantalla de la cámara sin encender ninguna cámara.
///
/// Lo que se prueba es lo que pasa **antes** de pulsar el botón: que se avise
/// cuando el servidor no está, que se explique qué es esto y qué no, y que
/// quepa en una pantalla pequeña con el texto agrandado. Encender la cámara de
/// verdad necesita un dispositivo y se comprueba a mano.
Widget _app(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

SignRecognitionService _service({required bool available, String? reason}) {
  return SignRecognitionService(
    api: ApiService(baseUrl: 'http://servidor.de.prueba'),
    client: MockClient(
      (request) async => http.Response(
        jsonEncode({'available': available, 'reason': ?reason}),
        200,
      ),
    ),
  );
}

/// Un servidor que no contesta: apagado o sin conexión.
SignRecognitionService _offline() => SignRecognitionService(
  api: ApiService(baseUrl: 'http://servidor.de.prueba'),
  client: MockClient((request) async => throw http.ClientException('sin red')),
);

/// Recuerda si se ofreció la guía, sin tocar el almacenamiento de verdad.
class _FakePrompt extends SignGuidePrompt {
  _FakePrompt({required this.offer});

  bool offer;
  bool marked = false;

  @override
  Future<bool> shouldOffer() async => offer;

  @override
  Future<void> markOffered() async {
    marked = true;
    offer = false;
  }
}

void main() {
  testWidgets('avisa cuando el servidor no puede reconocer señas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: false))),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no tiene activo el reconocimiento'),
      findsOneWidget,
    );
    expect(find.text('Volver a intentarlo'), findsOneWidget);
    // Sin servidor no se ofrece encender la cámara: pedir permiso para nada
    // sería maltratar a quien lo concede.
    expect(find.text('Encender la cámara'), findsNothing);
  });

  testWidgets('con el servidor listo ofrece encender la cámara', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: true))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Encender la cámara'), findsOneWidget);
    expect(find.text('La cámara está apagada'), findsOneWidget);
  });

  testWidgets('deja claro que es dactilología y no Lengua de Señas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: true))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('dactilología'), findsOneWidget);
    expect(find.textContaining('No es Lengua de Señas'), findsOneWidget);
  });

  testWidgets('dice que no se guarda ninguna imagen', (tester) async {
    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: true))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('se descartan'), findsOneWidget);
  });

  testWidgets('al practicar una letra lo dice desde el título', (tester) async {
    await tester.pumpWidget(
      _app(
        SignCameraScreen(targetLetter: 'A', service: _service(available: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Practica la A'), findsOneWidget);
    expect(find.textContaining('haz la letra A'), findsOneWidget);
  });

  testWidgets('cabe en una pantalla de 320 px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: true))),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('cabe con el texto al 200 por ciento', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        SignCameraScreen(service: _service(available: true)),
        textScale: 2.0,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('sin conexión lo dice así, y no que el servidor no puede', (
    tester,
  ) async {
    await tester.pumpWidget(_app(SignCameraScreen(service: _offline())));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo conectar'), findsOneWidget);
    expect(find.textContaining('no tiene activo'), findsNothing);
  });

  testWidgets('si el servidor explica por qué no puede, se ve el detalle', (
    tester,
  ) async {
    // Como en un Windows con el Control inteligente de aplicaciones, que
    // bloquea la librería de MediaPipe.
    await tester.pumpWidget(
      _app(
        SignCameraScreen(
          service: _service(
            available: false,
            reason: 'El servidor no puede crear el detector de manos',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Detalle técnico: El servidor no puede crear el detector de manos',
      ),
      findsOneWidget,
    );
    // La guía se puede leer aunque la cámara no funcione.
    expect(find.text('Guía del alfabeto (PDF)'), findsOneWidget);
  });

  testWidgets('la primera vez ofrece la guía, y la abre si se acepta', (
    tester,
  ) async {
    final prompt = _FakePrompt(offer: true);
    var opened = 0;
    await tester.pumpWidget(
      _app(
        SignCameraScreen(
          service: _service(available: true),
          guidePrompt: prompt,
          openGuide: () async {
            opened++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Antes de empezar'), findsOneWidget);
    expect(prompt.marked, isTrue);

    await tester.tap(find.text('Abrir la guía'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('Antes de empezar'), findsNothing);
  });

  testWidgets('después de la primera vez no vuelve a preguntar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SignCameraScreen(
          service: _service(available: true),
          guidePrompt: _FakePrompt(offer: false),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Antes de empezar'), findsNothing);
    expect(find.text('Guía del alfabeto (PDF)'), findsOneWidget);
  });

  testWidgets('el botón de la guía la abre', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      _app(
        SignCameraScreen(
          service: _service(available: true),
          guidePrompt: _FakePrompt(offer: false),
          openGuide: () async {
            opened++;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guía del alfabeto (PDF)'));
    await tester.pump();

    expect(opened, 1);
  });

  test('la guía en PDF existe y está declarada en la app', () {
    expect(File(signGuideAsset).existsSync(), isTrue);
    expect(File('pubspec.yaml').readAsStringSync(), contains('assets/docs/'));
  });

  test('no se ofrece practicar una letra que nunca se dará por buena', () {
    // La J, la Z y la Ñ llevan movimiento: desde una foto no hay forma.
    expect(practicableLetters(), isNot(contains('J')));
    expect(practicableLetters(), isNot(contains('Z')));
    expect(practicableLetters(), isNot(contains('Ñ')));
    expect(practicableLetters(), contains('A'));
  });
}
