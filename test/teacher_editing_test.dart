import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/course_content_json.dart';
import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/course_section_edits.dart';
import 'package:flutter_code4all/ui/teacher/teacher_widgets.dart';

/// Comprueba la lógica que hay detrás del editor del docente.
///
/// Lo que más importa aquí es que **no se pierda trabajo**: cambiar una cosa
/// no puede borrar otra, y una edición a medias no puede dejar un quiz roto
/// para el estudiante.
void main() {
  CourseSection sectionOf(int module, int number) =>
      PythonCourseCatalog.section(module, number)!;

  group('cambiar una cosa no toca las demás', () {
    test('cambiar el título deja intacto todo lo demás', () {
      final original = sectionOf(1, 1);
      final edited = original.copyWith(title: 'Otro título');

      expect(edited.title, 'Otro título');
      expect(edited.summary, original.summary);
      expect(edited.reading, same(original.reading));
      expect(edited.quiz, same(original.quiz));
      expect(edited.videos, same(original.videos));
    });

    test('la identidad de la sección no se puede cambiar', () {
      // Es lo que impide que una sección editada suplante a otra.
      final original = sectionOf(2, 1);
      final edited = original.copyWith(title: 'x');

      expect(edited.id, original.id);
      expect(edited.moduleNumber, original.moduleNumber);
      expect(edited.number, original.number);
    });

    test('se puede quitar una actividad sin tocar el resto', () {
      final original = sectionOf(1, 1);
      final edited = original.copyWith(capsule: null);

      expect(edited.capsule, isNull);
      expect(edited.reading, isNotNull);
      expect(edited.quiz, isNotEmpty);
    });

    test('no pasar un campo no lo borra', () {
      // El fallo clásico de un copyWith mal hecho: guardar el título y
      // llevarse por delante la lectura entera.
      final original = sectionOf(1, 1);
      final edited = original.copyWith(summary: 'nuevo');

      expect(edited.capsule, same(original.capsule));
      expect(edited.example, same(original.example));
      expect(edited.exercise, same(original.exercise));
    });
  });

  group('un quiz no se puede dejar roto', () {
    test('borrar la opción correcta recoloca la respuesta', () {
      const question = QuizQuestion(
        prompt: '¿Cuál es?',
        options: ['a', 'b', 'c'],
        correctIndex: 2,
      );

      // El docente deja solo dos opciones: la correcta era la tercera.
      final edited = question.copyWith(options: ['a', 'b']);

      expect(edited.correctIndex, lessThan(edited.options.length));
      expect(() => edited.correctOption, returnsNormally);
    });

    test('quedarse sin opciones no revienta', () {
      const question = QuizQuestion(
        prompt: 'x',
        options: ['a', 'b'],
        correctIndex: 1,
      );

      expect(question.copyWith(options: []).correctIndex, 0);
    });

    test('un índice negativo se corrige solo', () {
      const question = QuizQuestion(prompt: 'x', options: ['a'], correctIndex: 0);
      expect(question.copyWith(correctIndex: -3).correctIndex, 0);
    });
  });

  group('cambiar el tipo de un bloque', () {
    test('de párrafo a lista se conserva el título y el texto', () {
      const block = ReadingBlock.paragraph(
        title: 'Mi título',
        body: 'Mi texto',
      );
      final listed = block.asKind(ReadingBlockKind.bullets);

      expect(listed.kind, ReadingBlockKind.bullets);
      expect(listed.title, 'Mi título');
      expect(listed.body, 'Mi texto');
    });

    test('de código a párrafo no se pierde el título', () {
      const block = ReadingBlock.code(
        title: 'Ejemplo',
        code: 'print("hola")',
        codeCaption: 'Saluda',
      );
      final paragraph = block.asKind(ReadingBlockKind.paragraph);

      expect(paragraph.kind, ReadingBlockKind.paragraph);
      expect(paragraph.title, 'Ejemplo');
    });

    test('convertir al mismo tipo devuelve el mismo bloque', () {
      const block = ReadingBlock.paragraph(title: 'a', body: 'b');
      expect(block.asKind(ReadingBlockKind.paragraph), same(block));
    });

    test('editar un bloque de código conserva el código', () {
      // Si el copyWith reutilizara el constructor de párrafo, el código
      // desaparecería al cambiar solo el título.
      const block = ReadingBlock.code(title: 'a', code: 'x = 1');
      final edited = block.copyWith(title: 'b');

      expect(edited.code, 'x = 1');
      expect(edited.kind, ReadingBlockKind.code);
    });

    test('editar un recuadro conserva su intención', () {
      const block = ReadingBlock.callout(
        title: 'Cuidado',
        body: 'texto',
        tone: CalloutTone.warning,
      );
      expect(block.copyWith(body: 'otro').tone, CalloutTone.warning);
    });
  });

  group('pegar un enlace de YouTube', () {
    test('reconoce las formas habituales', () {
      const id = 'dQw4w9WgXcQ';
      for (final link in [
        id,
        'https://www.youtube.com/watch?v=$id',
        'https://youtu.be/$id',
        'https://www.youtube.com/embed/$id',
        'https://www.youtube.com/shorts/$id',
        'https://m.youtube.com/watch?v=$id&t=30s',
        '  https://www.youtube.com/watch?v=$id  ',
      ]) {
        expect(extractYoutubeId(link), id, reason: 'falló con: $link');
      }
    });

    test('con una lista de reproducción saca el video, no la lista', () {
      expect(
        extractYoutubeId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=PLabc123',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('lo que no es un video devuelve nulo, no algo inventado', () {
      for (final bad in ['', '   ', 'hola', 'https://vimeo.com/12345']) {
        expect(extractYoutubeId(bad), isNull, reason: 'falló con: "$bad"');
      }
    });
  });

  group('reordenar listas', () {
    test('subir y bajar un elemento', () {
      expect(moveItem([1, 2, 3], 2, 0), [3, 1, 2]);
      expect(moveItem([1, 2, 3], 0, 2), [2, 3, 1]);
    });

    test('no toca la lista original', () {
      final original = [1, 2, 3];
      moveItem(original, 0, 2);
      expect(original, [1, 2, 3]);
    });

    test('un índice fuera de rango no rompe nada', () {
      expect(moveItem([1, 2, 3], 5, 0), [1, 2, 3]);
      expect(moveItem([1, 2, 3], 0, 9), [1, 2, 3]);
      expect(moveItem(<int>[], 0, 0), isEmpty);
    });
  });

  group('lo editado se puede guardar y recuperar', () {
    test('una sección muy editada sobrevive al viaje al servidor', () {
      final original = sectionOf(1, 1);

      final edited = original.copyWith(
        title: 'Título nuevo',
        summary: 'Descripción nueva',
        quiz: [
          const QuizQuestion(
            prompt: '¿Sí o no?',
            options: ['Sí', 'No'],
            correctIndex: 1,
            explanation: 'Porque sí',
          ),
        ],
        videos: [
          const SectionVideo(
            title: 'Mi video',
            youtubeId: 'dQw4w9WgXcQ',
            description: 'descripción',
            transcript: 'la transcripción',
            duration: '4:20',
          ),
        ],
        capsule: null,
      );

      final recovered = sectionFromJson(sectionToJson(edited), original);

      expect(recovered.title, 'Título nuevo');
      expect(recovered.summary, 'Descripción nueva');
      expect(recovered.quiz.single.correctOption, 'No');
      expect(recovered.videos.single.youtubeId, 'dQw4w9WgXcQ');
      expect(recovered.videos.single.transcript, 'la transcripción');
      // Quitar la cápsula tiene que sobrevivir al viaje: si volviera, el
      // docente la habría borrado para nada.
      expect(recovered.capsule, isNull);
      // Y lo que no se tocó sigue ahí.
      expect(recovered.reading?.pages.length, original.reading?.pages.length);
    });

    test('quitar la lectura no la resucita al recargar', () {
      final original = sectionOf(2, 1);
      final edited = original.copyWith(reading: null);

      final recovered = sectionFromJson(sectionToJson(edited), original);
      expect(recovered.reading, isNull);
    });
  });
}
