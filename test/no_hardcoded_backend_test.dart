import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Vigila que nadie vuelva a escribir la dirección del servidor a mano.
///
/// Nace de un fallo real en producción. Al desplegar, cinco pantallas seguían
/// llamando a `http://127.0.0.1:8000` porque cada una construía la URL por su
/// cuenta. En el navegador de cada visitante eso es *su propio ordenador*, así
/// que el navegador lo bloqueaba:
///
///     Access to fetch at 'http://127.0.0.1:8000/api/modules/default-module'
///     from origin 'https://code4all-web.onrender.com' has been blocked by
///     CORS policy
///
/// Lo caro no fue arreglarlo: fue que solo se descubrió con la aplicación ya
/// publicada. Esta prueba lo detecta antes de salir.
void main() {
  /// El único sitio donde la dirección puede aparecer escrita.
  const permitido = 'api_service.dart';

  List<File> dartFiles(String path) => Directory(path)
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('ninguna pantalla escribe la dirección del servidor a mano', () {
    final culpables = <String>[];

    for (final file in dartFiles('lib')) {
      if (file.path.endsWith(permitido)) continue;

      final contenido = file.readAsStringSync();
      for (final aguja in ['127.0.0.1:8000', 'localhost:8000', '10.0.2.2:8000']) {
        if (contenido.contains(aguja)) {
          culpables.add('${file.path} contiene "$aguja"');
        }
      }
    }

    expect(
      culpables,
      isEmpty,
      reason:
          'Estas direcciones apuntan al ordenador de quien abre la aplicación, '
          'no al servidor. Usa ApiService().baseUrl, que sabe leer la que se '
          'fija al compilar:\n  ${culpables.join("\n  ")}',
    );
  });

  test('solo ApiService decide a qué servidor se llama', () {
    // Si otra pantalla leyera BACKEND_URL por su cuenta, al desplegar habria
    // que acordarse de configurarlo en dos sitios, y uno se olvida.
    final culpables = <String>[];

    for (final file in dartFiles('lib')) {
      if (file.path.endsWith(permitido)) continue;

      if (file.readAsStringSync().contains("dotenv.env['BACKEND_URL']")) {
        culpables.add(file.path);
      }
    }

    expect(culpables, isEmpty, reason: 'Deben usar ApiService().baseUrl');
  });
}
