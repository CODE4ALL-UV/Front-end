import 'package:flutter/material.dart';

import 'section_theme.dart';

/// Tarjeta base de la ruta de aprendizaje.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? palette.surface,
        borderRadius: BorderRadius.circular(SectionMetrics.cardRadius),
        border: Border.all(color: borderColor ?? palette.border),
      ),
      child: child,
    );
  }
}

/// Encabezado de una tarjeta: icono, título y subtítulo opcional.
///
/// Se marca como encabezado para lectores de pantalla, de modo que se pueda
/// navegar la pantalla saltando de título en título.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.color,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final effectiveColor = color ?? palette.textPrimary;

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: effectiveColor),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: effectiveColor,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Párrafo de lectura con interlineado holgado.
class SectionParagraph extends StatelessWidget {
  const SectionParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        // 1.6 de interlineado: facilita no perder el renglón, sobre todo con
        // baja visión o dislexia.
        height: 1.6,
        color: palette.textPrimary,
      ),
    );
  }
}

/// Lista de puntos o de pasos numerados.
class SectionList extends StatelessWidget {
  const SectionList({super.key, required this.items, this.numbered = false});

  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: numbered
                      ? Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: palette.accent,
                          ),
                        )
                      : Icon(Icons.circle, size: 8, color: palette.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    items[i],
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.55,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Bloque de código Python.
///
/// El lector de pantalla no deletrea los símbolos: anuncia "bloque de código"
/// y la persona escucha la explicación en palabras que va justo debajo. El
/// código se puede seleccionar y copiar, y se desplaza en horizontal en lugar
/// de cortar las líneas largas.
class SectionCodeBlock extends StatefulWidget {
  const SectionCodeBlock({super.key, required this.code, this.caption});

  final String code;
  final String? caption;

  @override
  State<SectionCodeBlock> createState() => _SectionCodeBlockState();
}

class _SectionCodeBlockState extends State<SectionCodeBlock> {
  /// Un scroll horizontal no se engancha al PrimaryScrollController, así que
  /// la barra necesita su propio controlador. Sin él Flutter lanza
  /// "The Scrollbar's ScrollController has no ScrollPosition attached" en
  /// cada frame.
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final code = widget.code;
    final caption = widget.caption;
    final hasCaption = caption != null && caption.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Bloque de código Python',
          child: ExcludeSemantics(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.codeBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.codeBorder),
              ),
              child: Scrollbar(
                controller: _controller,
                child: SingleChildScrollView(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontFamilyFallback: const [
                        'Roboto Mono',
                        'Consolas',
                        'Courier New',
                      ],
                      fontSize: 14,
                      height: 1.55,
                      color: palette.codeText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (hasCaption) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: palette.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border(left: BorderSide(color: palette.accent, width: 4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.record_voice_over, size: 18, color: palette.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Qué hace este código: $caption',
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.5,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Aviso destacado. El tono nunca es el único indicador: cada uno trae su
/// propio icono y su etiqueta.
class SectionCallout extends StatelessWidget {
  const SectionCallout({
    super.key,
    required this.title,
    required this.body,
    this.tone = SectionTone.info,
  });

  final String title;
  final String body;
  final SectionTone tone;

  IconData get _icon => switch (tone) {
    SectionTone.info => Icons.lightbulb_outline,
    SectionTone.success => Icons.check_circle_outline,
    SectionTone.warning => Icons.warning_amber_rounded,
    SectionTone.danger => Icons.dangerous_outlined,
  };

  String get _prefix => switch (tone) {
    SectionTone.info => 'Idea clave',
    SectionTone.success => 'Bien hecho',
    SectionTone.warning => 'Atención',
    SectionTone.danger => 'Cuidado',
  };

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final colors = palette.tone(tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 22, color: colors.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_prefix · $title',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                    color: colors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal de una pantalla de actividad.
///
/// Ocupa todo el ancho y respeta la altura mínima táctil, para que sea fácil
/// de acertar con el dedo o con un puntero poco preciso.
class SectionPrimaryButton extends StatelessWidget {
  const SectionPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticHint,
    this.tone = SectionTone.info,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticHint;
  final SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final colors = palette.tone(tone);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      hint: semanticHint,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.foreground,
            foregroundColor: palette.isDark ? palette.onAccent : Colors.white,
            disabledBackgroundColor: palette.border,
            disabledForegroundColor: palette.textSecondary,
            minimumSize: const Size.fromHeight(SectionMetrics.minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Icon(icon ?? Icons.arrow_forward, size: 20),
          // Con el texto al 200 % una etiqueta larga desbordaria el boton:
          // preferimos que baje a una segunda linea.
          label: Text(label, textAlign: TextAlign.center, maxLines: 2),
        ),
      ),
    );
  }
}

/// Botón secundario, del mismo tamaño táctil que el principal.
class SectionSecondaryButton extends StatelessWidget {
  const SectionSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      hint: semanticHint,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: palette.accent,
            disabledForegroundColor: palette.textSecondary,
            side: BorderSide(color: palette.accent, width: 1.6),
            minimumSize: const Size.fromHeight(SectionMetrics.minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Icon(icon ?? Icons.arrow_back, size: 20),
          label: Text(label, textAlign: TextAlign.center, maxLines: 2),
        ),
      ),
    );
  }
}

/// Etiqueta de estado: icono más texto, nunca solo color.
class SectionStatusChip extends StatelessWidget {
  const SectionStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = SectionTone.success,
  });

  final String label;
  final IconData icon;
  final SectionTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final colors = palette.tone(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
        border: Border.all(color: colors.foreground.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de avance con su valor anunciado para lectores de pantalla.
class SectionProgressBar extends StatelessWidget {
  const SectionProgressBar({
    super.key,
    required this.value,
    required this.label,
  });

  /// Avance entre 0 y 1.
  final double value;

  /// Texto que describe el avance, por ejemplo "Página 2 de 4".
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);
    final percent = (value.clamp(0.0, 1.0) * 100).round();

    return Semantics(
      label: label,
      value: '$percent por ciento',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(SectionMetrics.pillRadius),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: palette.border,
                valueColor: AlwaysStoppedAnimation<Color>(palette.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado que se muestra cuando una sección todavía no tiene material.
class SectionPendingContent extends StatelessWidget {
  const SectionPendingContent({
    super.key,
    required this.sectionTitle,
    required this.objectives,
  });

  final String sectionTitle;
  final List<String> objectives;

  @override
  Widget build(BuildContext context) {
    final palette = SectionPalette.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: 'Contenido en preparación',
            subtitle:
                'El material de "$sectionTitle" todavía no está cargado. '
                'Mientras tanto, estos son los objetivos previstos para esta '
                'sección.',
            icon: Icons.hourglass_empty,
            color: palette.warning,
          ),
          const SizedBox(height: 16),
          SectionList(items: objectives, numbered: true),
        ],
      ),
    );
  }
}
