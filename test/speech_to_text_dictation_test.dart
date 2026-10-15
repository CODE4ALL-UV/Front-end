import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
// Las interfaces de plataforma llegan con audioplayers y speech_to_text; se
// importan para sustituir el micrófono y el altavoz por unos simulados.
// ignore: depend_on_referenced_packages
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

import 'package:flutter_code4all/data/services/voice_dictation_service.dart';

/// El dictado por voz de verdad, con el reconocedor y el altavoz simulados.
///
/// Las otras pruebas del dictado usan un micrófono de mentira que implementa
/// `VoiceDictation`, así que nunca pasan por `SpeechToTextDictation`, que es
/// la que traduce lo que dice el reconocedor del sistema. Aquí se sustituye la
/// plataforma de speech_to_text y se le hace «hablar»: resultados parciales y
/// finales, silencios, errores de permiso y fallos al parar. Así se comprueba
/// lo que recibe la pantalla: el texto según se oye, la frase final limpia,
/// null cuando no se oyó nada y una explicación cuando no hay micrófono.
///
/// También se comprueban los pitidos de inicio y fin, que son la única forma
/// que tiene una persona ciega de saber cuándo puede empezar a hablar.
///
/// **Orden de las pruebas.** speech_to_text es un objeto único para toda la
/// app: una vez que se prepara bien, no vuelve a prepararse ni registra otros
/// oyentes. Por eso las pruebas de «no se puede preparar» van primero y todas
/// usan la misma instancia del dictado.
void main() {
  late SpeechToTextPlatform originalSpeech;
  late AudioplayersPlatformInterface originalAudio;
  late GlobalAudioplayersPlatformInterface originalGlobalAudio;
  late AudioCache originalCache;

  late _FakeSpeech speech;
  late _FakeAudio audio;
  late _FakeAudioCache cache;
  late SpeechToTextDictation dictation;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    originalSpeech = SpeechToTextPlatform.instance;
    originalAudio = AudioplayersPlatformInterface.instance;
    originalGlobalAudio = GlobalAudioplayersPlatformInterface.instance;
    originalCache = AudioCache.instance;

    speech = _FakeSpeech();
    audio = _FakeAudio();
    cache = _FakeAudioCache();
    SpeechToTextPlatform.instance = speech;
    AudioplayersPlatformInterface.instance = audio;
    GlobalAudioplayersPlatformInterface.instance = _FakeGlobalAudio();
    AudioCache.instance = cache;

    // El reproductor del pitido toma la plataforma al crearse: el dictado se
    // crea después de cambiarla.
    dictation = SpeechToTextDictation();
  });

  tearDownAll(() {
    SpeechToTextPlatform.instance = originalSpeech;
    AudioplayersPlatformInterface.instance = originalAudio;
    GlobalAudioplayersPlatformInterface.instance = originalGlobalAudio;
    AudioCache.instance = originalCache;
  });

  setUp(() => speech.reset());

  group('cuando no se puede dictar', () {
    testWidgets('sin reconocedor de voz lo dice con claridad', (tester) async {
      speech.initError = PlatformException(code: 'no_speech');

      await expectLater(
        dictation.listen(),
        throwsA(
          isA<DictationUnavailableException>().having(
            (error) => error.message,
            'mensaje',
            'El reconocimiento de voz no está disponible en este dispositivo.',
          ),
        ),
      );
      expect(speech.listens, isEmpty);
    });

    testWidgets('sin permiso de micrófono pide revisar los permisos', (
      tester,
    ) async {
      speech.initResult = false;

      await expectLater(
        dictation.listen(),
        throwsA(
          isA<DictationUnavailableException>().having(
            (error) => error.message,
            'mensaje',
            contains('Revisa que la aplicación o el navegador tengan permiso'),
          ),
        ),
      );
      expect(speech.listens, isEmpty);
    });

    testWidgets('si el micrófono no arranca avisa de que no pudo escuchar', (
      tester,
    ) async {
      speech.listenError = PlatformException(code: 'busy', message: 'ocupado');

      await expectLater(
        dictation.listen(),
        throwsA(
          isA<DictationUnavailableException>().having(
            (error) => error.message,
            'mensaje',
            'No se pudo empezar a escuchar por el micrófono.',
          ),
        ),
      );
      expect(speech.initCalls, 1);

      // Tras el fallo se puede volver a intentar sin quedarse colgado.
      speech.listenError = null;
      final retry = dictation.listen();
      await tester.pump();
      speech.say('vale', isFinal: true);
      expect(await retry, 'vale');

      await _drain(tester);
    });
  });

  group('escuchar una frase', () {
    testWidgets('enseña lo que va oyendo y devuelve la frase final limpia', (
      tester,
    ) async {
      final partials = <String>[];
      final heard = dictation.listen(onPartial: partials.add);
      await tester.pump();

      // Escucha en español de Colombia, dictando y sin quedarse abierto.
      final options = speech.listens.single!;
      expect(options.localeId, 'es-CO');
      expect(options.partialResults, isTrue);
      expect(options.listenMode, ListenMode.dictation);
      expect(options.cancelOnError, isTrue);
      expect(options.pauseFor, const Duration(seconds: 3));
      expect(options.listenFor, const Duration(seconds: 30));

      speech.say('hola');
      speech.say('hola mundo');
      speech.say('  hola mundo  ', isFinal: true);

      expect(partials, ['hola', 'hola mundo', '  hola mundo  ']);
      expect(await heard, 'hola mundo');

      await _drain(tester);
    });

    testWidgets('si termina sin oír nada devuelve null', (tester) async {
      final heard = dictation.listen();
      await tester.pump();

      speech.status('doneNoResult');

      expect(await heard, isNull);
      await _drain(tester);
    });

    testWidgets('sin permiso a mitad de escucha lo explica', (tester) async {
      final heard = dictation.listen();
      await tester.pump();

      final refused = expectLater(
        heard,
        throwsA(
          isA<DictationUnavailableException>().having(
            (error) => error.message,
            'mensaje',
            contains('No hay permiso para usar el micrófono'),
          ),
        ),
      );
      speech.fail('not-allowed', permanent: true);
      await tester.pump();
      await refused;
      // Con un error permanente el reconocedor se cancela.
      expect(speech.cancels, 1);

      await _drain(tester);
    });

    testWidgets('si se perdió el micrófono pero ya oyó algo, lo conserva', (
      tester,
    ) async {
      final heard = dictation.listen();
      await tester.pump();

      speech.say('print hola');
      speech.fail('audio-capture', permanent: true);
      await tester.pump();

      expect(await heard, 'print hola');
      await _drain(tester);
    });

    testWidgets('un error pasajero no se confunde con falta de permiso', (
      tester,
    ) async {
      final heard = dictation.listen();
      await tester.pump();

      // «No te entendí» no es un error de micrófono: sigue escuchando.
      speech.fail('error_no_match', permanent: false);
      await tester.pump();
      var finished = false;
      unawaited(heard.then((_) => finished = true));
      await tester.pump();
      expect(finished, isFalse);

      speech.status('doneNoResult');
      expect(await heard, isNull);

      await _drain(tester);
    });

    testWidgets('parar a mano devuelve lo que se llevaba entendido', (
      tester,
    ) async {
      final heard = dictation.listen();
      await tester.pump();
      speech.say('sebastián arroba');

      await dictation.stop();

      expect(speech.stops, 1);
      expect(await heard, 'sebastián arroba');
      await _drain(tester);
    });

    testWidgets('si el reconocedor falla al parar, la escucha termina igual', (
      tester,
    ) async {
      final heard = dictation.listen();
      await tester.pump();
      speech.say('clave');
      speech.stopError = PlatformException(code: 'stop_failed');

      await dictation.stop();

      expect(await heard, 'clave');
      speech.stopError = null;
      await _drain(tester);
    });

    testWidgets('volver a escuchar cierra antes la escucha anterior', (
      tester,
    ) async {
      final first = dictation.listen();
      await tester.pump();
      speech.say('uno');

      final second = dictation.listen();
      await tester.pump();

      expect(await first, 'uno');
      expect(speech.listens, hasLength(2));

      speech.say('dos', isFinal: true);
      expect(await second, 'dos');

      await _drain(tester);
    });
  });

  group('pitidos de aviso', () {
    test('suena un pitido distinto al empezar y al terminar', () async {
      await dictation.cue(start: true);
      // El pitido es corto: termina antes de que se pida el siguiente.
      await Future<void>.delayed(Duration.zero);
      await dictation.cue(start: false);

      expect(cache.loaded, ['audios/mic_start.wav', 'audios/mic_end.wav']);
      expect(audio.sources, [
        '/cache/assets/audios/mic_start.wav',
        '/cache/assets/audios/mic_end.wav',
      ]);
      expect(audio.resumes, 2);
      // Antes de cada pitido se corta el anterior, para que no se solapen.
      expect(audio.stops, 2);
    });

    test('si el altavoz falla se puede dictar igual', () async {
      audio.failStop = true;
      addTearDown(() => audio.failStop = false);

      await expectLater(dictation.cue(start: true), completes);
      expect(audio.sources, hasLength(2));
    });
  });
}

/// Deja que venzan los temporizadores internos de speech_to_text (la pausa
/// de 3 s y la espera del resultado final) para que no queden pendientes.
Future<void> _drain(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 10));

// --- Dobles de prueba --------------------------------------------------------

/// Un reconocedor de voz de mentira al que se le puede hacer «oír» frases.
class _FakeSpeech extends SpeechToTextPlatform {
  Object? initError;
  bool initResult = true;
  Object? listenError;
  Object? stopError;

  int initCalls = 0;
  int stops = 0;
  int cancels = 0;
  final List<SpeechListenOptions?> listens = [];

  void reset() {
    initError = null;
    initResult = true;
    listenError = null;
    stopError = null;
    initCalls = 0;
    stops = 0;
    cancels = 0;
    listens.clear();
  }

  /// El reconocedor entiende [words]; [isFinal] cierra la frase.
  void say(String words, {bool isFinal = false}) {
    onTextRecognition?.call(
      jsonEncode({
        'alternates': [
          {'recognizedWords': words, 'confidence': 0.9},
        ],
        'resultType': isFinal ? 2 : 0,
      }),
    );
  }

  void status(String value) => onStatus?.call(value);

  void fail(String message, {required bool permanent}) =>
      onError?.call(jsonEncode({'errorMsg': message, 'permanent': permanent}));

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async {
    initCalls++;
    final error = initError;
    if (error != null) throw error;
    return initResult;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    final error = listenError;
    if (error != null) throw error;
    listens.add(options);
    return true;
  }

  @override
  Future<void> stop() async {
    stops++;
    final error = stopError;
    if (error != null) throw error;
  }

  @override
  Future<void> cancel() async => cancels++;
}

/// Un altavoz de mentira: apunta qué suena y avisa de que cada pitido está
/// listo y de que termina enseguida, como haría uno real.
class _FakeAudio extends Fake implements AudioplayersPlatformInterface {
  final Map<String, StreamController<AudioEvent>> _events = {};
  final List<String> sources = [];
  int stops = 0;
  int resumes = 0;
  bool failStop = false;

  @override
  Future<void> create(String playerId) async {
    _events[playerId] = StreamController<AudioEvent>.broadcast();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) =>
      _events[playerId]!.stream;

  @override
  Future<void> stop(String playerId) async {
    if (failStop) throw PlatformException(code: 'sin_altavoz');
    stops++;
  }

  @override
  Future<void> setSourceUrl(
    String playerId,
    String url, {
    bool? isLocal,
    String? mimeType,
  }) async {
    sources.add(url);
    _events[playerId]!.add(
      const AudioEvent(eventType: AudioEventType.prepared, isPrepared: true),
    );
  }

  @override
  Future<void> resume(String playerId) async {
    resumes++;
    _events[playerId]!.add(
      const AudioEvent(eventType: AudioEventType.complete),
    );
  }

  @override
  Future<int?> getCurrentPosition(String playerId) async => 0;
}

class _FakeGlobalAudio extends Fake
    implements GlobalAudioplayersPlatformInterface {
  @override
  Future<void> init() async {}

  @override
  Stream<GlobalAudioEvent> getGlobalEventStream() => const Stream.empty();
}

/// Sin disco: dice dónde «estaría» cada sonido y apunta cuáles se pidieron.
class _FakeAudioCache extends AudioCache {
  final List<String> loaded = [];

  @override
  Future<String> loadPath(String fileName) async {
    loaded.add(fileName);
    return '/cache/$prefix$fileName';
  }
}
