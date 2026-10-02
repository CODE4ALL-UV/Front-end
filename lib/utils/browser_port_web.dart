import 'dart:js_interop';

import 'browser_port.dart';

BrowserPort createBrowserPort() => _WebBrowserPort();

extension type _Location(JSObject _) implements JSObject {
  external String get href;
  external void assign(String url);
}

extension type _History(JSObject _) implements JSObject {
  external void replaceState(JSAny? data, String unused, String url);
}

extension type _Storage(JSObject _) implements JSObject {
  external String? getItem(String key);
  external void setItem(String key, String value);
  external void removeItem(String key);
}

@JS('window.location')
external _Location get _location;

@JS('window.history')
external _History get _history;

@JS('window.sessionStorage')
external _Storage get _sessionStorage;

class _WebBrowserPort implements BrowserPort {
  @override
  Uri get current => Uri.parse(_location.href);

  @override
  void replace(String url) => _history.replaceState(null, '', url);

  @override
  void open(String url) => _location.assign(url);

  // El navegador puede negar el almacenamiento (modo privado estricto, datos
  // bloqueados). Entonces simplemente no se recuerda nada.
  @override
  String? read(String key) {
    try {
      return _sessionStorage.getItem(key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String key, String value) {
    try {
      _sessionStorage.setItem(key, value);
    } catch (_) {}
  }

  @override
  void remove(String key) {
    try {
      _sessionStorage.removeItem(key);
    } catch (_) {}
  }
}
