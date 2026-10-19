/// Piezas que comparten «Mis cursos» del estudiante y del docente.
///
/// Están juntas para que las dos pantallas se vean de la misma familia: la
/// misma cabecera, la misma rejilla y las mismas tarjetas, cambie lo que
/// cambie dentro.
library;

import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

/// Ancho máximo de las listas de cursos. Más que el del contenido de lectura
/// (720): aquí caben dos columnas de tarjetas en un portátil.
const double kCourseListMaxWidth = 1040;

/// Cuántas columnas de tarjetas caben en [width].
int courseColumnsFor(double width) => width >= 720 ? 2 : 1;

/// El primer nombre de [userName], o nada si no hay uno de verdad.
String? firstNameOf(String? userName) {
  final name = (userName ?? '').trim();
  if (name.isEmpty || name == 'Usuario' || name == 'Docente') return null;
  return name.split(RegExp(r'\s+')).first;
}

/// La cabecera de color de la pantalla: saludo, título, para qué sirve y la
/// acción principal.
///
/// El fondo es el color principal del tema y el texto su pareja `onPrimary`,
/// la misma combinación de la barra superior: así contrasta igual en los
/// nueve temas, también en los de daltonismo.
class CoursesHero extends StatelessWidget {
  const CoursesHero({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    this.overline,
    this.stats = const [],
  });

  final String? overline;
  final String title;
  final String description;
  final Widget action;

  /// Cifras de un vistazo, como [HeroStat]. A la derecha en pantalla ancha.
  final List<Widget> stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overline != null) ...[
          Text(
            overline!,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Semantics(
          header: true,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: colors.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: colors.onPrimary,
          ),
        ),
        const SizedBox(height: 16),
        action,
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dos círculos de adorno, sin nada encima que leer.
          Positioned(
            right: -40,
            top: -50,
            child: _Bubble(size: 180, color: colors.onPrimary),
          ),
          Positioned(
            right: 70,
            bottom: -70,
            child: _Bubble(size: 140, color: colors.onPrimary),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (stats.isEmpty) return text;
                if (constraints.maxWidth < 560) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      text,
                      const SizedBox(height: 18),
                      Wrap(spacing: 10, runSpacing: 10, children: stats),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: text),
                    const SizedBox(width: 24),
                    Wrap(spacing: 10, runSpacing: 10, children: stats),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.07),
        ),
      ),
    );
  }
}

/// Una cifra de la cabecera: el número grande y qué cuenta.
///
/// Sin relleno, solo con borde: el número queda sobre el mismo color de la
/// cabecera y conserva su contraste en cualquier tema.
class HeroStat extends StatelessWidget {
  const HeroStat({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.onPrimary.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.onPrimary, size: 22),
            const SizedBox(width: 10),
            // Flexible: con la letra al 200 % en un celular la etiqueta no
            // cabía al lado del icono y se salía por la derecha.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: colors.onPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12.5, color: colors.onPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las tarjetas en filas de [columns], todas las de una fila igual de altas.
///
/// En una rejilla de altura libre, una tarjeta con descripción larga junto a
/// otra sin ella dejaba la fila dentada y los botones a distinta altura.
class CourseGrid extends StatelessWidget {
  const CourseGrid({super.key, required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  static const double gap = 14;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            children[i],
          ],
        ],
      );
    }

    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) cells.add(const SizedBox(width: gap));
        final index = start + c;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// El marco de una tarjeta de curso: superficie, borde y esquinas.
///
/// Con [onTap] la tarjeta entera se puede tocar.
class CourseCardFrame extends StatelessWidget {
  const CourseCardFrame({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colors.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// El cuadrado de color con el icono del curso.
class CourseIconTile extends StatelessWidget {
  const CourseIconTile({super.key, required this.icon, this.general = false});

  final IconData icon;

  /// El curso general va en el color secundario, para distinguirlo de los
  /// cursos de cada docente.
  final bool general;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: general ? colors.secondary : colors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: general ? colors.onSecondary : colors.onPrimary,
          size: 24,
        ),
      ),
    );
  }
}

/// Lo que se ve cuando la lista está vacía: icono, qué pasa y qué hacer.
class CoursesEmptyState extends StatelessWidget {
  const CoursesEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(CourseCardFrame.radius),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.auto_stories_outlined,
              size: 44,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
