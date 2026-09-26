import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A qué ritmo habla el asistente de voz.
enum SpeechPace {
  slow('Lenta', 0.20),
  medium('Media', 0.35),
  fast('Rápida', 0.50);

  const SpeechPace(this.label, this.rate);

  /// Cómo se llama en el panel de ayuda.
  final String label;

  /// Lo que entiende el motor de voz. En web se traduce aparte, porque allí
  /// 1.0 es la velocidad normal y en móvil es 0.5.
  final double rate;

  static SpeechPace fromLabel(String label) => SpeechPace.values.firstWhere(
    (pace) => pace.label == label,
    orElse: () => SpeechPace.medium,
  );
}

/// Cuánto apoyo en señas se muestra.
enum SignSupportLevel {
  /// Ninguno: el contenido se ve como siempre.
  off('Desactivado'),

  /// Se deletrea con el alfabeto manual lo que se está diciendo.
  basic('Básico'),

  /// Además del deletreo, la seña de la palabra cuando existe grabada.
  advanced('Avanzado');

  const SignSupportLevel(this.label);

  final String label;

  static SignSupportLevel fromLabel(String label) =>
      SignSupportLevel.values.firstWhere(
        (level) => level.label == label,
        orElse: () => SignSupportLevel.off,
      );
}

/// Qué tipo de actividad prefiere quien aprende.
enum ContentPreference {
  none('Sin preferencia'),
  readings('Lecturas'),
  videos('Videos'),
  audios('Audios');

  const ContentPreference(this.label);

  final String label;

  static ContentPreference fromLabel(String label) =>
      ContentPreference.values.firstWhere(
        (preference) => preference.label == label,
        orElse: () => ContentPreference.none,
      );
}

/// Cuánto acompañamiento se muestra alrededor del contenido.
enum LearningLevel {
  /// Todo el apoyo: objetivos, resúmenes y la explicación de cada respuesta.
  basic('Básico'),

  /// El apoyo justo.
  medium('Medio'),

  /// Sin andamiaje: sólo el contenido.
  advanced('Avanzado');

  const LearningLevel(this.label);

  final String label;

  static LearningLevel fromLabel(String label) =>
      LearningLevel.values.firstWhere(
        (level) => level.label == label,
        orElse: () => LearningLevel.medium,
      );
}

/// Los ajustes de aprendizaje y accesibilidad que elige el estudiante.
///
/// Estaban todos dibujados en el menú de ayuda pero sin nada detrás: los
/// botones tenían `onTap: () {}` y el interruptor de la voz estaba fijo en
/// `true`. Aquí viven de verdad, se guardan en el dispositivo y cada pantalla
/// que dependa de ellos escucha los cambios.
///
/// Se guarda en el almacén seguro porque es el único que trae la aplicación y
/// funciona igual en web y en móvil.
class LearningPreferences extends ChangeNotifier {
  LearningPreferences._();

  static final LearningPreferences instance = LearningPreferences._();

  /// Para las pruebas: una instancia suelta que no toca el disco.
  @visibleForTesting
  factory LearningPreferences.forTest() {
    final preferences = LearningPreferences._();
    preferences._loaded = true;
    preferences._persist = false;
    return preferences;
  }

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _paceKey = 'learning_speech_pace';
  static const String _clearSpeechKey = 'learning_clear_speech';
  static const String _signKey = 'learning_sign_support';
  static const String _contentKey = 'learning_content_preference';
  static const String _levelKey = 'learning_level';
  static const String _hintsKey = 'learning_hints';
  static const String _manualKey = 'learning_manual';

  bool _loaded = false;
  bool _persist = true;

  SpeechPace _pace = SpeechPace.medium;
  bool _clearSpeech = false;
  SignSupportLevel _signSupport = SignSupportLevel.off;
  ContentPreference _contentPreference = ContentPreference.none;
  LearningLevel _level = LearningLevel.medium;
  bool _hintsEnabled = false;
  bool _manualEnabled = false;

  bool get isLoaded => _loaded;

  /// El ritmo al que habla el asistente.
  SpeechPace get pace => _pace;

  /// Si la voz va más pausada de lo normal.
  ///
  /// No es lo mismo que el ritmo: esto baja además la velocidad un escalón y
  /// separa las frases, para quien necesita tiempo entre idea e idea.
  bool get clearSpeech => _clearSpeech;

  /// La velocidad que hay que pedirle al motor, ya con todo aplicado.
  double get effectiveSpeechRate {
    final base = _pace.rate;
    return _clearSpeech ? (base * 0.7).clamp(0.1, 1.0) : base;
  }

  SignSupportLevel get signSupport => _signSupport;
  ContentPreference get contentPreference => _contentPreference;
  LearningLevel get level => _level;

  /// Si se ofrece una pista antes de responder.
  bool get hintsEnabled => _hintsEnabled;

  /// Si el recorrido guiado está encendido.
  bool get manualEnabled => _manualEnabled;

  /// Si hay que mostrar los apoyos del nivel básico.
  bool get showsExtraSupport => _level == LearningLevel.basic;

  /// Si se retiran los andamios: los objetivos de la sección dejan de ir
  /// desplegados.
  ///
  /// Sólo en «Avanzado». El nivel de partida es «Medio» y ahí todo sigue como
  /// estaba: un ajuste que nadie ha tocado no puede cambiar lo que se ve.
  bool get hidesScaffolding => _level == LearningLevel.advanced;

  /// Si hay que empezar a leer en voz alta al abrir una actividad.
  ///
  /// Sale de preferir «Audios»: de poco sirve decir que se prefiere el audio
  /// si luego hay que pedirlo a mano en cada pantalla.
  bool get autoReadAloud => _contentPreference == ContentPreference.audios;

  Future<void> ensureLoaded() async {
    if (_loaded) return;

    try {
      final stored = await _storage.readAll();
      _pace = SpeechPace.fromLabel(stored[_paceKey] ?? '');
      _clearSpeech = stored[_clearSpeechKey] == 'true';
      _signSupport = SignSupportLevel.fromLabel(stored[_signKey] ?? '');
      _contentPreference = ContentPreference.fromLabel(
        stored[_contentKey] ?? '',
      );
      _level = LearningLevel.fromLabel(stored[_levelKey] ?? '');
      _hintsEnabled = stored[_hintsKey] == 'true';
      _manualEnabled = stored[_manualKey] == 'true';
    } catch (e) {
      // Que no se pueda leer no puede dejar a nadie sin aplicación: se
      // arranca con los valores de siempre.
      debugPrint('No se pudieron leer los ajustes de aprendizaje: $e');
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setPace(SpeechPace value) =>
      _update(_paceKey, value.label, () => _pace = value);

  Future<void> setClearSpeech(bool value) =>
      _update(_clearSpeechKey, '$value', () => _clearSpeech = value);

  Future<void> setSignSupport(SignSupportLevel value) =>
      _update(_signKey, value.label, () => _signSupport = value);

  Future<void> setContentPreference(ContentPreference value) =>
      _update(_contentKey, value.label, () => _contentPreference = value);

  Future<void> setLevel(LearningLevel value) =>
      _update(_levelKey, value.label, () => _level = value);

  Future<void> setHintsEnabled(bool value) =>
      _update(_hintsKey, '$value', () => _hintsEnabled = value);

  Future<void> setManualEnabled(bool value) =>
      _update(_manualKey, '$value', () => _manualEnabled = value);

  Future<void> _update(String key, String value, VoidCallback apply) async {
    apply();
    _loaded = true;
    notifyListeners();

    if (!_persist) return;

    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      // El cambio ya se aplicó en pantalla; lo único que se pierde es que
      // sobreviva al reinicio.
      debugPrint('No se pudo guardar el ajuste $key: $e');
    }
  }
}
