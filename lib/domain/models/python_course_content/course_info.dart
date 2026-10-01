/// Un curso de Python de un docente, tal y como lo devuelve el servidor.
///
/// El temario es el mismo para todos; lo que cambia de un curso a otro es lo
/// que cada docente edita. Por eso aquí no va el contenido, solo de quién es el
/// curso y qué puede hacer con él quien lo mira.
class CourseInfo {
  const CourseInfo({
    required this.id,
    required this.title,
    this.description = '',
    this.isGeneral = false,
    this.teacherId,
    this.teacherName,
    this.isOwner = false,
    this.canEdit = false,
    this.joinCode,
    this.students,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'];
    return CourseInfo(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Curso',
      description: json['description'] as String? ?? '',
      isGeneral: json['is_general'] == true,
      teacherId: teacher is Map ? (teacher['id'] as num?)?.toInt() : null,
      teacherName: teacher is Map ? teacher['nombre'] as String? : null,
      isOwner: json['is_owner'] == true,
      canEdit: json['can_edit'] == true,
      joinCode: json['join_code'] as String?,
      students: (json['students'] as num?)?.toInt(),
    );
  }

  final int id;
  final String title;
  final String description;

  /// El curso de todos los estudiantes, sin docente. Lo edita la coordinación.
  final bool isGeneral;

  final int? teacherId;
  final String? teacherName;

  /// Lo creó quien está mirando.
  final bool isOwner;
  final bool canEdit;

  /// Solo lo recibe su docente y la coordinación.
  final String? joinCode;

  /// Cuántos estudiantes tiene. Nulo para quien no debe saberlo.
  final int? students;

  /// De quién es, dicho para una persona.
  String get ownerLabel => isGeneral
      ? 'Para todos los estudiantes'
      : (teacherName == null || teacherName!.trim().isEmpty
            ? 'Curso de un docente'
            : 'Docente: $teacherName');
}
