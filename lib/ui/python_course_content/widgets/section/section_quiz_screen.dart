import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_announcer_widget.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'dart:async';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/data/services/learning_analytics_service.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'section_activity_scaffold.dart';
import 'section_widgets.dart';

/// Pantalla de preguntas de opción múltiple.
/// La usan tanto el quiz como la evaluación final: sólo cambian el título, el
/// icono y el tipo de actividad que se marca como completada.
class SectionQuizScreen extends StatefulWidget {
  const SectionQuizScreen({
    super.key,
    required this.module,
    required this.section,
    required this.questions,
    required this.activityKind,
    required this.activityLabel,
    required this.activityIcon,
    this.introTitle,
    this.introBody,
  });

  final CourseModule module;
  final CourseSection section;
  final List<QuizQuestion> questions;
  final CourseActivityKind activityKind;
  final String activityLabel;
  final IconData activityIcon;

  /// Indicaciones que se muestran sobre la primera pregunta.
  final String? introTitle;
  final String? introBody;

  @override
  State<SectionQuizScreen> createState() => _SectionQuizScreenState();
}

class _SectionQuizScreenState extends State<SectionQuizScreen> {
  int _index = 0;
  int? _selected;
  bool _answered = false;

  /// Si ya se pidió la pista de la pregunta actual.
  bool _hintShown = false;

  final LearningPreferences _prefs = LearningPreferences.instance;

  /// Si hay pista que ofrecer: que el estudiante las haya activado y que esta
  /// pregunta traiga explicación. Sin explicación no hay nada que enseñar, y
  /// un botón que abre un hueco vacío es peor que no tenerlo.
  bool get _hintAvailable =>
      _prefs.hintsEnabled && _question.explanation.trim().isNotEmpty;

  void _showHint() {
    setState(() => _hintShown = true);
    announceForAccessibility(context, 'Pista: ${_question.explanation}');
  }

  int _correctCount = 0;
  bool _finished = false;

  /// Si se acerto cada pregunta, en el orden en que se mostraron.
  ///
  /// Hace falta el detalle, no solo el total: es lo que permite al docente
  /// saber que pregunta concreta esta fallando todo el mundo.
  late final List<bool> _results = List<bool>.filled(_questions.length, false);

  /// Cuanto tardo en contestar cada pregunta, en milisegundos.
  ///
  /// Se mide desde que la pregunta aparece hasta que elige opcion. Dice cosas
  /// que el acierto solo no dice: una pregunta acertada por todos pero que
  /// cuesta un minuto suele estar mal redactada.
  late final List<int?> _elapsed = List<int?>.filled(_questions.length, null);

  /// Cuando se mostro la pregunta que esta en pantalla.
  DateTime _shownAt = DateTime.now();

  List<QuizQuestion> get _questions => widget.questions;
  QuizQuestion get _question => _questions[_index];
  bool get _isLast => _index == _questions.length - 1;

  static const List<String> _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  void _select(int optionIndex) {
    if (_answered) return;

    final isCorrect = optionIndex == _question.correctIndex;

    setState(() {
      _selected = optionIndex;
      _answered = true;
      _results[_index] = isCorrect;
      _elapsed[_index] = DateTime.now().difference(_shownAt).inMilliseconds;
      if (isCorrect) _correctCount++;
    });

    // El resultado se anuncia con voz para quien no ve y se muestra con icono
    // y texto para quien no oye: nunca solo con color.
    announceForAccessibility(
      context,
      isCorrect
          ? 'Respuesta correcta. ${_question.explanation}'
          : 'Respuesta incorrecta. La correcta es la opción '
                '${_letters[_question.correctIndex]}: '
                '${_question.correctOption}. ${_question.explanation}',
    );
  }

  Future<void> _next() async {
    accessibilityReadingState.stop();

    if (!_isLast) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
        _hintShown = false;
        _shownAt = DateTime.now();
      });
      announceForAccessibility(
        context,
        'Pregunta ${_index + 1} de ${_questions.length}. ${_question.prompt}',
      );
      return;
    }

    if (_passed) {
      await CourseProgressStore.instance.markCompleted(
        widget.section.id,
        widget.activityKind,
      );
    }

    // Se manda sin esperar: el estudiante ya tiene su resultado en pantalla y
    // no debe quedarse mirando mientras viaja una estadistica.
    unawaited(
      LearningAnalyticsService.instance.recordAttempt(
        sectionId: widget.section.id,
        kind: widget.activityKind,
        prompts: [for (final q in _questions) q.prompt],
        results: _results,
        elapsedMs: _elapsed,
      ),
    );

    if (!mounted) return;
    setState(() => _finished = true);

    announceForAccessibility(
      context,
      'Actividad terminada. Acertaste $_correctCount de '
      '${_questions.length} preguntas.',
    );
  }

  /// Se aprueba con al menos el 60 % de aciertos.
  bool get _passed => _correctCount / _questions.length >= 0.6;

  void _retry() {
    setState(() {
      _index = 0;
      _selected = null;
      _answered = false;
      _hintShown = false;
      _correctCount = 0;
      _finished = false;
      // Un intento nuevo empieza de cero: si no, arrastraria los aciertos del
      // anterior y el docente veria mejor nota de la que hubo.
      _results.fillRange(0, _results.length, false);
      _elapsed.fillRange(0, _elapsed.length, null);
      _shownAt = DateTime.now();
    });
    announceForAccessibility(
      context,
      'Actividad reiniciada. Pregunta 1 de ${_questions.length}.',
    );
  }

  String get _spokenText {
    if (_finished) {
      return 'Resultado: acertaste $_correctCount de ${_questions.length} '
          'preguntas.';
    }

    final buffer = StringBuffer()
      ..writeln('Pregunta ${_index + 1} de ${_questions.length}.')
      ..writeln(_question.prompt);
    for (var i = 0; i < _question.options.length; i++) {
      buffer.writeln('Opción ${_letters[i]}: ${_question.options[i]}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SectionActivityScaffold(
      moduleLabel: widget.module.label,
      sectionTitle: widget.section.displayTitle,
      activityLabel: widget.activityLabel,
      activityIcon: widget.activityIcon,
      spokenText: _spokenText,
      progress: _finished
          ? 1
          : (_index + (_answered ? 1 : 0)) / _questions.length,
      progressLabel: _finished
          ? 'Actividad terminada'
          : 'Pregunta ${_index + 1} de ${_questions.length}',
      bottomBar: _buildBottomBar(),
      child: _finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;
    final hasIntro =
        _index == 0 &&
        widget.introBody != null &&
        widget.introBody!.trim().isNotEmpty;

    return Column(
      key: ValueKey<int>(_index),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasIntro) ...[
          SectionCallout(
            title: widget.introTitle ?? 'Instrucciones',
            body: widget.introBody!,
          ),
          const SizedBox(height: AppMetrics.sectionGap),
        ],
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pregunta ${_index + 1} de ${_questions.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: appTheme.infoText,
                ),
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  _question.prompt,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: appTheme.infoText,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppMetrics.sectionGap),
        // La pista, si el estudiante la activó en «Apoyo».
        //
        // Se ofrece pedirla, no se suelta sola: darla antes de que la persona
        // lo intente convierte el quiz en copiar la respuesta. Se usa la
        // explicación que ya trae la pregunta, que es la misma que se muestra
        // al responder, y por eso no hay texto que inventar ni mantener.
        if (!_answered && _hintAvailable) ...[
          if (_hintShown)
            SectionCallout(
              tone: AppThemeTone.info,
              title: 'Pista',
              body: _question.explanation,
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: SectionSecondaryButton(
                label: 'Ver una pista',
                icon: Icons.lightbulb_outline,
                semanticHint: 'Muestra una ayuda para esta pregunta',
                onPressed: _showHint,
              ),
            ),
          const SizedBox(height: AppMetrics.sectionGap),
        ],
        for (var i = 0; i < _question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OptionTile(
              letter: _letters[i],
              text: _question.options[i],
              isSelected: _selected == i,
              isCorrect: i == _question.correctIndex,
              revealed: _answered,
              onTap: _answered ? null : () => _select(i),
            ),
          ),
        if (_answered) ...[
          const SizedBox(height: 4),
          SectionCallout(
            title: _selected == _question.correctIndex
                ? 'Respuesta correcta'
                : 'Respuesta incorrecta',
            body: _selected == _question.correctIndex
                ? (_question.explanation.isNotEmpty
                      ? _question.explanation
                      : '¡Bien! Puedes continuar con la siguiente pregunta.')
                : 'La respuesta correcta es la opción '
                      '${_letters[_question.correctIndex]}: '
                      '${_question.correctOption}.'
                      '${_question.explanation.isNotEmpty ? ' ${_question.explanation}' : ''}',
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildResult() {
    final appTheme = context.activityColors;
    final total = _questions.length;
    final percent = ((_correctCount / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          background: _passed
              ? appTheme.successBackground
              : appTheme.warningBackground,
          borderColor: (_passed ? appTheme.infoBorder : appTheme.warningBorder)
              .withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(
                title: _passed
                    ? '¡Actividad superada!'
                    : 'Aún no es suficiente',
                subtitle: _passed
                    ? 'Acertaste $_correctCount de $total preguntas '
                          '($percent por ciento). Esta actividad queda marcada '
                          'como completada.'
                    : 'Acertaste $_correctCount de $total preguntas '
                          '($percent por ciento). Necesitas al menos el 60 por '
                          'ciento. Repasa la lectura y vuelve a intentarlo.',
                icon: _passed
                    ? Icons.emoji_events_outlined
                    : Icons.refresh_outlined,
                color: _passed
                    ? appTheme.successBackground
                    : appTheme.warningBackground,
              ),
              const SizedBox(height: 16),
              SectionProgressBar(
                value: _correctCount / total,
                label: 'Aciertos: $_correctCount de $total',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppMetrics.sectionGap),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeading(
                title: 'Repaso de las respuestas correctas',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < _questions.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                Text(
                  '${i + 1}. ${_questions[i].prompt}',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: appTheme.infoText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: appTheme.successBorder,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _questions[i].correctOption,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: appTheme.infoText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBottomBar() {
    if (_finished) {
      return Row(
        children: [
          Expanded(
            child: SectionSecondaryButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              semanticHint: 'Vuelve a empezar desde la primera pregunta',
              onPressed: _retry,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SectionPrimaryButton(
              label: 'Volver',
              icon: Icons.arrow_back,
              semanticHint: 'Regresa al listado de actividades de la sección',
              onPressed: () => Navigator.of(context).pop(_passed),
            ),
          ),
        ],
      );
    }

    return SectionPrimaryButton(
      label: _isLast ? 'Ver resultado' : 'Siguiente pregunta',
      icon: _isLast ? Icons.flag_outlined : Icons.arrow_forward,
      semanticHint: _answered ? null : 'Primero selecciona una de las opciones',
      onPressed: _answered ? _next : null,
    );
  }
}

/// Una opción de respuesta.
///
/// El estado se comunica con letra, icono y texto además del color, para que
/// se entienda con daltonismo o en escala de grises.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.revealed,
    required this.onTap,
  });

  final String letter;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool revealed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<ActivityThemeColors>()!;
    final showAsCorrect = revealed && isCorrect;
    final showAsWrong = revealed && isSelected && !isCorrect;

    final Color borderColor;
    final Color background;
    final Color foreground;

    if (showAsCorrect) {
      borderColor = appTheme.successBorder;
      background = appTheme.successBackground;
      foreground = appTheme.successBorder;
    } else if (showAsWrong) {
      borderColor = appTheme.dangerBorder;
      background = appTheme.dangerBackground;
      foreground = appTheme.dangerBorder;
    } else {
      borderColor = appTheme.infoBorder;
      background = appTheme.infoBackground;
      foreground = appTheme.infoText;
    }

    final statusLabel = showAsCorrect
        ? 'Respuesta correcta'
        : showAsWrong
        ? 'Respuesta incorrecta'
        : null;

    return Semantics(
      button: onTap != null,
      inMutuallyExclusiveGroup: true,
      selected: isSelected,
      label: 'Opción $letter. $text',
      hint: statusLabel,
      child: ExcludeSemantics(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppMetrics.minTapTarget + 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppMetrics.cardRadius),
                border: Border.all(
                  color: borderColor,
                  width: showAsCorrect || showAsWrong ? 2 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: foreground.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: foreground, width: 1.4),
                    ),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: appTheme.infoText,
                          ),
                        ),
                        if (statusLabel != null) ...[
                          const SizedBox(height: 8),
                          SectionStatusChip(
                            label: statusLabel,
                            icon: showAsCorrect
                                ? Icons.check_circle
                                : Icons.cancel,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
