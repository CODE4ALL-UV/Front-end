import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_fab_widget.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/core/ui/social_auth_block.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegister;
  final VoidCallback? onSuccess;

  const LoginPage({super.key, this.onRegister, this.onSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _authStorage = AuthStorage();
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

      _showMessage('Bienvenido ${response.nombre}');
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
      appBar: HeaderWidget(title: 'CODE4ALL v0.1.'),
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
      final googleServerClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb && googleServerClientId?.isNotEmpty == true
            ? googleServerClientId
            : null,
        serverClientId: !kIsWeb && googleServerClientId?.isNotEmpty == true
            ? googleServerClientId
            : null,
        scopes: ['email'],
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        _showMessage('Inicio de sesión cancelado');
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        _showMessage('No se obtuvo el idToken de Google');
        return;
      }

      final response = await _apiService.signInWithGoogle(idToken: idToken);

      // Guardar token de forma segura
      await _authStorage.saveToken(response.accessToken);

      _showMessage('Bienvenido ${response.nombre}');
      widget.onSuccess?.call();
    } on ApiException catch (e) {
      debugPrint('Google SignIn ApiException: ${e.toString()}');
      _showMessage(e.message);
    } catch (e, st) {
      // Mostrar error real para ayudar a depurar (se puede quitar en producción)
      debugPrint('Google SignIn exception: $e');
      debugPrint(st.toString());
      _showMessage('Error en autenticación con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
