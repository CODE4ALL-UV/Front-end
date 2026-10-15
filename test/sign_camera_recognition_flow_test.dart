import 'dart:async';
import 'dart:convert';

// La interfaz de plataforma de la cámara llega con el paquete camera; se
// importa directamente para poder sustituir la cámara real por una simulada.
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_camera_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_guide.dart';

/// Recorrido completo de la cámara de señas, con la cámara y el servidor
/// simulados.
///
/// Las otras pruebas de la pantalla solo llegan hasta el botón «Encender la
/// cámara», porque sin cámara de verdad no se puede seguir. Aquí la cámara se
/// sustituye en su interfaz de plataforma y el reconocimiento se guioniza foto
/// a foto, para comprobar lo que de verdad vive la persona: que se enciende la
/// cámara frontal, que una letra sostenida se escribe y se anuncia, las pistas
/// del modo práctica, los botones del dictado y cada error con su explicación
/// (sin cámara, sin permiso, sin plugin, servidor caído a media sesión).
///
/// La pantalla lee una foto cada 550 ms con un temporizador, así que cada
/// prueba avanza el reloj simulado de foto en foto y, al terminar, desmonta la
/// pantalla y deja correr el reloj para que el bucle se detenga solo.
void main() {
  late CameraPlatform originalCamera;
  late _FakeCameraPlatform camera;

  setUp(() {
    originalCamera = CameraPlatform.instance;
    camera = _FakeCameraPlatform();
    CameraPlatform.instance = camera;
  });

  tearDown(() {
    CameraPlatform.instance = originalCamera;
  });

  group('SignCameraScreen: encender y deletrear', () {
    testWidgets(
      'enciende la cámara frontal, manda las fotos y anuncia que empezó',
      (tester) async {
        camera.cameras = const [_back, _front];
        final service = _ScriptedService();
        await _open(tester, service: service);

        expect(find.text('Lee mi mano'), findsOneWidget);
        expect(find.text('La cámara está apagada'), findsOneWidget);
        tester.takeAnnouncements();

        await _turnOn(tester);

        // Se elige la frontal aunque no sea la primera de la lista: es la que
        // permite verse la mano.
        expect(camera.opened.map((c) => c.name), ['frontal']);
        expect(find.byKey(const ValueKey('vista-camara-1')), findsOneWidget);
        expect(find.text('La cámara está apagada'), findsNothing);
        expect(find.text('Apagar la cámara'), findsOneWidget);
        expect(
          _announced(tester),
          contains('Cámara encendida. Deletrea con la mano.'),
        );

        // La foto que sale de la cámara es la que llega al servicio.
        expect(service.frames, hasLength(1));
        expect(service.frames.single, camera.pictureBytes);

        // Con dos cámaras se ofrece cambiar; el dictado empieza vacío.
        expect(find.text('Cambiar de cámara'), findsOneWidget);
        expect(find.text('Llevas escrito'), findsOneWidget);
        expect(find.text('Nada todavía'), findsOneWidget);
        expect(
          find.text('Todavía no veo tu mano con claridad.'),
          findsOneWidget,
        );

        await _nextFrames(tester, 2);
        expect(service.frames, hasLength(3));

        await _leave(tester);
      },
    );

    testWidgets(
      'una letra sostenida se escribe, se anuncia y se puede editar',
      (tester) async {
        final service = _ScriptedService(
          script: [_confident('A'), _confident('A'), _confident('A')],
        );
        await _open(tester, service: service);
        await _turnOn(tester);
        tester.takeAnnouncements();

        // Tres fotos con la A todavía no bastan: hay que sostenerla cuatro.
        await _nextFrames(tester, 2);
        expect(find.text('Mantenla quieta para que cuente.'), findsOneWidget);
        expect(find.text('Nada todavía'), findsOneWidget);
        expect(_enabled(tester, 'Borrar'), isFalse);
        expect(_enabled(tester, 'Empezar de nuevo'), isFalse);

        service.script.add(_confident('A'));
        await _nextFrames(tester, 1);

        expect(find.text('Nada todavía'), findsNothing);
        // Una vez en la letra grande y otra en lo que se lleva escrito.
        expect(find.text('A'), findsNWidgets(2));
        expect(_announced(tester), contains('Letra A. Llevas A'));

        // La mano sale de cuadro: lo escrito se queda.
        await _nextFrames(tester, 1);
        expect(
          find.text('Todavía no veo tu mano con claridad.'),
          findsOneWidget,
        );
        expect(find.text('A'), findsOneWidget);

        await _tapButton(tester, 'Espacio');
        expect(find.text('A '), findsOneWidget);

        await _tapButton(tester, 'Borrar');
        expect(find.text('A '), findsNothing);
        expect(find.text('A'), findsOneWidget);

        await _tapButton(tester, 'Empezar de nuevo');
        expect(find.text('Nada todavía'), findsOneWidget);
        expect(_enabled(tester, 'Borrar'), isFalse);

        await _leave(tester);
      },
    );

    testWidgets('explica las lecturas dudosas y las que casi valen', (
      tester,
    ) async {
      final service = _ScriptedService(
        script: [
          SignReading(
            letter: 'H',
            confidence: 0.9,
            observed: signAlphabet['H']!,
            alternatives: const ['U'],
          ),
          SignReading(
            letter: 'C',
            confidence: 0.6,
            observed: signAlphabet['C']!,
          ),
        ],
      );
      await _open(tester, service: service);
      await _turnOn(tester);

      // Dos letras que se hacen igual: se enseñan las dos y no se escribe.
      expect(find.text('H o U'), findsOneWidget);
      expect(find.textContaining('no me atrevo a elegir'), findsOneWidget);

      await _nextFrames(tester, 1);
      expect(find.text('C'), findsOneWidget);
      expect(
        find.text('Casi. Acerca un poco la mano o mejora la luz.'),
        findsOneWidget,
      );
      expect(find.text('Nada todavía'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('cambiar de cámara suelta la actual y abre la otra', (
      tester,
    ) async {
      camera.cameras = const [_front, _back];
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);

      await _tapButton(tester, 'Cambiar de cámara');

      expect(camera.opened.map((c) => c.name), ['frontal', 'trasera']);
      expect(camera.disposed, [1]);
      expect(find.byKey(const ValueKey('vista-camara-2')), findsOneWidget);

      // Con la vuelta completa se regresa a la primera.
      await _tapButton(tester, 'Cambiar de cámara');
      expect(camera.opened.last.name, 'frontal');

      await _leave(tester);
    });

    testWidgets('cambiar de cámara a mitad de sesión no usa la ya soltada', (
      tester,
    ) async {
      camera.cameras = const [_front, _back];
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);

      // La trasera tarda en encenderse y, mientras, el bucle sigue: no puede
      // pedirle la foto a la frontal, que ya se soltó.
      final slow = Completer<void>();
      camera.initializeGate = slow;
      await _tapButton(tester, 'Cambiar de cámara');
      expect(camera.disposed, [1]);
      final before = camera.pictures;
      await _nextFrames(tester, 2);

      expect(camera.pictures, before);
      expect(find.textContaining('La cámara dio un problema'), findsNothing);
      expect(find.text('Apagar la cámara'), findsOneWidget);

      // Ya encendida, las fotos siguen con la nueva.
      slow.complete();
      await tester.pump();
      await _nextFrames(tester, 2);

      expect(camera.pictures, greaterThan(before));
      expect(find.byKey(const ValueKey('vista-camara-2')), findsOneWidget);
      expect(find.text('Apagar la cámara'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('si la otra cámara no enciende se explica y se para', (
      tester,
    ) async {
      camera.cameras = const [_front, _back];
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);

      camera.createError = CameraException('CameraAccessDenied', 'sin permiso');
      await _tapButton(tester, 'Cambiar de cámara');
      await _nextFrames(tester, 1);

      expect(
        find.text(
          'Hace falta permiso para usar la cámara. Puedes dárselo desde '
          'los ajustes del dispositivo y volver a intentarlo.',
        ),
        findsWidgets,
      );
      expect(find.text('Apagar la cámara'), findsNothing);

      await _leave(tester);
    });

    testWidgets(
      'cualquier otro fallo al cambiar de cámara se cuenta tal cual',
      (tester) async {
        camera.cameras = const [_front, _back];
        await _open(tester, service: _ScriptedService());
        await _turnOn(tester);

        camera.createError = StateError('la cámara se colgó');
        await _tapButton(tester, 'Cambiar de cámara');

        expect(
          find.textContaining('No se pudo cambiar de cámara'),
          findsWidgets,
        );
        expect(find.text('Apagar la cámara'), findsNothing);

        await _leave(tester);
      },
    );

    testWidgets('con una sola cámara no se ofrece cambiarla', (tester) async {
      camera.cameras = const [_back];
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);

      // Sin frontal se usa la que haya.
      expect(camera.opened.single.name, 'trasera');
      expect(find.text('Cambiar de cámara'), findsNothing);

      await _leave(tester);
    });

    testWidgets('apagar la cámara la suelta y deja de pedir fotos', (
      tester,
    ) async {
      final service = _ScriptedService();
      await _open(tester, service: service);
      await _turnOn(tester);

      await _tapButton(tester, 'Apagar la cámara');
      await tester.pump(const Duration(seconds: 2));

      expect(camera.disposed, [1]);
      expect(find.text('La cámara está apagada'), findsOneWidget);
      expect(find.text('Encender la cámara'), findsOneWidget);
      // El texto dictado y sus botones solo existen con la cámara encendida.
      expect(find.text('Espacio'), findsNothing);
      expect(service.frames, hasLength(1));
      expect(camera.pictures, 1);

      await _leave(tester);
    });

    testWidgets('al irse a segundo plano apaga la cámara', (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final service = _ScriptedService();
      await _open(tester, service: service);
      await _turnOn(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 2));

      expect(camera.disposed, [1]);
      expect(find.text('Encender la cámara'), findsOneWidget);
      expect(service.frames, hasLength(1));

      await _leave(tester);
    });

    testWidgets('al salir de la pantalla con la cámara encendida la libera', (
      tester,
    ) async {
      final service = _ScriptedService();
      await _open(tester, service: service);
      await _turnOn(tester);
      await _nextFrames(tester, 1);
      expect(service.frames, hasLength(2));

      await _leave(tester);

      expect(camera.disposed, [1]);
      expect(service.frames, hasLength(2));
    });
  });

  group('SignCameraScreen: práctica de una letra', () {
    testWidgets('da pistas hasta conseguir la letra y la celebra', (
      tester,
    ) async {
      final service = _ScriptedService(
        script: [
          SignRecognitionService.noHand,
          _confident('A'),
          for (var i = 0; i < 4; i++) _confident('B'),
        ],
      );
      await _open(tester, service: service, target: 'B');
      expect(find.text('Practica la B'), findsOneWidget);
      tester.takeAnnouncements();

      await _turnOn(tester);
      expect(
        _announced(tester),
        contains('Cámara encendida. Haz la letra B con la mano.'),
      );
      expect(find.text('Todavía no veo tu mano con claridad.'), findsOneWidget);
      // En la práctica no hay dictado libre.
      expect(find.text('Llevas escrito'), findsNothing);
      expect(find.text('Espacio'), findsNothing);

      // Hace la A: la pista dice qué corregir para llegar a la B.
      await _nextFrames(tester, 1);
      expect(find.text('A'), findsOneWidget);
      expect(
        find.text(HandLandmarkClassifier.hint(signAlphabet['A']!, 'B')),
        findsOneWidget,
      );
      expect(find.text('Estira más el índice.'), findsOneWidget);

      // Hace la B: se celebra en pantalla al momento...
      await _nextFrames(tester, 1);
      expect(find.text('¡Esa es la B!'), findsOneWidget);
      expect(_announced(tester), isNot(contains('¡Esa es la B!')));

      // ...y se anuncia cuando la sostiene lo bastante para que cuente.
      await _nextFrames(tester, 3);
      expect(_announced(tester), contains('¡Esa es la B!'));

      // Lo conseguido no se borra aunque la mano salga de cuadro.
      await _nextFrames(tester, 1);
      expect(find.text('¡Esa es la B!'), findsOneWidget);

      await _leave(tester);
    });
  });

  group('SignCameraScreen: cuando la cámara no se puede usar', () {
    testWidgets('sin cámaras lo dice y permite volver a intentarlo', (
      tester,
    ) async {
      camera.cameras = const [];
      await _open(tester, service: _ScriptedService());
      tester.takeAnnouncements();

      await _turnOn(tester);

      const message = 'No se encontró ninguna cámara en este dispositivo.';
      expect(find.text(message), findsOneWidget);
      expect(_announced(tester), contains(message));
      expect(find.text('Encender la cámara'), findsNothing);

      // Al reintentar se vuelve a comprobar el servidor y se ofrece la cámara.
      await _tapButton(tester, 'Volver a intentarlo');
      expect(find.text(message), findsNothing);
      expect(find.text('Encender la cámara'), findsOneWidget);

      await _leave(tester);
    });

    final cameraErrors = <(String, CameraException, String)>[
      (
        'sin permiso pide que se dé desde los ajustes',
        CameraException('CameraAccessDenied', 'El usuario no dio permiso'),
        'Hace falta permiso para usar la cámara. Puedes dárselo desde los '
            'ajustes del dispositivo y volver a intentarlo.',
      ),
      (
        'si el sistema no encuentra la cámara lo explica',
        CameraException('cameraNotFound', null),
        'No se encontró ninguna cámara disponible.',
      ),
      (
        'un fallo raro de la cámara muestra su descripción',
        CameraException('cameraBusy', 'La usa otra aplicación'),
        'La cámara dio un problema: La usa otra aplicación',
      ),
      (
        'un fallo sin descripción muestra al menos su código',
        CameraException('cameraBusy', null),
        'La cámara dio un problema: cameraBusy',
      ),
    ];

    for (final (name, error, message) in cameraErrors) {
      testWidgets(name, (tester) async {
        camera.createError = error;
        await _open(tester, service: _ScriptedService());
        tester.takeAnnouncements();

        await _turnOn(tester);

        expect(find.text(message), findsOneWidget);
        expect(_announced(tester), contains(message));
        expect(find.text('Volver a intentarlo'), findsOneWidget);
        expect(camera.pictures, 0);

        await _leave(tester);
      });
    }

    testWidgets('sin plugin de cámara sugiere abrirlo en otro sitio', (
      tester,
    ) async {
      camera.availableError = MissingPluginException('sin cámara');
      await _open(tester, service: _ScriptedService());

      await _turnOn(tester);

      expect(
        find.textContaining(
          'Esta versión de Code4All no puede abrir la cámara',
        ),
        findsOneWidget,
      );

      await _leave(tester);
    });

    testWidgets('cualquier otro fallo al encender se cuenta tal cual', (
      tester,
    ) async {
      camera.availableError = StateError('sin controlador');
      await _open(tester, service: _ScriptedService());

      await _turnOn(tester);

      expect(
        find.text('No se pudo encender la cámara: Bad state: sin controlador'),
        findsOneWidget,
      );

      await _leave(tester);
    });
  });

  group('SignCameraScreen: fallos a media sesión', () {
    testWidgets('si el servidor se cae deja de hacer fotos y lo explica', (
      tester,
    ) async {
      final service = _ScriptedService(
        script: [
          _confident('A'),
          SignRecognitionException(
            SignFailureKind.offline,
            'No se pudo conectar con el servidor para leer la mano.',
          ),
        ],
      );
      await _open(tester, service: service);
      await _turnOn(tester);
      tester.takeAnnouncements();

      await _nextFrames(tester, 1);
      const message = 'No se pudo conectar con el servidor para leer la mano.';
      expect(find.text(message), findsOneWidget);
      expect(_announced(tester), contains(message));
      expect(find.text('Volver a intentarlo'), findsOneWidget);

      // Ya no se piden más fotos: no tiene sentido seguir disparando.
      await _nextFrames(tester, 3);
      expect(camera.pictures, 2);

      await _leave(tester);
    });

    testWidgets('una foto que el servidor rechaza no corta la sesión', (
      tester,
    ) async {
      final service = _ScriptedService(
        script: [
          SignRecognitionException(
            SignFailureKind.badImage,
            'El servidor no aceptó la foto de la cámara.',
          ),
          _confident('L'),
        ],
      );
      await _open(tester, service: service);
      await _turnOn(tester);

      expect(find.textContaining('no aceptó la foto'), findsNothing);
      await _nextFrames(tester, 1);
      expect(find.text('L'), findsOneWidget);
      expect(find.text('Apagar la cámara'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('si la cámara falla al hacer la foto se explica y se para', (
      tester,
    ) async {
      final service = _ScriptedService();
      await _open(tester, service: service);
      await _turnOn(tester);

      camera.pictureErrors.add(
        CameraException('CameraAccessDenied', 'Permiso retirado'),
      );
      await _nextFrames(tester, 1);

      expect(find.textContaining('Hace falta permiso'), findsOneWidget);
      await _nextFrames(tester, 2);
      expect(camera.pictures, 2);

      await _leave(tester);
    });

    testWidgets('una respuesta suelta que no se entiende no tumba la sesión', (
      tester,
    ) async {
      // Por ejemplo, unos puntos con coordenadas mal formadas: es un fallo de
      // esa foto, no del servidor, así que se sigue mirando.
      final service = _ScriptedService(
        script: [const FormatException('coordenadas rotas'), _confident('Y')],
      );
      await _open(tester, service: service);
      await _turnOn(tester);

      expect(find.textContaining('coordenadas rotas'), findsNothing);
      expect(find.text('Apagar la cámara'), findsOneWidget);

      await _nextFrames(tester, 1);
      expect(find.text('Y'), findsOneWidget);
      expect(service.frames, hasLength(2));

      await _leave(tester);
    });
  });

  group('SignCameraScreen: con el servicio real y HTTP simulado', () {
    testWidgets('la foto viaja como imagen al servidor y vuelve como letra', (
      tester,
    ) async {
      final requests = <http.BaseRequest>[];
      final service = SignRecognitionService(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/signs/status') {
            return http.Response(jsonEncode({'available': true}), 200);
          }
          return http.Response(
            jsonEncode({
              'hands': [
                {'handedness': 'Right', 'landmarks': _fistWithThumbOut},
              ],
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);

      await _open(tester, service: service);
      await _turnOn(tester);

      final upload = requests.last;
      expect(upload.method, 'POST');
      expect(upload.url.path, '/api/signs/landmarks');
      expect(upload.headers['content-type'], contains('multipart/form-data'));

      // El puño con el pulgar fuera es la A, y se lee con seguridad.
      expect(find.text('A'), findsOneWidget);
      expect(find.text('Mantenla quieta para que cuente.'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('si al servidor le falta el reconocimiento se avisa', (
      tester,
    ) async {
      final service = SignRecognitionService(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async {
          if (request.url.path == '/api/signs/status') {
            return http.Response(jsonEncode({'available': true}), 200);
          }
          return http.Response('{"detail":"falta mediapipe"}', 503);
        }),
      );
      addTearDown(service.dispose);

      await _open(tester, service: service);
      await _turnOn(tester);

      expect(
        find.text(
          'El reconocimiento de señas no está disponible en el servidor.',
        ),
        findsOneWidget,
      );
      expect(find.text('Volver a intentarlo'), findsOneWidget);

      await _leave(tester);
    });
  });
}

// --- Montaje y pasos comunes ------------------------------------------------

/// Monta la pantalla con espacio de sobra para que todos los botones queden a
/// la vista sin desplazarse.
Future<void> _open(
  WidgetTester tester, {
  required SignRecognitionService service,
  String? target,
}) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: SignCameraScreen(
        service: service,
        targetLetter: target,
        guidePrompt: _QuietPrompt(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _turnOn(WidgetTester tester) =>
    _tapButton(tester, 'Encender la cámara');

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  // Todo lo que hace la cámara simulada se resuelve en microtareas, así que
  // un fotograma basta para encenderla y leer la primera foto.
  await tester.pump();
}

/// Deja pasar [count] intervalos de lectura: una foto por intervalo.
Future<void> _nextFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// Desmonta la pantalla y deja que el bucle de fotos termine su espera.
Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Si el botón con ese texto se puede pulsar.
bool _enabled(WidgetTester tester, String label) {
  final button = tester.widget<ButtonStyleButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    ),
  );
  return button.enabled;
}

List<String> _announced(WidgetTester tester) =>
    tester.takeAnnouncements().map((a) => a.message).toList();

SignReading _confident(String letter) => SignReading(
  letter: letter,
  confidence: 0.95,
  observed: signAlphabet[letter]!,
);

// --- Dobles de prueba --------------------------------------------------------

const _front = CameraDescription(
  name: 'frontal',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
);

const _back = CameraDescription(
  name: 'trasera',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

/// Una cámara de mentira que se enciende al instante y hace siempre la misma
/// foto. Registra qué cámaras se abren, cuáles se sueltan y cuántas fotos se
/// piden, y deja provocar cada tipo de fallo.
class _FakeCameraPlatform extends CameraPlatform {
  List<CameraDescription> cameras = const [_front];

  /// Se lanza al pedir la lista de cámaras.
  Object? availableError;

  /// Se lanza al crear la cámara, que es donde el sistema pide permiso.
  Object? createError;

  /// Si está puesta, encender la cámara espera a que se complete.
  Completer<void>? initializeGate;

  /// Fallos de las próximas fotos, en orden.
  final List<Object> pictureErrors = [];

  final List<CameraDescription> opened = [];
  final List<int> disposed = [];
  int pictures = 0;
  int _nextId = 0;

  final Uint8List pictureBytes = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);

  // Nunca emiten ni se cierran: una cámara que no da errores ni gira.
  final _errors = StreamController<CameraErrorEvent>.broadcast();
  final _orientation =
      StreamController<DeviceOrientationChangedEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async {
    final error = availableError;
    if (error != null) throw error;
    return cameras;
  }

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async {
    final error = createError;
    if (error != null) throw error;
    opened.add(cameraDescription);
    return ++_nextId;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    final gate = initializeGate;
    if (gate != null) await gate.future;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          640,
          480,
          ExposureMode.auto,
          true,
          FocusMode.auto,
          true,
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => _errors.stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      _orientation.stream;

  @override
  Future<XFile> takePicture(int cameraId) async {
    pictures++;
    if (pictureErrors.isNotEmpty) throw pictureErrors.removeAt(0);
    return XFile.fromData(pictureBytes, name: 'foto.jpg');
  }

  @override
  Widget buildPreview(int cameraId) =>
      SizedBox.expand(key: ValueKey('vista-camara-$cameraId'));

  @override
  Future<void> dispose(int cameraId) async => disposed.add(cameraId);
}

/// Reconocimiento guionizado: devuelve las lecturas de [script] en orden y,
/// cuando se acaban, que no hay mano. Los elementos que no son lecturas se
/// lanzan como error.
class _ScriptedService extends SignRecognitionService {
  _ScriptedService({List<Object>? script})
    : script = script ?? [],
      super(
        api: ApiService(baseUrl: 'http://servidor.de.prueba'),
        client: MockClient((request) async => http.Response('', 500)),
      );

  final List<Object> script;
  final List<Uint8List> frames = [];

  @override
  Future<bool> isAvailable({bool refresh = false}) async => true;

  @override
  Future<SignReading> read(Uint8List frame, {String format = 'jpeg'}) async {
    frames.add(frame);
    if (script.isEmpty) return SignRecognitionService.noHand;
    final next = script.removeAt(0);
    if (next is SignReading) return next;
    throw next;
  }
}

/// No ofrece la guía al entrar ni toca el almacenamiento.
class _QuietPrompt extends SignGuidePrompt {
  @override
  Future<bool> shouldOffer() async => false;

  @override
  Future<void> markOffered() async {}
}

/// Los 21 puntos de un puño con el pulgar separado: la letra A.
const List<Map<String, double>> _fistWithThumbOut = [
  {'x': 0.50, 'y': 0.90, 'z': 0.0},
  {'x': 0.44, 'y': 0.84, 'z': 0.0},
  {'x': 0.41, 'y': 0.75, 'z': 0.0},
  {'x': 0.38, 'y': 0.66, 'z': 0.0},
  {'x': 0.36, 'y': 0.58, 'z': 0.0},
  {'x': 0.42, 'y': 0.68, 'z': 0.0},
  {'x': 0.42, 'y': 0.59, 'z': 0.0},
  {'x': 0.48, 'y': 0.60, 'z': 0.0},
  {'x': 0.47, 'y': 0.64, 'z': 0.0},
  {'x': 0.49, 'y': 0.68, 'z': 0.0},
  {'x': 0.49, 'y': 0.58, 'z': 0.0},
  {'x': 0.55, 'y': 0.59, 'z': 0.0},
  {'x': 0.54, 'y': 0.64, 'z': 0.0},
  {'x': 0.56, 'y': 0.68, 'z': 0.0},
  {'x': 0.56, 'y': 0.59, 'z': 0.0},
  {'x': 0.62, 'y': 0.60, 'z': 0.0},
  {'x': 0.61, 'y': 0.64, 'z': 0.0},
  {'x': 0.63, 'y': 0.68, 'z': 0.0},
  {'x': 0.63, 'y': 0.61, 'z': 0.0},
  {'x': 0.68, 'y': 0.62, 'z': 0.0},
  {'x': 0.67, 'y': 0.66, 'z': 0.0},
];
