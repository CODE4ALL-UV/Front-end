import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';

class LaboratoryConsoleScreenDark extends StatefulWidget {
  const LaboratoryConsoleScreenDark({super.key});

  @override
  State<LaboratoryConsoleScreenDark> createState() =>
      _LaboratoryConsoleScreenDarkState();
}

class _LaboratoryConsoleScreenDarkState
    extends State<LaboratoryConsoleScreenDark> {
  final TextEditingController _codeController = TextEditingController(
    text: 'print("Hola Code4All")',
  );
  final TextEditingController _outputController = TextEditingController();

  String _expectedOutput = 'Hola Code4All';
  String? _feedback;
  bool _hasRun = false;

  @override
  void dispose() {
    _codeController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _runCode() {
    final source = _codeController.text.trim();
    if (source.isEmpty) {
      setState(() {
        _hasRun = true;
        _feedback = '❌ Escribe un código para ejecutarlo.';
        _outputController.text = '';
      });
      return;
    }

    try {
      final output = _evaluateSource(source);
      final isCorrect = output.trim() == _expectedOutput.trim();
      setState(() {
        _hasRun = true;
        _feedback = isCorrect
            ? '✅ Tu salida coincide con la esperada.'
            : '⚠️ Revisa el código, la salida no coincide todavía.';
        _outputController.text = output;
      });
    } catch (error) {
      setState(() {
        _hasRun = true;
        _feedback = '❌ Ocurrió un error: $error';
        _outputController.text = '';
      });
    }
  }

  void _restoreExample() {
    setState(() {
      _codeController.text = 'print("Hola Code4All")';
      _outputController.text = '';
      _feedback = null;
      _hasRun = false;
    });
  }

  void _finishLaboratory() {
    if (_feedback?.contains('✅') != true) {
      setState(() {
        _feedback =
            '⚠️ Completa el laboratorio con una salida correcta para terminar.';
      });
      return;
    }

    Navigator.pop(context, true);
  }

  String _evaluateSource(String source) {
    final variables = <String, dynamic>{};
    final outputs = <String>[];

    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }

      if (line.startsWith('print(') && line.endsWith(')')) {
        final expression = line.substring(6, line.length - 1).trim();
        final value = _evaluateExpression(expression, variables);
        outputs.add(_formatValue(value));
        continue;
      }

      final assignmentMatch = RegExp(
        r'^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$',
      ).firstMatch(line);
      if (assignmentMatch != null) {
        final name = assignmentMatch.group(1)!;
        final expression = assignmentMatch.group(2)!.trim();
        variables[name] = _evaluateExpression(expression, variables);
        continue;
      }

      throw FormatException('No se pudo interpretar: $line');
    }

    return outputs.join('\n');
  }

  dynamic _evaluateExpression(
    String expression,
    Map<String, dynamic> variables,
  ) {
    final parser = _ExpressionParser(expression, variables);
    return parser.parse();
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: HeaderWidget(
        title: 'CODE4ALL',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_feedback?.contains('✅') == true) {
              Navigator.of(context).pop(true);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        showUserIcon: true,
        userName: null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 130,
                        child: Image.asset(
                          'assets/images/ardilla_univalle.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Laboratorio de Python',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE2E8F0),
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              child: const Text(
                                'Escribe un código en Python y valida el resultado esperado. Ejemplo: imprime un texto con print().',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Objetivo: imprimir "${_expectedOutput}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF60A5FA),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consola',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        maxLines: 8,
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Escribe tu código aquí...',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _runCode,
                        icon: const Icon(Icons.play_arrow, size: 20),
                        label: const Text('Ejecutar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: OutlinedButton.icon(
                        onPressed: _restoreExample,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Ejemplo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF93C5FD),
                          side: const BorderSide(color: Color(0xFF60A5FA)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resultado',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE2E8F0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _outputController,
                        maxLines: 6,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFF1E293B),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_hasRun)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _feedback!.contains('✅')
                                ? const Color(0xFF14432A)
                                : const Color(0xFF3F1D2D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _feedback!.contains('✅')
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFF87171),
                            ),
                          ),
                          child: Text(
                            _feedback!,
                            style: const TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finishLaboratory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Terminar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpressionParser {
  final String source;
  final Map<String, dynamic> variables;
  int _position = 0;

  _ExpressionParser(this.source, this.variables);

  dynamic parse() {
    final value = _parseAddSub();
    _skipWhitespace();
    if (_position != source.length) {
      throw FormatException('Expresión incompleta: $source');
    }
    return value;
  }

  void _skipWhitespace() {
    while (_position < source.length && source[_position].trim().isEmpty) {
      _position++;
    }
  }

  dynamic _parseAddSub() {
    dynamic value = _parseMulDiv();
    while (true) {
      _skipWhitespace();
      if (_position >= source.length) {
        return value;
      }
      final operator = source[_position];
      if (operator != '+' && operator != '-') {
        return value;
      }
      _position++;
      final right = _parseMulDiv();
      if (operator == '+') {
        if (value is String || right is String) {
          value = value.toString() + right.toString();
        } else {
          value = (value as num) + (right as num);
        }
      } else {
        value = (value as num) - (right as num);
      }
    }
  }

  dynamic _parseMulDiv() {
    dynamic value = _parsePrimary();
    while (true) {
      _skipWhitespace();
      if (_position >= source.length) {
        return value;
      }
      final operator = source[_position];
      if (operator != '*' && operator != '/') {
        return value;
      }
      _position++;
      final right = _parsePrimary();
      if (operator == '*') {
        value = (value as num) * (right as num);
      } else {
        value = (value as num) / (right as num);
      }
    }
  }

  dynamic _parsePrimary() {
    _skipWhitespace();
    if (_position >= source.length) {
      throw FormatException('Expresión vacía');
    }

    final char = source[_position];
    if (char == '(') {
      _position++;
      final value = _parseAddSub();
      _skipWhitespace();
      if (_position >= source.length || source[_position] != ')') {
        throw FormatException('Falta cierre de paréntesis');
      }
      _position++;
      return value;
    }

    if (char == '"' || char == "'") {
      final quote = char;
      _position++;
      final buffer = StringBuffer();
      while (_position < source.length && source[_position] != quote) {
        buffer.write(source[_position]);
        _position++;
      }
      if (_position >= source.length) {
        throw FormatException('Falta cierre de cadena');
      }
      _position++;
      return buffer.toString();
    }

    if (char.contains(RegExp(r'[0-9]'))) {
      final start = _position;
      while (_position < source.length &&
          source[_position].contains(RegExp(r'[0-9.]'))) {
        _position++;
      }
      return num.parse(source.substring(start, _position));
    }

    final start = _position;
    while (_position < source.length &&
        source[_position].contains(RegExp(r'[A-Za-z0-9_]'))) {
      _position++;
    }
    final identifier = source.substring(start, _position);
    if (variables.containsKey(identifier)) {
      return variables[identifier];
    }

    throw FormatException('Variable no definida: $identifier');
  }
}
