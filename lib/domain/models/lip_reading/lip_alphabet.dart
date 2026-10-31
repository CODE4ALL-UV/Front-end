/// Qué se ve de la lengua, si se ve algo.
enum MouthTongue { none, behindTeeth, low }

/// Cómo dibujar una boca: es un esquema, no una fotografía.
class MouthPose {
  const MouthPose({
    required this.opening,
    required this.width,
    this.teeth = false,
    this.tongue = MouthTongue.none,
  });

  /// De 0 (labios juntos) a 1 (muy abierta).
  final double opening;

  /// De 0 (labios adelantados) a 1 (estirada hacia los lados).
  final double width;

  /// Si asoman los dientes de arriba.
  final bool teeth;

  final MouthTongue tongue;
}

/// Lo que se puede esperar de una letra al leerla en los labios.
enum LipVisibility {
  clear('Se ve bien'),
  similar('Se ve, pero se parece a otras'),
  hidden('Casi no se ve');

  const LipVisibility(this.label);

  final String label;
}

/// Las letras que se hacen de la misma manera.
class LipLetterGroup {
  const LipLetterGroup({required this.title, required this.summary});

  final String title;
  final String summary;
}

/// Cómo se hace una letra con la boca.
class LipLetter {
  const LipLetter({
    required this.letter,
    required this.group,
    required this.pose,
    required this.how,
    required this.example,
    required this.visibility,
    this.cameraReads = false,
  });

  final String letter;
  final LipLetterGroup group;
  final MouthPose pose;

  /// Qué hacer con los labios, los dientes y la lengua.
  final String how;

  /// Una palabra para practicarla.
  final String example;

  final LipVisibility visibility;

  /// Si la pantalla de la cámara distingue esta letra por su forma.
  final bool cameraReads;
}

const LipLetterGroup vowelsGroup = LipLetterGroup(
  title: 'Las vocales',
  summary:
      'Son las que mejor se leen. Cada una tiene su propia forma y la cámara '
      'las distingue.',
);

const LipLetterGroup lipsTogetherGroup = LipLetterGroup(
  title: 'Los labios se juntan',
  summary:
      'Se ven muy bien, pero se hacen casi igual: viendo solo los labios no se '
      'puede saber cuál de las cuatro es.',
);

const LipLetterGroup lipAndTeethGroup = LipLetterGroup(
  title: 'El labio toca los dientes',
  summary:
      'Es fácil de reconocer a simple vista. La cámara todavía no la separa '
      'de las letras que se hacen por dentro.',
);

const LipLetterGroup teethTogetherGroup = LipLetterGroup(
  title: 'Los dientes casi se juntan',
  summary:
      'El aire sale entre los dientes y se ven un poco. En Colombia, S, Z y la '
      'C suave suenan igual y se hacen igual.',
);

const LipLetterGroup tongueUpGroup = LipLetterGroup(
  title: 'La lengua sube detrás de los dientes',
  summary:
      'Se hacen por dentro: los labios apenas cambian y se confunden entre '
      'ellas. Ayuda mirar si asoma la punta de la lengua.',
);

const LipLetterGroup palateGroup = LipLetterGroup(
  title: 'La lengua sube hacia el paladar',
  summary: 'Se ven poco. La boca queda entreabierta y algo estirada.',
);

const LipLetterGroup backOfMouthGroup = LipLetterGroup(
  title: 'Se hacen al fondo de la boca',
  summary:
      'Son las más difíciles: por fuera no se ve casi nada. Hay que deducirlas '
      'por la palabra y por lo que se está hablando.',
);

const LipLetterGroup borrowedGroup = LipLetterGroup(
  title: 'Toman la forma de otra letra',
  summary: 'No tienen una forma propia: se ven como la letra que las acompaña.',
);

const MouthPose _closed = MouthPose(opening: 0, width: 0.55);
const MouthPose _ajar = MouthPose(opening: 0.2, width: 0.6);
const MouthPose _tongueUp = MouthPose(
  opening: 0.28,
  width: 0.6,
  teeth: true,
  tongue: MouthTongue.behindTeeth,
);
const MouthPose _teethTogether = MouthPose(
  opening: 0.14,
  width: 0.72,
  teeth: true,
);

/// El abecedario completo, agrupado por cómo se hace cada letra.
///
/// Describe el sonido de la letra, no su nombre: al leer labios se ve lo que
/// la boca hace al pronunciarla dentro de una palabra.
const List<LipLetter> lipAlphabet = [
  LipLetter(
    letter: 'A',
    group: vowelsGroup,
    pose: MouthPose(
      opening: 1,
      width: 0.6,
      teeth: true,
      tongue: MouthTongue.low,
    ),
    how:
        'Abre bien la boca, bajando la mandíbula. Los labios quedan relajados '
        'y la lengua se queda abajo.',
    example: 'agua',
    visibility: LipVisibility.clear,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'E',
    group: vowelsGroup,
    pose: MouthPose(
      opening: 0.45,
      width: 0.82,
      teeth: true,
      tongue: MouthTongue.low,
    ),
    how:
        'Abre la boca a medias y lleva las comisuras un poco hacia los lados, '
        'como una sonrisa pequeña. Se ven los dientes de arriba.',
    example: 'error',
    visibility: LipVisibility.clear,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'I',
    group: vowelsGroup,
    pose: MouthPose(opening: 0.18, width: 1, teeth: true),
    how:
        'Junta casi los dientes y estira las comisuras, como al sonreír. La '
        'abertura queda muy fina.',
    example: 'imprimir',
    visibility: LipVisibility.clear,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'O',
    group: vowelsGroup,
    pose: MouthPose(opening: 0.6, width: 0.25, tongue: MouthTongue.low),
    how:
        'Redondea los labios como un círculo y deja la boca medio abierta. '
        'Las comisuras se acercan.',
    example: 'hola',
    visibility: LipVisibility.clear,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'U',
    group: vowelsGroup,
    pose: MouthPose(opening: 0.22, width: 0),
    how:
        'Adelanta los labios y ciérralos casi del todo, como para soplar una '
        'vela. Es la boca más pequeña de todas.',
    example: 'número',
    visibility: LipVisibility.clear,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'M',
    group: lipsTogetherGroup,
    pose: _closed,
    how:
        'Junta los labios y déjalos así un momento. El aire sale por la nariz.',
    example: 'mal',
    visibility: LipVisibility.similar,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'B',
    group: lipsTogetherGroup,
    pose: _closed,
    how: 'Junta los labios y sepáralos con suavidad, dejando salir la voz.',
    example: 'bien',
    visibility: LipVisibility.similar,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'P',
    group: lipsTogetherGroup,
    pose: _closed,
    how: 'Aprieta los labios y ábrelos de golpe, soltando el aire.',
    example: 'python',
    visibility: LipVisibility.similar,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'V',
    group: lipsTogetherGroup,
    pose: _closed,
    how:
        'En español suena como la B: junta los labios y sepáralos con suavidad.',
    example: 'variable',
    visibility: LipVisibility.similar,
    cameraReads: true,
  ),
  LipLetter(
    letter: 'F',
    group: lipAndTeethGroup,
    pose: MouthPose(opening: 0.2, width: 0.6, teeth: true),
    how:
        'Apoya los dientes de arriba sobre el labio de abajo y deja salir el '
        'aire entre ellos.',
    example: 'función',
    visibility: LipVisibility.clear,
  ),
  LipLetter(
    letter: 'S',
    group: teethTogetherGroup,
    pose: _teethTogether,
    how:
        'Junta casi los dientes, con los labios un poco abiertos hacia los '
        'lados. El aire sale entre los dientes.',
    example: 'sí',
    visibility: LipVisibility.similar,
  ),
  LipLetter(
    letter: 'Z',
    group: teethTogetherGroup,
    pose: _teethTogether,
    how: 'En Colombia suena como la S y se hace igual.',
    example: 'empezar',
    visibility: LipVisibility.similar,
  ),
  LipLetter(
    letter: 'C',
    group: teethTogetherGroup,
    pose: _teethTogether,
    how:
        'Tiene dos formas. Antes de E o I se hace como la S, con los dientes '
        'casi juntos («ejercicio»). Antes de A, O o U se hace al fondo de la '
        'boca, como la K («código»).',
    example: 'ejercicio',
    visibility: LipVisibility.similar,
  ),
  LipLetter(
    letter: 'X',
    group: teethTogetherGroup,
    pose: _teethTogether,
    how:
        'Suena como K y S seguidas: primero la boca entreabierta y luego los '
        'dientes casi juntos.',
    example: 'texto',
    visibility: LipVisibility.similar,
  ),
  LipLetter(
    letter: 'T',
    group: tongueUpGroup,
    pose: _tongueUp,
    how:
        'Apoya la punta de la lengua detrás de los dientes de arriba y suéltala '
        'de golpe, con la boca entreabierta.',
    example: 'lista',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'D',
    group: tongueUpGroup,
    pose: _tongueUp,
    how:
        'Como la T, pero más suave. A veces la punta de la lengua asoma un poco '
        'entre los dientes.',
    example: 'código',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'N',
    group: tongueUpGroup,
    pose: _tongueUp,
    how:
        'Apoya la lengua detrás de los dientes de arriba y déjala ahí. El aire '
        'sale por la nariz.',
    example: 'no',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'L',
    group: tongueUpGroup,
    pose: _tongueUp,
    how:
        'Apoya la punta de la lengua detrás de los dientes de arriba y deja '
        'que el aire salga por los lados. A veces se ve la lengua subir.',
    example: 'lista',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'R',
    group: tongueUpGroup,
    pose: _tongueUp,
    how:
        'La punta de la lengua vibra detrás de los dientes de arriba, con la '
        'boca entreabierta.',
    example: 'error',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'Ñ',
    group: palateGroup,
    pose: _ajar,
    how:
        'Apoya la parte de arriba de la lengua en el paladar, con la boca '
        'entreabierta. Se parece a la N.',
    example: 'baño',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'Y',
    group: palateGroup,
    pose: MouthPose(opening: 0.18, width: 0.9, teeth: true),
    how:
        'Antes de una vocal, sube la lengua hacia el paladar con los labios un '
        'poco estirados («ayuda»). Sola o al final de una palabra se hace '
        'como la I («hoy»).',
    example: 'ayuda',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'G',
    group: backOfMouthGroup,
    pose: _ajar,
    how:
        'La parte de atrás de la lengua sube y se suelta. La boca queda '
        'entreabierta y los labios no cambian.',
    example: 'gracias',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'J',
    group: backOfMouthGroup,
    pose: _ajar,
    how: 'El aire roza el fondo de la boca, con la boca entreabierta.',
    example: 'ejercicio',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'K',
    group: backOfMouthGroup,
    pose: _ajar,
    how:
        'La parte de atrás de la lengua toca el paladar y se suelta de golpe. '
        'Por fuera casi no se ve.',
    example: 'kilo',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'Q',
    group: backOfMouthGroup,
    pose: _ajar,
    how:
        'Suena como la K y se hace igual. Siempre va con una U que, en «que» y '
        '«qui», no se pronuncia.',
    example: 'que',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'H',
    group: borrowedGroup,
    pose: MouthPose(opening: 0.6, width: 0.25, tongue: MouthTongue.low),
    how:
        'No suena. La boca ya hace la letra que sigue: en «hola» lo que se ve '
        'es la O.',
    example: 'hola',
    visibility: LipVisibility.hidden,
  ),
  LipLetter(
    letter: 'W',
    group: borrowedGroup,
    pose: MouthPose(opening: 0.22, width: 0),
    how:
        'Suena como una U muy corta: los labios se adelantan y se abren enseguida '
        'hacia la vocal que sigue.',
    example: 'web',
    visibility: LipVisibility.similar,
  ),
];
