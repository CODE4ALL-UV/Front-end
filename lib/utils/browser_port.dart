import 'browser_port_stub.dart'
    if (dart.library.js_interop) 'browser_port_web.dart'
    as impl;

/// Lo poco que la app toca del navegador: la dirección de la página y la
/// memoria de la pestaña (`sessionStorage`).
///
/// Lo usan la vuelta de Facebook y el enlace para cambiar la contraseña, que
/// llegan los dos como parámetros en la dirección. Fuera de la web no hay
/// dirección que leer: se usa una versión en memoria que no hace nada.
abstract class BrowserPort {
  static BrowserPort instance = impl.createBrowserPort();

  /// La dirección actual, con sus parámetros.
  Uri get current;

  /// Cambia la dirección sin recargar ni dejar rastro en el historial.
  void replace(String url);

  /// Va a otra página.
  void open(String url);

  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}
