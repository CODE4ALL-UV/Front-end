import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/user_manual.dart';
import 'package:flutter_code4all/ui/core/ui/user_profile_menu.dart';
import 'package:flutter_test/flutter_test.dart';

/// El acceso al manual de uso: a dónde lleva y que esté a la vista.
///
/// El manual abre las guías del rol según el ancla de la dirección. Si el
/// ancla no coincide con la que entiende `web/manual.html`, la persona cae en
/// «Primeros pasos» sin saber dónde buscar lo suyo.
void main() {
  group('la dirección', () {
    test('fuera del navegador apunta a la página publicada', () {
      final uri = userManualUri();
      expect(uri.removeFragment().toString(), userManualPublicUrl);
    });

    test('cada rol abre su parte del manual', () {
      expect(userManualUri(role: 'estudiante').fragment, 'estudiante');
      expect(userManualUri(role: 'docente').fragment, 'docente');
      expect(userManualUri(role: 'director').fragment, 'director');
    });

    test('sin rol, o con uno raro, abre los primeros pasos', () {
      expect(userManualUri().fragment, 'inicio');
      expect(userManualUri(role: '').fragment, 'inicio');
      expect(userManualUri(role: ' Docente ').fragment, 'docente');
      expect(userManualUri(role: 'invitado').fragment, 'inicio');
    });
  });

  testWidgets('el menú de perfil ofrece el manual con un icono visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: GlobalAppBarWidget(userName: 'Mateo'),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(UserProfileMenu));
    await tester.pumpAndSettle();

    expect(find.text('Manual de uso'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.menu_book_outlined));
    // Como los demás iconos del menú: sin color propio heredaría el blanco
    // de la barra y desaparecería sobre el fondo claro del desplegable.
    expect(icon.color, isNotNull);
    expect(icon.color, isNot(Colors.white));
  });
}
