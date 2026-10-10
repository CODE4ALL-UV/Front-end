import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Ajusta las rutas según la estructura de tu proyecto
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/ui/display_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AuthStorage authStorage;

  setUp(() {
    // Configura el mock en memoria de flutter_secure_storage para las pruebas
    FlutterSecureStorage.setMockInitialValues({});
    authStorage = AuthStorage();
  });

  group('AuthStorage', () {
    test('Guarda y recupera todos los datos correctamente', () async {
      await authStorage.saveToken('test_token_123');
      await authStorage.saveRole('docente');
      await authStorage.saveName('Ada Lovelace');
      await authStorage.saveEmail('ada@example.com');
      await authStorage.saveUserId(42);
      await authStorage.savePhotoUrl('https://example.com/photo.png');

      expect(await authStorage.getToken(), 'test_token_123');
      expect(await authStorage.getRole(), 'docente');
      expect(await authStorage.getName(), 'Ada Lovelace');
      expect(await authStorage.getEmail(), 'ada@example.com');
      expect(await authStorage.getUserId(), 42);
      expect(await authStorage.getPhotoUrl(), 'https://example.com/photo.png');
    });

    test('Devuelve null si no hay datos guardados', () async {
      expect(await authStorage.getToken(), isNull);
      expect(await authStorage.getUserId(), isNull);
    });

    test(
      'clear() borra la sesión pero conserva las preferencias de pantalla',
      () async {
        // 1. Guardamos datos de sesión
        await authStorage.saveToken('token_a_borrar');
        await authStorage.saveUserId(1);

        // 2. Simulamos guardar una preferencia de pantalla usando la misma instancia interna
        const secureStorage = FlutterSecureStorage();
        final displayKey = '${DisplayPreferences.prefix}theme_mode';
        await secureStorage.write(key: displayKey, value: 'dark');

        // 3. Ejecutamos la limpieza
        await authStorage.clear();

        // 4. Verificamos que los datos de sesión desaparecieron
        expect(await authStorage.getToken(), isNull);
        expect(await authStorage.getUserId(), isNull);

        // 5. Verificamos que las preferencias de pantalla sobrevivieron
        final remainingDisplayValue = await secureStorage.read(key: displayKey);
        expect(remainingDisplayValue, 'dark');
      },
    );
  });
}
