import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_code4all/data/services/braille_translation_service.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';
import 'accessibility_reading_state_widget.dart';

/// Colores fijos de alto contraste.
///
/// No siguen el tema de la aplicación a propósito: este teclado lo usa sobre
/// todo quien ve poco o nada, y el tema rojo o los de daltonismo no garantizan
/// el contraste que hace falta. Blanco y amarillo sobre negro pasan de 14:1.
class _BrailleColors {
  static const background = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const text = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFFD600);
  static const onAccent = Color(0xFF000000);
  static const error = Color(0xFFFF8A80);
}

/// Una celda Braille dibujada: seis puntos, rellenos los que están levantados.
///
/// Sirve de icono en el menú y para enseñar la celda que se está escribiendo.
class BrailleCellIcon extends StatelessWidget {
  const BrailleCellIcon({
    super.key,
    required this.dots,
    this.size = 24,
    this.color,
  });

  final Set<int> dots;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size * 0.7,
      height: size,
      child: CustomPaint(painter: _BrailleCellPainter(dots, resolved)),
    );
  }
}

class _BrailleCellPainter extends CustomPainter {
  _BrailleCellPainter(this.dots, this.color);

  final Set<int> dots;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 5;
    final fill = Paint()..color = color;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius / 3;

    for (var dot = 1; dot <= 6; dot++) {
      final column = dot <= 3 ? 0 : 1;
      final row = (dot - 1) % 3;
      final center = Offset(
        size.width * (column == 0 ? 0.25 : 0.75),
        size.height * (row * 2 + 1) / 6,
      );
      canvas.drawCircle(
        center,
        dots.contains(dot) ? radius : radius * 0.8,
        dots.contains(dot) ? fill : outline,
      );
    }
  }

  @override
  bool shouldRepaint(_BrailleCellPainter old) =>
      old.color != color || !setEquals(old.dots, dots);
}

/// Teclado Braille pensado para escribir sin ver la pantalla.
///
/// **Toda la pantalla es la celda.** Debajo de la barra superior hay seis
/// zonas grandes: la mitad izquierda son los puntos 1, 2 y 3 de arriba abajo, y
/// la derecha los puntos 4, 5 y 6. No hay que encontrar ningún botón pequeño:
/// basta con saber en qué parte de la pantalla está cada punto.
///
/// **La letra se reconoce sola.** Se tocan sus puntos —con varios dedos a la
/// vez o uno detrás de otro— y, al levantar los dedos y esperar un momento,
/// la celda se manda al backend, que la traduce, y la letra se dice en voz
/// alta. No hay que pulsar «Letra» ni «Enviar».
///
/// **Lo demás son gestos con un dedo,** que se hacen en cualquier sitio:
/// deslizar a la derecha es espacio, a la izquierda borrar, hacia abajo leer
/// todo el texto y hacia arriba repetir las instrucciones. Espacio, Atrás y
/// Enviar siguen también como botones en la barra superior, para quien ve o
/// ayuda a quien no ve.
///
/// Con teclado físico funciona como una máquina Perkins: F, D y S son los
/// puntos 1, 2 y 3; J, K y L los puntos 4, 5 y 6. Se pulsan a la vez y la
/// letra se confirma al soltarlas todas.
///
/// **Lector de pantalla.** Con TalkBack o VoiceOver encendidos el sistema se
/// queda los toques para explorar la pantalla, así que los acordes con varios
/// dedos no llegan. Cada zona sigue siendo un botón «Punto N» que se activa
/// con doble toque, y en ese caso se espera más antes de dar la letra por
/// terminada. Lo más rápido es pausar el lector mientras se escribe: este
/// teclado ya habla por sí solo.
///
/// **Rellenar campos.** Con [fields] el teclado escribe directamente en esos
/// campos —por ejemplo el correo y la contraseña del login—, uno detrás de
/// otro: deslizar hacia abajo da el campo por terminado y pasa al siguiente,
/// y en el último cierra el teclado devolviendo `true` para que la pantalla
/// envíe el formulario.
class BrailleKeyboardScreen extends StatefulWidget {
  const BrailleKeyboardScreen({
    super.key,
    this.fields,
    this.service,
    this.speak,
    this.commitDelay,
    this.dictation,
  });

  /// Para las pruebas. Sin él se dicta con el micrófono de verdad.
  final VoiceDictation? dictation;

  /// Cuánto hay que mantener un dedo quieto para hablar en vez de escribir.
  static const Duration holdToTalk = Duration(seconds: 1);

  /// Los campos que hay que rellenar, en orden. Sin ellos el teclado escribe
  /// en su propio recuadro.
  final List<BrailleField>? fields;

  /// Para las pruebas. Sin él se usa el backend de verdad.
  final BrailleTranslationService? service;

  /// Para las pruebas. Sin él se habla con el asistente de voz de la app.
  final void Function(String text)? speak;

  /// Cuánto se espera, con los dedos levantados, para dar la letra por
  /// terminada. Sin él: [defaultCommitDelay], o [screenReaderCommitDelay] si
  /// hay un lector de pantalla encendido.
  final Duration? commitDelay;

  /// Lo bastante largo para tocar los puntos de uno en uno sin prisa, y lo
  /// bastante corto para que escribir no se haga lento.
  static const Duration defaultCommitDelay = Duration(milliseconds: 1200);

  /// Con lector de pantalla cada punto es buscar y hacer doble toque.
  static const Duration screenReaderCommitDelay = Duration(seconds: 3);

  /// Distancia mínima para que un toque cuente como deslizar y no como punto.
  static const double swipeDistance = 60;

  static Route<void> route() => MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (_) => const BrailleKeyboardScreen(),
  );

  /// Abre el teclado para rellenar [fields]. Devuelve `true` si la persona
  /// terminó el último campo y quiere enviar el formulario.
  static Future<bool> fillFields(
    BuildContext context,
    List<BrailleField> fields,
  ) async {
    final submit = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => BrailleKeyboardScreen(fields: fields),
      ),
    );
    return submit ?? false;
  }

  /// Las instrucciones cuando se rellenan campos.
  static String fieldInstructions(List<BrailleField> fields) {
    final names = [for (final field in fields) field.label.toLowerCase()];
    final order = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
    return 'Teclado Braille abierto para escribir $order. '
        'Toda la pantalla, debajo de la barra de arriba, es una celda Braille '
        'de seis zonas: a la izquierda los puntos 1, 2 y 3, de arriba abajo; '
        'a la derecha los puntos 4, 5 y 6. '
        'Toca los puntos de cada letra y espera: te diré la letra. '
        'Desliza a la izquierda para borrar. '
        'Para la arroba toca solo el punto 5. El punto es el punto 3. '
        'Cuando termines un campo, desliza hacia abajo para pasar al '
        'siguiente. En el último, deslizar hacia abajo lo envía. '
        'Desliza hacia arriba para repetir estas instrucciones. '
        'También puedes hablar: mantén un dedo apoyado hasta oír un pitido y '
        'di lo que quieras escribir. Para el correo puedes decir, por '
        'ejemplo: sebastián arroba gmail punto com. '
        'Empieza por ${names.first}.';
  }

  static const String instructions =
      'Teclado Braille abierto. '
      'Toda la pantalla, debajo de la barra de arriba, es una celda Braille '
      'dividida en seis zonas grandes. '
      'La mitad izquierda tiene los puntos 1, 2 y 3, de arriba abajo. '
      'La mitad derecha tiene los puntos 4, 5 y 6. '
      'Toca los puntos de una letra, con varios dedos a la vez o uno detrás '
      'de otro. Cuando levantes los dedos y esperes un momento, te diré la '
      'letra. No hace falta pulsar ningún botón. '
      'Con un dedo: desliza a la derecha para poner un espacio, a la izquierda '
      'para borrar, hacia abajo para escuchar todo el texto, y hacia arriba '
      'para repetir estas instrucciones. '
      'Para escribir números, haz primero el signo de número, puntos 3, 4, 5 '
      'y 6, y después las letras de la a a la j: la a es el 1 y la j es el 0. '
      'También puedes hablar en vez de escribir: mantén un dedo apoyado hasta '
      'oír un pitido, di lo que quieras y espera. Al terminar sonará otro '
      'pitido.';

  @override
  State<BrailleKeyboardScreen> createState() => _BrailleKeyboardScreenState();
}

/// Un campo de texto que el teclado Braille puede rellenar.
class BrailleField {
  const BrailleField({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.email = false,
  });

  /// Cómo se llama en voz alta: «Correo electrónico», «Contraseña».
  final String label;
  final TextEditingController controller;

  /// Para contraseñas: en pantalla se tapa y, al terminar el campo, se dice
  /// cuántos caracteres tiene en vez de leerla entera.
  final bool obscure;

  /// Para correos: lo dictado se limpia («arroba» → @, sin espacios).
  final bool email;

  DictationKind get dictationKind => obscure
      ? DictationKind.password
      : email
      ? DictationKind.email
      : DictationKind.text;
}

/// Un dedo que está tocando la pantalla ahora mismo.
class _Touch {
  _Touch(this.start, this.dot);

  final Offset start;
  final int dot;
  Offset end = Offset.zero;
}

enum _Swipe { right, left, down, up }

class _BrailleKeyboardScreenState extends State<BrailleKeyboardScreen> {
  late final BrailleTranslationService _service =
      widget.service ?? BrailleTranslationService();

  /// Las celdas escritas en cada campo. Sin campos hay uno solo: el recuadro
  /// del propio teclado.
  late final List<List<Set<int>>> _cellsByField = [
    for (var i = 0; i < (widget.fields?.length ?? 1); i++) <Set<int>>[],
  ];

  /// Lo que cada campo tiene escrito que no sale de sus celdas: lo que ya
  /// había al abrir el teclado y lo que se dictó por el micrófono. Las celdas
  /// Braille se añaden detrás.
  late final List<String> _prefixByField = [
    for (var i = 0; i < (widget.fields?.length ?? 1); i++)
      widget.fields?[i].controller.text ?? '',
  ];

  /// En qué campo se está escribiendo.
  int _fieldIndex = 0;

  List<Set<int>> get _cells => _cellsByField[_fieldIndex];

  String get _prefix => _prefixByField[_fieldIndex];
  set _prefix(String value) => _prefixByField[_fieldIndex] = value;

  /// Todo lo escrito en el campo actual.
  String get _text => _prefix + (_translation?.text ?? '');

  BrailleField? get _field => widget.fields?[_fieldIndex];

  bool get _fillingFields => widget.fields?.isNotEmpty ?? false;

  String get _instructions => _fillingFields
      ? BrailleKeyboardScreen.fieldInstructions(widget.fields!)
      : BrailleKeyboardScreen.instructions;

  /// Los puntos de la letra que se está escribiendo, aún sin confirmar.
  final Set<int> _pending = {};

  BrailleTranslation? _translation;
  String? _error;
  bool _sent = false;

  /// Si se cerró pidiendo enviar el formulario.
  bool _submitted = false;

  /// Para descartar respuestas que llegan tarde: si se escribe rápido, la
  /// traducción de hace dos letras no puede pisar a la de ahora.
  int _requestId = 0;

  // Toques en la pantalla.
  final Map<int, _Touch> _touches = {};

  /// Cuántos dedos llegó a haber a la vez desde que no había ninguno. Con más
  /// de uno es un acorde, y entonces nada cuenta como deslizar.
  int _fingersInGesture = 0;
  Timer? _commitTimer;

  // Teclado físico: teclas pulsadas ahora y puntos acumulados en el acorde.
  static final Map<LogicalKeyboardKey, int> _perkinsKeys = {
    LogicalKeyboardKey.keyF: 1,
    LogicalKeyboardKey.keyD: 2,
    LogicalKeyboardKey.keyS: 3,
    LogicalKeyboardKey.keyJ: 4,
    LogicalKeyboardKey.keyK: 5,
    LogicalKeyboardKey.keyL: 6,
  };
  final Set<LogicalKeyboardKey> _held = {};
  final Set<int> _chord = {};

  final FocusNode _focusNode = FocusNode(debugLabel: 'Teclado Braille');

  // Dictado por el micrófono.
  late final VoiceDictation _dictation =
      widget.dictation ?? SpeechToTextDictation();
  bool _listening = false;
  String _partial = '';

  /// Cuenta el tiempo que lleva un dedo quieto, para hablar al mantenerlo.
  Timer? _holdTimer;

  /// Lo que queda de este gesto no escribe nada: ya sirvió para empezar o
  /// parar de escuchar.
  bool _ignoreGesture = false;

  @override
  void initState() {
    super.initState();
    // Lo primero que se oye al abrir: cómo se usa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _say(_instructions);
    });
  }

  @override
  void dispose() {
    _commitTimer?.cancel();
    _holdTimer?.cancel();
    if (_listening) unawaited(_dictation.stop());
    _focusNode.dispose();
    // Que la voz no siga hablando de un teclado que ya se cerró. Salvo al
    // enviar: ese «Enviando» es justo lo que hay que oír al salir.
    if (widget.speak == null && !_submitted) {
      unawaited(accessibilityReadingState.stop());
    }
    super.dispose();
  }

  Duration get _commitDelay {
    final custom = widget.commitDelay;
    if (custom != null) return custom;
    return MediaQuery.of(context).accessibleNavigation
        ? BrailleKeyboardScreen.screenReaderCommitDelay
        : BrailleKeyboardScreen.defaultCommitDelay;
  }

  void _say(String text) {
    if (!mounted) return;
    final speak = widget.speak;
    if (speak != null) {
      speak(text);
    } else {
      unawaited(accessibilityReadingState.read(text, context));
    }
  }

  static String _dotsText(Iterable<int> dots) {
    final sorted = dots.toList()..sort();
    if (sorted.length == 1) return 'punto ${sorted.first}';
    final last = sorted.removeLast();
    return 'puntos ${sorted.join(', ')} y $last';
  }

  // ---- Puntos ----

  /// Marca o desmarca un punto de la letra en curso.
  ///
  /// Sólo dice el número: la letra se dice al confirmarla, y repetir «punto»
  /// en cada toque haría que escribir una palabra sonara eterno.
  void _toggleDot(int dot) {
    HapticFeedback.selectionClick();
    setState(() {
      _sent = false;
      if (!_pending.remove(dot)) _pending.add(dot);
    });
    _say(_pending.contains(dot) ? '$dot' : '$dot quitado');
  }

  /// Vuelve a contar el tiempo para dar la letra por terminada.
  void _scheduleCommit() {
    _commitTimer?.cancel();
    if (_pending.isEmpty) return;
    _commitTimer = Timer(_commitDelay, _commitPending);
  }

  void _commitPending() {
    _commitTimer?.cancel();
    _commitTimer = null;
    if (_pending.isEmpty) return;
    HapticFeedback.mediumImpact();
    unawaited(_append([Set.of(_pending)]));
  }

  // ---- Toques y gestos ----

  int _dotAt(Offset position, Size size) {
    final column = position.dx < size.width / 2 ? 0 : 1;
    final row = (position.dy / (size.height / 3)).floor().clamp(0, 2);
    return column * 3 + row + 1;
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    // Hay alguien tocando: la letra todavía no ha terminado.
    _commitTimer?.cancel();

    // Escuchando, tocar la pantalla es «ya he terminado de hablar».
    if (_listening) {
      _ignoreGesture = true;
      unawaited(_dictation.stop());
    }

    // Un dedo solo y quieto un rato es hablar; un segundo dedo lo descarta,
    // porque entonces es un acorde.
    _holdTimer?.cancel();
    if (_touches.isEmpty && !_ignoreGesture) {
      _holdTimer = Timer(BrailleKeyboardScreen.holdToTalk, () {
        _ignoreGesture = true;
        unawaited(_startDictation());
      });
    }

    _touches[event.pointer] = _Touch(
      event.localPosition,
      _dotAt(event.localPosition, size),
    )..end = event.localPosition;
    if (_touches.length > _fingersInGesture) {
      _fingersInGesture = _touches.length;
    }
    if (_touches.length > 1) _holdTimer?.cancel();
    HapticFeedback.lightImpact();
  }

  void _onPointerMove(PointerMoveEvent event) {
    final touch = _touches[event.pointer];
    if (touch == null) return;
    touch.end = event.localPosition;
    // Si el dedo se mueve es que va a deslizar, no a hablar.
    if ((touch.end - touch.start).distance > kTouchSlop) _holdTimer?.cancel();
  }

  void _onPointerUp(PointerUpEvent event) {
    _holdTimer?.cancel();
    final touch = _touches.remove(event.pointer);
    if (touch == null) return;
    touch.end = event.localPosition;

    if (_ignoreGesture) {
      if (_touches.isEmpty) {
        _ignoreGesture = false;
        _fingersInGesture = 0;
      }
      return;
    }

    final swipe = _fingersInGesture == 1 ? _swipeOf(touch) : null;
    final moved =
        (touch.end - touch.start).distance >=
        BrailleKeyboardScreen.swipeDistance;

    if (swipe != null) {
      _onSwipe(swipe);
    } else if (!moved) {
      // Un dedo que se arrastra en un acorde no se sabe qué quería: se
      // descarta antes que marcar un punto que no se pidió.
      _toggleDot(touch.dot);
    }

    if (_touches.isEmpty) {
      _fingersInGesture = 0;
      _scheduleCommit();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _holdTimer?.cancel();
    _touches.remove(event.pointer);
    if (_touches.isEmpty) {
      _ignoreGesture = false;
      _fingersInGesture = 0;
      _scheduleCommit();
    }
  }

  _Swipe? _swipeOf(_Touch touch) {
    final delta = touch.end - touch.start;
    if (delta.distance < BrailleKeyboardScreen.swipeDistance) return null;
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? _Swipe.right : _Swipe.left;
    }
    return delta.dy > 0 ? _Swipe.down : _Swipe.up;
  }

  void _onSwipe(_Swipe swipe) {
    switch (swipe) {
      case _Swipe.right:
        _space();
      case _Swipe.left:
        _back();
      case _Swipe.down:
        unawaited(_send());
      case _Swipe.up:
        _say(_instructions);
    }
  }

  // ---- Acciones ----

  void _space() {
    _commitTimer?.cancel();
    unawaited(_append([if (_pending.isNotEmpty) Set.of(_pending), <int>{}]));
  }

  void _back() {
    _commitTimer?.cancel();
    HapticFeedback.selectionClick();
    if (_pending.isNotEmpty) {
      setState(_pending.clear);
      _say('Puntos de la letra borrados');
      return;
    }
    if (_cells.isEmpty) {
      if (_prefix.isNotEmpty) {
        // Lo dictado o lo que ya había no tiene celdas: se borra carácter a
        // carácter, como con un teclado normal.
        final removed = _prefix.substring(_prefix.length - 1);
        setState(() {
          _prefix = _prefix.substring(0, _prefix.length - 1);
          _sent = false;
        });
        _field?.controller.text = _prefix;
        _say('Borrado: ${_spokenChar(removed)}');
      } else if (_fillingFields && _fieldIndex > 0) {
        _goToField(_fieldIndex - 1);
      } else {
        _say('No hay nada que borrar');
      }
      return;
    }

    final index = _cells.length - 1;
    final readings = _translation?.cells;
    final removed = readings != null && index < readings.length
        ? readings[index].spoken
        : _cells[index].isEmpty
        ? 'espacio'
        : _dotsText(_cells[index]);

    setState(() {
      _cells.removeLast();
      _sent = false;
    });
    _say('Borrado: $removed');
    unawaited(_retranslate());
  }

  static String _spokenChar(String char) => switch (char) {
    ' ' => 'espacio',
    '.' => 'punto',
    ',' => 'coma',
    '@' => 'arroba',
    '-' => 'guion',
    '_' => 'guion bajo',
    _ => char,
  };

  /// Lee en voz alta todo lo escrito o, rellenando campos, da el campo por
  /// terminado.
  Future<void> _send() async {
    _commitTimer?.cancel();
    if (_fillingFields) return _finishField();
    if (_pending.isNotEmpty) {
      setState(() {
        _cells.add(Set.of(_pending));
        _pending.clear();
      });
    }
    if (_cells.isEmpty && _prefix.isEmpty) {
      _say('Todavía no has escrito nada.');
      return;
    }

    var unknown = 0;
    if (_cells.isNotEmpty) {
      final result = await _retranslate();
      if (!mounted) return;
      if (result == null) {
        _say(_error ?? 'No se pudo traducir el texto.');
        return;
      }
      unknown = result.unrecognizedCount;
    }

    setState(() => _sent = true);
    final text = _text.trim();
    _say(
      [
        text.isEmpty
            ? 'No se reconoció ningún texto.'
            : 'Texto traducido: $text.',
        if (unknown == 1) 'Hay una combinación no reconocida.',
        if (unknown > 1) 'Hay $unknown combinaciones no reconocidas.',
      ].join(' '),
    );
  }

  /// Cómo decir lo que lleva un campo. La contraseña no se lee entera.
  String _summary(BrailleField field) {
    final text = field.controller.text;
    if (text.isEmpty) return '${field.label} vacío';
    if (field.obscure) {
      return '${field.label}: ${text.length} '
          '${text.length == 1 ? 'carácter' : 'caracteres'}';
    }
    return '${field.label}: $text';
  }

  /// Da por terminado el campo actual y pasa al siguiente o, si era el
  /// último, cierra el teclado pidiendo enviar el formulario.
  Future<void> _finishField() async {
    if (_pending.isNotEmpty) await _append([Set.of(_pending)]);
    if (!mounted) return;

    final fields = widget.fields!;
    final summary = _summary(fields[_fieldIndex]);

    if (_fieldIndex == fields.length - 1) {
      _submitted = true;
      _say('$summary. Enviando.');
      Navigator.of(context).pop(true);
      return;
    }

    _goToField(_fieldIndex + 1, before: summary);
  }

  void _goToField(int index, {String? before}) {
    _commitTimer?.cancel();
    _requestId++;
    setState(() {
      _fieldIndex = index;
      _pending.clear();
      _translation = null;
      _error = null;
      _sent = false;
    });

    final field = _field!;
    final existing = field.controller.text;
    final parts = [
      if (before != null) '$before.',
      'Ahora escribe ${field.label.toLowerCase()}.',
      if (existing.isNotEmpty)
        'Ya tiene ${field.obscure ? '${existing.length} caracteres' : 'escrito $existing'}; '
            'lo que escribas se añade al final.',
    ];
    _say(parts.join(' '));

    // Al volver a un campo ya escrito, se recupera su traducción para que
    // borrar diga qué se borra.
    if (_cells.isNotEmpty) unawaited(_retranslate());
  }

  Future<void> _copy() async {
    final text = _text;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    _say('Texto copiado');
  }

  void _clearAll() {
    _commitTimer?.cancel();
    setState(() {
      _cells.clear();
      _pending.clear();
      _prefix = '';
      _translation = null;
      _error = null;
      _sent = false;
    });
    _field?.controller.clear();
    _requestId++;
    _say('Texto borrado');
  }

  /// Añade celdas y dice en voz alta qué se entendió de ellas.
  Future<void> _append(List<Set<int>> added) async {
    final from = _cells.length;
    setState(() {
      _cells.addAll(added);
      _pending.clear();
      _sent = false;
    });

    final result = await _retranslate();
    if (!mounted) return;

    if (result == null) {
      // Sin servidor la letra se guarda igual; se traducirá al volver.
      final typed = added
          .map((c) => c.isEmpty ? 'espacio' : _dotsText(c))
          .join(', ');
      _say(
        '$typed. Guardado, pero no se pudo traducir: '
        'no hay conexión con el servidor.',
      );
      return;
    }
    if (result.cells.length < from + added.length) return;

    final readings = result.cells.sublist(from, from + added.length);
    final spoken = [for (final cell in readings) cell.spoken];

    // Al cerrar una palabra se repite entera: letra a letra es fácil perder
    // la cuenta de qué se lleva escrito.
    if (readings.isNotEmpty && readings.last.kind == 'space') {
      final words = (_prefix + result.text).trim().split(RegExp(r'\s+'));
      final word = words.isEmpty ? '' : words.last;
      if (word.isNotEmpty) {
        spoken
          ..removeLast()
          ..add('$word, espacio');
      }
    }

    _say(spoken.join(', '));
  }

  /// Pide la traducción de todo lo escrito. Devuelve null si falló o si
  /// mientras tanto se escribió otra cosa.
  Future<BrailleTranslation?> _retranslate() async {
    final id = ++_requestId;
    final snapshot = [for (final cell in _cells) Set.of(cell)];
    // El campo se apunta ahora: si la respuesta llega después de cambiar de
    // campo, ya no es de este y se descarta por el número de petición.
    final field = _field;
    final prefix = _prefix;

    if (snapshot.isEmpty) {
      field?.controller.text = prefix;
      setState(() {
        _translation = null;
        _error = null;
      });
      return null;
    }

    try {
      final result = await _service.translate(snapshot);
      if (!mounted || id != _requestId) return null;
      // Lo escrito aparece en el campo de verdad según se escribe.
      field?.controller.text = prefix + result.text;
      setState(() {
        _translation = result;
        _error = null;
      });
      return result;
    } on BrailleTranslationException catch (e) {
      if (!mounted || id != _requestId) return null;
      setState(() => _error = e.message);
      return null;
    }
  }

  // ---- Micrófono ----

  /// Escucha por el micrófono y añade lo que se diga al campo actual.
  Future<void> _startDictation() async {
    if (_listening || !mounted) return;
    _commitTimer?.cancel();

    // La letra a medias se confirma antes: lo dictado va detrás.
    if (_pending.isNotEmpty) await _append([Set.of(_pending)]);
    if (!mounted) return;

    if (_cells.isNotEmpty && _translation == null) {
      _say(
        'Antes de hablar hace falta traducir lo escrito en Braille, y no hay '
        'conexión con el servidor.',
      );
      return;
    }

    // Lo escrito en Braille hasta ahora pasa a ser texto fijo, para que lo
    // dictado se añada detrás y no se mezcle con las celdas.
    setState(() {
      _prefix = _text;
      _cells.clear();
      _translation = null;
      _requestId++;
      _listening = true;
      _partial = '';
      _sent = false;
    });

    // Que la voz se calle: si no, el micrófono se oiría a sí mismo.
    if (widget.speak == null) await accessibilityReadingState.stop();
    HapticFeedback.heavyImpact();
    await _dictation.cue(start: true);
    // Un respiro para que el pitido no entre en lo que se reconoce.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    String? heard;
    String? failure;
    try {
      heard = await _dictation.listen(
        onPartial: (partial) {
          if (mounted) setState(() => _partial = partial);
        },
      );
    } on DictationUnavailableException catch (e) {
      failure = e.message;
    }
    if (!mounted) return;

    setState(() {
      _listening = false;
      _partial = '';
    });
    HapticFeedback.mediumImpact();
    await _dictation.cue(start: false);
    if (!mounted) return;

    if (failure != null) {
      _say(failure);
      return;
    }
    if (heard == null || heard.trim().isEmpty) {
      _say(
        'No te he entendido. Mantén un dedo apoyado para volver a '
        'intentarlo.',
      );
      return;
    }

    final kind = _field?.dictationKind ?? DictationKind.text;
    final added = VoiceDictation.normalize(heard, kind);
    final needsSpace =
        kind == DictationKind.text &&
        _prefix.isNotEmpty &&
        !_prefix.endsWith(' ');

    setState(() => _prefix = '$_prefix${needsSpace ? ' ' : ''}$added');
    _field?.controller.text = _prefix;

    _say(
      kind == DictationKind.password
          ? 'Escrito. ${_summary(_field!)}'
          : 'Escrito: $added',
    );
  }

  void _toggleDictation() {
    if (_listening) {
      unawaited(_dictation.stop());
    } else {
      unawaited(_startDictation());
    }
  }

  // ---- Teclado físico ----

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final dot = _perkinsKeys[event.logicalKey];
    if (dot != null) {
      if (event is KeyDownEvent) {
        _held.add(event.logicalKey);
        _chord.add(dot);
      } else if (event is KeyUpEvent) {
        _held.remove(event.logicalKey);
        if (_held.isEmpty && _chord.isNotEmpty) {
          final cell = Set.of(_chord);
          _chord.clear();
          _commitTimer?.cancel();
          unawaited(_append([cell]));
        }
      }
      return KeyEventResult.handled;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.space) {
      _space();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _back();
    } else if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      unawaited(_send());
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- Interfaz ----

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _BrailleColors.background,
        colorScheme: const ColorScheme.dark(
          primary: _BrailleColors.accent,
          onPrimary: _BrailleColors.onAccent,
          surface: _BrailleColors.surface,
          onSurface: _BrailleColors.text,
          error: _BrailleColors.error,
        ),
      ),
      child: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: _BrailleColors.background,
            foregroundColor: _BrailleColors.text,
            title: Semantics(
              header: true,
              child: const Text('Teclado Braille'),
            ),
            actions: [
              IconButton(
                key: const ValueKey('braille-action-Espacio'),
                tooltip: 'Espacio',
                icon: const Icon(Icons.space_bar),
                onPressed: _space,
              ),
              IconButton(
                key: const ValueKey('braille-action-Atrás'),
                tooltip: 'Atrás: borrar lo último',
                icon: const Icon(Icons.backspace_outlined),
                onPressed: _back,
              ),
              IconButton(
                key: const ValueKey('braille-action-Enviar'),
                tooltip: _fillingFields
                    ? 'Enviar: terminar este campo'
                    : 'Enviar: traducir y leer todo el texto',
                icon: const Icon(Icons.send),
                onPressed: () => unawaited(_send()),
              ),
              IconButton(
                key: const ValueKey('braille-action-Hablar'),
                tooltip: _listening
                    ? 'Dejar de escuchar'
                    : 'Hablar: escribir con el micrófono',
                icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                color: _listening ? _BrailleColors.accent : null,
                onPressed: _toggleDictation,
              ),
              IconButton(
                tooltip: 'Ayuda: escuchar las instrucciones',
                icon: const Icon(Icons.record_voice_over_outlined),
                onPressed: () => _say(_instructions),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOutput(),
                Expanded(child: _buildTouchSurface()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutput() {
    if (_fillingFields) return _buildFieldsOutput();

    final text = _text;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      decoration: BoxDecoration(
        color: _BrailleColors.surface,
        border: Border(
          bottom: BorderSide(
            color: _sent ? _BrailleColors.accent : _BrailleColors.text,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: text.isEmpty ? 'Sin texto todavía' : 'Texto: $text',
                  child: ExcludeSemantics(
                    child: Text(
                      text.isEmpty ? '—' : text,
                      key: const ValueKey('braille-output'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _sent
                            ? _BrailleColors.accent
                            : _BrailleColors.text,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (text.isNotEmpty) ...[
                IconButton(
                  tooltip: 'Copiar texto',
                  color: _BrailleColors.text,
                  icon: const Icon(Icons.copy),
                  onPressed: _copy,
                ),
                IconButton(
                  tooltip: 'Borrar todo el texto',
                  color: _BrailleColors.text,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearAll,
                ),
              ],
            ],
          ),
          _gestureHint(
            '→ espacio   ← borrar   ↓ leer todo   ↑ ayuda   '
            'mantener = hablar',
          ),
          ?_listeningBanner(),
          ?_errorText(),
        ],
      ),
    );
  }

  Widget _gestureHint(String text) => ExcludeSemantics(
    child: Text(
      text,
      style: const TextStyle(color: _BrailleColors.text, fontSize: 14),
    ),
  );

  /// Se ve mientras el micrófono está abierto, con lo que se va entendiendo.
  Widget? _listeningBanner() {
    if (!_listening) return null;
    final heard = _partial.isEmpty ? 'Habla ahora…' : _partial;
    return Semantics(
      liveRegion: true,
      label: 'Escuchando',
      child: Container(
        key: const ValueKey('braille-listening'),
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _BrailleColors.accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.mic, color: _BrailleColors.onAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                heard,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BrailleColors.onAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _errorText() {
    final error = _error;
    if (error == null) return null;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          error,
          style: const TextStyle(color: _BrailleColors.error, fontSize: 15),
        ),
      ),
    );
  }

  /// Los campos que se están rellenando, con lo que llevan escrito. El que
  /// está activo va resaltado; las contraseñas, tapadas.
  Widget _buildFieldsOutput() {
    final fields = widget.fields!;
    final isLast = _fieldIndex == fields.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: _BrailleColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < fields.length; i++)
            _fieldRow(fields[i], active: i == _fieldIndex, index: i),
          const SizedBox(height: 4),
          _gestureHint(
            '← borrar   ↓ ${isLast ? 'enviar' : 'siguiente campo'}   '
            '↑ ayuda   mantener = hablar',
          ),
          ?_listeningBanner(),
          ?_errorText(),
        ],
      ),
    );
  }

  Widget _fieldRow(
    BrailleField field, {
    required bool active,
    required int index,
  }) {
    final text = field.controller.text;
    final shown = field.obscure ? '•' * text.length : text;

    return Semantics(
      liveRegion: active,
      selected: active,
      label: _summary(field),
      child: ExcludeSemantics(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _BrailleColors.background,
            border: Border.all(
              color: active ? _BrailleColors.accent : _BrailleColors.text,
              width: active ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: TextStyle(
                  color: active ? _BrailleColors.accent : _BrailleColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                shown.isEmpty ? '—' : shown,
                key: ValueKey('braille-field-$index'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _BrailleColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Las seis zonas, ocupando todo el espacio que queda.
  ///
  /// Se escucha con un [Listener] y no con botones porque hace falta ver
  /// varios dedos a la vez —los acordes— y distinguir un toque de un deslizar
  /// en cualquier parte de la pantalla.
  Widget _buildTouchSurface() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final zone = Size(size.width / 2, size.height / 3);

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _onPointerDown(event, size),
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: Stack(
            children: [
              for (var dot = 1; dot <= 6; dot++)
                Positioned(
                  left: dot <= 3 ? 0 : zone.width,
                  top: zone.height * ((dot - 1) % 3),
                  width: zone.width,
                  height: zone.height,
                  child: _DotZone(
                    key: ValueKey('braille-dot-$dot'),
                    dot: dot,
                    selected: _pending.contains(dot),
                    // Sólo lo usa el lector de pantalla: el dedo lo recoge
                    // el Listener de arriba.
                    onSemanticTap: () {
                      _toggleDot(dot);
                      _scheduleCommit();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DotZone extends StatelessWidget {
  const _DotZone({
    super.key,
    required this.dot,
    required this.selected,
    required this.onSemanticTap,
  });

  final int dot;
  final bool selected;
  final VoidCallback onSemanticTap;

  @override
  Widget build(BuildContext context) {
    final position = dot <= 3 ? 'mitad izquierda' : 'mitad derecha';
    final row = const ['arriba', 'en medio', 'abajo'][(dot - 1) % 3];

    return Semantics(
      button: true,
      toggled: selected,
      label: 'Punto $dot',
      hint: '$position, $row',
      onTap: onSemanticTap,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: _BrailleColors.surface, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final diameter = (constraints.biggest.shortestSide * 0.7).clamp(
              24.0,
              160.0,
            );
            return Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? _BrailleColors.accent
                      : _BrailleColors.background,
                  border: Border.all(
                    color: selected
                        ? _BrailleColors.accent
                        : _BrailleColors.text,
                    width: 4,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$dot',
                  style: TextStyle(
                    color: selected
                        ? _BrailleColors.onAccent
                        : _BrailleColors.text,
                    fontSize: diameter * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
