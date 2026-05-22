import 'package:flutter/material.dart';

class FormPageDark extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;
  const FormPageDark({super.key, this.onBack, this.onSuccess});

  @override
  State<FormPageDark> createState() => _FormPageDarkState();
}

class _FormPageDarkState extends State<FormPageDark> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptTerms = false;

  void _handleRegister() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validación básica
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo electrónico válido')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    // Registro exitoso → navegar a Welcome
    widget.onSuccess?.call();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 136, 135, 135),
        elevation: 0,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onBack,
              )
            : Padding(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Logo Code4All (versión blanca para dark mode)
                  Image.asset(
                    'assets/images/logoblancoTg.png',
                    height: 120,
                    width: 200,
                  ),
                  const SizedBox(height: 24),

                  // Card del formulario
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3E3E3E)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo Correo electrónico
                        const Text(
                          'Correo electrónico',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Valor',
                            hintStyle: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3A3A3A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFFFD600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Campo Contraseña
                        const Text(
                          'Contraseña',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE0E0E0),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Valor',
                            hintStyle: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF3A3A3A),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF4A4A4A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFFFD600)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Checkbox Aviso / Términos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _acceptTerms,
                                activeColor: const Color(0xFF5C6BC0),
                                checkColor: Colors.white,
                                side: const BorderSide(color: Color(0xFF9E9E9E)),
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
                                    color: Color(0xFFE0E0E0),
                                  ),
                                ),
                                Text(
                                  'Acepto términos y condiciones',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9E9E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Botón Registrarse
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _acceptTerms
                                ? () => _handleRegister()
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF212121),
                              disabledBackgroundColor: const Color(0xFF3A3A3A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
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