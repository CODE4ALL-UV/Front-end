import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/course/my_courses_store.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';

/// Decide si se entra por «Mis cursos» o directamente al curso de siempre.
///
/// Con el servidor nuevo cada docente tiene sus cursos y hay que elegir uno.
/// Con el de antes, que no conoce los cursos, se entra como siempre a un único
/// curso para todos. Así la aplicación funciona con los dos mientras se pasa
/// de uno a otro.
class CoursesGate extends StatefulWidget {
  const CoursesGate({
    super.key,
    required this.withCourses,
    required this.withoutCourses,
    this.userName,
    this.onLogout,
  });

  final WidgetBuilder withCourses;
  final WidgetBuilder withoutCourses;
  final String? userName;
  final VoidCallback? onLogout;

  @override
  State<CoursesGate> createState() => _CoursesGateState();
}

class _CoursesGateState extends State<CoursesGate> {
  final MyCoursesStore _store = MyCoursesStore.instance;

  /// Quien no pudo cargar sus cursos y prefirió seguir con el general.
  bool _skipped = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    if (_store.supported == null) _store.refresh();
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_store.supported == true) return widget.withCourses(context);
    if (_store.supported == false || _skipped) {
      return widget.withoutCourses(context);
    }

    final colors = context.colorScheme;
    final problem = _store.problem;

    return Scaffold(
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppMetrics.sectionGap),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: problem == null
                ? Semantics(
                    liveRegion: true,
                    label: 'Cargando tus cursos',
                    child: const CircularProgressIndicator(),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 44,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppMetrics.gap),
                      Text(
                        problem,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: colors.onSurface),
                      ),
                      const SizedBox(height: AppMetrics.sectionGap),
                      FilledButton.icon(
                        onPressed: _store.refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Volver a intentarlo'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _skipped = true),
                        child: const Text('Entrar al curso general'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
