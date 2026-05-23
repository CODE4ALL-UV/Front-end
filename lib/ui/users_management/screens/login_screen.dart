import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_code4all/ui/core/ui/header_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_fab_widget.dart';
import 'package:flutter_code4all/ui/core/ui/multimodal_footer_bar.dart';
import 'package:flutter_code4all/ui/core/ui/social_auth_block.dart';

class LoginPage extends StatelessWidget {
  final VoidCallback? onRegister;
  const LoginPage({super.key, this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. Insertamos el header unificado. Leerá automáticamente el tema activo.
      appBar: HeaderWidget(title: 'CODE4ALL v0.1.'),
      // 2. Cuerpo de la vista protegido contra desbordamientos en pantallas pequeñas
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Code4All optimizado
              Image.asset(
                'assets/images/logo-flutter.png',
                height: 460,
                width: 460,
              ),
              const SizedBox(height: 5),

              // 3. Bloque de Botones Sociales Componetizado con Semántica
              SocialAuthBlock(
                onGoogleTap: () {
                  // TODO: Conectar con authViewModel.signInWithGoogle()
                },
                onFacebookTap: () {
                  // TODO: Conectar con authViewModel.signInWithFacebook()
                },
              ),
              const SizedBox(height: 20),

              // 4. Botón Registrarse
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
                    onPressed: onRegister ?? () {},
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

      // 5. Botón Flotante de Accesibilidad con Semantics nativo para TalkBack/VoiceOver
      floatingActionButton: const AccessibilityFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,

      // 6. Barra Multimodal Inferior acoplada a tu bottomNavigationBarTheme
      bottomNavigationBar: const MultimodalNavBar(),
    );
  }
}
