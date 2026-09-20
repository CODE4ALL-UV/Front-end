//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
import 'package:flutter/material.dart';
import 'package:flutter_code4all/domain/models/python_course_content/new_python_module_model.dart';
import 'package:flutter_code4all/ui/core/themes/app_theme.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/help_action_button.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_bottomappbar_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/NEW_video_topic_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/learning_module_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_detail_card_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_reading_topic_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/quiz_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/quiz_with_video_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/unused_knowledge_nugget_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_activity_row_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/chapter_summary_widget.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_example_code_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/final_evaluation_screen.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/new_interactive_example.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/laboratory_console_screen.dart';

// Asegúrate de importar tu GlobalHeaderWidget aquí

class ChapterDetailScreen extends StatefulWidget {
  final String userName; // NO EN EL ORIGINAL, VA EN MODULOAPRENDIZAJE
  final VoidCallback? onLogout; // NO EN EL ORIGINAL, VA EN MODULOAPRENDIZAJE
  final ChapterModel chapter; // <-- ¡Un solo objeto con toda la información!
  final List<String>?
  bottomLabels; // NO EN EL ORIGINAL, VA EN MODULOAPRENDIZAJE

  const ChapterDetailScreen({
    super.key,
    this.userName = 'Usuario',
    this.onLogout,
    required this.chapter,
    this.bottomLabels,
  });

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  bool _resumenExpanded = true;
  bool _rutaExpanded = true;
  bool _isNavigatingToOtherModule = false;
  final Set<String> _completedActivities = <String>{};

  Future<void> _openLectura(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingTopicScreen(
          actividad: actividad,
          contenido: _textoLecturaPorActividad(actividad),
        ),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
    }
  }

  String _textoLecturaPorActividad(String actividad) {
    switch (actividad) {
      case 'Relevancia del lenguaje Python':
        return 'Python es un lenguaje de programación interpretado, legible y versátil que se utiliza en desarrollo web, ciencia de datos, automatización y educación. Su sintaxis clara reduce la curva de aprendizaje y facilita que una persona se concentre en la lógica del problema en lugar de pelear con la estructura del código.\n\nEn proyectos reales, Python destaca por su ecosistema de librerías, su comunidad activa y su capacidad de integrarse con otros servicios. Esto lo vuelve ideal para construir prototipos rápidos y también para sistemas de producción cuando se diseña una arquitectura adecuada.';
      case '¿Qué es un IDE/Editor?':
        return 'Un editor de código es una herramienta para escribir y organizar archivos de programación, mientras que un IDE integra además funcionalidades como depuración, autocompletado inteligente y administración del proyecto.\n\nPara aprender Python, usar un entorno como VS Code permite ejecutar scripts, revisar errores en tiempo real y mantener una estructura ordenada. Elegir bien tu entorno mejora la productividad y disminuye errores comunes de configuración.';
      case 'Palabras clave':
        return 'En Python, las palabras clave son términos reservados por el lenguaje como if, for, while, def o class. Estas palabras tienen un significado especial y no se deben usar como nombres de variables.\n\nComprender estas palabras es fundamental porque forman la base de la lectura de cualquier programa. Identificarlas rápido te ayuda a entender el flujo del código, las condiciones y la forma en que se definen funciones y estructuras de datos.';
      default:
        return 'Esta lectura explica el contexto de la actividad y su propósito dentro del módulo. Revisa los conceptos principales, identifica las ideas clave y relaciona el contenido con los ejercicios prácticos para reforzar tu aprendizaje de Python.';
    }
  }

  Future<void> _openCapsulaConocimiento(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeNuggetScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado el tip satisfactoriamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEjemplo(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExampleCodeScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado este ejemplo satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEjercicio(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InteractiveExampleScreen(actividad: actividad),
      ),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado este ejercicio satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openEvaluacionFinal(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FinalEvaluationScreen()),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado la evaluación final.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openQuiz(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Éxito! Has completado el quiz satisfactoriamente.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openLaboratorio(String actividad) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LaboratoryConsoleScreen()),
    );

    if (completed == true && mounted) {
      setState(() {
        _completedActivities.add(actividad);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Éxito! Has completado el laboratorio satisfactoriamente.',
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openVideo(String actividad) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoTopicScreen(actividad: actividad)),
    );
  }

  //PENDIENTE: Modificar esta funcion para que pueda navegar a la pantalla del siguiente modulo,
  //de manera secuencial del 1 al 7 y viceversa
  void _goToModulo() {
    if (_isNavigatingToOtherModule) return;
    _isNavigatingToOtherModule = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LearningModuleScreen(),
      ), //PENDIENTE: Crear y cambiar a algo como ModuloAprendizaje() ya que en ese componente nuevo se cambiaria dinamicamente el contenido de cada modulo, dependiendo del modulo que se este mostrando
    ).then((_) {
      _isNavigatingToOtherModule = false;
    });
  }

  // 1. Función auxiliar para decidir qué abrir al tocar el botón de lectura/acción
  VoidCallback? _getOnBookTapAction(ActivityItem item) {
    switch (item.label) {
      case 'Nombre del Tip/Cápsula de conocimiento':
        return () => _openCapsulaConocimiento(item.label);
      case 'Ejemplo':
        return () => _openEjemplo(item.label);
      case 'Ejercicio':
        return () => _openEjercicio(item.label);
      case 'Quiz':
        return () => _openQuiz(item.label);
      case 'Evaluación final':
        return () => _openEvaluacionFinal(item.label);
      case 'Laboratorio':
        return () => _openLaboratorio(item.label);
      default:
        if (item.emoji.contains('📦')) {
          return () => _openLectura(item.label);
        }
        return null;
    }
  }

  // 2. Función auxiliar para decidir qué abrir al tocar el botón de video
  VoidCallback? _getOnVideoTapAction(BuildContext context, ActivityItem item) {
    if (item.label == 'Quiz') {
      return () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizWithVideoScreen(actividad: item.label),
        ),
      );
    } else if (item.emoji.contains('🖥️')) {
      return () => _openVideo(item.label);
    }
    return null;
  }

  Widget _buildNextModuleIndicator(
    BuildContext context,
    String nextModuleName,
  ) {
    // Reutilizamos la paleta de textos sutiles de nuestro ThemeExtension
    final colors = Theme.of(context).extension<ActivityThemeColors>();
    final textColor =
        colors?.infoText ?? const Color(0xFF607D8B); // Fallback de seguridad

    return Text(
      'Desliza hacia arriba para abrir $nextModuleName',
      style: TextStyle(
        fontSize: 12,
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter; // Referencia rápida
    final screenW = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenW < 360 ? 10.0 : 16.0;
    final labels =
        widget.bottomLabels ??
        []; //NO DEBERIA IR AQUI SINO EN MODULOAPRENDIZAJE TAL VEZ

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: widget.userName,
        onLogout: widget.onLogout,
      ),
      body: Column(
        children: [
          // Header del Módulo dinámico
          Container(
            width: double.infinity,
            color: const Color(0xFFE8F7FA),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              chapter.moduloTitulo,
              style: const TextStyle(
                color: Color(0xFF607D8B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.overscroll > 14 &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 1) {
                  _goToModulo(); // FUNCION PENDIENTE DE MODIFICAR, Lógica para abrir el siguiente módulo
                  return true;
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  12,
                  horizontalPadding,
                  16,
                ),
                child: Column(
                  children: [
                    DetailCard(
                      title: chapter.capituloTitulo,
                      expanded: _resumenExpanded,
                      onToggle: () =>
                          setState(() => _resumenExpanded = !_resumenExpanded),
                      child: ChapterSummaryWidget(
                        title: 'Resumen del capítulo',
                        topicsCount: 5,
                        capsulesCount: 2,
                        exercisesCount: 3,
                        quizzesCount: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DetailCard(
                      title: 'Ruta de actividades',
                      expanded: _rutaExpanded,
                      onToggle: () =>
                          setState(() => _rutaExpanded = !_rutaExpanded),
                      child: Column(
                        children: chapter.rutaItems
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: ActivityRowWidget(
                                  item: item,
                                  isCompleted: _completedActivities.contains(
                                    item.label,
                                  ),
                                  onBookTap: _getOnBookTapAction(item),
                                  onVideoTap: _getOnVideoTapAction(
                                    context,
                                    item,
                                  ),
                                  // isCompleted: Puedes pasar un booleano aquí cuando tengas esa lógica
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildNextModuleIndicator(context, 'Módulo 2'),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: HelpActionButton(), // Asegúrate de importarlo
            ),
          ),
        ],
      ),
      bottomNavigationBar: MultimodalBottomAppBarWidget(
        previousLabel: labels.isNotEmpty ? labels[0] : null,
        playLabel: labels.length > 1 ? labels[1] : null,
        nextLabel: labels.length > 2 ? labels[2] : null,
      ),
      //PROBAR ESTO bottomNavigationBar: const MultimodalBottomAppBarWidget(),
    );
  }
}
