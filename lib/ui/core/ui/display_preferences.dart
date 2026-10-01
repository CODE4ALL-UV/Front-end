import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';

/// Recuerda en el dispositivo los colores y el tamaño del texto.
///
/// Sin esto, quien necesita el tema oscuro o la letra al 150 % tenía que
/// volver a ponerlos cada vez que abría la aplicación, y el login —donde no
/// hay ningún ajuste— le salía siempre en claro y a tamaño normal.
///
/// Las claves empiezan por [prefix] para que cerrar sesión no las borre: son
/// del dispositivo, no de quien entró.
class DisplayPreferences {
  DisplayPreferences._();

  static final DisplayPreferences instance = DisplayPreferences._();

  static const String prefix = 'display_';
  static const String _themeKey = '${prefix}theme_mode';
  static const String _scaleKey = '${prefix}text_scale';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool _started = false;

  /// Aplica lo guardado y empieza a guardar cada cambio.
  Future<void> restore() async {
    if (_started) return;
    _started = true;

    try {
      final theme = await _storage.read(key: _themeKey);
      final scale = double.tryParse(await _storage.read(key: _scaleKey) ?? '');

      for (final mode in AppThemeMode.values) {
        if (mode.name == theme) ThemeManager.changeTheme(mode);
      }
      if (scale != null) {
        AccessibilityTextScaleController.global.setScale(scale);
      }
    } catch (e) {
      debugPrint('No se pudieron leer los ajustes de pantalla: $e');
    }

    ThemeManager.themeNotifier.addListener(_saveTheme);
    AccessibilityTextScaleController.global.addListener(_saveScale);
  }

  void _saveTheme() => _write(_themeKey, ThemeManager.themeNotifier.value.name);

  void _saveScale() => _write(
    _scaleKey,
    AccessibilityTextScaleController.global.scale.toStringAsFixed(2),
  );

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('No se pudo guardar el ajuste de pantalla: $e');
    }
  }
}
