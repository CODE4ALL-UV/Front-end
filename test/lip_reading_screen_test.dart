import 'dart:async';
import 'dart:io';

// La interfaz de plataforma de la cámara llega con el paquete camera; se
// importa directamente para poder sustituir la cámara real por una simulada.
// ignore: depend_on_referenced_packages
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/lip_reading_service.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_reading_models.dart';
import 'package:flutter_code4all/ui/core/ui/lip_alphabet_guide_screen.dart';
import 'package:flutter_code4all/ui/core/ui/lip_painters.dart';
import 'package:flutter_code4all/ui/core/ui/lip_reading_screen.dart';

/// Recorrido de la lectura de labios, con la cámara y el servidor simulados.
///
/// La cámara se sustituye en su interfaz de plataforma, como en la prueba de la
/// cámara de señas. El lector en sí se prueba en Python: aquí importa lo que
/// vive la persona con lo que el servidor conteste.
void main() {
  late CameraPlatform originalCamera;
  late _FakeCameraPlatform camera;

  setUp(() {
    originalCamera = CameraPlatform.instance;
    camera = _FakeCameraPlatform();
    CameraPlatform.instance = camera;
    // El menú de la barra superior lee la sesión guardada.
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    CameraPlatform.instance = originalCamera;
  });

  group('LipReadingScreen: antes de encender', () {
    testWidgets('explica qué hace y qué no, sin encender nada', (tester) async {
      await _open(tester, service: _ScriptedService());

      expect(find.text('Lectura de labios'), findsOneWidget);
      expect(find.textContaining('muchas consonantes'), findsOneWidget);
      expect(find.textContaining('no se guarda ninguna'), findsNothing);
      expect(find.textContaining('se descartan'), findsOneWidget);
      expect(find.text('Encender la cámara'), findsOneWidget);
      expect(find.text('La cámara está apagada'), findsOneWidget);
      expect(find.text('Leer una palabra'), findsNothing);
      expect(camera.opened, isEmpty);

      await _leave(tester);
    });

    testWidgets('muestra qué palabras sabe leer', (tester) async {
      await _open(tester, service: _ScriptedService(words: ['hola', 'no']));

      await tester.ensureVisible(find.text('Palabras que sé leer (2)'));
      await tester.tap(find.text('Palabras que sé leer (2)'));
      await tester.pumpAndSettle();

      expect(find.text('hola, no'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('sin palabras conocidas no se ofrece la lista', (tester) async {
      await _open(tester, service: _ScriptedService(words: const []));

      expect(find.textContaining('Palabras que sé leer'), findsNothing);

      await _leave(tester);
    });

    testWidgets('abre el manual de las letras', (tester) async {
      await _open(tester, service: _ScriptedService());

      await _tapButton(tester, 'Las letras con la boca');
      await tester.pumpAndSettle();

      expect(find.byType(LipAlphabetGuideScreen), findsOneWidget);
    });

    testWidgets('abrir el manual apaga la cámara: ya no se ve lo que mira', (
      tester,
    ) async {
      final service = _ScriptedService(frames: _relaxed(3));
      await _open(tester, service: service);
      await _turnOn(tester);

      await _tapButton(tester, 'Las letras con la boca');
      await tester.pumpAndSettle();
      final sent = service.sentFrames.length;
      await _liveFrames(tester, 3);

      expect(find.byType(LipAlphabetGuideScreen), findsOneWidget);
      expect(camera.disposed, [1]);
      expect(service.sentFrames, hasLength(sent));

      // Al volver, la cámara espera a que la persona la encienda otra vez.
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Encender la cámara'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('si el servidor no lo tiene activo se explica y se reintenta', (
      tester,
    ) async {
      final service = _ScriptedService(available: false)
        ..lastFailure = LipFailureKind.unavailable
        ..lastReason = 'Faltan dependencias';
      await _open(tester, service: service);

      expect(
        find.textContaining('no tiene activa la lectura de labios'),
        findsOneWidget,
      );
      expect(find.textContaining('Faltan dependencias'), findsOneWidget);
      expect(find.text('Encender la cámara'), findsNothing);
      // El manual no depende del servidor.
      expect(find.text('Las letras con la boca'), findsOneWidget);

      service.available = true;
      await _tapButton(tester, 'Volver a intentarlo');
      await tester.pump();

      expect(find.text('Encender la cámara'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('sin conexión lo dice y no culpa al servidor', (tester) async {
      final service = _ScriptedService(available: false)
        ..lastFailure = LipFailureKind.offline;
      await _open(tester, service: service);

      expect(find.textContaining('tarda hasta un minuto'), findsOneWidget);

      await _leave(tester);
    });
  });

  group('LipReadingScreen: la cámara en marcha', () {
    testWidgets('enciende la frontal y dibuja los labios encima', (
      tester,
    ) async {
      camera.cameras = const [_back, _front];
      final service = _ScriptedService(frames: [_mouth()]);
      await _open(tester, service: service);
      tester.takeAnnouncements();

      await _turnOn(tester);

      expect(camera.opened.map((c) => c.name), ['frontal']);
      expect(find.byKey(const ValueKey('vista-camara-1')), findsOneWidget);
      expect(find.text('Apagar la cámara'), findsOneWidget);
      expect(find.text('Cambiar de cámara'), findsOneWidget);
      expect(
        _announced(tester),
        contains(
          'Cámara encendida. Deja la boca cerrada y relajada un momento.',
        ),
      );

      // La foto que sale de la cámara es la que llega al servidor.
      expect(service.sentFrames.single, camera.pictureBytes);

      final overlay = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((paint) => paint.painter)
          .whereType<LipOverlayPainter>()
          .single;
      expect(overlay.frame, isNotNull);

      // Muchas fotos seguidas: el flash queda apagado.
      expect(camera.flashModes, [FlashMode.off]);

      await _leave(tester);
    });

    testWidgets('sin cara pide colocarse, y no empieza a ajustar', (
      tester,
    ) async {
      final service = _ScriptedService();
      await _open(tester, service: service);
      await _turnOn(tester);

      expect(find.textContaining('Todavía no veo tu cara'), findsOneWidget);
      expect(_enabled(tester, 'Leer una palabra'), isFalse);

      await _leave(tester);
    });

    testWidgets('primero se ajusta a la cara y luego deja leer', (
      tester,
    ) async {
      final service = _ScriptedService(frames: _relaxed(6, width: 0.58));
      await _open(tester, service: service);
      await _turnOn(tester);
      tester.takeAnnouncements();

      expect(find.textContaining('Ajustando a tu cara'), findsOneWidget);
      expect(_enabled(tester, 'Leer una palabra'), isFalse);
      expect(service.neutralWidths.last, isNull);

      await _liveFrames(tester, 5);

      expect(find.textContaining('Ajustando a tu cara'), findsNothing);
      expect(_enabled(tester, 'Leer una palabra'), isTrue);
      expect(
        _announced(tester),
        contains('Listo. Pulsa «Leer una palabra» cuando quieras.'),
      );

      // Desde ahora el servidor juzga con la boca de esta persona.
      await _liveFrames(tester, 1);
      expect(service.neutralWidths.last, 0.58);

      await _leave(tester);
    });

    testWidgets('marca la forma de la boca y la describe', (tester) async {
      final service = _ScriptedService(
        frames: [..._relaxed(6), _mouth(shape: LipShape.o)],
      );
      await _open(tester, service: service);
      await _turnOn(tester);
      await _liveFrames(tester, 6);

      expect(find.text(LipShape.o.description), findsOneWidget);
      for (final shape in LipShape.values) {
        expect(find.text(shape.label), findsOneWidget, reason: shape.code);
      }

      await _leave(tester);
    });

    testWidgets('volver a ajustar pide otra vez la boca relajada', (
      tester,
    ) async {
      final service = _ScriptedService(frames: _relaxed(40));
      await _open(tester, service: service);
      await _turnOn(tester);
      await _liveFrames(tester, 5);

      await _tapButton(tester, 'Volver a ajustar');

      expect(find.textContaining('Ajustando a tu cara'), findsOneWidget);
      expect(_enabled(tester, 'Leer una palabra'), isFalse);

      await _leave(tester);
    });

    testWidgets('apagar suelta la cámara y deja de mandar fotos', (
      tester,
    ) async {
      final service = _ScriptedService(frames: _relaxed(3));
      await _open(tester, service: service);
      await _turnOn(tester);

      await _tapButton(tester, 'Apagar la cámara');
      final sent = service.sentFrames.length;
      await _liveFrames(tester, 4);

      expect(find.text('La cámara está apagada'), findsOneWidget);
      expect(camera.disposed, [1]);
      expect(service.sentFrames, hasLength(sent));

      await _leave(tester);
    });

    testWidgets('encender otra vez empieza a ajustar de nuevo', (tester) async {
      final service = _ScriptedService(frames: _relaxed(20));
      await _open(tester, service: service);
      await _turnOn(tester);
      await _liveFrames(tester, 5);
      expect(_enabled(tester, 'Leer una palabra'), isTrue);

      await _tapButton(tester, 'Apagar la cámara');
      await _turnOn(tester);

      expect(_enabled(tester, 'Leer una palabra'), isFalse);
      // Un solo bucle de fotos, aunque se haya apagado y encendido deprisa.
      final before = camera.pictures;
      await tester.pump(const Duration(milliseconds: 200));
      expect(camera.pictures - before, lessThanOrEqualTo(1));

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

      await _leave(tester);
    });

    testWidgets('si el servidor se cae a media sesión se explica y se apaga', (
      tester,
    ) async {
      final service = _ScriptedService(
        frames: [
          LipReadingException(
            LipFailureKind.offline,
            'No se pudo conectar con el servidor para leer los labios.',
          ),
        ],
      );
      await _open(tester, service: service);
      await _turnOn(tester);
      await tester.pump();

      expect(
        find.text('No se pudo conectar con el servidor para leer los labios.'),
        findsOneWidget,
      );
      expect(camera.disposed, [1]);
      expect(find.text('Volver a intentarlo'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('una foto rechazada no tumba la sesión', (tester) async {
      final service = _ScriptedService(
        frames: [
          LipReadingException(LipFailureKind.badImage, 'no vale'),
          StateError('una respuesta rara'),
          ..._relaxed(10),
        ],
      );
      await _open(tester, service: service);
      await _turnOn(tester);
      await _liveFrames(tester, 3);

      expect(find.text('Apagar la cámara'), findsOneWidget);
      expect(find.textContaining('Ajustando a tu cara'), findsOneWidget);

      await _leave(tester);
    });

    final cameraFailures = <String, (Object, String)>{
      'sin permiso': (
        CameraException('CameraAccessDenied', 'sin permiso'),
        'Hace falta permiso para usar la cámara',
      ),
      'sin cámara conectada': (
        CameraException('cameraNotFound', 'nada'),
        'No se encontró ninguna cámara disponible',
      ),
      'otro problema de la cámara': (
        CameraException('rara', 'se colgó'),
        'La cámara dio un problema: se colgó',
      ),
      'esta versión no tiene cámara': (
        MissingPluginException(),
        'Esta versión de Code4All no puede abrir la cámara',
      ),
      'cualquier otro fallo': (
        StateError('rara'),
        'No se pudo encender la cámara',
      ),
    };
    cameraFailures.forEach((name, failure) {
      testWidgets('al encender, $name se explica', (tester) async {
        camera.createError = failure.$1;
        await _open(tester, service: _ScriptedService());

        await _turnOn(tester);

        expect(find.textContaining(failure.$2), findsOneWidget);
        expect(find.text('Volver a intentarlo'), findsOneWidget);

        await _leave(tester);
      });
    });

    testWidgets('sin ninguna cámara se dice', (tester) async {
      camera.cameras = const [];
      await _open(tester, service: _ScriptedService());

      await _turnOn(tester);

      expect(
        find.text('No se encontró ninguna cámara en este dispositivo.'),
        findsOneWidget,
      );

      await _leave(tester);
    });

    testWidgets('si la cámara falla en una foto se apaga y se explica', (
      tester,
    ) async {
      camera.pictureErrors.add(CameraException('rara', 'se soltó'));
      await _open(tester, service: _ScriptedService());

      await _turnOn(tester);
      await tester.pump();

      expect(
        find.text('La cámara dio un problema: se soltó'),
        findsOneWidget,
      );

      await _leave(tester);
    });

    testWidgets('la foto en camino al apagar no se cuenta como un fallo', (
      tester,
    ) async {
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);
      await tester.pump(const Duration(milliseconds: 200));

      final gate = Completer<void>();
      camera.pictureGate = gate;
      await tester.pump(const Duration(milliseconds: 200));
      await _tapButton(tester, 'Apagar la cámara');

      camera.pictureErrors.add(CameraException('rara', 'ya la soltaron'));
      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('La cámara dio un problema'), findsNothing);
      expect(find.text('Encender la cámara'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('borra cada foto en cuanto la lee', (tester) async {
      camera.pictureFile = File(
        '${Directory.systemTemp.createTempSync('code4all_labios_').path}'
        '${Platform.pathSeparator}foto.jpg',
      );
      await _open(tester, service: _ScriptedService());
      await _turnOn(tester);
      expect(camera.pictures, 1);
      expect(camera.pictureFile!.existsSync(), isTrue);

      // Se apaga para que no llegue otra foto justo antes de comprobarlo.
      await _tapButton(tester, 'Apagar la cámara');

      // Leer y borrar un archivo es E/S de verdad: no avanza con el reloj
      // simulado, así que se le deja tiempo real a trozos.
      for (var i = 0; i < 250 && camera.pictureFile!.existsSync(); i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }

      expect(camera.pictureFile!.existsSync(), isFalse);

      camera.pictureFile!.parent.deleteSync(recursive: true);
      camera.pictureFile = null;
      await _leave(tester);
    });

    testWidgets('al irse a segundo plano suelta la cámara', (tester) async {
      await _open(tester, service: _ScriptedService(frames: _relaxed(2)));
      await _turnOn(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(camera.disposed, [1]);
      expect(find.text('La cámara está apagada'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _leave(tester);
    });
  });

  group('LipReadingScreen: leer una palabra', () {
    testWidgets('junta las fotos, las manda juntas y escribe la palabra', (
      tester,
    ) async {
      final service = _ScriptedService(
        frames: _relaxed(40),
        clips: [
          const LipWordReading(
            word: 'hola',
            alternatives: ['no'],
            shapes: [LipShape.o, LipShape.a],
          ),
        ],
      );
      await _readyToRead(tester, service);
      tester.takeAnnouncements();

      await _tapButton(tester, 'Leer una palabra');
      expect(find.text('Terminar'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        _announced(tester),
        contains('Te estoy mirando. Di la palabra y pulsa terminar.'),
      );

      await _clipFrames(tester, 8);
      await _tapButton(tester, 'Terminar');
      await tester.pump();

      expect(service.sentClips.single.length, greaterThanOrEqualTo(7));
      expect(service.clipNeutralWidths.single, isNotNull);
      expect(find.text('Creo que dijiste: hola.'), findsOneWidget);
      expect(find.text('Formas que vi: O → A'), findsOneWidget);
      expect(find.text('hola'), findsOneWidget);
      expect(_announced(tester), contains('Creo que dijiste: hola.'));

      await _leave(tester);
    });

    testWidgets('si se equivocó, otra candidata reemplaza a la palabra', (
      tester,
    ) async {
      final service = _ScriptedService(
        frames: _relaxed(40),
        clips: [
          const LipWordReading(word: 'hola', alternatives: ['clase']),
        ],
      );
      await _readyToRead(tester, service);
      await _readWord(tester);

      expect(find.textContaining('¿No era esa?'), findsOneWidget);
      await _tapButton(tester, 'clase');

      // Reemplaza a «hola», no se suma detrás.
      expect(find.text('clase'), findsOneWidget);
      expect(find.text('hola'), findsNothing);
      expect(find.text('hola clase'), findsNothing);

      await _leave(tester);
    });

    testWidgets('si duda no escribe nada y deja elegir', (tester) async {
      final service = _ScriptedService(
        frames: _relaxed(40),
        clips: [
          const LipWordReading(alternatives: ['hola', 'no']),
          const LipWordReading(word: 'sí'),
        ],
      );
      await _readyToRead(tester, service);
      await _readWord(tester);

      expect(find.text('No estoy seguro. ¿Era alguna de estas?'), findsOneWidget);
      expect(find.text('Nada todavía'), findsOneWidget);
      expect(find.textContaining('¿No era esa?'), findsNothing);

      await _tapButton(tester, 'no');
      expect(find.text('Nada todavía'), findsNothing);
      expect(find.text('no'), findsOneWidget);

      // Lo elegido se queda: la palabra siguiente se suma detrás.
      await _readWord(tester);
      expect(find.text('no sí'), findsOneWidget);

      await _leave(tester);
    });

    final problems = <String, (LipWordReading, String)>{
      'corto': (
        const LipWordReading(problem: LipReadingProblem.tooShort),
        'Fue muy corto',
      ),
      'sin cara': (
        const LipWordReading(problem: LipReadingProblem.noFace),
        'No vi bien tu cara',
      ),
      'sin movimiento': (
        const LipWordReading(problem: LipReadingProblem.noMovement),
        'No vi moverse tu boca',
      ),
      'sin ninguna candidata': (
        const LipWordReading(),
        'No reconocí la palabra',
      ),
    };
    problems.forEach((name, problem) {
      testWidgets('un clip $name se explica y no escribe nada', (tester) async {
        final service = _ScriptedService(
          frames: _relaxed(40),
          clips: [problem.$1],
        );
        await _readyToRead(tester, service);
        await _readWord(tester);

        expect(find.textContaining(problem.$2), findsOneWidget);
        expect(find.text('Nada todavía'), findsOneWidget);

        await _leave(tester);
      });
    });

    testWidgets('si falla el servidor se dice, y la cámara sigue encendida', (
      tester,
    ) async {
      final service = _ScriptedService(
        frames: _relaxed(40),
        clips: [
          LipReadingException(LipFailureKind.offline, 'Sin conexión al leer.'),
        ],
      );
      await _readyToRead(tester, service);
      await _readWord(tester);

      expect(find.text('Sin conexión al leer.'), findsOneWidget);
      expect(find.text('Apagar la cámara'), findsOneWidget);
      expect(find.text('Leer una palabra'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('mientras analiza lo dice y no toma más fotos', (tester) async {
      final answer = Completer<LipWordReading>();
      final service = _ScriptedService(
        frames: _relaxed(40),
        clips: [answer.future],
      );
      await _readyToRead(tester, service);

      await _tapButton(tester, 'Leer una palabra');
      await _clipFrames(tester, 4);
      await _tapButton(tester, 'Terminar');
      await tester.pump();

      expect(find.text('Leyendo tu boca…'), findsOneWidget);
      expect(find.text('Leer una palabra'), findsNothing);
      final pictures = camera.pictures;
      await _liveFrames(tester, 3);
      expect(camera.pictures, pictures);

      answer.complete(const LipWordReading(word: 'hola'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Creo que dijiste: hola.'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('una palabra se corta sola al llegar al límite', (tester) async {
      final service = _ScriptedService(
        frames: _relaxed(80),
        clips: [const LipWordReading(word: 'hola')],
      );
      await _readyToRead(tester, service);

      await _tapButton(tester, 'Leer una palabra');
      await _clipFrames(tester, 45);
      await tester.pump();

      // Nadie pulsó «Terminar»: se manda sola, sin pasarse de lo que el
      // servidor acepta.
      expect(service.sentClips.single.length, lessThanOrEqualTo(40));
      expect(find.text('Creo que dijiste: hola.'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('apagar a mitad de una palabra la descarta', (tester) async {
      final service = _ScriptedService(frames: _relaxed(40));
      await _readyToRead(tester, service);

      await _tapButton(tester, 'Leer una palabra');
      await _clipFrames(tester, 3);
      await _tapButton(tester, 'Apagar la cámara');
      await _liveFrames(tester, 2);

      expect(service.sentClips, isEmpty);
      expect(find.text('La cámara está apagada'), findsOneWidget);

      await _leave(tester);
    });

    testWidgets('se puede borrar la última palabra o empezar de nuevo', (
      tester,
    ) async {
      final service = _ScriptedService(
        frames: _relaxed(60),
        clips: [
          const LipWordReading(word: 'hola'),
          const LipWordReading(word: 'bien'),
          const LipWordReading(word: 'no'),
        ],
      );
      await _readyToRead(tester, service);

      expect(_enabled(tester, 'Borrar la última'), isFalse);
      expect(_enabled(tester, 'Empezar de nuevo'), isFalse);

      await _readWord(tester);
      await _readWord(tester);
      expect(find.text('hola bien'), findsOneWidget);

      await _tapButton(tester, 'Borrar la última');
      expect(find.text('hola'), findsOneWidget);

      await _readWord(tester);
      expect(find.text('hola no'), findsOneWidget);

      await _tapButton(tester, 'Empezar de nuevo');
      expect(find.text('Nada todavía'), findsOneWidget);
      expect(_enabled(tester, 'Borrar la última'), isFalse);

      await _leave(tester);
    });
  });

  group('los dibujos de la boca', () {
    final frame = LipFrame(
      outer: [
        for (var i = 0; i < 20; i++) LipPoint(0.4 + i * 0.01, 0.6 + i * 0.002),
      ],
      inner: [
        for (var i = 0; i < 20; i++) LipPoint(0.42 + i * 0.008, 0.6),
      ],
      opening: 0.2,
      width: 0.6,
      rounding: 0.1,
      shape: LipShape.a,
    );

    testWidgets('se pintan sin fallar, con datos y sin ellos', (tester) async {
      final painters = <CustomPainter>[
        LipOverlayPainter(frame: frame),
        LipOverlayPainter(frame: frame, mirror: true),
        const LipOverlayPainter(frame: null),
        MouthZoomPainter(frame: frame, aspectRatio: 4 / 3),
        const MouthZoomPainter(frame: null, aspectRatio: 4 / 3),
        LipMovementPainter(
          history: [frame, frame, frame],
          neutralWidth: 0.6,
          openingColor: Colors.red,
          widthColor: Colors.blue,
          roundingColor: Colors.green,
          gridColor: Colors.grey,
        ),
        LipMovementPainter(
          history: const [],
          neutralWidth: 0.6,
          openingColor: Colors.red,
          widthColor: Colors.blue,
          roundingColor: Colors.green,
          gridColor: Colors.grey,
        ),
      ];

      for (final painter in painters) {
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              width: 200,
              height: 120,
              child: CustomPaint(painter: painter),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    test('solo se repintan si cambia algo', () {
      final overlay = LipOverlayPainter(frame: frame);
      expect(overlay.shouldRepaint(LipOverlayPainter(frame: frame)), isFalse);
      expect(
        overlay.shouldRepaint(LipOverlayPainter(frame: frame, mirror: true)),
        isTrue,
      );

      final zoom = MouthZoomPainter(frame: frame, aspectRatio: 1);
      expect(
        zoom.shouldRepaint(MouthZoomPainter(frame: frame, aspectRatio: 1)),
        isFalse,
      );
      expect(
        zoom.shouldRepaint(const MouthZoomPainter(frame: null, aspectRatio: 1)),
        isTrue,
      );
    });

    testWidgets('el icono de labios no le dice nada al lector de pantalla', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: LipsIcon(color: Colors.black)),
        ),
      );

      expect(find.byType(LipsIcon), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });
}

// --- Ayudas ------------------------------------------------------------------

Future<void> _open(
  WidgetTester tester, {
  required LipReadingService service,
}) async {
  tester.view.physicalSize = const Size(900, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: LipReadingScreen(service: service)),
  );
  await tester.pump();
}

Future<void> _turnOn(WidgetTester tester) =>
    _tapButton(tester, 'Encender la cámara');

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  // Todo lo que hace la cámara simulada se resuelve en microtareas, así que un
  // fotograma basta para encenderla y leer la primera foto.
  await tester.pump();
}

/// Deja pasar [count] fotos a ritmo normal.
Future<void> _liveFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Deja pasar [count] fotos al ritmo de cuando se está hablando.
Future<void> _clipFrames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 110));
  }
}

/// Enciende la cámara y deja que termine de ajustarse a la cara.
Future<void> _readyToRead(
  WidgetTester tester,
  _ScriptedService service,
) async {
  await _open(tester, service: service);
  await _turnOn(tester);
  await _liveFrames(tester, 5);
  expect(_enabled(tester, 'Leer una palabra'), isTrue);
}

/// Una palabra entera: pulsar, unas cuantas fotos y terminar.
Future<void> _readWord(WidgetTester tester) async {
  await _tapButton(tester, 'Leer una palabra');
  await _clipFrames(tester, 4);
  await _tapButton(tester, 'Terminar');
  await tester.pump();
  await tester.pump();
}

/// Desmonta la pantalla y deja que el bucle de fotos termine su espera.
Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

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

LipFrame _mouth({
  LipShape shape = LipShape.closed,
  double opening = 0.0,
  double width = 0.6,
}) => LipFrame(
  outer: const [LipPoint(0.4, 0.6), LipPoint(0.6, 0.6)],
  inner: const [LipPoint(0.45, 0.6), LipPoint(0.55, 0.6)],
  opening: opening,
  width: width,
  rounding: 0,
  shape: shape,
);

List<LipFrame> _relaxed(int count, {double width = 0.6}) => [
  for (var i = 0; i < count; i++) _mouth(width: width),
];

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

class _FakeCameraPlatform extends CameraPlatform {
  List<CameraDescription> cameras = const [_front];

  /// Se lanza al crear la cámara, que es donde el sistema pide permiso.
  Object? createError;

  /// Fallos de las próximas fotos, en orden.
  final List<Object> pictureErrors = [];

  /// Si está puesta, la próxima foto espera a que se complete.
  Completer<void>? pictureGate;

  /// Si está puesto, cada foto queda en este archivo, como en un móvil.
  File? pictureFile;

  final List<CameraDescription> opened = [];
  final List<int> disposed = [];
  final List<FlashMode> flashModes = [];
  int pictures = 0;
  int _nextId = 0;

  final Uint8List pictureBytes = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);

  // Nunca emiten ni se cierran: una cámara que no da errores ni gira.
  final _errors = StreamController<CameraErrorEvent>.broadcast();
  final _orientation =
      StreamController<DeviceOrientationChangedEvent>.broadcast();

  @override
  Future<List<CameraDescription>> availableCameras() async => cameras;

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
  }) async {}

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
  Future<void> setFlashMode(int cameraId, FlashMode mode) async =>
      flashModes.add(mode);

  @override
  Future<XFile> takePicture(int cameraId) async {
    pictures++;
    final gate = pictureGate;
    if (gate != null) {
      pictureGate = null;
      await gate.future;
    }
    if (pictureErrors.isNotEmpty) throw pictureErrors.removeAt(0);
    final file = pictureFile;
    if (file != null) {
      file.writeAsBytesSync(pictureBytes);
      return XFile(file.path);
    }
    return XFile.fromData(pictureBytes, name: 'foto.jpg');
  }

  @override
  Widget buildPreview(int cameraId) =>
      SizedBox.expand(key: ValueKey('vista-camara-$cameraId'));

  @override
  Future<void> dispose(int cameraId) async => disposed.add(cameraId);
}

/// Servidor guionizado: contesta lo que diga cada lista, en orden. Lo que no
/// sea una respuesta se lanza como error.
class _ScriptedService extends LipReadingService {
  _ScriptedService({
    this.available = true,
    List<String> words = const ['hola', 'no', 'sí'],
    List<Object>? frames,
    List<Object>? clips,
  }) : frameScript = frames ?? [],
       clipScript = clips ?? [],
       super(
         api: ApiService(baseUrl: 'http://servidor.de.prueba'),
         client: MockClient((request) async => http.Response('', 500)),
       ) {
    this.words = words;
  }

  bool available;
  final List<Object> frameScript;
  final List<Object> clipScript;

  final List<Uint8List> sentFrames = [];
  final List<double?> neutralWidths = [];
  final List<List<Uint8List>> sentClips = [];
  final List<double?> clipNeutralWidths = [];

  @override
  Future<bool> isAvailable({bool refresh = false}) async => available;

  @override
  Future<LipFrame?> readFrame(Uint8List frame, {double? neutralWidth}) async {
    sentFrames.add(frame);
    neutralWidths.add(neutralWidth);
    if (frameScript.isEmpty) return null;
    final next = frameScript.removeAt(0);
    if (next is LipFrame) return next;
    throw next;
  }

  @override
  Future<LipWordReading> readClip(
    List<Uint8List> frames, {
    double? neutralWidth,
  }) async {
    sentClips.add(frames);
    clipNeutralWidths.add(neutralWidth);
    if (clipScript.isEmpty) return const LipWordReading();
    final next = clipScript.removeAt(0);
    if (next is LipWordReading) return next;
    if (next is Future<LipWordReading>) return next;
    throw next;
  }
}
