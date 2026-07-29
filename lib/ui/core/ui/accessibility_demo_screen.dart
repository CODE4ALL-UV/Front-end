import 'package:flutter/material.dart';

class AccessibilityDemoScreen extends StatefulWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  State<AccessibilityDemoScreen> createState() =>
      _AccessibilityDemoScreenState();
}

class _AccessibilityDemoScreenState extends State<AccessibilityDemoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo de accesibilidad')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Mensaje introductorio',
                hint: 'Aquí verás ejemplos prácticos para TalkBack',
                child: const Text(
                  'Estos elementos están preparados para que TalkBack pueda leerlos claramente.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                image: true,
                label: 'Logo de Code4All',
                hint: 'Imagen de ejemplo con descripción accesible',
                child: Center(
                  child: Image.asset(
                    'assets/images/logo-flutter.png',
                    semanticLabel: 'Logo de Code4All',
                    height: 140,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: 'Texto de ayuda',
                hint: 'Explica el propósito de esta pantalla',
                child: const Text(
                  'Los botones, imágenes y formularios tienen etiquetas y pistas adicionales para mejorar la experiencia.',
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'Botón de ayuda',
                hint: 'Abre una guía adicional de accesibilidad',
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Guía de accesibilidad abierta'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Ayuda'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Formulario accesible',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Campo de nombre',
                hint: 'Escribe tu nombre completo',
                textField: true,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Campo de correo electrónico',
                hint: 'Escribe tu correo para recibir información',
                textField: true,
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Aceptar términos',
                hint: 'Activa esta opción para continuar',
                child: CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() => _acceptedTerms = value ?? false);
                  },
                  title: const Text('Acepto los términos'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Enviar formulario',
                hint: 'Guarda la información del formulario',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Formulario listo para ${_nameController.text.isEmpty ? 'enviar' : _nameController.text}',
                          ),
                        ),
                      );
                    },
                    child: const Text('Enviar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
