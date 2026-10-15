import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/teacher/course_section_edits.dart';

/// Las copias con cambios de cada pieza del temario y sus nombres visibles.
///
/// Los editores nunca modifican el contenido: hacen una copia con lo que
/// cambia. Si una copia olvidara un campo, el docente lo perdería al guardar
/// sin haberlo tocado. Por eso cada `copyWith` se prueba en las dos
/// direcciones: lo que se pasa cambia y lo que no se pasa se queda. También
/// los casos en que hay que poder *quitar* algo (pasar nulo a propósito).
void main() {
  group('lectura y páginas', () {
    const page = ReadingPage(
      title: 'Página',
      summary: 'Resumen',
      blocks: [ReadingBlock.paragraph(title: 't', body: 'b')],
    );
    const reading = SectionReading(
      title: 'Lectura',
      intro: 'Intro',
      pages: [page],
    );

    test('la lectura cambia solo lo que se le pasa', () {
      final retitled = reading.copyWith(title: 'Otra');
      expect(retitled.title, 'Otra');
      expect(retitled.intro, 'Intro');
      expect(retitled.pages, same(reading.pages));

      final repaged = reading.copyWith(pages: const []);
      expect(repaged.pages, isEmpty);
      expect(repaged.title, 'Lectura');
    });

    test('la página cambia solo lo que se le pasa', () {
      final summarized = page.copyWith(summary: 'Nuevo');
      expect(summarized.summary, 'Nuevo');
      expect(summarized.title, 'Página');
      expect(summarized.blocks, same(page.blocks));

      expect(page.copyWith(blocks: const []).blocks, isEmpty);
      expect(page.copyWith(title: 'T').summary, 'Resumen');
    });
  });

  group('bloques de lectura', () {
    test('cada tipo conserva su tipo al editarlo', () {
      const blocks = [
        ReadingBlock.paragraph(title: 'p', body: 'b'),
        ReadingBlock.bullets(title: 'l', items: ['a']),
        ReadingBlock.steps(title: 's', items: ['1']),
        ReadingBlock.code(title: 'c', code: 'x = 1'),
        ReadingBlock.callout(title: 'r', body: 'b', tone: CalloutTone.success),
      ];

      for (final block in blocks) {
        final edited = block.copyWith(title: 'nuevo');
        expect(edited.kind, block.kind, reason: block.kind.label);
        expect(edited.title, 'nuevo');
        expect(edited.body, block.body);
        expect(edited.items, block.items);
      }
    });

    test('a una lista se le cambian los puntos sin perder la introducción', () {
      const steps = ReadingBlock.steps(
        title: 'Pasos',
        items: ['uno'],
        body: 'Sigue esto:',
      );
      final edited = steps.copyWith(items: ['uno', 'dos']);

      expect(edited.items, ['uno', 'dos']);
      expect(edited.body, 'Sigue esto:');
      expect(edited.kind, ReadingBlockKind.steps);
    });

    test('a un bloque de código se le puede quitar la explicación', () {
      const code = ReadingBlock.code(
        title: 'c',
        code: 'print(1)',
        codeCaption: 'Imprime 1',
      );

      expect(code.copyWith(code: 'print(2)').codeCaption, 'Imprime 1');
      expect(code.copyWith(codeCaption: null).codeCaption, isNull);
      expect(code.copyWith(codeCaption: null).code, 'print(1)');
    });

    test('un recuadro conserva sus puntos y cambia de intención', () {
      const callout = ReadingBlock.callout(title: 'r', body: 'b', items: ['x']);
      final edited = callout.copyWith(tone: CalloutTone.warning);

      expect(edited.tone, CalloutTone.warning);
      expect(edited.items, ['x']);
    });

    test('pasar de lista a pasos y a recuadro no pierde lo escrito', () {
      const bullets = ReadingBlock.bullets(
        title: 'Lista',
        items: ['a', 'b'],
        body: 'Intro',
      );

      final steps = bullets.asKind(ReadingBlockKind.steps);
      expect(steps.kind, ReadingBlockKind.steps);
      expect(steps.items, ['a', 'b']);
      expect(steps.body, 'Intro');

      final callout = steps.asKind(ReadingBlockKind.callout);
      expect(callout.kind, ReadingBlockKind.callout);
      expect(callout.title, 'Lista');
      expect(callout.body, 'Intro');
      expect(callout.items, ['a', 'b']);
      expect(callout.tone, CalloutTone.info);
    });

    test('pasar de párrafo a código deja el código vacío para escribirlo', () {
      const paragraph = ReadingBlock.paragraph(title: 't', body: 'texto');
      final code = paragraph.asKind(ReadingBlockKind.code);

      expect(code.kind, ReadingBlockKind.code);
      expect(code.code, '');
      expect(code.body, 'texto');
    });

    test('el resumen de la lista del editor dice lo esencial de cada tipo', () {
      expect(
        const ReadingBlock.paragraph(title: '', body: 'Texto').editorSummary,
        'Texto',
      );
      expect(
        const ReadingBlock.bullets(title: '', items: ['a']).editorSummary,
        '1 punto',
      );
      expect(
        const ReadingBlock.steps(title: '', items: ['a', 'b']).editorSummary,
        '2 puntos',
      );
      expect(
        const ReadingBlock.code(title: '', code: 'x').editorSummary,
        'Fragmento de código',
      );
      expect(
        const ReadingBlock.code(
          title: '',
          code: 'x',
          codeCaption: 'Asigna x',
        ).editorSummary,
        'Asigna x',
      );
      expect(
        const ReadingBlock.callout(title: '', body: 'Aviso').editorSummary,
        'Aviso',
      );
    });

    test('cada tipo y cada intención tienen un nombre para el docente', () {
      expect(
        {for (final k in ReadingBlockKind.values) k: k.label},
        {
          ReadingBlockKind.paragraph: 'Párrafo',
          ReadingBlockKind.bullets: 'Lista de puntos',
          ReadingBlockKind.steps: 'Pasos numerados',
          ReadingBlockKind.code: 'Código',
          ReadingBlockKind.callout: 'Recuadro destacado',
        },
      );
      expect(
        {for (final t in CalloutTone.values) t: t.label},
        {
          CalloutTone.info: 'Información',
          CalloutTone.success: 'Bien hecho',
          CalloutTone.warning: 'Cuidado',
          CalloutTone.danger: 'Error frecuente',
        },
      );
    });
  });

  group('cápsula', () {
    const capsule = KnowledgeCapsule(
      title: 'T',
      headline: 'H',
      intro: 'I',
      tips: [CapsuleTip(title: 'a', body: 'b')],
      closing: 'C',
      badCode: 'x=1',
      goodCode: 'x = 1',
      badCodeCaption: 'mal',
      goodCodeCaption: 'bien',
    );

    test('cambiar el título no toca la comparación de código', () {
      final edited = capsule.copyWith(title: 'Otro');

      expect(edited.title, 'Otro');
      expect(edited.headline, 'H');
      expect(edited.intro, 'I');
      expect(edited.closing, 'C');
      expect(edited.tips, same(capsule.tips));
      expect(edited.hasCodeComparison, isTrue);
      expect(edited.badCodeCaption, 'mal');
      expect(edited.goodCodeCaption, 'bien');
    });

    test('la comparación se puede quitar entera', () {
      final edited = capsule.copyWith(
        badCode: null,
        goodCode: null,
        badCodeCaption: null,
        goodCodeCaption: null,
      );

      expect(edited.hasCodeComparison, isFalse);
      expect(edited.badCodeCaption, isNull);
      expect(edited.goodCodeCaption, isNull);
      expect(edited.title, 'T');
    });
  });

  group('ejemplo, ejercicio y videos', () {
    test('el ejemplo cambia solo lo que se le pasa', () {
      const example = CodeExample(
        title: 'T',
        description: 'D',
        code: 'print(1)',
        output: '1',
        codeCaption: 'Imprime',
        steps: [ExampleStep(code: 'print', explanation: 'muestra')],
      );

      final edited = example.copyWith(output: '2', code: 'print(2)');
      expect(edited.output, '2');
      expect(edited.code, 'print(2)');
      expect(edited.title, 'T');
      expect(edited.description, 'D');
      expect(edited.codeCaption, 'Imprime');
      expect(edited.steps, same(example.steps));

      expect(example.copyWith(steps: const []).steps, isEmpty);
      expect(example.copyWith(codeCaption: 'Otro').codeCaption, 'Otro');
    });

    test('el ejercicio cambia solo lo que se le pasa', () {
      const exercise = SectionExercise(
        title: 'T',
        instructions: 'Une',
        pairs: [ConceptPair(concept: 'int', definition: 'entero')],
      );

      final edited = exercise.copyWith(
        questions: const [
          QuizQuestion(prompt: '¿?', options: ['a', 'b'], correctIndex: 0),
        ],
      );
      expect(edited.questions, hasLength(1));
      expect(edited.pairs, same(exercise.pairs));
      expect(edited.title, 'T');
      expect(edited.instructions, 'Une');
      expect(exercise.copyWith(pairs: const []).isEmpty, isTrue);
    });

    test('el video cambia solo lo que se le pasa', () {
      const video = SectionVideo(
        title: 'T',
        youtubeId: 'dQw4w9WgXcQ',
        description: 'D',
        transcript: 'Hola',
        duration: '1:00',
      );

      final edited = video.copyWith(duration: '2:00', title: 'Otro');
      expect(edited.duration, '2:00');
      expect(edited.title, 'Otro');
      expect(edited.youtubeId, 'dQw4w9WgXcQ');
      expect(edited.description, 'D');
      expect(edited.transcript, 'Hola');
      expect(
        video.copyWith(youtubeId: 'abcdefghijk').url,
        endsWith('abcdefghijk'),
      );
    });

    test('también reconoce el enlace de una emisión en directo', () {
      expect(
        extractYoutubeId('https://www.youtube.com/live/dQw4w9WgXcQ?si=x'),
        'dQw4w9WgXcQ',
      );
    });
  });
}
