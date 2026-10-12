import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';

/// Pruebas del menú de perfil tal como aparece en la barra superior.
void main() {
  Widget inAppBar({VoidCallback? onLogout, String name = 'Mateo'}) {
    return MaterialApp(
      home: Scaffold(
        appBar: GlobalAppBarWidget(userName: name, onLogout: onLogout),
        body: const SizedBox.expand(),
      ),
    );
  }

  Widget directMenu({
    String? name = 'Mateo',
    bool showName = true,
    VoidCallback? onLogout,
  }) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFE53935),
          foregroundColor: Colors.white,
          actions: [
            UserProfileMenu(
              userName: name,
              showName: showName,
              onLogout: onLogout,
            ),
          ],
        ),
        body: const SizedBox.expand(),
      ),
    );
  }

  Future<void> openMenu(WidgetTester tester) async {
    // Espera el primer renderizado y las cargas asíncronas del perfil.
    await tester.pump();
    await tester.tap(find.byType(UserProfileMenu));
    await tester.pumpAndSettle();
  }

  group('UserProfileMenu: visualización', () {
    testWidgets('el menú se abre y muestra las opciones comunes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(inAppBar());
      await openMenu(tester);

      expect(find.text('Teclado Braille'), findsOneWidget);
      expect(find.text('Manual de uso'), findsOneWidget);
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('los iconos del menú tienen color visible sobre fondo claro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(inAppBar());
      await openMenu(tester);

      for (final icon in [Icons.person_outline, Icons.logout]) {
        final finder = find.byIcon(icon);
        expect(finder, findsOneWidget);
        final widget = tester.widget<Icon>(finder);
        expect(
          widget.color,
          isNotNull,
          reason: 'el icono $icon debe tener un color explícito',
        );
        expect(
          widget.color,
          isNot(Colors.white),
          reason: 'el icono $icon no debe desaparecer sobre el menú claro',
        );
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('el avatar contrasta con la barra y muestra la inicial', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(inAppBar());
      await tester.pump();

      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.backgroundColor, isNot(const Color(0xFFE53935)));
      expect(avatar.backgroundColor, Colors.white);
      expect(find.text('M'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('showName false conserva el avatar y oculta el nombre', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(directMenu(showName: false));
      await tester.pump();

      expect(find.byType(UserProfileMenu), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('M'), findsOneWidget);
      expect(find.text('Mateo'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('actualiza el nombre cuando cambia la propiedad del widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(inAppBar(name: 'Mateo'));
      await tester.pump();
      expect(find.text('Mateo'), findsOneWidget);

      await tester.pumpWidget(inAppBar(name: 'Laura'));
      await tester.pump();

      expect(find.text('Laura'), findsOneWidget);
      expect(find.text('Mateo'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('UserProfileMenu: perfil', () {
    testWidgets('abrir Mi perfil muestra el diálogo sin cerrar sesión', (
      WidgetTester tester,
    ) async {
      var logoutCalls = 0;
      await tester.pumpWidget(inAppBar(onLogout: () => logoutCalls++));
      await openMenu(tester);

      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      expect(
        find.descendant(of: dialog, matching: find.text('Mateo')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text('ESTUDIANTE')),
        findsOneWidget,
      );
      expect(
        find.text('Tu perfil está listo para mostrar tus datos de usuario.'),
        findsOneWidget,
      );
      expect(logoutCalls, 0);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('UserProfileMenu: cerrar sesión', () {
    testWidgets('una sola pulsación ejecuta onLogout una vez', (
      WidgetTester tester,
    ) async {
      var logoutCalls = 0;
      await tester.pumpWidget(inAppBar(onLogout: () => logoutCalls++));
      await openMenu(tester);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(
        logoutCalls,
        1,
        reason: 'una pulsación debe cerrar la sesión una vez',
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets(
      'la acción de salida no espera el resultado del almacenamiento',
      (WidgetTester tester) async {
        // En el entorno de widget test el almacenamiento nativo puede no estar
        // disponible. La salida debe invocar onLogout sin esperar su respuesta.
        var logoutCalls = 0;
        await tester.pumpWidget(inAppBar(onLogout: () => logoutCalls++));
        await openMenu(tester);

        await tester.tap(find.text('Cerrar sesión'));
        await tester.pump();

        expect(logoutCalls, 1);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
