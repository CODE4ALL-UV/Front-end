import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/ui/users_management/widgets/form_screen.dart';

/// Docente y director se registran con el código de la coordinación.
///
/// El servidor ya no acepta esos roles sin él: si el formulario no lo pidiera,
/// quien elige «Docente» recibiría un 403 sin saber por qué.
void main() {
  test('el código solo viaja cuando hay uno', () {
    const student = RegisterRequest(
      nombre: 'Ana',
      correo: 'ana@example.com',
      password: 'clave-segura',
      rol: 'estudiante',
    );
    expect(student.toJson().containsKey('codigo_invitacion'), isFalse);

    const teacher = RegisterRequest(
      nombre: 'Laura',
      correo: 'laura@example.com',
      password: 'clave-segura',
      rol: 'docente',
      codigoInvitacion: '  abc123 ',
    );
    expect(teacher.toJson()['codigo_invitacion'], 'abc123');
  });

  testWidgets('el campo del código aparece al elegir docente', (tester) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: FormScreen()));
    await tester.pump();

    expect(find.text('Código de invitación'), findsNothing);

    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente').last);
    await tester.pumpAndSettle();

    expect(find.text('Código de invitación'), findsOneWidget);
  });
}
