import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_text_scale_widget.dart';
import 'package:flutter_code4all/ui/core/ui/display_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'restaura preferencias guardadas y persiste los cambios posteriores',
    () async {
      // Elegimos modos válidos de la aplicación, sin depender de sus nombres.
      final initialMode = ThemeManager.themeNotifier.value;
      final savedMode = AppThemeMode.values.firstWhere(
        (mode) => mode != initialMode,
        orElse: () => initialMode,
      );

      // Sustituye el almacenamiento seguro por uno en memoria para el test.
      FlutterSecureStorage.setMockInitialValues({
        'display_theme_mode': savedMode.name,
        'display_text_scale': '1.25',
      });

      await DisplayPreferences.instance.restore();

      // Comprueba que se hayan aplicado las preferencias persistidas.
      expect(ThemeManager.themeNotifier.value, savedMode);
      expect(
        AccessibilityTextScaleController.global.scale,
        closeTo(1.25, 0.001),
      );

      // Cambiar las preferencias después de restaurarlas debe guardarlas.
      final nextMode = AppThemeMode.values.firstWhere(
        (mode) => mode != savedMode,
        orElse: () => savedMode,
      );
      ThemeManager.changeTheme(nextMode);
      AccessibilityTextScaleController.global.setScale(1.35);

      // Los listeners guardan de manera asíncrona.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'display_theme_mode'), nextMode.name);
      expect(await storage.read(key: 'display_text_scale'), '1.35');

      // restore() debe ser idempotente: una segunda llamada no debe volver
      // a aplicar valores distintos que se escriban después en el almacenamiento.
      await storage.write(key: 'display_theme_mode', value: savedMode.name);
      await storage.write(key: 'display_text_scale', value: '1.10');

      await DisplayPreferences.instance.restore();

      expect(ThemeManager.themeNotifier.value, nextMode);
      expect(
        AccessibilityTextScaleController.global.scale,
        closeTo(1.35, 0.001),
      );
    },
  );
}
