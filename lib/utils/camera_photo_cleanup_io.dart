import 'dart:io';

import 'package:camera/camera.dart';

/// Borra una foto de la cámara en cuanto ya no hace falta.
///
/// En el móvil y en el escritorio, cada foto queda como un archivo en la caché
/// hasta que el sistema decida limpiarla. Con varias fotos por segundo serían
/// decenas de megas al minuto, y decirle a la persona que no se guarda ninguna
/// imagen no sería verdad.
Future<void> discardCameraPhoto(XFile photo) async {
  if (photo.path.isEmpty) return;
  try {
    await File(photo.path).delete();
  } on FileSystemException {
    // Ya no estaba: era lo que se quería.
  }
}
