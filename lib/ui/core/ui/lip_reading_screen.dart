import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_code4all/data/services/lip_reading_service.dart';
import 'package:flutter_code4all/domain/models/lip_reading/lip_reading_models.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/themes/message_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/lip_alphabet_guide_screen.dart';
import 'package:flutter_code4all/ui/core/ui/lip_painters.dart';
import 'package:flutter_code4all/utils/camera_photo_cleanup_io.dart'
    if (dart.library.js_interop) 'package:flutter_code4all/utils/camera_photo_cleanup_web.dart';

/// En qué punto está la pantalla.
enum _Stage { checking, unavailable, ready, running, failed }

/// Lee los labios con la cámara: muestra cómo se mueve la boca y escribe
/// palabras sueltas.
///
/// Hay dos ritmos. En vivo se manda una foto en cuanto el servidor termina con
/// la anterior, para dibujar los labios y decir qué forma tiene la boca. Para
/// leer una palabra hacen falta muchas más fotos de las que el servidor puede
/// atender una a una: se toman aquí, se guardan mientras se habla y se mandan
/// todas juntas al terminar.
///
/// **Qué lee y qué no.** Los labios no lo dicen todo: la mayoría de las
/// consonantes se hacen dentro de la boca. Por eso lee las vocales, los labios
/// que se juntan y las palabras de una lista cerrada, y si duda deja elegir en
/// vez de escribir por la persona algo que no dijo. Sirve para practicar, no
/// para evaluar a nadie.
///
/// **Privacidad.** Las fotos van al servidor de la propia aplicación, se
/// analizan en memoria y se descartan. No se graba vídeo ni se guarda ninguna
/// imagen, y la cámara solo se enciende cuando la persona pulsa el botón.
class LipReadingScreen extends StatefulWidget {
  const LipReadingScreen({super.key, this.service});

  /// Se puede inyectar en las pruebas.
  final LipReadingService? service;

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const LipReadingScreen());

  @override
  State<LipReadingScreen> createState() => _LipReadingScreenState();
}

class _LipReadingScreenState extends State<LipReadingScreen>
    with WidgetsBindingObserver {
  /// Cada cuánto se mira la boca en vivo, si el servidor da abasto.
  static const Duration _liveInterval = Duration(milliseconds: 180);

  /// Cada cuánto se toma una foto mientras se habla. Una vocal dura unas dos
  /// décimas de segundo: más despacio se la saltaría.
  static const Duration _clipInterval = Duration(milliseconds: 100);

  /// Lo que dura como mucho una palabra.
  static const Duration _maxClip = Duration(seconds: 4);

  /// Cuántas fotos caben en una palabra. El servidor no acepta más de 60.
  static const int _maxClipFrames = 40;

  /// Las fotos que caben en la gráfica del movimiento.
  static const int _historyLength = 60;

  /// El ancho de una boca relajada si todavía no se ha medido el de esta
  /// persona. Es el mismo que usa el servidor.
  static const double _defaultNeutralWidth = 0.6;

  late final LipReadingService _service = widget.service ?? LipReadingService();

  final LipCalibration _calibration = LipCalibration();
  final List<LipFrame> _history = [];
  final List<String> _words = [];
  final Stopwatch _clipClock = Stopwatch();

  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  _Stage _stage = _Stage.checking;
  String _problem = '';

  /// Lo que explicó el servidor al decir que no, si lo explicó.
  String? _problemDetail;

  /// Cambia cada vez que se enciende o se apaga la cámara: un bucle de fotos
  /// que estaba esperando sabe así que ya no le toca seguir.
  int _session = 0;

  LipFrame? _frame;
  bool _liveBusy = false;

  bool _recording = false;
  bool _analyzing = false;
  List<Uint8List> _clip = [];
  LipWordReading? _reading;
  String? _readingProblem;

  /// Si la última palabra de [_words] la acaba de escribir el lector, y por
  /// tanto una candidata la reemplaza en lugar de sumarse.
  bool _lastWordIsGuess = false;

  bool get _mirrorOverlay {
    final camera = _camera;
    if (camera == null || kIsWeb) return false;
    final isPhone =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return isPhone &&
        camera.description.lensDirection == CameraLensDirection.front;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _stage = _Stage.ready; // detiene el bucle si estuviera en marcha
    _camera?.dispose();
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al irse a segundo plano el sistema puede quitarnos la cámara; soltarla a
    // conciencia evita que la pantalla vuelva en negro.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stop();
    }
  }

  Future<void> _check() async {
    final available = await _service.isAvailable(refresh: true);
    if (!mounted) return;

    if (!available) {
      setState(() {
        _stage = _Stage.unavailable;
        _problem = _service.lastFailure == LipFailureKind.offline
            ? 'No se pudo conectar con el servidor de Code4All. Si estaba en '
                  'reposo tarda hasta un minuto en despertar: espera un '
                  'momento y vuelve a intentarlo.'
            : 'El servidor de Code4All no tiene activa la lectura de labios '
                  'ahora mismo.';
        _problemDetail = _service.lastReason;
      });
      return;
    }

    setState(() => _stage = _Stage.ready);
  }

  Future<void> _start() async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        // Se empieza por la cámara frontal: es con la que uno se ve la boca.
        final front = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );
        _cameraIndex = front >= 0 ? front : 0;
      }

      if (_cameras.isEmpty) {
        _fail('No se encontró ninguna cámara en este dispositivo.');
        return;
      }

      await _openCamera();
      if (!mounted) return;

      _calibration.reset();
      setState(() {
        _stage = _Stage.running;
        _session++;
        _frame = null;
        _history.clear();
      });
      announceForAccessibility(
        context,
        'Cámara encendida. Deja la boca cerrada y relajada un momento.',
      );

      unawaited(_loop(_session));
    } on CameraException catch (error) {
      _fail(_explain(error));
    } on MissingPluginException {
      // Android, iOS, web y Windows tienen cámara; Linux de escritorio no.
      _fail(
        'Esta versión de Code4All no puede abrir la cámara. Ábrelo en el '
        'navegador o en el móvil para usar esta práctica.',
      );
    } catch (error) {
      _fail('No se pudo encender la cámara: $error');
    }
  }

  Future<void> _openCamera() async {
    // Se suelta antes de esperar a la nueva: mientras se enciende, el bucle
    // de fotos no puede pedírsela a una cámara ya liberada.
    final previous = _camera;
    _camera = null;
    await previous?.dispose();

    final controller = CameraController(
      _cameras[_cameraIndex],
      // Media resolución: de sobra para ver una boca de cerca y mucho más
      // ligera de mandar. El servidor no acepta fotos de más de 1 MB.
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    try {
      // Muchas fotos seguidas con el flash automático serían un destello tras
      // otro en una habitación con poca luz.
      await controller.setFlashMode(FlashMode.off);
    } catch (_) {
      // No todas las cámaras tienen flash ni dejan tocarlo.
    }
    _camera = controller;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    try {
      await _openCamera();
    } on CameraException catch (error) {
      _fail(_explain(error));
      return;
    } catch (error) {
      _fail('No se pudo cambiar de cámara: $error');
      return;
    }
    if (mounted) setState(() {});
  }

  void _stop() {
    if (_stage != _Stage.running) return;

    setState(() {
      _stage = _Stage.ready;
      _session++;
      _frame = null;
      _recording = false;
      _clip = [];
    });
    _camera?.dispose();
    _camera = null;
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _session++;
      _problem = message;
      _recording = false;
      _clip = [];
    });
    // Sin esto la luz de la cámara seguiría encendida junto al mensaje de error.
    _camera?.dispose();
    _camera = null;
    announceForAccessibility(context, message);
  }

  /// Toma fotos una y otra vez mientras la cámara esté encendida.
  Future<void> _loop(int session) async {
    while (mounted && _stage == _Stage.running && session == _session) {
      final started = DateTime.now();
      final keepGoing = await _capture();
      if (!keepGoing) return;

      final interval = _recording ? _clipInterval : _liveInterval;
      final left = interval - DateTime.now().difference(started);
      await Future<void>.delayed(left > Duration.zero ? left : Duration.zero);
    }
  }

  /// Devuelve falso si hay que parar del todo.
  Future<bool> _capture() async {
    final camera = _camera;
    // Sin cámara a mano es que se está cambiando por la otra: se espera a la
    // siguiente vuelta. Apagar o salir ya paran el bucle por su cuenta.
    if (camera == null || !camera.value.isInitialized) return true;

    // Mientras se analiza una palabra no hace falta ninguna foto más: en un
    // servidor lento, cada una solo retrasaría la respuesta.
    if (_analyzing) return true;

    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      unawaited(discardCameraPhoto(shot));
      if (!mounted || _stage != _Stage.running) return false;

      if (_recording) {
        _clip.add(bytes);
        if (_clipClock.elapsed >= _maxClip || _clip.length >= _maxClipFrames) {
          unawaited(_finishRecording());
        } else {
          setState(() {}); // Avanza la barra de lo que queda.
        }
      }

      if (!_liveBusy && !_analyzing) unawaited(_sendLive(bytes));
      return true;
    } on CameraException catch (error) {
      // Una foto que estaba en camino al apagar la cámara o cambiarla por la
      // otra no es un fallo: es lo que se pidió.
      if (!identical(camera, _camera)) return true;
      _fail(_explain(error));
      return false;
    } catch (_) {
      // Un fallo suelto de una foto no debería tumbar la sesión.
      return true;
    }
  }

  /// Se espera a la respuesta antes de mandar otra: si el servidor va lento, es
  /// mejor mirar menos veces que acumular peticiones.
  Future<void> _sendLive(Uint8List bytes) async {
    _liveBusy = true;
    final session = _session;
    try {
      final frame = await _service.readFrame(
        bytes,
        neutralWidth: _calibration.neutralWidth,
      );
      if (!mounted || session != _session) return;
      _applyFrame(frame);
    } on LipReadingException catch (error) {
      // Si el problema es del servidor no tiene sentido seguir disparando.
      if (error.kind == LipFailureKind.badImage) return;
      if (mounted && session == _session) _fail(error.message);
    } catch (_) {
      // Una respuesta suelta rara no debería tumbar la sesión.
    } finally {
      _liveBusy = false;
    }
  }

  void _applyFrame(LipFrame? frame) {
    final wasCalibrating = !_calibration.isDone;

    setState(() {
      _frame = frame;
      if (frame != null) {
        _calibration.offer(frame);
        _history.add(frame);
        if (_history.length > _historyLength) _history.removeAt(0);
      }
    });

    if (wasCalibrating && _calibration.isDone) {
      announceForAccessibility(
        context,
        'Listo. Pulsa «Leer una palabra» cuando quieras.',
      );
    }
  }

  void _recalibrate() {
    setState(_calibration.reset);
    announceForAccessibility(context, 'Deja la boca cerrada y relajada.');
  }

  void _startRecording() {
    setState(() {
      _recording = true;
      _clip = [];
      _reading = null;
      _readingProblem = null;
      _clipClock
        ..reset()
        ..start();
    });
    announceForAccessibility(
      context,
      'Te estoy mirando. Di la palabra y pulsa terminar.',
    );
  }

  Future<void> _finishRecording() async {
    if (!_recording) return;

    final frames = _clip;
    _clip = [];
    _clipClock.stop();
    setState(() {
      _recording = false;
      _analyzing = true;
    });

    try {
      final reading = await _service.readClip(
        frames,
        neutralWidth: _calibration.neutralWidth,
      );
      if (!mounted) return;

      setState(() {
        _analyzing = false;
        _reading = reading;
        _lastWordIsGuess = reading.word != null;
        if (reading.word != null) _words.add(reading.word!);
      });
      announceForAccessibility(context, _describe(reading));
    } on LipReadingException catch (error) {
      if (!mounted) return;
      setState(() {
        _analyzing = false;
        _readingProblem = error.message;
      });
      announceForAccessibility(context, error.message);
    }
  }

  String _describe(LipWordReading reading) {
    final word = reading.word;
    if (word != null) return 'Creo que dijiste: $word.';

    return switch (reading.problem) {
      LipReadingProblem.tooShort =>
        'Fue muy corto. Pulsa «Leer una palabra», dila y vuelve a pulsar.',
      LipReadingProblem.noFace =>
        'No vi bien tu cara. Acércate a la cámara y busca más luz.',
      LipReadingProblem.noMovement =>
        'No vi moverse tu boca. Vocaliza un poco más.',
      null =>
        reading.alternatives.isEmpty
            ? 'No reconocí la palabra. Prueba a vocalizar más despacio.'
            : 'No estoy seguro. ¿Era alguna de estas?',
    };
  }

  /// La persona corrige al lector, o elige entre las candidatas si dudó.
  void _pickWord(String word) {
    setState(() {
      if (_lastWordIsGuess && _words.isNotEmpty) _words.removeLast();
      _words.add(word);
      _reading = null;
      _lastWordIsGuess = false;
    });
    announceForAccessibility(context, 'Escrito: $word.');
  }

  void _removeLastWord() {
    setState(() {
      _words.removeLast();
      _reading = null;
      _lastWordIsGuess = false;
    });
  }

  void _clearWords() {
    setState(() {
      _words.clear();
      _reading = null;
      _lastWordIsGuess = false;
    });
  }

  String _explain(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('permission') || code.contains('denied')) {
      return 'Hace falta permiso para usar la cámara. Puedes dárselo desde '
          'los ajustes del dispositivo y volver a intentarlo.';
    }
    if (code.contains('notfound') || code.contains('nocamera')) {
      return 'No se encontró ninguna cámara disponible.';
    }
    return 'La cámara dio un problema: ${error.description ?? error.code}';
  }

  /// El manual tapa la cámara, así que se apaga: seguir mandando fotos sin que
  /// la persona vea lo que se está mirando no tiene sentido ni está bien.
  void _openGuide() {
    _stop();
    Navigator.of(context).push(LipAlphabetGuideScreen.route());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: const GlobalAppBarWidget(title: 'Lectura de labios'),
      body: SafeArea(
        child: Column(
          children: [
            // Aquí el tamaño del texto importa especialmente: las instrucciones
            // se leen sentado frente a la cámara, a cierta distancia.
            const AccessibilityToolbar(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: AppMetrics.pagePadding(constraints.maxWidth),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppMetrics.maxContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _body(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    return switch (_stage) {
      _Stage.checking => [
        const _Message(
          busy: true,
          text: 'Comprobando si la lectura de labios está disponible…',
        ),
      ],
      _Stage.unavailable => [
        _Message(
          text: _problem,
          detail: _problemDetail,
          icon: Icons.cloud_off,
          error: true,
        ),
        const SizedBox(height: AppMetrics.gap),
        _retryButton(),
        const SizedBox(height: AppMetrics.gap),
        // El manual se puede leer aunque la cámara no funcione ahora.
        Center(child: _GuideButton(onPressed: _openGuide)),
      ],
      _Stage.failed => [
        _Message(text: _problem, icon: Icons.error_outline, error: true),
        const SizedBox(height: AppMetrics.gap),
        _retryButton(),
        const SizedBox(height: AppMetrics.gap),
        Center(child: _GuideButton(onPressed: _openGuide)),
      ],
      _Stage.ready || _Stage.running => _sessionView(),
    };
  }

  Widget _retryButton() => Center(
    child: FilledButton.icon(
      onPressed: () {
        setState(() => _stage = _Stage.checking);
        _check();
      },
      style: FilledButton.styleFrom(
        backgroundColor: context.messageColors.infoBackground,
        foregroundColor: context.messageColors.infoForeground,
        minimumSize: const Size(0, AppMetrics.minTapTarget),
      ),
      icon: const Icon(Icons.refresh),
      label: const Text('Volver a intentarlo'),
    ),
  );

  List<Widget> _sessionView() {
    final running = _stage == _Stage.running;
    final neutral = _calibration.neutralWidth ?? _defaultNeutralWidth;
    final camera = _camera;

    return [
      const _Explanation(),
      const SizedBox(height: AppMetrics.gap),
      Center(child: _GuideButton(onPressed: _openGuide)),
      const SizedBox(height: AppMetrics.sectionGap),
      _Preview(
        camera: camera,
        running: running,
        frame: _frame,
        mirror: _mirrorOverlay,
      ),
      const SizedBox(height: AppMetrics.gap),
      _cameraControls(running),
      if (running) ...[
        const SizedBox(height: AppMetrics.sectionGap),
        _LiveBox(
          frame: _frame,
          calibration: _calibration,
          onRecalibrate: _recalibrate,
        ),
        const SizedBox(height: AppMetrics.gap),
        _MovementBox(
          frame: _frame,
          history: _history,
          neutralWidth: neutral,
        ),
        const SizedBox(height: AppMetrics.sectionGap),
        _recordControl(),
      ],
      if (_reading != null || _readingProblem != null) ...[
        const SizedBox(height: AppMetrics.gap),
        _ReadingBox(
          message: _readingProblem ?? _describe(_reading!),
          reading: _reading,
          onPick: _pickWord,
        ),
      ],
      const SizedBox(height: AppMetrics.gap),
      _WrittenBox(
        words: _words,
        onRemoveLast: _words.isEmpty ? null : _removeLastWord,
        onClear: _words.isEmpty ? null : _clearWords,
      ),
      const SizedBox(height: AppMetrics.gap),
      _Vocabulary(words: _service.words),
    ];
  }

  Widget _cameraControls(bool running) {
    final messages = context.messageColors;

    return Wrap(
      spacing: AppMetrics.gap,
      runSpacing: AppMetrics.gap,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: running ? _stop : _start,
          style: FilledButton.styleFrom(
            backgroundColor: running
                ? messages.dangerBackground
                : messages.warningBackground,
            foregroundColor: messages.infoForeground,
            minimumSize: const Size(0, AppMetrics.minTapTarget),
          ),
          icon: Icon(running ? Icons.stop : Icons.photo_camera),
          label: Text(running ? 'Apagar la cámara' : 'Encender la cámara'),
        ),
        if (running && _cameras.length > 1)
          OutlinedButton.icon(
            onPressed: _switchCamera,
            style: _outlinedButton(context),
            icon: const Icon(Icons.cameraswitch),
            label: const Text('Cambiar de cámara'),
          ),
      ],
    );
  }

  /// Leer una palabra: el botón grande, y mientras tanto lo que está pasando.
  Widget _recordControl() {
    final colors = context.colorScheme;

    if (_analyzing) {
      return Column(
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: AppMetrics.gap),
          Text(
            'Leyendo tu boca…',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.5, color: colors.onSurface),
          ),
        ],
      );
    }

    final ready = _calibration.isDone;
    final elapsed =
        _clipClock.elapsedMilliseconds / _maxClip.inMilliseconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_recording) ...[
          LinearProgressIndicator(
            value: elapsed.clamp(0.0, 1.0),
            minHeight: 8,
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppMetrics.pillRadius),
          ),
          const SizedBox(height: AppMetrics.gap),
        ],
        Center(
          child: FilledButton.icon(
            onPressed: !ready
                ? null
                : _recording
                ? _finishRecording
                : _startRecording,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppMetrics.minTapTarget + 8),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: Icon(_recording ? Icons.check : Icons.record_voice_over),
            label: Text(_recording ? 'Terminar' : 'Leer una palabra'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _recording
              ? 'Di la palabra despacio, exagerando un poco la boca, y pulsa '
                    '«Terminar». La barra es el tiempo máximo: no hace falta '
                    'llenarla.'
              : 'Pulsa, di una palabra de la lista despacio y vuelve a pulsar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

ButtonStyle _outlinedButton(BuildContext context) {
  final accent = AppContrast.readableOn(
    context.messageColors.infoForeground,
    context.colorScheme.surface,
    AppContrast.text,
  );
  return OutlinedButton.styleFrom(
    foregroundColor: accent,
    side: BorderSide(color: accent),
    minimumSize: const Size(0, AppMetrics.minTapTarget),
  );
}

class _GuideButton extends StatelessWidget {
  const _GuideButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: 'Abre el manual de cómo se hace cada letra con la boca',
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: _outlinedButton(context),
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('Las letras con la boca'),
      ),
    );
  }
}

/// Qué es esto y qué no es, antes de encender nada.
class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mira de frente a la cámara, con buena luz. Verás tus labios '
            'dibujados y cómo se mueven. Después puedes decir una palabra para '
            'que la app la lea.',
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          const _Note(
            icon: Icons.visibility_outlined,
            text:
                'Los labios no lo dicen todo: muchas consonantes se hacen por '
                'dentro de la boca y no se ven. Por eso solo lee palabras de '
                'una lista y, si duda, te deja elegir. Sirve para practicar, '
                'no para evaluar a nadie.',
          ),
          const SizedBox(height: 8),
          const _Note(
            icon: Icons.lock_outline,
            text:
                'Las fotos se analizan al momento y se descartan. No se graba '
                'vídeo ni se guarda ninguna imagen.',
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.5, height: 1.4, color: color),
          ),
        ),
      ],
    );
  }
}

/// Lo que ve la cámara, con los labios dibujados encima, o un hueco que explica
/// que está apagada.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.camera,
    required this.running,
    required this.frame,
    required this.mirror,
  });

  final CameraController? camera;
  final bool running;
  final LipFrame? frame;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final messages = context.messageColors;
    final controller = camera;
    final ready =
        running && controller != null && controller.value.isInitialized;

    return Semantics(
      label: ready
          ? 'Vista de la cámara, con tus labios dibujados encima.'
          : 'La cámara está apagada.',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        child: ExcludeSemantics(
          child: ready
              // Con su proporción de verdad, sin forzar otra: los labios se
              // dibujan en coordenadas de la foto y no coincidirían.
              ? ColoredBox(
                  color: Colors.black,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: Center(
                      child: CameraPreview(
                        controller,
                        child: CustomPaint(
                          painter: LipOverlayPainter(
                            frame: frame,
                            mirror: mirror,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              // Más bajo que la cámara encendida: si no, el botón de encenderla
              // queda fuera de la pantalla.
              : Container(
                  height: 200,
                  color: messages.dangerBackground,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.no_photography_outlined,
                        size: 48,
                        color: messages.infoForeground,
                      ),
                      const SizedBox(height: AppMetrics.gap),
                      Text(
                        'La cámara está apagada',
                        style: TextStyle(
                          fontSize: 15,
                          color: messages.infoForeground,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// La forma que tiene la boca ahora mismo.
class _LiveBox extends StatelessWidget {
  const _LiveBox({
    required this.frame,
    required this.calibration,
    required this.onRecalibrate,
  });

  final LipFrame? frame;
  final LipCalibration calibration;
  final VoidCallback onRecalibrate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final current = frame;

    final String detail;
    if (current == null) {
      detail = 'Todavía no veo tu cara. Colócate de frente, con buena luz.';
    } else if (!calibration.isDone) {
      detail = 'Ajustando a tu cara: deja la boca cerrada y relajada.';
    } else {
      detail = current.shape.description;
    }

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sin región viva: la forma cambia varias veces por segundo y un
          // lector de pantalla no podría seguirla. Lo importante, la palabra
          // leída, sí se anuncia.
          Text(
            detail,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.4,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          if (!calibration.isDone && current != null)
            LinearProgressIndicator(
              value: calibration.progress,
              minHeight: 6,
              color: colors.primary,
              borderRadius: BorderRadius.circular(AppMetrics.pillRadius),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final shape in LipShape.values)
                  _ShapeChip(
                    shape: shape,
                    active: calibration.isDone && current?.shape == shape,
                  ),
              ],
            ),
          if (calibration.isDone) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRecalibrate,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  minimumSize: const Size(0, AppMetrics.minTapTarget),
                ),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Volver a ajustar'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShapeChip extends StatelessWidget {
  const _ShapeChip({required this.shape, required this.active});

  final LipShape shape;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final background = active ? colors.primary : colors.surface;
    final foreground = active ? colors.onPrimary : colors.onSurface;

    return Semantics(
      selected: active,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: active ? colors.primary : colors.outline),
          borderRadius: BorderRadius.circular(AppMetrics.radius),
        ),
        child: Text(
          shape.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

/// La boca ampliada y una gráfica de cómo se ha movido.
class _MovementBox extends StatelessWidget {
  const _MovementBox({
    required this.frame,
    required this.history,
    required this.neutralWidth,
  });

  final LipFrame? frame;
  final List<LipFrame> history;
  final double neutralWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final messages = context.messageColors;

    Color readable(Color color) =>
        AppContrast.readableOn(color, colors.surface, AppContrast.ui);
    final openingColor = readable(colors.primary);
    final widthColor = readable(messages.infoForeground);
    final roundingColor = readable(colors.tertiary);

    return Semantics(
      label:
          'Tu boca ampliada y una gráfica de cómo se ha movido en los últimos '
          'segundos.',
      image: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppMetrics.gap),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.outline),
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final zoom = Container(
                height: 130,
                width: constraints.maxWidth < 420 ? double.infinity : 180,
                decoration: BoxDecoration(
                  color: messages.infoBackground,
                  borderRadius: BorderRadius.circular(AppMetrics.radius),
                ),
                child: CustomPaint(painter: MouthZoomPainter(frame: frame)),
              );
              final chart = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: LipMovementPainter(
                        history: history,
                        neutralWidth: neutralWidth,
                        openingColor: openingColor,
                        widthColor: widthColor,
                        roundingColor: roundingColor,
                        gridColor: colors.outlineVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _Legend('Apertura', openingColor, thickness: 4),
                      _Legend('Ancho', widthColor, thickness: 2),
                      _Legend('Redondez', roundingColor, dots: true),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 420) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    zoom,
                    const SizedBox(height: AppMetrics.gap),
                    chart,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  zoom,
                  const SizedBox(width: AppMetrics.gap),
                  Expanded(child: chart),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.text, this.color, {this.thickness = 2, this.dots = false});

  final String text;
  final Color color;
  final double thickness;
  final bool dots;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dots)
          for (var i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
        else
          Container(width: 18, height: thickness, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Qué se leyó en la última palabra y, si cabe la duda, qué más podría ser.
class _ReadingBox extends StatelessWidget {
  const _ReadingBox({
    required this.message,
    required this.reading,
    required this.onPick,
  });

  final String message;
  final LipWordReading? reading;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final current = reading;
    final tone = context.messageColors.tone(
      current?.word != null ? MessageThemeTone.success : MessageThemeTone.info,
    );
    final foreground = AppContrast.readableOn(
      tone.foreground,
      tone.background,
      AppContrast.text,
    );
    final candidates = current?.alternatives ?? const <String>[];
    final seen = current?.shapes ?? const <LipShape>[];

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          if (seen.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Formas que vi: ${seen.map((shape) => shape.code).join(' → ')}',
              style: TextStyle(fontSize: 13.5, color: foreground),
            ),
          ],
          if (candidates.isNotEmpty) ...[
            const SizedBox(height: AppMetrics.gap),
            if (current?.word != null) ...[
              Text(
                '¿No era esa? También podría ser:',
                style: TextStyle(fontSize: 13.5, color: foreground),
              ),
              const SizedBox(height: 6),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in candidates)
                  OutlinedButton(
                    onPressed: () => onPick(word),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foreground,
                      side: BorderSide(color: foreground),
                      minimumSize: const Size(0, AppMetrics.minTapTarget),
                    ),
                    child: Text(word),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Lo que se lleva escrito.
class _WrittenBox extends StatelessWidget {
  const _WrittenBox({
    required this.words,
    required this.onRemoveLast,
    required this.onClear,
  });

  final List<String> words;
  final VoidCallback? onRemoveLast;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Llevas escrito',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            words.isEmpty ? 'Nada todavía' : words.join(' '),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: words.isEmpty ? colors.onSurfaceVariant : colors.onSurface,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          Wrap(
            spacing: AppMetrics.gap,
            runSpacing: AppMetrics.gap,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onRemoveLast,
                style: _outlinedButton(context),
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('Borrar la última'),
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                style: _outlinedButton(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Empezar de nuevo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Las palabras que sabe leer: decir otra nunca va a funcionar, y hay que
/// poder saberlo sin probar.
class _Vocabulary extends StatelessWidget {
  const _Vocabulary({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    if (words.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        textColor: colors.onSurface,
        collapsedTextColor: colors.onSurface,
        iconColor: colors.onSurface,
        collapsedIconColor: colors.onSurface,
        title: Text('Palabras que sé leer (${words.length})'),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppMetrics.gap,
          0,
          AppMetrics.gap,
          AppMetrics.gap,
        ),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(
            words.join(', '),
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje a pantalla completa, para esperar o para explicar un problema.
class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    this.detail,
    this.icon,
    this.busy = false,
    this.error = false,
  });

  final String text;

  /// Lo que dijo el servidor, para quien lo mantiene.
  final String? detail;
  final IconData? icon;
  final bool busy;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final tone = context.messageColors.tone(
      error ? MessageThemeTone.danger : MessageThemeTone.info,
    );
    final foreground = AppContrast.readableOn(
      tone.foreground,
      tone.background,
      AppContrast.text,
    );

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppMetrics.sectionGap),
        decoration: BoxDecoration(
          color: tone.background,
          border: Border.all(color: foreground),
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        ),
        child: Column(
          children: [
            if (busy)
              CircularProgressIndicator(color: foreground)
            else if (icon != null)
              Icon(icon, size: 40, color: foreground),
            const SizedBox(height: AppMetrics.gap),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.5, height: 1.45, color: foreground),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppMetrics.gap),
              Text(
                'Detalle técnico: $detail',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: foreground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
