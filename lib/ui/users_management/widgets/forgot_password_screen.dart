import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/users_management/widgets/password_widgets.dart';

/// «¿Olvidaste tu contraseña?»: pide el correo y manda el enlace.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = '', this.api});

  /// Lo que ya estuviera escrito en el login, para no tener que repetirlo.
  final String initialEmail;

  /// Para las pruebas.
  final ApiService? api;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  late final ApiService _api = widget.api ?? ApiService();

  bool _sending = false;
  String? _error;
  String? _sent;

  static final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Escribe tu correo electrónico.');
      return;
    }
    if (!_emailShape.hasMatch(email)) {
      setState(
        () => _error =
            'Ese correo no parece completo. Revisa que tenga @ y un dominio, '
            'por ejemplo ana@gmail.com.',
      );
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final reply = await _api.requestPasswordReset(email);
      if (!mounted) return;
      setState(
        () => _sent = reply.isNotEmpty
            ? reply
            : 'Si hay una cuenta con ese correo, te enviamos un enlace para '
                  'cambiar la contraseña.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PasswordScreenFrame(
      appBar: const GlobalAppBarWidget(
        title: 'Recuperar contraseña',
        showUserIcon: false,
      ),
      toolbar: const AccessibilityToolbar(),
      children: [
        Semantics(
          header: true,
          child: Text(
            '¿Olvidaste tu contraseña?',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Escribe el correo con el que te registraste. Te enviaremos un '
          'enlace para elegir una contraseña nueva.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (_sent == null) ...[
          TextField(
            key: const ValueKey('forgot-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'ENVIAR ENLACE',
            busy: _sending,
            onPressed: _send,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          StatusMessage.error(_error!),
        ],
        if (_sent != null) ...[
          StatusMessage.success(
            '$_sent El enlace sirve una sola vez y caduca en 30 minutos.',
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'VOLVER AL INICIO DE SESIÓN',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _sending
                ? null
                : () => setState(() {
                    _sent = null;
                    _error = null;
                  }),
            child: const Text('No me llegó: enviarlo otra vez'),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '¿Entras con Google o con Facebook? Entonces no necesitas '
          'contraseña: vuelve y usa el mismo botón de siempre.',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}
