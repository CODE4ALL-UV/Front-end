import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_fab_widget.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/core/ui/social_auth_block.dart';
import 'package:flutter_code4all/data/services/google_auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegister;
  final void Function(String role)? onSuccess;

  const LoginPage({super.key, this.onRegister, this.onSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
    final isWide = screenWidth >= 800;
    final logoSize = screenWidth < 360 ? 180.0 : (isWide ? 250.0 : 220.0);
    final horizontalPadding = screenWidth < 480 ? 20.0 : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: HeaderWidget(
        title: 'CODE4ALL v0.1.',
        showUserIcon: false,
        userName: 'Usuario',
        onLogout: () => widget.onSuccess?.call('logout'),
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
                    'assets/images/logo-flutter.png',
                    height: logoSize,
                    width: logoSize,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
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
                        backgroundColor: const Color(0xFF1E88E5),
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
                                color: Colors.white,
                              ),
                            )
                          : const Text('INICIAR SESIÓN'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SocialAuthBlock(
                    onGoogleTap: () {
                      _handleGoogleSignIn();
                    },
                    onFacebookTap: () {
                      // TODO: Conectar con authViewModel.signInWithFacebook()
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onRegister ?? () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'REGISTRARSE',
                          style: TextStyle(
                            color: Color(0xFFFFD600),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
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
      floatingActionButton: const AccessibilityFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: const MultimodalNavBar(),
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
      debugPrint('Google SignIn ApiException: ${e.toString()}');
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e, st) {
      debugPrint('Google SignIn exception: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      _showMessage('Error en autenticación con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
