import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state.dart';

class FormPageLight extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;

  const FormPageLight({super.key, this.onBack, this.onSuccess});

  @override
  State<FormPageLight> createState() => _FormPageLightState();
}

class _FormPageLightState extends State<FormPageLight> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();

  int? _tipoDiscapacidad;
  String _selectedRole = 'estudiante';
  bool _acceptTerms = false;
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    final nombre = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nombre.isEmpty) {
      _showMessage('Ingresa tu nombre');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Ingresa un correo electrónico válido');
      return;
    }

    if (password.length < 6) {
      _showMessage('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    if (!_acceptTerms) {
      _showMessage('Debes aceptar los términos y condiciones');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.register(
        nombre: nombre,
        correo: email,
        password: password,
        tipoDiscapacidad: _tipoDiscapacidad,
        rol: _selectedRole,
      );

      if (!mounted) return;
      _showMessage(
        'Registro exitoso: ${response.nombre}. Rol asignado: ${response.rol}',
      );
      widget.onSuccess?.call();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Ocurrió un error inesperado');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = screenWidth < 360 ? 140.0 : 180.0;
    final horizontalPadding = screenWidth < 480 ? 20.0 : 32.0;

    return ReadableScreenHighlight(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFE53935),
          elevation: 0,
          leading: widget.onBack != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onBack,
                )
              : Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Image.asset('assets/images/logoUV_Gris1.png'),
                ),
          title: const Text(
            'CODE4ALL',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo-flutter.png',
                      height: logoSize,
                      width: logoSize * 1.5,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nombre',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Correo electrónico',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Contraseña',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tipo de discapacidad',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<int?>(
                            value: _tipoDiscapacidad,
                            decoration: _inputDecoration(),
                            items: const [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No especificar'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 1,
                                child: Text('Tipo 1'),
                              ),
                              DropdownMenuItem<int?>(
                                value: 2,
                                child: Text('Tipo 2'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => _tipoDiscapacidad = value),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rol de acceso',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: _inputDecoration(),
                            items: const [
                              DropdownMenuItem(
                                value: 'estudiante',
                                child: Text('Estudiante'),
                              ),
                              DropdownMenuItem(
                                value: 'docente',
                                child: Text('Docente'),
                              ),
                              DropdownMenuItem(
                                value: 'director',
                                child: Text('Director'),
                              ),
                            ],
                            onChanged: (value) => setState(
                              () => _selectedRole = value ?? 'estudiante',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  activeColor: const Color(0xFF5C6BC0),
                                  onChanged: (val) {
                                    setState(() => _acceptTerms = val ?? false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aviso',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  Text(
                                    'Acepto términos y condiciones',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF212121),
                                disabledBackgroundColor: const Color(
                                  0xFF9E9E9E,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          color: const Color(0xFFE53935),
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              Icon(Icons.skip_previous, color: Colors.white, size: 28),
              Icon(Icons.play_arrow, color: Colors.white, size: 32),
              Icon(Icons.skip_next, color: Colors.white, size: 28),
              Icon(Icons.settings, color: Colors.white, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
    hintText: 'Valor',
    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: Color(0xFFE53935)),
    ),
  );
}
