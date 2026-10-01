class RegisterRequest {
  final String nombre;
  final String correo;
  final String password;
  final int? tipoDiscapacidad;
  final String rol;

  /// Solo para docente o director: el servidor no acepta esos roles sin el
  /// código que entrega la coordinación.
  final String? codigoInvitacion;

  const RegisterRequest({
    required this.nombre,
    required this.correo,
    required this.password,
    this.tipoDiscapacidad,
    required this.rol,
    this.codigoInvitacion,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'correo': correo,
    'password': password,
    'tipo_discapacidad': tipoDiscapacidad,
    'rol': rol,
    if (codigoInvitacion != null && codigoInvitacion!.trim().isNotEmpty)
      'codigo_invitacion': codigoInvitacion!.trim(),
  };
}

class RegisterResponse {
  final int idUsuario;
  final String nombre;
  final String correo;
  final int? tipoDiscapacidad;
  final DateTime fechaRegistro;
  final String rol;

  const RegisterResponse({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.tipoDiscapacidad,
    required this.fechaRegistro,
    required this.rol,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      idUsuario: json['id_usuario'] as int,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      tipoDiscapacidad: json['tipo_discapacidad'] as int?,
      fechaRegistro: DateTime.parse(json['fecha_registro'] as String),
      rol: (json['rol'] ?? 'estudiante').toString(),
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String email;
  final String nombre;
  final String rol;
  final String? photoUrl;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    required this.email,
    required this.nombre,
    required this.rol,
    this.photoUrl,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
      userId: json['user_id'] as int,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: (json['rol'] ?? 'estudiante').toString(),
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  @override
  String toString() => message;
}
