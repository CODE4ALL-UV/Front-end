import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_test/flutter_test.dart';

// IMPORTANTE: Ajusta esta ruta según el nombre real de tu paquete
// import 'package:tu_app/data/models/auth_models.dart';

void main() {
  group('Auth Models Tests', () {
    test('RegisterRequest - constructor y toJson', () {
      // Cubre las líneas 12-19 (constructor)
      const request = RegisterRequest(
        nombre: 'Juan',
        correo: 'juan@test.com',
        password: '123',
        tipoDiscapacidad: 1,
        rol: 'estudiante',
        codigoInvitacion: 'XYZ',
      );

      // Verificamos que el constructor asigne bien
      expect(request.nombre, 'Juan');

      // Cubre las líneas 21-29 (toJson) aunque ya estaba parcialmente verde
      final json = request.toJson();
      expect(json['nombre'], 'Juan');
      expect(json['codigo_invitacion'], 'XYZ');
    });

    test('RegisterResponse - constructor y fromJson', () {
      final fechaPrueba = DateTime.now();

      // Cubre las líneas 40-47 (constructor)
      final response = RegisterResponse(
        idUsuario: 1,
        nombre: 'Juan',
        correo: 'juan@test.com',
        tipoDiscapacidad: 1,
        fechaRegistro: fechaPrueba,
        rol: 'estudiante',
      );
      expect(response.idUsuario, 1);

      // Cubre las líneas 49-59 (RegisterResponse.fromJson)
      final Map<String, dynamic> jsonResponse = {
        'id_usuario': 2,
        'nombre': 'Ana',
        'correo': 'ana@test.com',
        'tipo_discapacidad': 2,
        'fecha_registro': '2023-10-01T12:00:00Z',
        'rol': 'docente',
      };

      final fromJsonResult = RegisterResponse.fromJson(jsonResponse);
      expect(fromJsonResult.idUsuario, 2);
      expect(fromJsonResult.nombre, 'Ana');
      expect(fromJsonResult.rol, 'docente');
    });

    test('LoginRequest - constructor y toJson', () {
      // Cubre la línea 65 (constructor)
      const request = LoginRequest(
        email: 'test@test.com',
        password: 'password123',
      );
      expect(request.email, 'test@test.com');

      // Cubre la línea 67 (toJson)
      final json = request.toJson();
      expect(json['email'], 'test@test.com');
      expect(json['password'], 'password123');
    });

    test('ApiException - toString', () {
      // Cubre la instanciación de la excepción
      const apiException = ApiException(
        statusCode: 404,
        message: 'Usuario no encontrado',
      );

      // Cubre las líneas 108-110 (toString override)
      expect(apiException.toString(), 'Usuario no encontrado');
    });
  });
}
