/// Las formas de boca que distingue el servidor.
///
/// Son pocas a propósito: la mayoría de las consonantes se hacen dentro de la
/// boca y, viendo solo los labios, no se pueden separar unas de otras.
enum LipShape {
  closed('M', 'M B P V', 'Labios juntos: puede ser M, B, P o V.'),
  hidden(
    'N',
    'T D N L S',
    'Boca entreabierta: puede ser T, D, N, L, S o R, que se hacen por dentro.',
  ),
  a('A', 'A', 'Boca muy abierta: A.'),
  e('E', 'E', 'Medio abierta y estirada hacia los lados: E.'),
  i('I', 'I', 'Casi cerrada, como al sonreír: I.'),
  o('O', 'O', 'Labios redondos y boca abierta: O.'),
  u('U', 'U', 'Labios adelantados y casi cerrados: U.');

  const LipShape(this.code, this.label, this.description);

  /// Como la nombra el servidor.
  final String code;

  /// Texto corto para la pantalla.
  final String label;

  /// Qué se ve y qué letras pueden ser.
  final String description;

  static LipShape? fromCode(Object? code) {
    for (final shape in values) {
      if (shape.code == code) return shape;
    }
    return null;
  }
}

/// Un punto del contorno de los labios, de 0 a 1 respecto a la foto.
class LipPoint {
  const LipPoint(this.x, this.y);

  factory LipPoint.fromJson(Map<String, dynamic> json) => LipPoint(
    (json['x'] as num?)?.toDouble() ?? 0,
    (json['y'] as num?)?.toDouble() ?? 0,
  );

  final double x;
  final double y;
}

/// Lo que el servidor vio en una foto: dónde están los labios y cómo están.
class LipFrame {
  const LipFrame({
    required this.outer,
    required this.inner,
    required this.opening,
    required this.width,
    required this.rounding,
    required this.shape,
  });

  factory LipFrame.fromJson(Map<String, dynamic> json) {
    final lips = json['lips'] as Map<String, dynamic>? ?? const {};

    List<LipPoint> contour(String name) => [
      for (final point in lips[name] as List? ?? const [])
        if (point is Map<String, dynamic>) LipPoint.fromJson(point),
    ];

    return LipFrame(
      outer: contour('outer'),
      inner: contour('inner'),
      opening: (json['opening'] as num?)?.toDouble() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      rounding: (json['rounding'] as num?)?.toDouble() ?? 0,
      shape: LipShape.fromCode(json['shape']) ?? LipShape.hidden,
    );
  }

  final List<LipPoint> outer;
  final List<LipPoint> inner;

  /// Lo que se separan los labios, en distancias entre ojos.
  final double opening;

  /// El ancho de la boca, en distancias entre ojos.
  final double width;

  /// Lo redondeados que están los labios, de 0 a 1.
  final double rounding;

  final LipShape shape;
}

/// Por qué no se llegó a intentar leer una palabra.
enum LipReadingProblem { tooShort, noFace, noMovement }

/// Lo que el servidor leyó en un clip.
class LipWordReading {
  const LipWordReading({
    this.word,
    this.alternatives = const [],
    this.shapes = const [],
    this.problem,
  });

  factory LipWordReading.fromJson(Map<String, dynamic> json) {
    return LipWordReading(
      word: json['word'] as String?,
      alternatives: [
        for (final word in json['alternatives'] as List? ?? const [])
          if (word is String) word,
      ],
      shapes: [
        for (final code in json['shapes'] as List? ?? const [])
          ?LipShape.fromCode(code),
      ],
      problem: switch (json['reason']) {
        'too_short' => LipReadingProblem.tooShort,
        'no_face' => LipReadingProblem.noFace,
        'no_movement' => LipReadingProblem.noMovement,
        _ => null,
      },
    );
  }

  /// La palabra, si la lectura fue clara. Si no, se ofrecen [alternatives].
  final String? word;

  /// Otras palabras que podrían ser, de la más a la menos parecida.
  final List<String> alternatives;

  /// Las formas de boca que se vieron, en orden.
  final List<LipShape> shapes;

  final LipReadingProblem? problem;
}

/// Mide la boca relajada de esta persona.
///
/// Una boca se ve redonda o estirada comparada con la suya en reposo, y ese
/// ancho cambia bastante de una cara a otra. Sin medirlo, una boca estrecha
/// parecería siempre a punto de decir U.
class LipCalibration {
  LipCalibration({this.framesNeeded = 6, this.giveUpAfter = 30});

  /// Cuántas fotos con la boca relajada hacen falta.
  final int framesNeeded;

  /// Tras cuántas fotos con cara se deja de esperar y se sigue sin medida:
  /// quien no consiga relajar la boca tiene que poder seguir usándolo.
  final int giveUpAfter;

  /// Por encima de esto la boca no está relajada.
  static const double _maxOpening = 0.05;
  static const double _maxRounding = 0.35;

  final List<double> _widths = [];
  int _seen = 0;
  double? _neutralWidth;

  /// El ancho de la boca relajada, si ya se midió.
  double? get neutralWidth => _neutralWidth;

  /// Ya no hace falta esperar, se haya podido medir o no.
  bool get isDone => _neutralWidth != null || _seen >= giveUpAfter;

  double get progress =>
      isDone ? 1 : (_widths.length / framesNeeded).clamp(0.0, 1.0);

  void offer(LipFrame frame) {
    if (isDone) return;
    _seen++;
    if (frame.opening > _maxOpening || frame.rounding > _maxRounding) return;

    _widths.add(frame.width);
    if (_widths.length < framesNeeded) return;

    // La mediana, para que un gesto suelto no cuente.
    final sorted = [..._widths]..sort();
    _neutralWidth = sorted[sorted.length ~/ 2];
  }

  void reset() {
    _widths.clear();
    _seen = 0;
    _neutralWidth = null;
  }
}
