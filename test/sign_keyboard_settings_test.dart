import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_settings.dart';

void main() {
  group('SignKeyboardSettings Tests', () {
    late SignKeyboardSettings settings;

    setUp(() {
      // Crea una instancia aislada que no lee ni escribe almacenamiento real.
      settings = SignKeyboardSettings.forTest();
    });

    tearDown(() {
      settings.dispose();
    });

    test(
      'Inicia desactivado, cargado y sin una sesión de estudiante activa',
      () {
        expect(settings.isEnabled, isFalse);
        expect(settings.isLoaded, isTrue);
        expect(settings.isActive, isFalse);
      },
    );

    test('Permite crear una instancia de prueba activada', () {
      settings.dispose();
      settings = SignKeyboardSettings.forTest(enabled: true);

      expect(settings.isEnabled, isTrue);
      expect(settings.isLoaded, isTrue);
      // Aunque la preferencia esté activada, requiere sesión de estudiante.
      expect(settings.isActive, isFalse);
    });

    test(
      'setEnabled(true) actualiza el valor y notifica a los listeners',
      () async {
        var notifications = 0;
        settings.addListener(() => notifications++);

        await settings.setEnabled(true);

        expect(settings.isEnabled, isTrue);
        expect(settings.isLoaded, isTrue);
        expect(settings.isActive, isFalse);
        expect(notifications, 1);
      },
    );

    test('setEnabled(false) desactiva una preferencia habilitada', () async {
      settings.dispose();
      settings = SignKeyboardSettings.forTest(enabled: true);
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setEnabled(false);

      expect(settings.isEnabled, isFalse);
      expect(settings.isActive, isFalse);
      expect(notifications, 1);
    });

    test('No notifica cuando setEnabled recibe el valor actual', () async {
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.setEnabled(false);
      expect(notifications, 0);

      await settings.setEnabled(true);
      expect(notifications, 1);

      await settings.setEnabled(true);
      expect(settings.isEnabled, isTrue);
      expect(notifications, 1);
    });

    test('toggle alterna la preferencia y notifica en cada cambio', () async {
      var notifications = 0;
      settings.addListener(() => notifications++);

      await settings.toggle();
      expect(settings.isEnabled, isTrue);
      expect(settings.isActive, isFalse);
      expect(notifications, 1);

      await settings.toggle();
      expect(settings.isEnabled, isFalse);
      expect(settings.isActive, isFalse);
      expect(notifications, 2);
    });

    test(
      'ensureLoaded no modifica una instancia de prueba ya cargada',
      () async {
        settings.dispose();
        settings = SignKeyboardSettings.forTest(enabled: true);

        var notifications = 0;
        settings.addListener(() => notifications++);

        await settings.ensureLoaded();

        expect(settings.isLoaded, isTrue);
        expect(settings.isEnabled, isTrue);
        expect(notifications, 0);
      },
    );
  });
}
