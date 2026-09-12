// este es un ejempl ode modulo dart que sirve para mostrar como se pueden crear modelos de datos en Dart
//REFACTOR-APROVED - COLOR TEST REMAINING - DONT TESTED IN UI
class ActivityItem {
  final String label;
  final String emoji;

  const ActivityItem({required this.label, required this.emoji});

  // Getters auxiliares para que la UI no tenga que evaluar emojis directamente
  bool get hasLectura => emoji.contains('📦');
  bool get hasVideo => emoji.contains('🖥️');
}

class ChapterModel {
  final String id;
  final String capituloNombre;
  final String moduloTitulo;
  final String capituloTitulo;
  final String resumenTexto;
  final List<ActivityItem> rutaItems;

  const ChapterModel({
    required this.id,
    required this.capituloNombre,
    required this.moduloTitulo,
    required this.capituloTitulo,
    required this.resumenTexto,
    required this.rutaItems,
  });
}
