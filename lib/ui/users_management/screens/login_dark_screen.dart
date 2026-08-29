import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/data/services/google_auth_service.dart';

class LoginPageDark extends StatefulWidget {
  final VoidCallback? onRegister;
  final void Function(String role)? onSuccess;

  const LoginPageDark({super.key, this.onRegister, this.onSuccess});

  @override
  State<LoginPageDark> createState() => _LoginPageDarkState();
}

class _LoginPageDarkState extends State<LoginPageDark> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _authStorage = AuthStorage();
  final _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Ingresa un correo electrónico válido');
      return;
    }

    if (password.length < 6) {
      _showMessage('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;
      await _authStorage.saveToken(response.accessToken);
      await _authStorage.saveRole(response.rol);
      await _authStorage.saveName(response.nombre);
      await _authStorage.saveEmail(response.email);
      await _authStorage.saveUserId(response.userId);
      final existingPhotoUrl = await _authStorage.getPhotoUrl();
      final nextPhotoUrl = (response.photoUrl?.trim().isNotEmpty ?? false)
          ? response.photoUrl!
          : (existingPhotoUrl ?? '');
      await _authStorage.savePhotoUrl(nextPhotoUrl);
      _showMessage(_buildWelcomeMessage(response));
      widget.onSuccess?.call(response.rol);
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

  String _buildWelcomeMessage(LoginResponse response) {
    final roleLabel = response.rol.toLowerCase();
    if (roleLabel == 'docente') {
      return 'Bienvenido ${response.nombre}. Tu rol es docente. Estamos construyendo las vistas necesarias próximamente.';
    }
    if (roleLabel == 'director') {
      return 'Bienvenido ${response.nombre}. Tu rol es director. Estamos construyendo las vistas necesarias próximamente.';
    }
    return 'Bienvenido ${response.nombre}. Tu rol es estudiante y puedes acceder a aprendizaje.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final logoSize = screenWidth < 360 ? 180.0 : 220.0;
    final horizontalPadding = screenWidth < 480 ? 20.0 : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 136, 135, 135),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset('assets/images/logoUV_Oficial_Rojo.png'),
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
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logoblancoTg.png',
                    height: logoSize,
                    width: logoSize,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1A1A1A),
                              ),
                            )
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(color: Color(0xFF1A1A1A)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButtonDark(
                        onTap: _isLoading ? null : () => _handleGoogleSignIn(),
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SvgPicture.network(
                            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                            width: 28,
                            height: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SocialButtonDark(
                        onTap: () {},
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/2023_Facebook_icon.svg/800px-2023_Facebook_icon.svg.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.facebook,
                                  color: Color(0xFF1877F2),
                                  size: 28,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: widget.onRegister ?? () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'REGISTRARSE',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color.fromARGB(255, 136, 135, 135),
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
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final response = await _googleAuthService.signIn(context: context);

      await _authStorage.saveToken(response.accessToken);
      await _authStorage.saveRole(response.rol);
      await _authStorage.saveName(response.nombre);
      await _authStorage.saveEmail(response.email);
      await _authStorage.saveUserId(response.userId);
      final existingPhotoUrl = await _authStorage.getPhotoUrl();
      final nextPhotoUrl = (response.photoUrl?.trim().isNotEmpty ?? false)
          ? response.photoUrl!
          : (existingPhotoUrl ?? '');
      await _authStorage.savePhotoUrl(nextPhotoUrl);

      _showMessage(_buildWelcomeMessage(response));
      widget.onSuccess?.call(response.rol);
    } on GoogleAuthCanceledException {
      if (!mounted) return;
      _showMessage('Inicio de sesión cancelado');
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Error en autenticación con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _SocialButtonDark extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const _SocialButtonDark({
    required this.child,
    required this.onTap,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
