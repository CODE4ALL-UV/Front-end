import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_scope_widget.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_settings.dart';
import 'package:flutter_code4all/ui/core/ui/sign_keyboard_widget.dart';

/// Cómo se engancha el teclado de dactilología a un campo cualquiera.
///
/// Lo importante de estas pruebas: apagado no debe notarse **nada**. Es una
/// ayuda para quien la necesita, no algo que cambie la aplicación para el
/// resto, y un campo que de pronto no acepta el teclado del sistema sería un
/// fallo grave para todos los demás.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // El almacén seguro no existe en un test: sin fingirlo, cada lectura o
  // escritura de la preferencia se queda esperando a un canal nativo que no
  // hay.
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final stored = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, Object?>() ?? {};
          final key = args['key']?.toString() ?? '';
          switch (call.method) {
            case 'write':
              stored[key] = args['value']?.toString() ?? '';
              return null;
            case 'read':
              return stored[key];
            case 'delete':
              stored.remove(key);
              return null;
            case 'readAll':
              return stored;
            default:
              return null;
          }
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  Widget host({required TextEditingController controller}) => MaterialApp(
    theme: AppTheme.getTheme(mode: AppThemeMode.light),
    home: Scaffold(
      body: SignKeyboardScope(
        child: Center(
          child: SignKeyboardField(
            controller: controller,
            builder: (context, focusNode, readOnly) => TextField(
              controller: controller,
              focusNode: focusNode,
              readOnly: readOnly,
              showCursor: true,
            ),
          ),
        ),
      ),
    ),
  );

  tearDown(() async {
    // El ajuste es global: si una prueba lo deja encendido, envenena la
    // siguiente.
    await SignKeyboardSettings.instance.setEnabled(false);
  });

  testWidgets('apagado, el campo se comporta como siempre', (tester) async {
    await SignKeyboardSettings.instance.setEnabled(false);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(host(controller: controller));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(
      find.byType(SignKeyboard),
      findsNothing,
      reason: 'sin activarlo no debe aparecer',
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).readOnly,
      isFalse,
      reason: 'el teclado del sistema tiene que seguir funcionando',
    );
  });

  testWidgets('encendido, sale al enfocar el campo y escribe en él', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await SignKeyboardSettings.instance.setEnabled(true);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(host(controller: controller));

    // El campo pasa a sólo lectura: es lo que impide que salga el teclado del
    // sistema encima del nuestro.
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.byType(SignKeyboard), findsOneWidget);

    await tester.tap(find.text('S'));
    await tester.pump();
    await tester.tap(find.text('I'));
    await tester.pump();

    expect(controller.text, 'SI');
  });

  testWidgets('apagarlo mientras está abierto lo cierra', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await SignKeyboardSettings.instance.setEnabled(true);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(host(controller: controller));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.byType(SignKeyboard), findsOneWidget);

    await SignKeyboardSettings.instance.setEnabled(false);
    await tester.pump();

    expect(
      find.byType(SignKeyboard),
      findsNothing,
      reason: 'dejarlo puesto sería ignorar lo que se acaba de pedir',
    );
  });

  testWidgets('la tecla Listo lo cierra sin borrar lo escrito', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await SignKeyboardSettings.instance.setEnabled(true);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(host(controller: controller));
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Listo'));
    await tester.pump();

    expect(find.byType(SignKeyboard), findsNothing);
    expect(controller.text, 'A');
  });
}
