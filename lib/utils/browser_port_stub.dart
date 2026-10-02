import 'browser_port.dart';

BrowserPort createBrowserPort() => MemoryBrowserPort(Uri.base);

/// Sin navegador: recuerda en memoria y no va a ningún sitio.
///
/// También sirve en las pruebas para simular con qué dirección se abrió la
/// app y comprobar adónde quiso ir.
class MemoryBrowserPort implements BrowserPort {
  MemoryBrowserPort(this.current);

  @override
  Uri current;

  final Map<String, String> storage = {};
  final List<String> opened = [];

  @override
  void replace(String url) => current = Uri.parse(url);

  @override
  void open(String url) => opened.add(url);

  @override
  String? read(String key) => storage[key];

  @override
  void write(String key, String value) => storage[key] = value;

  @override
  void remove(String key) => storage.remove(key);
}
