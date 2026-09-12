import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_camera_screen.dart';

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

SignRecognitionService _service({required bool available}) {
  return SignRecognitionService(
    api: ApiService(baseUrl: 'http://servidor.de.prueba'),
    client: MockClient(
      (request) async =>
          http.Response(jsonEncode({'available': available}), 200),
    ),
  );
}

void main() {
  testWidgets('avisa cuando el servidor no puede reconocer señas', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(SignCameraScreen(service: _service(available: false))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('no está disponible'), findsOneWidget);
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
        SignCameraScreen(
          targetLetter: 'A',
          service: _service(available: true),
        ),
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

  test('no se ofrece practicar una letra que nunca se dará por buena', () {
    // La J, la Z y la Ñ llevan movimiento: desde una foto no hay forma.
    expect(practicableLetters(), isNot(contains('J')));
    expect(practicableLetters(), isNot(contains('Z')));
    expect(practicableLetters(), isNot(contains('Ñ')));
    expect(practicableLetters(), contains('A'));
  });
}
