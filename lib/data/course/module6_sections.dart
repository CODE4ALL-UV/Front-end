import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 6. Especialización y futuro.
///
/// Nota de contenido: todavía no se ha entregado material para este módulo.
/// Las secciones quedan declaradas con su título y sus objetivos para que la
/// ruta de aprendizaje se vea completa y el docente sepa exactamente qué
/// contenido falta. En la app se muestran como "contenido en preparación",
/// nunca como un enlace roto.
const CourseModule module6 = CourseModule(
  number: 6,
  title: 'Especialización y futuro',
  sections: [
    CourseSection(
      id: 'm6-s1',
      shortTitle: 'Diseño de\ninterfaces',
      moduleNumber: 6,
      number: 1,
      title: 'Diseño de interfaces de usuario',
      summary:
          'Qué es una interfaz gráfica, qué librerías existen y cuál es su '
          'ciclo de vida.',
      objectives: [
        'Explicar qué es una interfaz gráfica de usuario.',
        'Comparar las librerías más usadas en Python.',
        'Describir el ciclo de vida de una ventana.',
      ],
      hasLaboratory: false,
    ),
    CourseSection(
      id: 'm6-s2',
      shortTitle: 'Componentes\nde interfaz',
      moduleNumber: 6,
      number: 2,
      title: 'Componentes de una interfaz',
      summary:
          'Ventanas, etiquetas, botones, campos de texto y organización del '
          'espacio.',
      objectives: [
        'Crear ventanas y etiquetas.',
        'Añadir botones y campos de texto.',
        'Organizar componentes con layouts.',
      ],
      hasLaboratory: false,
    ),
    CourseSection(
      id: 'm6-s3',
      shortTitle: 'Trabajo\ncolaborativo',
      moduleNumber: 6,
      number: 3,
      title: 'Trabajo colaborativo',
      summary:
          'Roles del equipo, control de versiones con Git y documentación.',
      objectives: [
        'Reconocer los roles de un equipo de desarrollo.',
        'Usar Git para trabajar en equipo.',
        'Comunicar y documentar el trabajo.',
      ],
      hasLaboratory: false,
    ),
  ],
);
