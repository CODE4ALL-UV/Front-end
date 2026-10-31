import 'dart:js_interop';

import 'package:camera/camera.dart';

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(JSString url);

/// Suelta una foto de la cámara en cuanto ya no hace falta.
///
/// En la web cada foto se queda en la memoria del navegador, detrás de una URL
/// `blob:`, hasta que alguien la suelta o se cierra la página. Con varias fotos
/// por segundo serían decenas de megas al minuto.
Future<void> discardCameraPhoto(XFile photo) async {
  if (photo.path.startsWith('blob:')) _revokeObjectUrl(photo.path.toJS);
}
