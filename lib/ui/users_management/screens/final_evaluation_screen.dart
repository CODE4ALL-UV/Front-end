import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';

class FinalEvaluationScreen extends StatefulWidget {
  const FinalEvaluationScreen({super.key});

  @override
  State<FinalEvaluationScreen> createState() => _FinalEvaluationScreenState();
}

class _FinalEvaluationScreenState extends State<FinalEvaluationScreen> {
  final List<_Question> _questions = const [
    _Question(
      prompt:
          '¿Cuáles son las tres aplicaciones principales de Python mencionadas en la lectura?',
      correctAnswer:
          'Ciencia de datos, inteligencia artificial y desarrollo web',
      options: [
        'Ciencia de datos, inteligencia artificial y desarrollo web',
        'Solo videojuegos',
        'Diseño gráfico exclusivamente',
      ],
    ),
    _Question(
      prompt:
          '¿Qué comando utilizas para verificar que Python está correctamente instalado?',
      correctAnswer: 'python --version',
      options: [
        'python --version',
        'pip install',
        'python run',
        'python --help',
      ],
    ),
    _Question(
      prompt:
          'Verdadero o Falso: "Los entornos virtuales en Python son innecesarios para pequeños proyectos"',
      correctAnswer: 'Falso',
      options: ['Verdadero', 'Falso'],
    ),
    _Question(
      prompt: '¿Cuál es la función de pip?',
      correctAnswer: 'Gestionar e instalar librerías externas',
      options: [
        'Compilar código Python',
        'Gestionar e instalar librerías externas',
        'Crear archivos ejecutables',
        'Cambiar la versión de Python',
      ],
    ),
  ];

  late final List<String?> _answers;
  late final List<bool?> _results;

  @override
  void initState() {
    super.initState();
    _answers = List<String?>.filled(_questions.length, null);
    _results = List<bool?>.filled(_questions.length, null);
  }

  void _handleDrop(int index, String answer) {
    setState(() {
      _answers[index] = answer;
      _results[index] = answer == _questions[index].correctAnswer;
    });
  }

  void _finishEvaluation() {
    final hasUnanswered = _answers.any((answer) => answer == null);
    final hasWrong = _results.contains(false);

    if (hasUnanswered || hasWrong) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa y valida todas las respuestas correctamente.',
          ),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Éxito! Has completado la evaluación final.'),
        backgroundColor: Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF607D8B);
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE0E0E0);
    final accent = isDark ? const Color(0xFF60A5FA) : const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: HeaderWidget(
        title: 'CODE4ALL',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        showUserIcon: true,
        userName: null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evaluación final',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Arrastra la respuesta correcta hacia cada pregunta y valida tu resultado.',
                      style: TextStyle(color: muted, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _questions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final question = _questions[index];
                    final answer = _answers[index];
                    final result = _results[index];

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: result == true
                              ? const Color(0xFF2E7D32)
                              : result == false
                              ? const Color(0xFFE53935)
                              : border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.prompt,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DragTarget<String>(
                            builder: (context, candidateData, rejectedData) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: result == true
                                      ? const Color(0xFFE8F5E9)
                                      : result == false
                                      ? const Color(0xFFFFEBEE)
                                      : isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      result == true
                                          ? Icons.check_circle
                                          : result == false
                                          ? Icons.cancel
                                          : Icons.touch_app,
                                      color: result == true
                                          ? const Color(0xFF2E7D32)
                                          : result == false
                                          ? const Color(0xFFE53935)
                                          : accent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        answer ??
                                            'Arrastra la respuesta correcta aquí',
                                        style: TextStyle(
                                          color: answer == null
                                              ? muted
                                              : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF111827)),
                                          fontWeight: answer == null
                                              ? FontWeight.w500
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onWillAcceptWithDetails: (details) => true,
                            onAcceptWithDetails: (details) {
                              _handleDrop(index, details.data);
                            },
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: question.options.map((option) {
                              final isSelected = answer == option;
                              return Draggable<String>(
                                data: option,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.45,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Text(option),
                                  ),
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent.withOpacity(0.15)
                                        : isDark
                                        ? const Color(0xFF1F2937)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? accent : border,
                                    ),
                                  ),
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? accent
                                          : (isDark
                                                ? Colors.white
                                                : const Color(0xFF111827)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishEvaluation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }
}

class _Question {
  final String prompt;
  final String correctAnswer;
  final List<String> options;

  const _Question({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });
}
