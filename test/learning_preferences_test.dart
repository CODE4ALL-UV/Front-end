import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';
import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';
import 'package:flutter_code4all/ui/core/ui/learning_preferences.dart';
import 'package:flutter_code4all/ui/python_course_content/widgets/section/section_activity_launcher.dart';

/// Los seis paneles del menú de ayuda estaban dibujados pero vacíos: los
/// botones tenían `onTap: () {}` y el interruptor de la voz estaba fijo en
/// `true`. Estas pruebas fijan que ahora cada ajuste cambia algo de verdad.
///
/// Lo más importante de todas: que un ajuste que nadie ha tocado no cambie
/// nada. Estas preferencias son ayudas para quien las necesita, no cambios
/// para todos.
void main() {
  final prefs = LearningPreferences.instance;

  tearDown(() async {
    // Son globales: una prueba que las deje puestas envenena la siguiente.
    await prefs.setPace(SpeechPace.medium);
    await prefs.setClearSpeech(false);
    await prefs.setSignSupport(SignSupportLevel.off);
    await prefs.setContentPreference(ContentPreference.none);
    await prefs.setLevel(LearningLevel.medium);
    await prefs.setHintsEnabled(false);
    await prefs.setManualEnabled(false);
  });

  group('asistencia auditiva', () {
    test('la velocidad deja de estar fija y sigue lo elegido', () async {
      await prefs.setPace(SpeechPace.slow);
      final lenta = prefs.effectiveSpeechRate;

      await prefs.setPace(SpeechPace.fast);
      final rapida = prefs.effectiveSpeechRate;

      expect(
        lenta,
        lessThan(rapida),
        reason: 'antes las tres pastillas daban 0.3 igual',
      );
    });

    test('«voz más pausada» baja el ritmo además de la velocidad', () async {
      await prefs.setPace(SpeechPace.medium);
      final normal = prefs.effectiveSpeechRate;

      await prefs.setClearSpeech(true);

      expect(prefs.effectiveSpeechRate, lessThan(normal));
    });

    test('nunca pide una velocidad que el motor no acepte', () async {
      for (final pace in SpeechPace.values) {
        for (final clear in [true, false]) {
          await prefs.setPace(pace);
          await prefs.setClearSpeech(clear);
          expect(prefs.effectiveSpeechRate, inInclusiveRange(0.1, 1.0));
        }
      }
    });
  });

  group('preferencias de aprendizaje', () {
    /// Una sección que tenga lectura y video, para poder comparar el orden.
    CourseSection sectionWithBoth() => PythonCourseCatalog.allSections.firstWhere(
      (section) => section.reading != null && section.videos.isNotEmpty,
    );

    test('sin preferencia, la ruta va en su orden pedagógico', () async {
      await prefs.setContentPreference(ContentPreference.none);
      final section = sectionWithBoth();

      expect(
        SectionActivityLauncher.activitiesFor(section).first,
        CourseActivityKind.lectura,
        reason: 'el orden de siempre empieza por la lectura',
      );
    });

    test('preferir videos los pone primero', () async {
      await prefs.setContentPreference(ContentPreference.videos);
      final section = sectionWithBoth();

      expect(
        SectionActivityLauncher.activitiesFor(section).first,
        CourseActivityKind.video,
      );
    });

    test('reordenar no pierde ni repite ninguna actividad', () async {
      final section = sectionWithBoth();

      await prefs.setContentPreference(ContentPreference.none);
      final original = SectionActivityLauncher.activitiesFor(section);

      await prefs.setContentPreference(ContentPreference.videos);
      final reordenada = SectionActivityLauncher.activitiesFor(section);

      expect(reordenada.toSet(), original.toSet());
      expect(reordenada.length, original.length);
    });

    test('preferir audios no toca el orden: enciende la lectura en voz alta', () async {
      final section = sectionWithBoth();

      await prefs.setContentPreference(ContentPreference.none);
      final original = SectionActivityLauncher.activitiesFor(section);

      await prefs.setContentPreference(ContentPreference.audios);

      expect(SectionActivityLauncher.activitiesFor(section), original);
      expect(prefs.autoReadAloud, isTrue);
    });
  });

  group('nivel de aprendizaje', () {
    test('el nivel de partida no cambia nada de lo que se ve', () {
      expect(prefs.level, LearningLevel.medium);
      expect(
        prefs.hidesScaffolding,
        isFalse,
        reason: 'un ajuste que nadie tocó no puede esconder los objetivos',
      );
    });

    test('solo «Avanzado» retira los andamios', () async {
      await prefs.setLevel(LearningLevel.basic);
      expect(prefs.hidesScaffolding, isFalse);
      expect(prefs.showsExtraSupport, isTrue);

      await prefs.setLevel(LearningLevel.advanced);
      expect(prefs.hidesScaffolding, isTrue);
      expect(prefs.showsExtraSupport, isFalse);
    });
  });

  group('lo que está apagado de fábrica', () {
    test('señas, pistas y manual empiezan apagados', () {
      expect(prefs.signSupport, SignSupportLevel.off);
      expect(prefs.hintsEnabled, isFalse);
      expect(prefs.manualEnabled, isFalse);
    });
  });

  group('las etiquetas del panel y los valores coinciden', () {
    test('cada etiqueta que se muestra resuelve a su valor', () {
      expect(SpeechPace.fromLabel('Lenta'), SpeechPace.slow);
      expect(SignSupportLevel.fromLabel('Avanzado'), SignSupportLevel.advanced);
      expect(ContentPreference.fromLabel('Videos'), ContentPreference.videos);
      expect(LearningLevel.fromLabel('Básico'), LearningLevel.basic);
    });

    test('una etiqueta desconocida cae en algo seguro, no revienta', () {
      // Pasa si alguien renombra un botón y olvida el valor: vale más volver
      // al de partida que dejar la aplicación sin arrancar.
      expect(SpeechPace.fromLabel('ninguna'), SpeechPace.medium);
      expect(SignSupportLevel.fromLabel(''), SignSupportLevel.off);
      expect(LearningLevel.fromLabel('otro'), LearningLevel.medium);
    });
  });
}
