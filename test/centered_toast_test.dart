import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/centered_toast.dart';

/// El aviso de los ajustes del menú de ayuda.
///
/// Antes era un `SnackBar`, que sale abajo: justo donde están los botones de
/// ese menú, así que el aviso quedaba tapado por ellos. Se cambiaba un ajuste
/// y parecía que el toque no había hecho nada.
void main() {
  Widget host(void Function(BuildContext) onPressed) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onPressed(context),
            child: const Text('probar'),
          ),
        ),
      ),
    ),
  );

  /// Cierra el aviso y deja correr su animación.
  ///
  /// Hay que hacerlo dentro del test y no en un tearDown: Flutter comprueba
  /// que no queden temporizadores pendientes **antes** de ejecutar los
  /// tearDown, así que allí llegaría tarde y el test fallaría por un
  /// temporizador que sí se iba a cancelar.
  Future<void> cerrarAviso(WidgetTester tester) async {
    CenteredToast.dismissNow();
    await tester.pumpAndSettle();
  }

  testWidgets('sale en el centro, no abajo', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host((context) => CenteredToast.show(context, 'Pistas activadas.')),
    );
    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();

    final aviso = find.text('Pistas activadas.');
    expect(aviso, findsOneWidget);

    final caja = tester.renderObject<RenderBox>(aviso);
    final centro = caja.localToGlobal(Offset.zero).dy + caja.size.height / 2;

    // Con un SnackBar esto caía por debajo de 700 y quedaba bajo los botones
    // del menú de ayuda.
    expect(
      centro,
      inInclusiveRange(300, 500),
      reason: 'debe quedar a media altura, lejos de los botones de abajo',
    );

    await cerrarAviso(tester);
  });

  testWidgets('desaparece solo', (tester) async {
    await tester.pumpWidget(
      host((context) => CenteredToast.show(context, 'Nivel avanzado.')),
    );
    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();
    expect(find.text('Nivel avanzado.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();

    expect(find.text('Nivel avanzado.'), findsNothing);
  });

  testWidgets('un aviso nuevo reemplaza al anterior, no se apilan', (
    tester,
  ) async {
    late BuildContext saved;
    await tester.pumpWidget(
      host((context) {
        saved = context;
        CenteredToast.show(context, 'Primero.');
      }),
    );
    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();

    CenteredToast.show(saved, 'Segundo.');
    await tester.pumpAndSettle();

    // Apilados en el centro se taparían entre ellos, que es justo el problema
    // que se venía a resolver.
    expect(find.text('Primero.'), findsNothing);
    expect(find.text('Segundo.'), findsOneWidget);

    await cerrarAviso(tester);
  });

  testWidgets('no bloquea lo que hay debajo', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  toques++;
                  CenteredToast.show(context, 'Hola.');
                },
                child: const Text('probar'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();
    // El aviso está puesto y encima del botón; aun así se puede volver a
    // pulsar, porque no intercepta toques.
    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();

    expect(toques, 2);

    await cerrarAviso(tester);
  });

  testWidgets('un mensaje largo dura más que uno corto', (tester) async {
    await tester.pumpWidget(
      host(
        (context) => CenteredToast.show(
          context,
          'Apoyo en señas: básico.\nEn las actividades de video verás un panel '
          'que deletrea con el alfabeto manual lo que se está diciendo.',
        ),
      ),
    );
    await tester.tap(find.text('probar'));
    await tester.pumpAndSettle();

    // A los 3 segundos un mensaje corto ya se habría ido; este no, porque hay
    // que darle tiempo a leerlo.
    await tester.pump(const Duration(seconds: 3));
    expect(find.textContaining('alfabeto manual'), findsOneWidget);

    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.textContaining('alfabeto manual'), findsNothing);
  });
}
