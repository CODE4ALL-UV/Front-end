import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_code4all/data/services/api_service.dart';

/// Comprueba a qué servidor apunta la aplicación.
///
/// Importa más de lo que parece: si al desplegar la web quedara apuntando a
/// `127.0.0.1`, funcionaría en el ordenador de quien la compiló y en ningún
/// otro, porque esa dirección es «este mismo ordenador» para cada visitante.
void main() {
  group('la dirección del servidor', () {
    test('se puede fijar explícitamente', () {
      final api = ApiService(baseUrl: 'https://code4all-api.onrender.com');
      expect(api.baseUrl, 'https://code4all-api.onrender.com');
    });

    test('no deja barras de más al armar una ruta', () {
      // Una doble barra en la URL es fea y algunos servidores la rechazan.
      final api = ApiService(baseUrl: 'https://ejemplo.com');

      expect(api.buildUrl('/api/auth/login'), 'https://ejemplo.com/api/auth/login');
      expect(api.buildUrl('api/auth/login'), 'https://ejemplo.com/api/auth/login');
      expect(api.baseUrl, isNot(endsWith('/')));
    });

    test('se limpian los espacios sobrantes', () {
      // Una dirección pegada de un panel suele venir con espacios.
      expect(
        ApiService(baseUrl: '  https://ejemplo.com  ').baseUrl,
        'https://ejemplo.com',
      );
    });

    test('sin configurar apunta a la máquina local, no a la nada', () {
      // En desarrollo debe seguir funcionando sin tener que definir nada.
      final api = ApiService();

      expect(api.baseUrl, isNotEmpty);
      expect(api.baseUrl, startsWith('http'));
    });
  });
}
