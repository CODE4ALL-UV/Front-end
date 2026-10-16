import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/module_header_widget.dart';
import 'package:flutter_code4all/ui/users_management/widgets/teacher_module_editor_screen.dart';

/// La cabecera de cada módulo: su número, su título y, solo para el docente,
/// el lápiz que abre el editor del módulo.
///
/// Lo importante es el viaje de ida y vuelta: el lápiz abre el editor de ese
/// módulo y, al volver, la pantalla recibe lo que el editor devolvió (el
/// nombre nuevo, o nada si se salió sin guardar) para refrescarse.
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  /// El editor pide el módulo al servidor al abrirse. Este responde que el
  /// módulo nunca se editó, que es lo normal la primera vez.
  final server = MockClient((_) async => http.Response('', 404));

  Future<void> pumpHeader(
    WidgetTester tester, {
    String moduleId = '2',
    bool isTeacher = true,
    void Function(String?)? onEditCompleted,
  }) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(mode: AppThemeMode.light, moduleId: 2),
        home: Scaffold(
          body: ModuleHeaderWidget(
            moduleId: moduleId,
            moduleTitle: 'Fundamentos',
            isTeacher: isTeacher,
            onEditCompleted: onEditCompleted ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('el estudiante no ve el lápiz de edición', (tester) async {
    await pumpHeader(tester, isTeacher: false);

    expect(find.text('Módulo 2'), findsOneWidget);
    expect(find.text('Fundamentos'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('el lápiz abre el editor de ese módulo y devuelve el nombre '
      'nuevo', (tester) async {
    final results = <String?>[];
    await pumpHeader(tester, onEditCompleted: results.add);

    await http.runWithClient(
      () => tester.tap(find.byIcon(Icons.edit)),
      () => server,
    );
    await tester.pumpAndSettle();

    final editor = tester.widget<TeacherModuleEditor>(
      find.byType(TeacherModuleEditor),
    );
    expect(editor.moduleId, '2');
    expect(results, isEmpty, reason: 'aún no se ha vuelto del editor');

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .pop('Fundamentos de Python');
    await tester.pumpAndSettle();

    expect(results, ['Fundamentos de Python']);
    expect(find.byType(TeacherModuleEditor), findsNothing);
  });

  testWidgets('salir del editor sin guardar también avisa, sin nombre', (
    tester,
  ) async {
    final results = <String?>[];
    await pumpHeader(tester, moduleId: '5', onEditCompleted: results.add);

    await http.runWithClient(
      () => tester.tap(find.byIcon(Icons.edit)),
      () => server,
    );
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(results, [null]);
  });

  testWidgets('cada módulo lleva su propio icono', (tester) async {
    const icons = {
      '1': Icons.menu_book_rounded,
      '2': Icons.foundation_rounded,
      '3': Icons.hardware_rounded,
      '4': Icons.more_time_rounded,
      '5': Icons.show_chart_rounded,
      '6': Icons.business_rounded,
      '9': Icons.pending_rounded,
    };
    for (final MapEntry(key: id, value: icon) in icons.entries) {
      await pumpHeader(tester, moduleId: id, isTeacher: false);
      expect(find.byIcon(icon), findsOneWidget, reason: 'módulo $id');
    }
  });
}
