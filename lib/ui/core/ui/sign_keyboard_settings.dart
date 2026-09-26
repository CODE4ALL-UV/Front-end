import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Si el estudiante quiere escribir con el teclado de dactilología.
///
/// Se guarda en el dispositivo porque es una preferencia de accesibilidad:
/// quien la necesita la necesita siempre, y tener que volver a activarla en
/// cada sesión es justo la clase de fricción que hace que se deje de usar.
///
/// Se usa el almacén seguro porque es el único que trae la aplicación y
/// funciona igual en web y en móvil. Para un booleano es más maquinaria de la
/// necesaria, pero añadir otra dependencia para esto lo sería más.
class SignKeyboardSettings extends ChangeNotifier {
  SignKeyboardSettings._();

  static final SignKeyboardSettings instance = SignKeyboardSettings._();

  /// Para las pruebas: una instancia suelta que no toca el disco.
  @visibleForTesting
  factory SignKeyboardSettings.forTest({bool enabled = false}) {
    final settings = SignKeyboardSettings._();
    settings._enabled = enabled;
    settings._loaded = true;
    settings._persist = false;
    return settings;
  }

  static const String _key = 'sign_keyboard_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _enabled = false;
  bool _loaded = false;
  bool _persist = true;

  /// Si está activado ahora mismo.
  bool get isEnabled => _enabled;

  /// Si ya se leyó lo guardado al menos una vez.
  bool get isLoaded => _loaded;

  /// Lee la preferencia guardada. Llamarlo de más no cuesta nada.
  Future<void> ensureLoaded() async {
    if (_loaded) return;

    try {
      final stored = await _storage.read(key: _key);
      _enabled = stored == 'true';
    } catch (e) {
      // Que no se pueda leer no puede dejar a nadie sin aplicación: se
      // arranca con el teclado normal, que es el comportamiento de siempre.
      debugPrint('No se pudo leer la preferencia del teclado de señas: $e');
      _enabled = false;
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;

    _enabled = value;
    _loaded = true;
    notifyListeners();

    if (!_persist) return;

    try {
      await _storage.write(key: _key, value: value ? 'true' : 'false');
    } catch (e) {
      // El cambio ya está aplicado en pantalla; lo único que se pierde es que
      // sobreviva al reinicio. Vale más eso que deshacer lo que la persona
      // acaba de pedir.
      debugPrint('No se pudo guardar la preferencia del teclado de señas: $e');
    }
  }

  Future<void> toggle() => setEnabled(!_enabled);
}
