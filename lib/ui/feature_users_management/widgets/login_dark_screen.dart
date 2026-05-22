import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginPageDark extends StatelessWidget {
  final VoidCallback? onRegister;
  const LoginPageDark({super.key, this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: const [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Icon(Icons.account_circle_outlined, color: Colors.white, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Code4All
                  Image.asset(
                    'assets/images/logoblancoTg.png',
                    height: 460,
                    width: 460,
                  ),
                  const SizedBox(height: 5),

                  // Botones sociales
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      _SocialButtonDark(
                        onTap: () {},
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
                      // Facebook
                      _SocialButtonDark(
                        onTap: () {},
                        backgroundColor: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b9/2023_Facebook_icon.svg/800px-2023_Facebook_icon.svg.png',
                            width: 28,
                            height: 28,
                            errorBuilder: (context, error, stackTrace) => const Icon(
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

                  // Botón Registrarse
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onRegister ?? () {},
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

          // Ícono accesibilidad
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF5C6BC0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.accessibility_new, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),

      // Barra inferior
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
}

class _SocialButtonDark extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
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
              color: Colors.black.withOpacity(0.12),
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