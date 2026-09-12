import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sabe qué imágenes de señas hay realmente empaquetadas en la app.
///
/// El panel de señas dibuja la mano en código, pero en cuanto se añade una
/// foto o un clip real ese material manda. Para no obligar a tocar código cada
/// vez, este índice lee una sola vez el manifiesto de assets y recuerda qué
/// letras y qué palabras tienen imagen.
///
/// Basta con dejar los archivos en su carpeta y declararla en el
/// `pubspec.yaml`; no hay ningún interruptor que activar.
class SignAssetIndex {
  SignAssetIndex._();

  static final SignAssetIndex instance = SignAssetIndex._();

  /// Una imagen por letra: `a.png`, `b.png`, `enie.png`…
  static const String lettersFolder = 'assets/sign_language/letras';

  /// Una imagen o GIF por palabra: `funcion.gif`, `variable.gif`…
  static const String wordsFolder = 'assets/sign_language/palabras';

  final Map<String, String> _letters = {};
  final Map<String, String> _words = {};

  Future<void>? _loading;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get hasAnyLetter => _letters.isNotEmpty;
  bool get hasAnyWord => _words.isNotEmpty;

  /// Lee el manifiesto la primera vez que se llama; después no hace nada.
  Future<void> ensureLoaded() {
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      // Con un tiempo límite: si el manifiesto no llegara, el panel debe
      // seguir dibujando la mano en vez de quedarse esperando para siempre.
      final manifest = await AssetManifest.loadFromAssetBundle(
        rootBundle,
      ).timeout(const Duration(seconds: 5));

      for (final path in manifest.listAssets()) {
        if (!_isImage(path)) continue;

        if (path.startsWith('$lettersFolder/')) {
          final key = _keyOf(path);
          if (key.isNotEmpty) _letters[key] = path;
        } else if (path.startsWith('$wordsFolder/')) {
          final key = _keyOf(path);
          if (key.isNotEmpty) _words[key] = path;
        }
      }
    } catch (e) {
      // Que no haya manifiesto (por ejemplo en pruebas) no puede impedir que
      // se dibuje la mano: simplemente no habrá imágenes.
      debugPrint('No se pudo leer el manifiesto de señas: $e');
    }

    _loaded = true;
  }

  /// Ruta de la imagen de una letra, o `null` si no hay ninguna.
  String? letterAsset(String letter) => _letters[_normalize(letter)];

  /// Ruta de la imagen de una palabra, o `null` si no hay ninguna.
  String? wordAsset(String word) => _words[_normalize(word)];

  /// Los README de cada carpeta también están empaquetados: no son señas.
  static bool _isImage(String path) {
    const extensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif'];
    final lower = path.toLowerCase();
    return extensions.any(lower.endsWith);
  }

  /// Nombre del archivo, sin carpeta ni extensión y ya normalizado.
  static String _keyOf(String path) {
    final fileName = path.split('/').last;
    final dot = fileName.lastIndexOf('.');
    return _normalize(dot == -1 ? fileName : fileName.substring(0, dot));
  }

  /// Deja el texto en minúscula y sin tildes, para que `FUNCIÓN`, `funcion` y
  /// `Función` encuentren el mismo archivo.
  @visibleForTesting
  static String normalizeForTest(String value) => _normalize(value);

  static String _normalize(String value) {
    const from = 'áàäâéèëêíìïîóòöôúùüûÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛ';
    const to = 'aaaaeeeeiiiioooouuuuaaaaeeeeiiiioooouuuu';

    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }

    final plain = buffer.toString();

    // La letra suelta se llama "enie". Dentro de una palabra la eñe se
    // transcribe "ni", para que "año" sea "anio" y no algo desafortunado.
    if (plain == 'ñ') return 'enie';
    return plain.replaceAll('ñ', 'ni');
  }
}
