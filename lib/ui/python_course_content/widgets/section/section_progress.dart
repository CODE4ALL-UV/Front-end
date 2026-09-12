import 'package:flutter_code4all/data/course/python_course_catalog.dart';
import 'package:flutter_code4all/data/services/course_progress_store.dart';

import 'section_activity_launcher.dart';

/// Cuánto lleva hecho el estudiante de una sección, de 0 a 1.
///
/// Se calcula igual que dentro de la propia sección: cuántas de sus
/// actividades están completadas, dividido entre cuántas tiene. Al vivir en un
/// solo sitio, el círculo del mapa y la barra de dentro de la sección no pueden
/// decir cosas distintas.
///
/// Cada sección tiene las actividades que le corresponden según su contenido
/// —una sin video no cuenta un video que no existe—, así que el denominador
/// cambia de una a otra. Es lo correcto: terminar las tres actividades de una
/// sección es terminarla, tenga tres o siete.
///
/// Devuelve 0 si la sección todavía no tiene contenido, en lugar de fingir un
/// avance sobre algo que no se puede hacer.
double sectionProgress(int moduleNumber, int sectionNumber) {
  final section = PythonCourseCatalog.section(moduleNumber, sectionNumber);
  if (section == null) return 0;

  final activities = SectionActivityLauncher.activitiesFor(section);
  if (activities.isEmpty) return 0;

  final done = CourseProgressStore.instance.completedCount(
    section.id,
    activities,
  );
  return done / activities.length;
}

/// Lo que un lector de pantalla debe decir de la circunferencia de una sección.
///
/// Sin esto las tres circunferencias del mapa suenan exactamente igual
/// —«Lección con 33% de progreso»— y quien navega por voz no sabe cuál está
/// tocando. Con el número y el título de la sección sí.
String sectionProgressLabel(int moduleNumber, int sectionNumber) {
  final section = PythonCourseCatalog.section(moduleNumber, sectionNumber);
  final percentage = (sectionProgress(moduleNumber, sectionNumber) * 100)
      .round();

  if (section == null) {
    return 'Sección $sectionNumber, todavía sin contenido';
  }

  final activities = SectionActivityLauncher.activitiesFor(section);
  if (activities.isEmpty) {
    return 'Sección $sectionNumber, ${section.boxTitle}, '
        'todavía sin actividades';
  }

  final done = CourseProgressStore.instance.completedCount(
    section.id,
    activities,
  );

  // El número suelto no dice nada: «2 de 5 actividades» sí.
  return 'Sección $sectionNumber, ${section.boxTitle}. '
      '$done de ${activities.length} actividades completadas, '
      '$percentage por ciento';
}

/// Pide el progreso guardado si todavía no se ha leído.
///
/// Se puede llamar tantas veces como haga falta: la primera lee el
/// almacenamiento y avisa a quien esté escuchando, y las siguientes no hacen
/// nada. Así una pantalla puede pedirlo sin preocuparse de si otra se le
/// adelantó.
void ensureProgressLoaded() {
  final store = CourseProgressStore.instance;
  if (store.isLoaded) return;
  store.load();
}
