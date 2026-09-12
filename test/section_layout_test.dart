import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/ui/python_course_content/widgets/section/course_chapter_page.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_asset_index.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/sign_language_panel.dart';

/// Comprueba que la ruta de aprendizaje se ve bien en las condiciones que
/// realmente usa un estudiante con baja visión: pantalla pequeña y texto
/// agrandado al máximo.
///
/// Un desbordamiento de layout hace fallar el test, así que estas pruebas
/// detectan las franjas amarillas y negras antes de que lleguen al teléfono.
Widget _app(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

void main() {
  group('Ruta de actividades', () {
    testWidgets('cabe en una pantalla de 320 px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(const CourseChapterPage(moduleNumber: 3, sectionNumber: 2)),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('cabe con el texto al 200 por ciento', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(
          const CourseChapterPage(moduleNumber: 2, sectionNumber: 3),
          textScale: 2.0,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('cada actividad muestra su paso y su acción', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _app(const CourseChapterPage(moduleNumber: 4, sectionNumber: 1)),
      );
      await tester.pump();

      expect(find.textContaining('Paso 1 · Lectura'), findsOneWidget);
      expect(find.textContaining('Video'), findsWidgets);
      expect(find.text('2 videos con subtítulos y señas'), findsOneWidget);
    });
  });

  group('Panel de señas', () {
    testWidgets('muestra las dos mitades y deletrea el subtítulo', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(
              width: 320,
              child: SignLanguagePanel(text: 'Python'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Mitad y mitad.
      expect(find.text('Señas'), findsOneWidget);
      expect(find.text('Dactilología'), findsOneWidget);
      expect(find.text('Lengua de señas'), findsOneWidget);

      // Izquierda: la letra actual. Derecha: la palabra completa.
      expect(find.text('P'), findsOneWidget);
      expect(find.text('PYTHON'), findsOneWidget);

      // Y va avanzando letra a letra.
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Y'), findsOneWidget);

      await tester.pumpWidget(_app(const SizedBox.shrink()));
    });

    testWidgets('el panel se mantiene compacto', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                child: SignLanguagePanel(text: 'def suma'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Antes ocupaba un cuadrado de todo el ancho y empujaba la lección
      // fuera de la pantalla. Debe caber en una franja baja.
      final size = tester.getSize(find.byType(SignLanguagePanel));
      expect(size.height, lessThan(220));

      await tester.pumpWidget(_app(const SizedBox.shrink()));
    });

    testWidgets('la mano se dibuja con tamaño real, no colapsada', (
      tester,
    ) async {
      // Un CustomPaint sin hijo colapsa a cero con restricciones sueltas,
      // que es lo que da el Stack de AnimatedSwitcher. Esta prueba evita que
      // la mano vuelva a quedarse invisible.
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [SignLanguagePanel(text: 'def suma')]),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);

      final hand = find.descendant(
        of: find.byType(SignLanguagePanel),
        matching: find.byType(CustomPaint),
      );
      final painted = tester
          .widgetList<CustomPaint>(hand)
          .where((widget) => widget.painter != null);
      expect(painted, isNotEmpty, reason: 'no se dibujó ninguna mano');

      final sizes = hand
          .evaluate()
          .map((element) => element.size)
          .where((size) => size != null && size.width > 40 && size.height > 40);
      expect(sizes, isNotEmpty, reason: 'la mano quedó colapsada a cero');

      await tester.pumpWidget(_app(const SizedBox.shrink()));
    });

    testWidgets('sin texto no se rompe', (tester) async {
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(width: 320, child: SignLanguagePanel(text: '')),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Señas'), findsOneWidget);
    });
  });

  group('Índice de imágenes de señas', () {
    test('el nombre del archivo ignora tildes, mayúsculas y espacios', () {
      // 'FUNCIÓN', 'función' y ' Funcion ' tienen que encontrar funcion.gif.
      expect(SignAssetIndex.normalizeForTest('FUNCIÓN'), 'funcion');
      expect(SignAssetIndex.normalizeForTest(' Función '), 'funcion');
      expect(SignAssetIndex.normalizeForTest('función'), 'funcion');

      // La eñe se escribe 'enie' en el archivo.
      expect(SignAssetIndex.normalizeForTest('Ñ'), 'enie');
      expect(SignAssetIndex.normalizeForTest('AÑO'), 'anio');
    });

    testWidgets('sin imágenes empaquetadas no devuelve ninguna ruta', (
      tester,
    ) async {
      // Con testWidgets para que exista el binding: sin él, leer el
      // manifiesto de assets se queda esperando indefinidamente.
      await SignAssetIndex.instance.ensureLoaded();

      expect(SignAssetIndex.instance.isLoaded, isTrue);
      expect(SignAssetIndex.instance.letterAsset('A'), isNull);
      expect(SignAssetIndex.instance.wordAsset('python'), isNull);
    });
  });
}
