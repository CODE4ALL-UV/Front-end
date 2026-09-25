import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_code4all/data/services/sign_recognition_service.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_alphabet.dart';
import 'package:flutter_code4all/domain/models/sign_language/hand_landmark_classifier.dart';
import 'package:flutter_code4all/domain/models/sign_language/sign_dictation.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';

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
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;

    return Scaffold(
      backgroundColor: appColorScheme.surface,
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: SafeArea(
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
    );
  }

  List<Widget> _body() {
    return switch (_stage) {
      _Stage.checking => [
        _Message(
          busy: true,
          text: 'Comprobando si el reconocimiento está disponible…',
        ),
      ],
      _Stage.unavailable => [
        _Message(text: _problem, icon: Icons.cloud_off),
        const SizedBox(height: AppMetrics.gap),
        _retryButton(Theme.of(context)),
      ],
      _Stage.failed => [
        _Message(text: _problem, icon: Icons.error_outline),
        const SizedBox(height: AppMetrics.gap),
        _retryButton(Theme.of(context)),
      ],
      _Stage.ready || _Stage.running => _session(),
    };
  }

  Widget _retryButton(ThemeData appTheme) => Center(
    child: FilledButton.icon(
      onPressed: () {
        setState(() => _stage = _Stage.checking);
        _check();
      },
      style: FilledButton.styleFrom(
        backgroundColor: appTheme
            .extension<ActivityThemeColors>()!
            .infoBackground,
        foregroundColor: appTheme.extension<ActivityThemeColors>()!.infoText,
        minimumSize: const Size(0, AppMetrics.minTapTarget),
      ),
      icon: const Icon(Icons.refresh),
      label: const Text('Volver a intentarlo'),
    ),
  );

  List<Widget> _session() {
    final running = _stage == _Stage.running;

    return [
      _Explanation(target: widget.targetLetter),
      const SizedBox(height: AppMetrics.sectionGap),
      _Preview(camera: _camera, running: running),
      const SizedBox(height: AppMetrics.sectionGap),
      if (running) ...[
        _ReadingBox(
          reading: _reading,
          dictation: _dictation,
          target: widget.targetLetter,
          achieved: _achieved,
        ),
        const SizedBox(height: AppMetrics.gap),
      ],
      _controls(running),
    ];
  }

  Widget _controls(bool running) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final buttons = <Widget>[
      FilledButton.icon(
        onPressed: running ? _stop : _start,
        style: FilledButton.styleFrom(
          backgroundColor: running
              ? appSemanticColors.dangerBackground
              : appSemanticColors.warningBackground,
          foregroundColor: appSemanticColors.infoText,
          minimumSize: const Size(0, AppMetrics.minTapTarget),
        ),
        icon: Icon(running ? Icons.stop : Icons.photo_camera),
        label: Text(running ? 'Apagar la cámara' : 'Encender la cámara'),
      ),
      if (running && _cameras.length > 1)
        OutlinedButton.icon(
          onPressed: _switchCamera,
          style: _outlined(Theme.of(context)),
          icon: const Icon(Icons.cameraswitch),
          label: const Text('Cambiar de cámara'),
        ),
      if (!_isPractice && running) ...[
        OutlinedButton.icon(
          onPressed: () => setState(_dictation.addSpace),
          style: _outlined(Theme.of(context)),
          icon: const Icon(Icons.space_bar),
          label: const Text('Espacio'),
        ),
        OutlinedButton.icon(
          onPressed: _dictation.isEmpty
              ? null
              : () => setState(_dictation.backspace),
          style: _outlined(Theme.of(context)),
          icon: const Icon(Icons.backspace_outlined),
          label: const Text('Borrar'),
        ),
        OutlinedButton.icon(
          onPressed: _dictation.isEmpty
              ? null
              : () => setState(_dictation.clear),
          style: _outlined(Theme.of(context)),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Empezar de nuevo'),
        ),
      ],
    ];

    return Wrap(
      spacing: AppMetrics.gap,
      runSpacing: AppMetrics.gap,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }

  ButtonStyle _outlined(ThemeData appTheme) => OutlinedButton.styleFrom(
    foregroundColor: appTheme.extension<ActivityThemeColors>()!.infoText,
    side: BorderSide(
      color: appTheme.extension<ActivityThemeColors>()!.infoBorder,
    ),
    minimumSize: const Size(0, AppMetrics.minTapTarget),
  );
}

/// Qué es esto y qué no es, antes de encender nada.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.target});

  final String? target;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final text = target != null
        ? 'Coloca la mano delante de la cámara y haz la letra $target. '
              'Te iré diciendo qué te falta para conseguirla.'
        : 'Coloca la mano delante de la cámara y ve haciendo las letras. '
              'Mantén cada una quieta un momento para que cuente.';

    return Container(
      padding: const EdgeInsets.all(AppMetrics.gap),
      decoration: BoxDecoration(
        color: appSemanticColors.dangerBackground,
        border: Border.all(color: appSemanticColors.infoBorder),
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              color: appSemanticColors.infoText,
            ),
          ),
          const SizedBox(height: AppMetrics.gap),
          _Note(
            icon: Icons.sign_language,
            text:
                'Esto es dactilología: el alfabeto que se deletrea letra a '
                'letra. No es Lengua de Señas Colombiana, que tiene señas y '
                'gramática propias.',
          ),
          const SizedBox(height: 8),
          _Note(
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
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: appSemanticColors.infoText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: appSemanticColors.infoText,
            ),
          ),
        ),
      ],
    );
  }
}

/// Lo que ve la cámara, o un hueco que explica que está apagada.
class _Preview extends StatelessWidget {
  const _Preview({required this.camera, required this.running});

  final CameraController? camera;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final controller = camera;
    final ready =
        running && controller != null && controller.value.isInitialized;

    return Semantics(
      label: ready
          ? 'Vista de la cámara. Coloca la mano dentro del recuadro.'
          : 'La cámara está apagada.',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ExcludeSemantics(
            child: ready
                ? CameraPreview(controller)
                : Container(
                    color: appSemanticColors.dangerBackground,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.no_photography_outlined,
                          size: 48,
                          color: appSemanticColors.infoText,
                        ),
                        const SizedBox(height: AppMetrics.gap),
                        Text(
                          'La cámara está apagada',
                          style: TextStyle(
                            fontSize: 15,
                            color: appSemanticColors.infoText,
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
    required this.reading,
    required this.dictation,
    required this.target,
    required this.achieved,
  });

  final SignReading reading;
  final SignDictation dictation;
  final String? target;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appColorScheme = appTheme.colorScheme;
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
    final letter = reading.letter;
    final holding = dictation.holding;

    final String headline;
    final String detail;
    final Color tone;

    if (target != null) {
      if (achieved) {
        headline = target!;
        detail = '¡Esa es la $target!';
        tone = appSemanticColors.successBackground;
      } else if (letter == null) {
        headline = '—';
        detail = 'Todavía no veo tu mano con claridad.';
        tone = appSemanticColors.infoText;
      } else {
        headline = letter;
        detail = HandLandmarkClassifier.hint(reading.observed, target!);
        tone = appSemanticColors.warningBackground;
      }
    } else if (reading.isAmbiguous) {
      headline = [letter!, ...reading.alternatives].join(' o ');
      detail =
          'Estas letras se hacen casi igual, así que no me atrevo a elegir. '
          'No la doy por buena.';
      tone = appSemanticColors.warningBackground;
    } else if (letter == null) {
      headline = '—';
      detail = holding == null
          ? 'Todavía no veo tu mano con claridad.'
          : 'Sujeta la mano un poco más quieta.';
      tone = appSemanticColors.infoText;
    } else {
      headline = letter;
      detail = reading.isConfident
          ? 'Mantenla quieta para que cuente.'
          : 'Casi. Acerca un poco la mano o mejora la luz.';
      tone = reading.isConfident
          ? appSemanticColors.successBackground
          : appSemanticColors.infoText;
    }

    return Semantics(
      liveRegion: true,
      label: '$headline. $detail',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppMetrics.gap),
          decoration: BoxDecoration(
            color: appColorScheme.surface,
            border: Border.all(color: appSemanticColors.infoBorder),
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LetterBadge(letter: headline, progress: dictation.progress),
                  const SizedBox(width: AppMetrics.gap),
                  Expanded(
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: appSemanticColors.infoText,
                      ),
                    ),
                  ),
                ],
              ),
              if (target == null) ...[
                const SizedBox(height: AppMetrics.gap),
                Divider(color: appSemanticColors.infoBorder, height: 1),
                const SizedBox(height: AppMetrics.gap),
                Text(
                  'Llevas escrito',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appSemanticColors.infoText,
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
                        ? appSemanticColors.infoText
                        : appSemanticColors.infoText,
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
  const _LetterBadge({required this.letter, required this.progress});

  final String letter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;
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
              backgroundColor: appSemanticColors.dangerBorder,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
            ),
          ),
          Text(
            letter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: letter.length > 3 ? 15 : 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mensaje a pantalla completa, para esperar o para explicar un problema.
class _Message extends StatelessWidget {
  const _Message({required this.text, this.icon, this.busy = false});

  final String text;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final appSemanticColors = appTheme.extension<ActivityThemeColors>()!;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppMetrics.sectionGap),
        decoration: BoxDecoration(
          color: appSemanticColors.dangerText,
          border: Border.all(color: appSemanticColors.infoBorder),
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
        ),
        child: Column(
          children: [
            if (busy)
              CircularProgressIndicator(
                color: appSemanticColors.warningBackground,
              )
            else if (icon != null)
              Icon(icon, size: 40, color: appSemanticColors.infoText),
            const SizedBox(height: AppMetrics.gap),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.45,
                color: appSemanticColors.infoText,
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
