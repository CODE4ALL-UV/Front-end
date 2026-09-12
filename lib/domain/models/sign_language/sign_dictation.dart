import 'hand_landmark_classifier.dart';

/// Qué pasó al mirar la última foto.
enum SignDictationEvent {
  /// Nada digno de contar: la mano se está colocando.
  nothing,

  /// Una letra nueva acaba de entrar en el texto.
  accepted,

  /// La mano salió de cuadro y se soltó la letra que se estaba sosteniendo.
  released,
}

/// Va juntando letras sueltas en palabras, mirando foto a foto.
///
/// Sin esto el reconocimiento parpadea: la mano pasa por formas intermedias
/// mientras se coloca y cada una se leería como una letra. Aquí una letra solo
/// cuenta si se mantiene quieta varias fotos seguidas, que además es como se
/// deletrea de verdad.
///
/// Para escribir la misma letra dos veces —la «rr» de «perro»— hay que bajar
/// la mano y volver a subirla, igual que al deletrear con una persona. Si no,
/// sostener la mano quieta llenaría la pantalla de una sola letra.
class SignDictation {
  SignDictation({this.framesToAccept = 4, this.framesToRelease = 3})
    : assert(framesToAccept > 0),
      assert(framesToRelease > 0);

  /// Cuántas fotos seguidas hay que sostener la letra para que cuente.
  final int framesToAccept;

  /// Cuántas fotos sin mano hacen falta para poder repetir la misma letra.
  final int framesToRelease;

  final StringBuffer _text = StringBuffer();

  String? _holding;
  int _held = 0;
  int _empty = 0;
  String? _justAccepted;

  /// Lo que se lleva deletreado.
  String get text => _text.toString();

  /// La letra que se está sosteniendo ahora mismo, si hay alguna.
  String? get holding => _holding;

  /// Cuánto falta para que la letra sostenida cuente, de 0 a 1.
  ///
  /// Sirve para dibujar un círculo que se va llenando, que es la única forma
  /// de que la espera no parezca que la aplicación se colgó.
  double get progress {
    if (_holding == null) return 0;
    return (_held / framesToAccept).clamp(0.0, 1.0);
  }

  /// Hay algo escrito.
  bool get isEmpty => _text.isEmpty;

  /// Mete la lectura de una foto y dice qué ha cambiado.
  SignDictationEvent offer(SignReading reading) {
    // Solo cuentan las lecturas claras. Una letra dudosa se enseña en pantalla
    // pero no se escribe: adivinar sería peor que esperar.
    final letter = reading.isConfident ? reading.letter : null;

    if (letter == null) {
      _holding = null;
      _held = 0;
      _empty++;

      if (_justAccepted != null && _empty >= framesToRelease) {
        _justAccepted = null;
        return SignDictationEvent.released;
      }
      return SignDictationEvent.nothing;
    }

    _empty = 0;

    // La misma letra que se acaba de escribir no vuelve a contar hasta que la
    // mano salga de cuadro.
    if (letter == _justAccepted) return SignDictationEvent.nothing;

    if (letter != _holding) {
      _holding = letter;
      _held = 1;
      return SignDictationEvent.nothing;
    }

    _held++;
    if (_held < framesToAccept) return SignDictationEvent.nothing;

    _text.write(letter);
    _justAccepted = letter;
    _holding = null;
    _held = 0;
    return SignDictationEvent.accepted;
  }

  /// Añade un espacio, para separar palabras a mano.
  void addSpace() {
    if (_text.isNotEmpty && !text.endsWith(' ')) {
      _text.write(' ');
      _justAccepted = null;
    }
  }

  /// Borra la última letra.
  void backspace() {
    final current = text;
    if (current.isEmpty) return;

    final shorter = current.substring(0, current.length - 1);
    _text
      ..clear()
      ..write(shorter);
    _justAccepted = null;
  }

  /// Empieza de cero.
  void clear() {
    _text.clear();
    _holding = null;
    _held = 0;
    _empty = 0;
    _justAccepted = null;
  }
}
