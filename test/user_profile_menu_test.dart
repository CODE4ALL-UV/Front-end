import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

/// Comprueba el menú de la esquina: el avatar, los iconos y salir de verdad.
///
/// Nace de dos problemas reales. Los iconos del menú heredaban el blanco de la
/// barra roja y desaparecían sobre el fondo claro del desplegable: se leía el
/// texto pero no se veía el icono. Y cerrar sesión dependía de que el
/// almacenamiento seguro respondiera bien; si fallaba, la persona se quedaba
/// dentro por mucho que pulsara.
void main() {
  /// Monta el menú donde de verdad vive: dentro de una barra de color, que es
  /// lo que provocaba que los iconos se volvieran invisibles.
  Widget inAppBar({VoidCallback? onLogout, String name = 'Mateo'}) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          title: const Text('CODE4ALL'),
          actions: [
            UserProfileMenu(userName: name, onLogout: onLogout, showName: true),
          ],
        ),
        body: const SizedBox.expand(),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pump();
    await tester.tap(find.byType(UserProfileMenu));
    await tester.pumpAndSettle();
  }

  group('se ve lo que hay que ver', () {
    testWidgets('el menú se abre con sus dos opciones', (tester) async {
      await tester.pumpWidget(inAppBar());
      await openMenu(tester);

      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('los iconos del menú no son blancos', (tester) async {
      // Este es el fallo exacto: heredaban el blanco de la barra y quedaban
      // invisibles sobre el fondo claro del desplegable.
      await tester.pumpWidget(inAppBar());
      await openMenu(tester);

      for (final icon in [Icons.person_outline, Icons.logout]) {
        final widget = tester.widget<Icon>(find.byIcon(icon));
        expect(widget.color, isNotNull, reason: 'el icono $icon no lleva color');
        expect(
          widget.color,
          isNot(Colors.white),
          reason: 'el icono $icon se perderia sobre el menu claro',
        );
      }
    });

    testWidgets('el avatar contrasta con la barra, no se funde en ella', (
      tester,
    ) async {
      await tester.pumpWidget(inAppBar());
      await tester.pump();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      // La barra es roja; el circulo tiene que distinguirse de ella.
      expect(avatar.backgroundColor, isNot(const Color(0xFFE53935)));
      expect(find.text('M'), findsOneWidget);
    });
  });

  group('cerrar sesión', () {
    testWidgets('una sola pulsación basta', (tester) async {
      var salidas = 0;
      await tester.pumpWidget(inAppBar(onLogout: () => salidas++));
      await openMenu(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(salidas, 1, reason: 'con una pulsación debe salir');
      expect(tester.takeException(), isNull);
    });

    testWidgets('sale aunque el almacenamiento falle', (tester) async {
      // En las pruebas el almacenamiento seguro no tiene plataforma detrás y
      // falla: justo el caso que dejaba a la persona atrapada. Salir no puede
      // depender de que se consiga borrar el token.
      var salidas = 0;
      await tester.pumpWidget(inAppBar(onLogout: () => salidas++));
      await openMenu(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(salidas, 1);
    });

    testWidgets('abrir el perfil no cierra la sesión', (tester) async {
      var salidas = 0;
      await tester.pumpWidget(inAppBar(onLogout: () => salidas++));
      await openMenu(tester);

      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();

      expect(salidas, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
