import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_code4all/data/course/course_analytics_store.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

/// Arma un informe del curso en texto plano.
///
/// En texto y no en PDF a propósito: se copia y se pega en un correo, en un
/// documento o en el capítulo de resultados de una tesis sin depender de nada
/// más. Y un lector de pantalla lo lee entero, que con un PDF generado no
/// siempre pasa.
String buildCourseReport(CourseAnalyticsStore stats, {DateTime? now}) {
  final when = now ?? DateTime.now();
  final buffer = StringBuffer();

  String fecha(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  buffer
    ..writeln('INFORME DEL CURSO DE PYTHON')
    ..writeln('Generado el ${fecha(when)}')
    ..writeln();

  if (stats.isEmpty) {
    buffer
      ..writeln('Todavía no hay actividad registrada.')
      ..writeln()
      ..writeln(
        'Las cifras de este informe salen de lo que hacen los estudiantes: '
        'las lecturas que terminan, los videos que ven y los quiz que '
        'responden.',
      );
    return buffer.toString();
  }

  final accuracy = (stats.overallAccuracy * 100).round();

  buffer
    ..writeln('RESUMEN')
    ..writeln('  Actividades terminadas: ${stats.totalCompletions}')
    ..writeln('  Respuestas registradas: ${stats.totalAnswers}')
    ..writeln('  Aciertos: $accuracy %')
    ..writeln(
      '  Estudiantes que han empezado: ${stats.activeStudents} '
      'de ${stats.students.length}',
    )
    ..writeln();

  final hard = stats.hardestSections();
  if (hard.isNotEmpty) {
    buffer.writeln('TEMAS, DEL QUE MÁS CUESTA AL QUE MENOS');
    for (final section in hard) {
      final percent = (section.accuracy * 100).round();
      buffer.writeln(
        '  $percent %  ${section.title}  '
        '(${section.correct}/${section.answered} respuestas, '
        '${section.students} estudiantes'
        '${section.avgSeconds == null ? "" : ", ${section.avgSeconds!.round()} s de media"})',
      );
    }
    buffer.writeln();

    // Decirlo con palabras, y no solo con la lista ordenada, es lo que hace
    // que el informe se pueda pegar en una conclusión tal cual.
    buffer
      ..writeln('  El tema que más cuesta es "${hard.first.title}".')
      ..writeln('  El que mejor va es "${hard.last.title}".')
      ..writeln();
  }

  final questions = stats.hardestQuestions(take: 10);
  if (questions.isNotEmpty) {
    buffer.writeln('PREGUNTAS QUE MÁS SE FALLAN');
    for (final question in questions) {
      final percent = (question.accuracy * 100).round();
      buffer
        ..writeln('  $percent %  ${question.sectionTitle}')
        ..writeln(
          '         ${question.prompt.isEmpty ? "(sin enunciado)" : question.prompt}',
        )
        ..writeln(
          '         ${question.failed} fallos de ${question.answered} '
          'respuestas',
        );
    }
    buffer.writeln();
  }

  final lentas = stats.slowestQuestions(take: 5);
  if (lentas.isNotEmpty) {
    buffer.writeln('PREGUNTAS QUE MÁS TIEMPO CUESTAN');
    for (final question in lentas) {
      buffer
        ..writeln('  ${question.avgSeconds!.round()} s de media')
        ..writeln(
          '         ${question.prompt.isEmpty ? "(sin enunciado)" : question.prompt}',
        )
        ..writeln('         ${question.sectionTitle}');
    }
    buffer.writeln();
  }

  final sinEmpezar = stats.students.where((s) => s.hasNotStarted).toList();
  if (sinEmpezar.isNotEmpty) {
    buffer.writeln('ESTUDIANTES QUE TODAVÍA NO HAN EMPEZADO');
    for (final student in sinEmpezar) {
      buffer.writeln('  ${student.name} <${student.email}>');
    }
    buffer.writeln();
  }

  buffer
    ..writeln('NOTA SOBRE ESTOS DATOS')
    ..writeln(
      '  Se cuenta si cada respuesta fue acertada, no cuál eligió el '
      'estudiante. Los porcentajes con pocas respuestas detrás dicen poco: '
      'un tema con tres respuestas no se puede comparar con otro que tenga '
      'treinta.',
    );

  return buffer.toString();
}

/// Enseña el informe listo para copiar.
Future<void> showReportSheet(
  BuildContext context,
  CourseAnalyticsStore stats,
) async {
  final palette = SectionPalette.of(context);
  final report = buildCourseReport(stats);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.surface,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(SectionMetrics.gap),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Informe del curso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: report));
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Informe copiado.'),
                            backgroundColor: palette.success,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.accent,
                        foregroundColor: palette.onAccent,
                        minimumSize: const Size(0, SectionMetrics.minTapTarget),
                      ),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: palette.border),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(SectionMetrics.gap),
                  child: SelectableText(
                    report,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
