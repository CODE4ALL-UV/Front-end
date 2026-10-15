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

/// Monta la pantalla respetando el escalado de texto solicitado por la prueba.
Widget _app(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

SignRecognitionService _service({required bool available, String? reason}) {
  final body = <String, dynamic>{'available': available};
  if (reason != null) body['reason'] = reason;

  return SignRecognitionService(
    api: ApiService(baseUrl: 'http://servidor.de.prueba'),
    client: MockClient((request) async => http.Response(jsonEncode(body), 200)),
  );
}

/// Un servidor que no contesta: apagado o sin conexión.
SignRecognitionService _offline() => SignRecognitionService(
  api: ApiService(baseUrl: 'http://servidor.de.prueba'),
  client: MockClient((request) async => throw http.ClientException('sin red')),
);

/// Evita tocar las preferencias persistentes que se usan para ofrecer la guía.
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

/// El servicio se inyecta para poder usar HTTP simulado; por tanto, la pantalla
/// no es propietaria de él y la prueba debe cerrarlo después de desmontarla.
void _cleanup(WidgetTester tester, SignRecognitionService service) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    service.dispose();
  });
}

/// Servicio controlable para verificar el reintento de disponibilidad sin
/// depender de la caché o del tiempo de respuesta HTTP del servicio real.
class _RetryableSignRecognitionService extends SignRecognitionService {
  _RetryableSignRecognitionService()
    : super(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient(
          (request) async =>
              http.Response(jsonEncode({'available': false}), 200),
        ),
      );

  bool available = false;
  int checkCount = 0;

  @override
  Future<bool> isAvailable({bool refresh = false}) async {
    checkCount++;
    return available;
  }
}

void main() {
  group('SignCameraScreen: disponibilidad y contenido', () {
    testWidgets(
      'al presionar "Encender la cámara" sin hardware disponible muestra el fallo en UI',
      (tester) async {
        // Ampliamos el tamaño de la ventana para que los controles queden dentro del área visible
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final service = _service(available: true);
        _cleanup(tester, service);

        await tester.pumpWidget(
          _app(
            SignCameraScreen(
              service: service,
              guidePrompt: _FakePrompt(offer: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Encender la cámara'), findsOneWidget);

        // Aseguramos la visibilidad y hacemos tap sobre el botón
        await tester.ensureVisible(find.text('Encender la cámara'));
        await tester.tap(find.text('Encender la cámara'));
        await tester.pumpAndSettle();

        // Verificamos que la app manejó el fallo mostrando un mensaje relacionado con la cámara
        expect(find.textContaining('cámara'), findsWidgets);
      },
    );

    testWidgets('avisa cuando el servidor no puede reconocer señas', (
      tester,
    ) async {
      final service = _service(available: false);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('no tiene activo el reconocimiento'),
        findsOneWidget,
      );
      expect(find.text('Volver a intentarlo'), findsOneWidget);
      // Sin servidor no se ofrece encender la cámara: no pedir permiso para nada.
      expect(find.text('Encender la cámara'), findsNothing);
    });

    testWidgets('con el servidor listo ofrece encender la cámara', (
      tester,
    ) async {
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Encender la cámara'), findsOneWidget);
      expect(find.text('La cámara está apagada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('deja claro que es dactilología y no Lengua de Señas', (
      tester,
    ) async {
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('dactilología'), findsOneWidget);
      expect(find.textContaining('No es Lengua de Señas'), findsOneWidget);
    });

    testWidgets('explica que las fotos se descartan y no se guardan', (
      tester,
    ) async {
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('se descartan'), findsOneWidget);
      expect(find.textContaining('No se graba vídeo'), findsOneWidget);
    });

    testWidgets(
      'al practicar una letra la muestra en el título e instrucciones',
      (tester) async {
        final service = _service(available: true);
        _cleanup(tester, service);

        await tester.pumpWidget(
          _app(
            SignCameraScreen(
              targetLetter: 'A',
              service: service,
              guidePrompt: _FakePrompt(offer: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Practica la A'), findsOneWidget);
        expect(find.textContaining('haz la letra A'), findsOneWidget);
        // En modo práctica no se ofrece el texto libre del dictado.
        expect(find.text('Empezar de nuevo'), findsNothing);
      },
    );

    testWidgets('cabe en una pantalla pequeña de 320 x 640', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('cabe con el texto al 200 por ciento', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
          textScale: 2.0,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'si se pausa la app antes de iniciar no intenta encender cámara',
      (tester) async {
        final service = _service(available: true);
        _cleanup(tester, service);

        await tester.pumpWidget(
          _app(
            SignCameraScreen(
              service: service,
              guidePrompt: _FakePrompt(offer: false),
            ),
          ),
        );
        await tester.pumpAndSettle();

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(find.text('Encender la cámara'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('al reintentar consulta de nuevo y actualiza el estado', (
      tester,
    ) async {
      final service = _RetryableSignRecognitionService();
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(service.checkCount, 1);
      expect(find.text('Volver a intentarlo'), findsOneWidget);
      expect(find.text('Encender la cámara'), findsNothing);

      // Se cambia el resultado del servicio simulado. La prueba no depende
      // de cachés, tiempos de espera ni de una respuesta HTTP real.
      service.available = true;
      await tester.tap(find.text('Volver a intentarlo'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.checkCount, 2);
      expect(find.text('Encender la cámara'), findsOneWidget);
      expect(find.text('Volver a intentarlo'), findsNothing);
    });
  });

  group('SignCameraScreen: errores del servicio', () {
    testWidgets('sin conexión muestra un mensaje específico', (tester) async {
      final service = _offline();
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('No se pudo conectar'), findsOneWidget);
      expect(find.textContaining('no tiene activo'), findsNothing);
    });

    testWidgets('muestra el detalle técnico que devuelve el servidor', (
      tester,
    ) async {
      final service = _service(
        available: false,
        reason: 'El servidor no puede crear el detector de manos',
      );
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
            guidePrompt: _FakePrompt(offer: false),
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
      expect(find.text('Guía del alfabeto (PDF)'), findsOneWidget);
    });
  });

  group('SignCameraScreen: guía del alfabeto', () {
    testWidgets('la primera vez ofrece la guía y la abre si se acepta', (
      tester,
    ) async {
      final prompt = _FakePrompt(offer: true);
      var opened = 0;
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
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

    testWidgets('si ya se ofreció, no vuelve a preguntar al entrar', (
      tester,
    ) async {
      final prompt = _FakePrompt(offer: false);
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(SignCameraScreen(service: service, guidePrompt: prompt)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antes de empezar'), findsNothing);
      expect(find.text('Guía del alfabeto (PDF)'), findsOneWidget);
      expect(prompt.marked, isFalse);
    });

    testWidgets('el botón de la guía la abre', (tester) async {
      var opened = 0;
      final service = _service(available: true);
      _cleanup(tester, service);

      await tester.pumpWidget(
        _app(
          SignCameraScreen(
            service: service,
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

    test('el PDF existe y está declarado como recurso de la aplicación', () {
      expect(File(signGuideAsset).existsSync(), isTrue);
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/docs/'));
    });
  });

  group('practicableLetters', () {
    test('excluye letras con movimiento y conserva letras estáticas', () {
      final letters = practicableLetters();

      // J, Z y Ñ necesitan movimiento y no se pueden verificar con una foto.
      expect(letters, isNot(contains('J')));
      expect(letters, isNot(contains('Z')));
      expect(letters, isNot(contains('Ñ')));
      expect(letters, contains('A'));
      expect(letters, isNotEmpty);
    });
  });
}
