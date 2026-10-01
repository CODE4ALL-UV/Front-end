import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

/// En qué curso se está estudiando, con un camino de vuelta a «Mis cursos».
///
/// El mismo tema puede estar explicado distinto en el curso de cada docente.
/// Sin esto, quien está en dos cursos no sabría en cuál está leyendo. Con el
/// servidor de antes (un único curso) no se muestra.
class ActiveCourseBanner extends StatelessWidget {
  const ActiveCourseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MyCoursesStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final course = store.active;
        if (course == null) return const SizedBox.shrink();

        final colors = context.colorScheme;
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  course.isGeneral ? Icons.public : Icons.school_outlined,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label:
                        'Estás en el curso ${course.title}. ${course.ownerLabel}.',
                    excludeSemantics: true,
                    child: Text(
                      '${course.title} · ${course.ownerLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, AppMetrics.minTapTarget),
                  ),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Mis cursos'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
