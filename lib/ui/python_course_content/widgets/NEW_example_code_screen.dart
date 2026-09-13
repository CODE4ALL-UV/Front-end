import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';

class ExampleCodeScreen extends StatelessWidget {
  final String actividad;

  const ExampleCodeScreen({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GlobalAppBarWidget(
        userName: '', //widget.userName,
        onLogout: null, //widget.onLogout,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF0B4F6C).withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Ejemplo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mi primer programa en Python',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _LecturaCard(
                title: 'Ejemplo: Mi primer programa en Python',
                body:
                    '## Ejemplo: Mi primer programa en Python\n\n```python\n# Mi primer programa en Python\n\nprint("¡Bienvenido a Python!")\n\nprint("Este es mi primer código")\n\nnumero = 10\n\nmensaje = "Python es genial"\n\nprint(f"Número: {numero}")\n\nprint(f"Mensaje: {mensaje}")\n```\n\nResultado en la terminal:\n\n¡Bienvenido a Python!\n\nEste es mi primer código\n\nNúmero: 10\n\nMensaje: Python es genial\n\n### Explicación línea por línea:\n\n1. print("¡Bienvenido a Python!") — Imprime un texto en la pantalla\n2. print("Este es mi primer código") — Imprime otra línea de texto\n3. numero = 10 — Crea una variable llamada numero y le asigna el valor 10\n4. mensaje = "Python es genial" — Crea una variable llamada mensaje con un texto\n5. print(f"Número: {numero}") — Imprime el valor de la variable numero dentro del texto\n6. print(f"Mensaje: {mensaje}") — Imprime el valor de la variable mensaje dentro del texto',
                color: const Color(0xFF1565C0),
                backgroundColor: const Color(0xFFF4F8FC),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5E7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFB8860B).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado en la terminal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Bienvenido a Python!\n\nEste es mi primer código\n\nNúmero: 10\n\nMensaje: Python es genial',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF6D4C41),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explicación línea por línea',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStep(
                      'print("¡Bienvenido a Python!")',
                      'Imprime un texto en la pantalla.',
                    ),
                    _buildStep(
                      'print("Este es mi primer código")',
                      'Imprime otra línea de texto.',
                    ),
                    _buildStep(
                      'numero = 10',
                      'Crea una variable llamada numero y le asigna el valor 10.',
                    ),
                    _buildStep(
                      'mensaje = "Python es genial"',
                      'Crea una variable llamada mensaje con un texto.',
                    ),
                    _buildStep(
                      'print(f"Número: {numero}")',
                      'Imprime el valor de la variable numero dentro del texto.',
                    ),
                    _buildStep(
                      'print(f"Mensaje: {mensaje}")',
                      'Imprime el valor de la variable mensaje dentro del texto.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Terminar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String code, String explanation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$code\n',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF0B4F6C),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: explanation,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2A67AB),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
