import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_exercise_screen.dart';

/// Estas pruebas protegen el contenido del curso, no la interfaz.
///
/// Un `correctIndex` fuera de rango o una lectura sin páginas no se ve al
/// compilar: revienta delante del estudiante. Aquí se detecta antes.
void main() {
  group('Catálogo del curso', () {
    test('los seis módulos tienen tres secciones numeradas 1, 2 y 3', () {
      expect(PythonCourseCatalog.modules.length, 6);

      for (final module in PythonCourseCatalog.modules) {
        expect(
          module.sections.length,
          3,
          reason: 'El módulo ${module.number} debe tener 3 secciones',
        );
        expect(
          module.sections.map((s) => s.number).toList(),
          [1, 2, 3],
          reason:
              'Las secciones del módulo ${module.number} están mal numeradas',
        );
      }
    });

    test('los identificadores de sección son únicos y coherentes', () {
      final ids = <String>{};

      for (final module in PythonCourseCatalog.modules) {
        for (final section in module.sections) {
          expect(
            ids.add(section.id),
            isTrue,
            reason: 'El identificador ${section.id} está repetido',
          );
          expect(section.id, 'm${module.number}-s${section.number}');
          expect(section.moduleNumber, module.number);
          expect(PythonCourseCatalog.sectionById(section.id), same(section));
        }
      }
    });

    test('toda sección tiene título, resumen y objetivos', () {
      for (final section in PythonCourseCatalog.allSections) {
        expect(section.title.trim(), isNotEmpty, reason: section.id);
        expect(section.summary.trim(), isNotEmpty, reason: section.id);
        expect(section.objectives, isNotEmpty, reason: section.id);
      }
    });

    test('las lecturas tienen páginas y cada página tiene bloques', () {
      for (final section in PythonCourseCatalog.allSections) {
        final reading = section.reading;
        if (reading == null) continue;

        expect(reading.pages, isNotEmpty, reason: section.id);
        for (final page in reading.pages) {
          expect(page.title.trim(), isNotEmpty, reason: section.id);
          expect(page.summary.trim(), isNotEmpty, reason: section.id);
          expect(
            page.blocks,
            isNotEmpty,
            reason: '${section.id} / ${page.title}',
          );
        }
      }
    });

    test('todo bloque de código explica en palabras lo que hace', () {
      // Sin esta descripción, quien usa lector de pantalla solo escucharía
      // símbolos sueltos.
      for (final section in PythonCourseCatalog.allSections) {
        for (final page in section.reading?.pages ?? const <ReadingPage>[]) {
          for (final block in page.blocks) {
            if (block.kind != ReadingBlockKind.code) continue;
            expect(
              block.codeCaption?.trim(),
              isNotEmpty,
              reason: 'Falta codeCaption en ${section.id} / ${block.title}',
            );
          }
        }
      }
    });

    test('los videos traen transcripción escrita y duración', () {
      // El contenido del video tiene que estar disponible sin audio, y el
      // panel de señas deletrea justamente esa transcripción.
      final usedIds = <String>{};

      for (final section in PythonCourseCatalog.allSections) {
        for (final video in section.videos) {
          expect(
            video.youtubeId.length,
            11,
            reason:
                '${section.id}: id de YouTube inválido '
                '"${video.youtubeId}"',
          );
          expect(video.url, startsWith('https://'), reason: section.id);
          expect(video.title.trim(), isNotEmpty, reason: section.id);
          expect(video.duration.trim(), isNotEmpty, reason: section.id);
          expect(
            video.transcript.trim(),
            isNotEmpty,
            reason: '${section.id}: "${video.title}" sin transcripción',
          );
          expect(
            usedIds.add(video.youtubeId),
            isTrue,
            reason: 'El video ${video.youtubeId} está repetido en otra sección',
          );
        }
      }
    });

    test('las secciones con contenido tienen al menos un video', () {
      final sinVideo = PythonCourseCatalog.allSections
          .where((section) => !section.isPlaceholder && section.videos.isEmpty)
          .map((section) => section.id)
          .toList();

      expect(sinVideo, isEmpty);
    });

    test('las preguntas son válidas y su respuesta correcta existe', () {
      void check(String where, List<QuizQuestion> questions) {
        for (final question in questions) {
          expect(question.prompt.trim(), isNotEmpty, reason: where);
          expect(
            question.options.length,
            greaterThanOrEqualTo(2),
            reason: '$where: "${question.prompt}" necesita al menos 2 opciones',
          );
          expect(
            question.correctIndex,
            inInclusiveRange(0, question.options.length - 1),
            reason:
                '$where: índice correcto fuera de rango en '
                '"${question.prompt}"',
          );
          expect(
            question.options.toSet().length,
            question.options.length,
            reason: '$where: hay opciones repetidas en "${question.prompt}"',
          );
        }
      }

      for (final section in PythonCourseCatalog.allSections) {
        check('${section.id} quiz', section.quiz);
        check('${section.id} evaluación', section.finalEvaluation);
        check(
          '${section.id} ejercicio',
          section.exercise?.questions ?? const [],
        );
      }
    });

    test('los ejercicios de emparejar generan preguntas resolubles', () {
      for (final section in PythonCourseCatalog.allSections) {
        final exercise = section.exercise;
        if (exercise == null || exercise.isEmpty) continue;

        final questions = buildExerciseQuestions(exercise);
        expect(
          questions.length,
          exercise.pairs.length + exercise.questions.length,
          reason: section.id,
        );

        for (final question in questions) {
          expect(
            question.correctIndex,
            inInclusiveRange(0, question.options.length - 1),
            reason: '${section.id}: "${question.prompt}"',
          );
          expect(
            question.options.toSet().length,
            question.options.length,
            reason: '${section.id}: opciones repetidas en "${question.prompt}"',
          );
        }
      }
    });

    test('navegar entre secciones respeta los límites del módulo', () {
      final primera = PythonCourseCatalog.section(2, 1)!;
      final ultima = PythonCourseCatalog.section(2, 3)!;

      expect(PythonCourseCatalog.previousSectionInModule(primera), isNull);
      expect(PythonCourseCatalog.nextSectionInModule(primera)?.number, 2);
      expect(PythonCourseCatalog.nextSectionInModule(ultima), isNull);
      expect(PythonCourseCatalog.previousSectionInModule(ultima)?.number, 2);
    });

    test('las secciones sin material quedan marcadas como pendientes', () {
      final pendientes = PythonCourseCatalog.allSections
          .where((section) => section.isPlaceholder)
          .map((section) => section.id)
          .toList();

      // Módulo 4 sección 3 (funciones recursivas) y todo el módulo 6 siguen a
      // la espera de contenido. Si esta lista cambia, es que se cargó o se
      // perdió material.
      expect(pendientes, ['m4-s3', 'm6-s1', 'm6-s2', 'm6-s3']);
    });
  });
}
