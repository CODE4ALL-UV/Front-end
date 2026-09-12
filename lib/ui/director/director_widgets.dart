/// Piezas compartidas por las pantallas de dirección.
library;

import 'package:flutter/material.dart';

import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_theme.dart';

/// Una nota de 1 a 5, en estrellas y también en número.
///
/// Las estrellas solas no se pueden contar de un vistazo ni leer en voz alta,
/// así que el número va siempre al lado. Y cuando todavía no hay nota se dice
/// «sin valorar» en lugar de enseñar cinco estrellas vacías, que se leen como
/// un cero.
class ScoreStars extends StatelessWidget {
  const ScoreStars({super.key, required this.palette, required this.score});

  final SectionPalette palette;
  final int? score;

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Semantics(
        label: 'Sin valorar',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
            ),
            child: Text(
              'Sin valorar',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final value = score!;
    final tone = value >= 4
        ? palette.success
        : (value >= 3 ? palette.warning : palette.danger);

    return Semantics(
      label: 'Nota $value de 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 15,
                color: i <= value ? tone : palette.border,
              ),
            const SizedBox(width: 5),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: tone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un distintivo con icono y texto.
class DirectorBadge extends StatelessWidget {
  const DirectorBadge({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    this.tone,
  });

  final SectionPalette palette;
  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? palette.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          // Flexible para que un texto largo se recorte en vez de desbordarse:
          // dentro de un Wrap nadie encoge a un hijo que no quepa, y con el
          // texto agrandado «2 valoraciones · media 4.0» no cabe.
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso destacado: algo que la dirección debería mirar.
class DirectorNotice extends StatelessWidget {
  const DirectorNotice({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.body,
    this.tone,
  });

  final SectionPalette palette;
  final IconData icon;
  final String title;
  final String body;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? palette.warning;

    return Semantics(
      liveRegion: true,
      label: '$title. $body',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: palette.warningSoft,
            borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que se ve cuando todavía no hay nada que mirar.
class DirectorEmpty extends StatelessWidget {
  const DirectorEmpty({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    required this.body,
  });

  final SectionPalette palette;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SectionMetrics.sectionGap),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: palette.textSecondary),
              const SizedBox(height: SectionMetrics.gap),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Algo del servidor no fue bien.
class DirectorProblem extends StatelessWidget {
  const DirectorProblem({
    super.key,
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final SectionPalette palette;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SectionMetrics.sectionGap),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 40, color: palette.danger),
            const SizedBox(height: SectionMetrics.gap),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: SectionMetrics.sectionGap),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.onAccent,
                minimumSize: const Size(0, SectionMetrics.minTapTarget),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a intentarlo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una fecha dicha como se dice en voz alta: «hace 2 días».
///
/// «12/09/2026 a las 05:17» obliga a calcular mentalmente cuánto hace. Lo que
/// la dirección quiere saber es si fue hace poco o hace mucho.
String relativeDate(DateTime when) {
  final diff = DateTime.now().difference(when);

  if (diff.inMinutes < 1) return 'ahora mismo';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) {
    return 'hace ${diff.inHours} ${diff.inHours == 1 ? "hora" : "horas"}';
  }
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 30) return 'hace ${diff.inDays} días';

  final months = diff.inDays ~/ 30;
  if (months < 12) return 'hace $months ${months == 1 ? "mes" : "meses"}';

  final years = diff.inDays ~/ 365;
  return 'hace $years ${years == 1 ? "año" : "años"}';
}
