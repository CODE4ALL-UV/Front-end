import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';
import 'package:flutter_code4all/ui/users_management/widgets/password_widgets.dart';

/// Lo que se abre con el enlace del correo: elegir la contraseña nueva.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.onDone,
    this.api,
  });

  /// El token del enlace. Es la prueba de que quien está aquí recibió el
  /// correo.
  final String token;

  /// Volver al login.
  final VoidCallback onDone;

  /// Para las pruebas.
  final ApiService? api;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  late final ApiService _api = widget.api ?? ApiService();

  bool _saving = false;
  String? _error;
  String? _done;

  /// El enlace caducó o ya se usó: lo único útil es pedir otro.
  bool _linkUseless = false;

  @override
  void dispose() {
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  /// Las mismas reglas que el registro y que el servidor.
  String? _problem(String password, String repeat) {
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (utf8.encode(password).length > 72) {
      return 'La contraseña es demasiado larga: usa como máximo 72 caracteres.';
    }
    if (password != repeat) {
      return 'Las dos contraseñas no coinciden. Escríbelas otra vez.';
    }
    return null;
  }

  Future<void> _save() async {
    final password = _password.text;
    final problem = _problem(password, _repeat.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final reply = await _api.resetPassword(
        token: widget.token,
        password: password,
      );
      if (!mounted) return;
      setState(
        () => _done = reply.isNotEmpty
            ? reply
            : 'Listo. Ya puedes iniciar sesión con tu contraseña nueva.',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _linkUseless = e.statusCode == 400 && e.message.contains('enlace');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PasswordScreenFrame(
      appBar: const GlobalAppBarWidget(
        title: 'Contraseña nueva',
        showUserIcon: false,
      ),
      toolbar: const AccessibilityToolbar(),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Elige una contraseña nueva',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Al menos 6 caracteres. Desde ahora entrarás con ella.',
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (_done == null && !_linkUseless) ...[
          PasswordField(
            key: const ValueKey('reset-password'),
            controller: _password,
            label: 'Contraseña nueva',
          ),
          const SizedBox(height: 12),
          PasswordField(
            key: const ValueKey('reset-repeat'),
            controller: _repeat,
            label: 'Repite la contraseña nueva',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'GUARDAR CONTRASEÑA',
            busy: _saving,
            onPressed: _save,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          StatusMessage.error(_error!),
        ],
        if (_linkUseless) ...[
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'PEDIR UN ENLACE NUEVO',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ForgotPasswordScreen(api: widget.api),
              ),
            ),
          ),
        ],
        if (_done != null) ...[
          StatusMessage.success(_done!),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'IR A INICIAR SESIÓN',
            onPressed: widget.onDone,
          ),
        ],
        if (_done == null) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onDone,
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      ],
    );
  }
}
