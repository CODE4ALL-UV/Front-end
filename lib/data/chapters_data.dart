//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
import 'package:flutter_code4all/domain/models/python_course_content/python_module_model.dart';

final List<ChapterModel> capitulosModulo1 = [
  const ChapterModel(
    id: 'cap_1',
    moduloTitulo: 'Módulo 1. Preparación',
    capituloTitulo: 'Capítulo 1: Fundamentos',
    resumenTexto:
        'En este capítulo aprenderás los conceptos básicos del desarrollo.',
    rutaItems: [
      ActivityItem(label: 'Relevancia del lenguaje Python', emoji: '📦🖥️🎧'),
      ActivityItem(
        label: 'Nombre del Tip/Cápsula de conocimiento',
        emoji: '🎁',
      ),
      ActivityItem(label: 'Ejemplo', emoji: '⚙️'),
      ActivityItem(label: 'Ejercicio', emoji: '🎮'),
      ActivityItem(label: 'Quiz', emoji: '❓'),
      ActivityItem(label: 'Laboratorio', emoji: '🧪'),
      ActivityItem(label: 'Evaluación final', emoji: '📋'),
    ],
  ),
  const ChapterModel(
    id: 'cap_2',
    moduloTitulo: 'Módulo 1. Preparación',
    capituloTitulo: 'Capítulo 2: El entorno',
    resumenTexto:
        'Aprenderás a configurar tu IDE, terminal y herramientas accesibles.',
    rutaItems: [
      ActivityItem(label: '¿Qué es un IDE/Editor?', emoji: '📦🖥️🎧'),
      ActivityItem(
        label: 'Nombre del Tip/Cápsula de conocimiento',
        emoji: '🎁',
      ),
      ActivityItem(label: 'Ejemplo', emoji: '⚙️'),
      ActivityItem(label: 'Configuración para accesibilidad', emoji: '📦🖥️🎧'),
      ActivityItem(
        label: 'Nombre del Tip/Cápsula de conocimiento',
        emoji: '🎁',
      ),
      ActivityItem(label: 'Ejercicio', emoji: '🎮'),
      ActivityItem(label: 'Tu primer "Hola Mundo"', emoji: '📦🖥️🎧'),
      ActivityItem(label: 'Nombre de la buena práctica', emoji: '🏅'),
      ActivityItem(label: 'Quiz', emoji: '❓'),
      ActivityItem(label: 'Laboratorio', emoji: '🧪'),
      ActivityItem(label: 'Evaluación final', emoji: '📋'),
    ],
  ),
  const ChapterModel(
    id: 'cap_3',
    moduloTitulo: 'Módulo 1. Preparación',
    capituloTitulo: 'Capítulo 3: Desarrollo',
    resumenTexto:
        'Aprenderás a configurar tu IDE, terminal y herramientas accesibles.',
    rutaItems: [
      ActivityItem(label: 'Palabras clave', emoji: '📦🖥️🎧'),
      ActivityItem(
        label: 'Nombre del Tip/Cápsula de conocimiento',
        emoji: '🎁',
      ),
      ActivityItem(label: 'Ejemplo', emoji: '⚙️'),
      ActivityItem(label: 'Glosario visual/auditivo', emoji: '📦🖥️🎧'),
      ActivityItem(
        label: 'Nombre del Tip/Cápsula de conocimiento',
        emoji: '🎁',
      ),
      ActivityItem(label: 'Ejercicio', emoji: '🎮'),
      ActivityItem(label: 'Nombre de la buena práctica', emoji: '🏅'),
      ActivityItem(label: 'Quiz', emoji: '❓'),
      ActivityItem(label: 'Laboratorio', emoji: '🧪'),
      ActivityItem(label: 'Evaluación final', emoji: '📋'),
    ],
  ),
  // Puedes agregar el Capítulo 3 aquí directamente sin tocar widgets...
];
