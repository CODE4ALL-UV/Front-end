import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_dictation.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';

import 'section_theme.dart';

/// En qué punto está la pantalla.
enum _Stage { checking, unavailable, ready, running, failed }

/// Lee con la cámara las letras que la persona hace con la mano.
///
/// Toma una foto cada poco, le pregunta al servidor dónde están los dedos y
/// decide la letra aquí mismo, con la misma tabla que usa el panel para
/// dibujarla. Las letras que se sostienen quietas se van juntando en un texto.
///
/// **Qué reconoce y qué no.** Es el alfabeto manual —dactilología—, que es
/// deletrear letra a letra. No es Lengua de Señas Colombiana: la LSC tiene
/// señas propias y gramática propia, y esto no las entiende. Además, las
/// letras que llevan movimiento (J, Z, Ñ) no se pueden ver en una foto, y
/// algunas parejas se hacen tan parecido que se enseñan las dos en lugar de
/// elegir una. Sirve para practicar, no para evaluar a nadie.
///
/// **Privacidad.** Las fotos van al servidor de la propia aplicación, se
/// analizan en memoria y se descartan. No se graba vídeo, no se guarda ninguna
/// imagen y no se manda nada a servicios de terceros. La cámara solo se
/// enciende cuando la persona pulsa el botón, nunca sola.
class SignCameraScreen extends StatefulWidget {
  const SignCameraScreen({super.key, this.targetLetter, this.service});

  /// Letra que se quiere practicar.
  ///
  /// Si viene, la pantalla acompaña con pistas hasta conseguirla. Si no,
  /// deletrea libremente lo que vea.
  final String? targetLetter;

  /// Se puede inyectar en las pruebas.
  final SignRecognitionService? service;

  @override
  State<SignCameraScreen> createState() => _SignCameraScreenState();
}

class _SignCameraScreenState extends State<SignCameraScreen>
    with WidgetsBindingObserver {
  /// Cada cuánto se mira la mano.
  ///
  /// Unas dos veces por segundo. Más rápido no ayuda —la mano no cambia tan
  /// deprisa— y carga el servidor y la batería para nada.
  static const Duration _interval = Duration(milliseconds: 550);

  late final SignRecognitionService _service =
      widget.service ?? SignRecognitionService();

  final SignDictation _dictation = SignDictation();

  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  _Stage _stage = _Stage.checking;
  String _problem = '';
  SignReading _reading = SignRecognitionService.noHand;
  bool _achieved = false;

  bool get _isPractice => widget.targetLetter != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final available = await _service.isAvailable();
    if (!mounted) return;

    if (!available) {
      setState(() {
        _stage = _Stage.unavailable;
        _problem =
            'El reconocimiento de señas no está disponible ahora mismo. '
            'Necesita que el servidor de Code4All esté encendido.';
      });
      return;
    }

    setState(() => _stage = _Stage.ready);
  }

  Future<void> _start() async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        // Se empieza por la cámara frontal: es con la que uno se ve la mano.
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

      setState(() => _stage = _Stage.running);
      announceForAccessibility(
        context,
        _isPractice
            ? 'Cámara encendida. Haz la letra ${widget.targetLetter} con la mano.'
            : 'Cámara encendida. Deletrea con la mano.',
      );

      unawaited(_loop());
    } on CameraException catch (error) {
      _fail(_explain(error));
    } on MissingPluginException {
      // Android, iOS, web y Windows tienen cámara; Linux de escritorio no.
      // Vale más decirlo que dejar a alguien peleándose con los permisos.
      _fail(
        'Esta versión de Code4All no puede abrir la cámara. Ábrelo en el '
        'navegador o en el móvil para usar esta práctica.',
      );
    } catch (error) {
      _fail('No se pudo encender la cámara: $error');
    }
  }

  Future<void> _openCamera() async {
    await _camera?.dispose();

    final controller = CameraController(
      _cameras[_cameraIndex],
      // Media resolución: de sobra para ver una mano y mucho más ligera de
      // mandar que una foto entera.
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    _camera = controller;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _openCamera();
    if (mounted) setState(() {});
  }

  void _stop() {
    if (_stage != _Stage.running) return;

    setState(() {
      _stage = _Stage.ready;
      _reading = SignRecognitionService.noHand;
    });
    _camera?.dispose();
    _camera = null;
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _problem = message;
    });
    announceForAccessibility(context, message);
  }

  /// Mira la mano una y otra vez mientras la cámara esté encendida.
  ///
  /// Se espera a que termine una foto antes de pedir la siguiente: si el
  /// servidor va lento, es mejor mirar menos veces que acumular peticiones.
  Future<void> _loop() async {
    while (mounted && _stage == _Stage.running) {
      final started = DateTime.now();
      final keepGoing = await _readFrame();
      if (!keepGoing) return;

      final left = _interval - DateTime.now().difference(started);
      if (left > Duration.zero) await Future<void>.delayed(left);
    }
  }

  /// Devuelve falso si hay que parar del todo.
  Future<bool> _readFrame() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return false;

    try {
      final shot = await camera.takePicture();
      final bytes = await shot.readAsBytes();
      if (!mounted || _stage != _Stage.running) return false;

      final reading = await _service.read(bytes);
      if (!mounted || _stage != _Stage.running) return false;

      _apply(reading);
      return true;
    } on SignRecognitionException catch (error) {
      // Si el problema es del servidor no tiene sentido seguir disparando.
      if (error.kind == SignFailureKind.badImage) return true;
      _fail(error.message);
      return false;
    } on CameraException catch (error) {
      _fail(_explain(error));
      return false;
    } catch (_) {
      // Un fallo suelto de una foto no debería tumbar la sesión.
      return true;
    }
  }

  void _apply(SignReading reading) {
    final event = _dictation.offer(reading);
    final target = widget.targetLetter;

    setState(() {
      _reading = reading;
      if (_isPractice && reading.isConfident && reading.letter == target) {
        _achieved = true;
      }
    });

    if (_isPractice) {
      if (_achieved && event != SignDictationEvent.nothing) {
        announceForAccessibility(context, '¡Esa es la $target!');
      }
      return;
    }

    if (event == SignDictationEvent.accepted) {
      announceForAccessibility(
        context,
        'Letra ${_dictation.text.characters.last}. '
        'Llevas ${_dictation.text}',
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.appBar,
        foregroundColor: palette.onAccent,
        title: Text(
          _isPractice ? 'Practica la ${widget.targetLetter}' : 'Lee mi mano',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: SectionMetrics.pagePadding(constraints.maxWidth),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: SectionMetrics.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _body(palette),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _body(SectionPalette palette) {
    return switch (_stage) {
      _Stage.checking => [
        _Message(
          palette: palette,
          busy: true,
          text: 'Comprobando si el reconocimiento está disponible…',
        ),
      ],
      _Stage.unavailable => [
        _Message(palette: palette, text: _problem, icon: Icons.cloud_off),
        const SizedBox(height: SectionMetrics.gap),
        _retryButton(palette),
      ],
      _Stage.failed => [
        _Message(palette: palette, text: _problem, icon: Icons.error_outline),
        const SizedBox(height: SectionMetrics.gap),
        _retryButton(palette),
      ],
      _Stage.ready || _Stage.running => _session(palette),
    };
  }

  Widget _retryButton(SectionPalette palette) => Center(
    child: FilledButton.icon(
      onPressed: () {
        setState(() => _stage = _Stage.checking);
        _check();
      },
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        minimumSize: const Size(0, SectionMetrics.minTapTarget),
      ),
      icon: const Icon(Icons.refresh),
      label: const Text('Volver a intentarlo'),
    ),
  );

  List<Widget> _session(SectionPalette palette) {
    final running = _stage == _Stage.running;

    return [
      _Explanation(palette: palette, target: widget.targetLetter),
      const SizedBox(height: SectionMetrics.sectionGap),
      _Preview(palette: palette, camera: _camera, running: running),
      const SizedBox(height: SectionMetrics.sectionGap),
      if (running) ...[
        _ReadingBox(
          palette: palette,
          reading: _reading,
          dictation: _dictation,
          target: widget.targetLetter,
          achieved: _achieved,
        ),
        const SizedBox(height: SectionMetrics.gap),
      ],
      _controls(palette, running),
    ];
  }

  Widget _controls(SectionPalette palette, bool running) {
    final buttons = <Widget>[
      FilledButton.icon(
        onPressed: running ? _stop : _start,
        style: FilledButton.styleFrom(
          backgroundColor: running ? palette.danger : palette.accent,
          foregroundColor: palette.onAccent,
          minimumSize: const Size(0, SectionMetrics.minTapTarget),
        ),
        icon: Icon(running ? Icons.stop : Icons.photo_camera),
        label: Text(running ? 'Apagar la cámara' : 'Encender la cámara'),
      ),
      if (running && _cameras.length > 1)
        OutlinedButton.icon(
          onPressed: _switchCamera,
          style: _outlined(palette),
          icon: const Icon(Icons.cameraswitch),
          label: const Text('Cambiar de cámara'),
        ),
      if (!_isPractice && running) ...[
        OutlinedButton.icon(
          onPressed: () => setState(_dictation.addSpace),
          style: _outlined(palette),
          icon: const Icon(Icons.space_bar),
          label: const Text('Espacio'),
        ),
        OutlinedButton.icon(
          onPressed: _dictation.isEmpty
              ? null
              : () => setState(_dictation.backspace),
          style: _outlined(palette),
          icon: const Icon(Icons.backspace_outlined),
          label: const Text('Borrar'),
        ),
        OutlinedButton.icon(
          onPressed: _dictation.isEmpty
              ? null
              : () => setState(_dictation.clear),
          style: _outlined(palette),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Empezar de nuevo'),
        ),
      ],
    ];

    return Wrap(
      spacing: SectionMetrics.gap,
      runSpacing: SectionMetrics.gap,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  ButtonStyle _outlined(SectionPalette palette) => OutlinedButton.styleFrom(
    foregroundColor: palette.accent,
    side: BorderSide(color: palette.border),
    minimumSize: const Size(0, SectionMetrics.minTapTarget),
  );
}

/// Qué es esto y qué no es, antes de encender nada.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.palette, required this.target});

  final SectionPalette palette;
  final String? target;

  @override
  Widget build(BuildContext context) {
    final text = target != null
        ? 'Coloca la mano delante de la cámara y haz la letra $target. '
              'Te iré diciendo qué te falta para conseguirla.'
        : 'Coloca la mano delante de la cámara y ve haciendo las letras. '
              'Mantén cada una quieta un momento para que cuente.';

    return Container(
      padding: const EdgeInsets.all(SectionMetrics.gap),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: SectionMetrics.gap),
          _Note(
            palette: palette,
            icon: Icons.sign_language,
            text:
                'Esto es dactilología: el alfabeto que se deletrea letra a '
                'letra. No es Lengua de Señas Colombiana, que tiene señas y '
                'gramática propias.',
          ),
          const SizedBox(height: 8),
          _Note(
            palette: palette,
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
  const _Note({required this.palette, required this.icon, required this.text});

  final SectionPalette palette;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: palette.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lo que ve la cámara, o un hueco que explica que está apagada.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.palette,
    required this.camera,
    required this.running,
  });

  final SectionPalette palette;
  final CameraController? camera;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final controller = camera;
    final ready =
        running && controller != null && controller.value.isInitialized;

    return Semantics(
      label: ready
          ? 'Vista de la cámara. Coloca la mano dentro del recuadro.'
          : 'La cámara está apagada.',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ExcludeSemantics(
            child: ready
                ? CameraPreview(controller)
                : Container(
                    color: palette.surfaceAlt,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_photography_outlined,
                          size: 48,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(height: SectionMetrics.gap),
                        Text(
                          'La cámara está apagada',
                          style: TextStyle(
                            fontSize: 15,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Qué se está leyendo ahora mismo y qué se lleva deletreado.
class _ReadingBox extends StatelessWidget {
  const _ReadingBox({
    required this.palette,
    required this.reading,
    required this.dictation,
    required this.target,
    required this.achieved,
  });

  final SectionPalette palette;
  final SignReading reading;
  final SignDictation dictation;
  final String? target;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final letter = reading.letter;
    final holding = dictation.holding;

    final String headline;
    final String detail;
    final Color tone;

    if (target != null) {
      if (achieved) {
        headline = target!;
        detail = '¡Esa es la $target!';
        tone = palette.success;
      } else if (letter == null) {
        headline = '—';
        detail = 'Todavía no veo tu mano con claridad.';
        tone = palette.textSecondary;
      } else {
        headline = letter;
        detail = HandLandmarkClassifier.hint(reading.observed, target!);
        tone = palette.warning;
      }
    } else if (reading.isAmbiguous) {
      headline = [letter!, ...reading.alternatives].join(' o ');
      detail =
          'Estas letras se hacen casi igual, así que no me atrevo a elegir. '
          'No la doy por buena.';
      tone = palette.warning;
    } else if (letter == null) {
      headline = '—';
      detail = holding == null
          ? 'Todavía no veo tu mano con claridad.'
          : 'Sujeta la mano un poco más quieta.';
      tone = palette.textSecondary;
    } else {
      headline = letter;
      detail = reading.isConfident
          ? 'Mantenla quieta para que cuente.'
          : 'Casi. Acerca un poco la mano o mejora la luz.';
      tone = reading.isConfident ? palette.success : palette.textSecondary;
    }

    return Semantics(
      liveRegion: true,
      label: '$headline. $detail',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(SectionMetrics.gap),
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LetterBadge(
                    palette: palette,
                    letter: headline,
                    tone: tone,
                    progress: dictation.progress,
                  ),
                  const SizedBox(width: SectionMetrics.gap),
                  Expanded(
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (target == null) ...[
                const SizedBox(height: SectionMetrics.gap),
                Divider(color: palette.border, height: 1),
                const SizedBox(height: SectionMetrics.gap),
                Text(
                  'Llevas escrito',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dictation.isEmpty ? 'Nada todavía' : dictation.text,
                  style: TextStyle(
                    fontSize: 24,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: dictation.isEmpty
                        ? palette.textSecondary
                        : palette.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// La letra grande, con un aro que se llena mientras se sostiene.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge({
    required this.palette,
    required this.letter,
    required this.tone,
    required this.progress,
  });

  final SectionPalette palette;
  final String letter;
  final Color tone;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: progress == 0 ? null : progress,
              strokeWidth: 5,
              backgroundColor: palette.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          Text(
            letter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: letter.length > 3 ? 15 : 30,
              fontWeight: FontWeight.w800,
              color: tone,
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
    required this.palette,
    required this.text,
    this.icon,
    this.busy = false,
  });

  final SectionPalette palette;
  final String text;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(SectionMetrics.sectionGap),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
        ),
        child: Column(
          children: [
            if (busy)
              CircularProgressIndicator(color: palette.accent)
            else if (icon != null)
              Icon(icon, size: 40, color: palette.textSecondary),
            const SizedBox(height: SectionMetrics.gap),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.45,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las letras que esta pantalla puede comprobar de verdad.
///
/// Las que llevan movimiento se quedan fuera a propósito: ofrecer practicar
/// una letra que nunca se va a dar por buena solo frustra.
List<String> practicableLetters() => [
  for (final entry in signAlphabet.entries)
    if (!entry.value.hasMotion) entry.key,
];
