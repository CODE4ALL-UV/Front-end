import 'package:flutter/material.dart';
import 'package:flutter_code4all/ui/core/ui/global_appbar_widget.dart';

class KnowledgeNuggetScreen extends StatelessWidget {
  final String actividad;

  const KnowledgeNuggetScreen({super.key, required this.actividad});

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
                      '💡 Cápsula de conocimiento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B4F6C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Python',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B4F6C).withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Escribe código claro, legible y fácil de mantener.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        color: Color(0xFF2A67AB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // _LecturaCard(
              //   title: 'El poder de los nombres descriptivos',
              //   body:
              //       'Cuando escribes código en Python, toma un momento extra para elegir nombres claros y descriptivos para tus variables y funciones. Python premia la claridad, y un buen nombre reduce el esfuerzo de entender el programa.',
              //   color: const Color(0xFF0B4F6C),
              //   backgroundColor: const Color(0xFFEAF7FF),
              // ),
              const SizedBox(height: 12),
              // _LecturaCard(
              //   title: 'Ejemplo',
              //   body:
              //       'Malo: x = 25\n\ny = "Juan"\n\ndef f(a, b):\n    return a + b\n\nBueno: edad_usuario = 25\n\nnombre_cliente = "Juan"\n\ndef sumar_numeros(numero1, numero2):\n    return numero1 + numero2',
              //   color: const Color(0xFF1565C0),
              //   backgroundColor: const Color(0xFFF4F8FC),
              // ),
              const SizedBox(height: 12),
              // _LecturaCard(
              //   title: '¿Por qué importa?',
              //   body:
              //       '• Tu código será más fácil de mantener\n• Otros desarrolladores lo entenderán rápido\n• Los errores serán más fáciles de encontrar\n• Python prioriza la legibilidad',
              //   color: const Color(0xFF1E88E5),
              //   backgroundColor: const Color(0xFFF8FBFF),
              // ),
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
                      'Bonus: La regla del Zen de Python',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Escribe import this en tu intérprete y descubrirás los principios que guían a Python. El primero dice: “Beautiful is better than ugly”.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: const Color(0xFF6D4C41).withValues(alpha: 0.95),
                      ),
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
}
