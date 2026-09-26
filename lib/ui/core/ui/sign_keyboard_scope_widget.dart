import 'package:flutter/material.dart';

import 'sign_keyboard_settings.dart';
import 'sign_keyboard_widget.dart';

/// Envuelve una pantalla para que sus campos puedan escribirse con el teclado
/// de dactilología.
///
/// La pantalla sigue montando sus `TextField` como siempre; lo único que
/// cambia es que les pasa un [SignKeyboardField] alrededor. Cuando la
/// preferencia está apagada —que es lo normal— esto no hace absolutamente
/// nada y se escribe con el teclado del sistema.
///
/// El teclado se dibuja aquí, al fondo de la pantalla, y no dentro de cada
/// campo: así aparece completo aunque el campo esté dentro de un formulario
/// estrecho, y sólo hay uno abierto a la vez.
class SignKeyboardScope extends StatefulWidget {
  const SignKeyboardScope({super.key, required this.child});

  final Widget child;

  static _SignKeyboardScopeState? _of(BuildContext context) =>
      context.findAncestorStateOfType<_SignKeyboardScopeState>();

  @override
  State<SignKeyboardScope> createState() => _SignKeyboardScopeState();
}

class _SignKeyboardScopeState extends State<SignKeyboardScope> {
  final SignKeyboardSettings _settings = SignKeyboardSettings.instance;
  TextEditingController? _active;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _settings.ensureLoaded();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (!mounted) return;
    // Al apagarlo se cierra lo que hubiera abierto: dejarlo puesto sería
    // ignorar lo que la persona acaba de pedir.
    setState(() {
      if (!_settings.isEnabled) _active = null;
    });
  }

  void _open(TextEditingController controller) {
    if (!_settings.isEnabled) return;
    setState(() => _active = controller);
  }

  void _close() {
    if (_active == null) return;
    setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;

    return Column(
      children: [
        Expanded(child: widget.child),
        if (active != null)
          SignKeyboard(
            controller: active,
            onDone: _close,
            // Como mucho la mitad de la pantalla: por encima de eso no
            // quedaría a la vista lo que se está escribiendo, que es lo que
            // hay que poder mirar mientras se escribe.
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
      ],
    );
  }
}

/// Un campo de texto que, si la preferencia está encendida, se escribe con el
/// teclado de dactilología en lugar del teclado del sistema.
///
/// Se pone alrededor del `TextField` que ya hubiera, sin tocarlo:
///
/// ```dart
/// SignKeyboardField(
///   controller: _emailController,
///   builder: (context, focusNode, readOnly) => TextField(
///     controller: _emailController,
///     focusNode: focusNode,
///     readOnly: readOnly,
///     showCursor: true,
///   ),
/// )
/// ```
///
/// `readOnly` es lo que impide que salga el teclado del sistema, y
/// `showCursor: true` lo que evita el efecto secundario de que un campo de
/// sólo lectura deje de enseñar dónde se está escribiendo.
class SignKeyboardField extends StatefulWidget {
  const SignKeyboardField({
    super.key,
    required this.controller,
    required this.builder,
  });

  final TextEditingController controller;

  /// Construye el campo. Recibe el foco que debe usar y si tiene que estar en
  /// sólo lectura para que no salte el teclado del sistema.
  final Widget Function(
    BuildContext context,
    FocusNode focusNode,
    bool readOnly,
  )
  builder;

  @override
  State<SignKeyboardField> createState() => _SignKeyboardFieldState();
}

class _SignKeyboardFieldState extends State<SignKeyboardField> {
  final FocusNode _focusNode = FocusNode();
  final SignKeyboardSettings _settings = SignKeyboardSettings.instance;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _settings.addListener(_onSettingsChanged);
    _settings.ensureLoaded();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _settings.removeListener(_onSettingsChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (!_settings.isEnabled) return;
    if (_focusNode.hasFocus) {
      SignKeyboardScope._of(context)?._open(widget.controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _settings.isEnabled;

    return GestureDetector(
      // Con el campo en sólo lectura hay teclados y navegadores que no dan
      // el foco al tocarlo. Pedirlo a mano hace que un toque baste.
      onTap: enabled ? () => _focusNode.requestFocus() : null,
      child: widget.builder(context, _focusNode, enabled),
    );
  }
}
