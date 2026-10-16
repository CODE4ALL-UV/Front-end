import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_settings.dart';

/// Los ajustes de accesibilidad se guardan en el almacén seguro del
/// dispositivo, y ese almacén falla de vez en cuando: hay navegadores que no
/// lo dejan usar y móviles que lo bloquean.
///
/// La regla es la misma en todos: **que el almacén falle no puede dejar a
/// nadie sin aplicación ni deshacer lo que acaba de elegir**. Si no se puede
/// leer, se arranca con los valores de siempre; si no se puede guardar, el
/// cambio se aplica igual y solo se pierde que sobreviva al reinicio.
///
/// Se finge el canal nativo del almacén para hacerlo fallar a voluntad.
///
/// Ojo: las dos primeras pruebas leen por primera vez los ajustes globales,
/// que solo se leen una vez por proceso. Por eso van al principio.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final calls = <MethodCall>[];

  /// Qué operaciones fallan: el método, o «método:clave» para una sola clave.
  final failing = <String>{};

  setUp(() {
    calls.clear();
    failing.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final key = (call.arguments as Map?)?['key'];
          if (failing.contains(call.method) ||
              failing.contains('${call.method}:$key')) {
            throw PlatformException(code: 'storage', message: 'bloqueado');
          }
          if (call.method == 'readAll') return <String, String>{};
          if (call.method == 'read' && key == 'sign_keyboard_enabled') {
            return 'true';
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('teclado con dactilología', () {
    final settings = SignKeyboardSettings.instance;

    tearDown(() async {
      // Se deja como sin sesión y desactivado, que es como arranca.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => null);
      await settings.setEnabled(false);
      await settings.refreshSession();
    });

    test('si no se puede leer, arranca con el teclado normal', () async {
      failing.add('read');

      await settings.ensureLoaded();

      expect(settings.isLoaded, isTrue);
      expect(settings.isEnabled, isFalse);
      expect(settings.isActive, isFalse);
    });

    test('si no se puede saber el rol, no se activa por si acaso', () async {
      // La preferencia sí se lee (estaba activada), pero el rol no.
      failing.add('read:auth_role');
      await settings.setEnabled(true);

      await settings.refreshSession();

      expect(settings.isEnabled, isTrue);
      expect(
        settings.isActive,
        isFalse,
        reason: 'sin saber si es estudiante, mejor el teclado normal',
      );
    });

    test('con sesión de estudiante y activado, se usa', () async {
      final notified = <bool>[];
      void listener() => notified.add(settings.isActive);
      settings.addListener(listener);
      addTearDown(() => settings.removeListener(listener));

      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            final key = (call.arguments as Map?)?['key'];
            return key == 'auth_role' ? 'Estudiante ' : null;
          });

      await settings.setEnabled(true);
      await settings.refreshSession();

      expect(settings.isActive, isTrue);
      // Cambiar de sesión avisa a quien escucha, para que el campo cambie.
      expect(notified.last, isTrue);

      // Volver a mirar con el mismo rol no avisa de nada nuevo.
      final before = notified.length;
      await settings.refreshSession();
      expect(notified.length, before);
    });

    test('si no se puede guardar, el cambio se aplica igual', () async {
      failing.add('write');

      await settings.setEnabled(true);

      expect(settings.isEnabled, isTrue);
      expect(
        calls.where((c) => c.method == 'write'),
        hasLength(1),
        reason: 'se intentó guardar',
      );
    });

    test('pedir el mismo valor que ya tiene no escribe nada', () async {
      await settings.setEnabled(false);
      calls.clear();

      await settings.setEnabled(false);

      expect(calls, isEmpty);
    });
  });

  group('ajustes de aprendizaje', () {
    final prefs = LearningPreferences.instance;

    tearDown(() async {
      failing.clear();
      await prefs.setPace(SpeechPace.medium);
      await prefs.setLevel(LearningLevel.medium);
    });

    test('si no se pueden leer, arranca con los valores de siempre', () async {
      failing.add('readAll');

      await prefs.ensureLoaded();

      expect(prefs.isLoaded, isTrue);
      expect(prefs.pace, SpeechPace.medium);
      expect(prefs.clearSpeech, isFalse);
      expect(prefs.level, LearningLevel.medium);
      expect(prefs.signSupport, SignSupportLevel.off);
    });

    test('si no se puede guardar, el cambio se aplica igual', () async {
      failing.add('write');
      var notified = 0;
      void listener() => notified++;
      prefs.addListener(listener);
      addTearDown(() => prefs.removeListener(listener));

      await prefs.setLevel(LearningLevel.advanced);

      expect(prefs.level, LearningLevel.advanced);
      expect(prefs.hidesScaffolding, isTrue);
      expect(notified, 1, reason: 'las pantallas se enteran del cambio');
    });

    test('la instancia de pruebas no toca el almacén', () async {
      final local = LearningPreferences.forTest();

      expect(local.isLoaded, isTrue);
      await local.ensureLoaded();
      await local.setPace(SpeechPace.slow);
      await local.setClearSpeech(true);

      expect(local.pace, SpeechPace.slow);
      expect(local.clearSpeech, isTrue);
      expect(calls, isEmpty);
      // Y no se mezcla con los ajustes globales.
      expect(prefs.pace, SpeechPace.medium);
    });
  });
}
