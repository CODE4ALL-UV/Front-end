import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';
import 'package:flutter_test/flutter_test.dart';

const _exampleCode = 'print("Hola Code4All")';

Finder get _codeField => find.byType(TextField).first;
Finder get _outputField => find.byType(TextField).last;

String _fieldText(WidgetTester tester, Finder finder) {
  return tester.widget<TextField>(finder).controller!.text;
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: LaboratoryConsoleScreen()));
  await tester.pumpAndSettle();
}

Future<void> _run(WidgetTester tester, String source) async {
  await tester.enterText(_codeField, source);
  await tester.tap(find.text('Ejecutar'));
  await tester.pump();
}

void main() {
  group('LaboratoryConsoleScreen: renderizado y ejemplo', () {
    testWidgets('muestra el objetivo, el código inicial y los controles', (
      tester,
    ) async {
      await _pumpScreen(tester);

      expect(find.text('Laboratorio de Python'), findsOneWidget);
      expect(find.text('Objetivo: imprimir "Hola Code4All"'), findsOneWidget);
      expect(find.text('Consola'), findsOneWidget);
      expect(find.text('Resultado'), findsOneWidget);
      expect(find.text('Ejecutar'), findsOneWidget);
      expect(find.text('Ejemplo'), findsOneWidget);
      expect(find.text('Terminar'), findsOneWidget);
      expect(_fieldText(tester, _codeField), _exampleCode);
      expect(_fieldText(tester, _outputField), isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('el ejemplo inicial genera la salida esperada', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.text('Ejecutar'));
      await tester.pump();

      expect(_fieldText(tester, _outputField), 'Hola Code4All');
      expect(
        find.text('✅ Tu salida coincide con la esperada.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Ejemplo restaura el código y limpia resultado y feedback', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, 'print("Otra salida")');
      expect(_fieldText(tester, _outputField), 'Otra salida');
      expect(
        find.text('⚠️ Revisa el código, la salida no coincide todavía.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ejemplo'));
      await tester.pump();

      expect(_fieldText(tester, _codeField), _exampleCode);
      expect(_fieldText(tester, _outputField), isEmpty);
      expect(find.textContaining('Revisa el código'), findsNothing);
      expect(find.textContaining('Tu salida coincide'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('LaboratoryConsoleScreen: evaluación del código', () {
    testWidgets('avisa si el código está vacío o solo contiene espacios', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, '   \n  ');

      expect(_fieldText(tester, _outputField), isEmpty);
      expect(find.text('❌ Escribe un código para ejecutarlo.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muestra una advertencia cuando la salida no coincide', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, 'print("Incorrecto")');

      expect(_fieldText(tester, _outputField), 'Incorrecto');
      expect(
        find.text('⚠️ Revisa el código, la salida no coincide todavía.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('evalúa variables y cadenas entre comillas simples', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, "saludo = 'Hola Code4All'\nprint(saludo)");

      expect(_fieldText(tester, _outputField), 'Hola Code4All');
      expect(
        find.text('✅ Tu salida coincide con la esperada.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('evalúa aritmética, paréntesis y prioridad de operadores', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, 'resultado = (2 + 3) * 4\nprint(resultado)');

      expect(_fieldText(tester, _outputField), '20');
      expect(
        find.text('⚠️ Revisa el código, la salida no coincide todavía.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('concatena cadenas con variables e imprime varias líneas', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(
        tester,
        'nombre = "Code4All"\nprint("Hola " + nombre)\nprint("Listo")',
      );

      expect(_fieldText(tester, _outputField), 'Hola Code4All\nListo');
      expect(
        find.text('⚠️ Revisa el código, la salida no coincide todavía.'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muestra error cuando la variable no está definida', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, 'print(nombre)');

      expect(_fieldText(tester, _outputField), isEmpty);
      expect(
        find.textContaining('Variable no definida: nombre'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muestra error cuando no puede interpretar una instrucción', (
      tester,
    ) async {
      await _pumpScreen(tester);
      await _run(tester, 'if True:');

      expect(_fieldText(tester, _outputField), isEmpty);
      expect(
        find.textContaining('No se pudo interpretar: if True:'),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muestra error por una cadena sin cerrar', (tester) async {
      await _pumpScreen(tester);
      await _run(tester, 'print("Hola)');

      expect(_fieldText(tester, _outputField), isEmpty);
      expect(find.textContaining('Cadena sin cerrar'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('muestra error por una expresión incompleta', (tester) async {
      await _pumpScreen(tester);
      await _run(tester, 'print(2 + )');

      expect(_fieldText(tester, _outputField), isEmpty);
      expect(find.textContaining('Expresión vacía'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('LaboratoryConsoleScreen: finalizar y volver', () {
    testWidgets('no permite terminar mientras la salida sea incorrecta', (
      tester,
    ) async {
      await _pumpScreen(tester);

      // Primero ejecutamos código válido sintácticamente, pero con salida incorrecta.
      // Así _hasRun queda activo y el feedback de finalización se renderiza.
      await _run(tester, 'print("Otra salida")');

      final finishButton = find.text('Terminar');
      await tester.ensureVisible(finishButton);
      await tester.pumpAndSettle();
      await tester.tap(finishButton);
      await tester.pump();

      expect(find.byType(LaboratoryConsoleScreen), findsOneWidget);
      expect(
        find.text(
          '⚠️ Completa el laboratorio con una salida correcta para terminar.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Terminar sin haber ejecutado nada explica por qué no sale', (
      tester,
    ) async {
      await _pumpScreen(tester);

      final finishButton = find.text('Terminar');
      await tester.ensureVisible(finishButton);
      await tester.pumpAndSettle();
      await tester.tap(finishButton);
      await tester.pump();

      expect(find.byType(LaboratoryConsoleScreen), findsOneWidget);
      expect(
        find.text(
          '⚠️ Completa el laboratorio con una salida correcta para terminar.',
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Terminar devuelve true después de una salida correcta', (
      tester,
    ) async {
      final result = Completer<bool?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const LaboratoryConsoleScreen(),
                        ),
                      )
                      .then(result.complete);
                },
                child: const Text('Abrir laboratorio'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir laboratorio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ejecutar'));
      await tester.pump();

      // El botón queda al final del contenido desplazable.
      final finishButton = find.text('Terminar');
      await tester.ensureVisible(finishButton);
      await tester.pumpAndSettle();
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      expect(await result.future, isTrue);
    });

    testWidgets('la flecha atrás no indica éxito antes de completar', (
      tester,
    ) async {
      final result = Completer<bool?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const LaboratoryConsoleScreen(),
                        ),
                      )
                      .then(result.complete);
                },
                child: const Text('Abrir laboratorio'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir laboratorio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(await result.future, isNull);
    });

    testWidgets('la flecha atrás devuelve true tras una salida correcta', (
      tester,
    ) async {
      final result = Completer<bool?>();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .push<bool>(
                        MaterialPageRoute<bool>(
                          builder: (_) => const LaboratoryConsoleScreen(),
                        ),
                      )
                      .then(result.complete);
                },
                child: const Text('Abrir laboratorio'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir laboratorio'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ejecutar'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(await result.future, isTrue);
    });
  });
}
