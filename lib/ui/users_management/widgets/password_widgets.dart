import 'package:flutter/material.dart';

/// Azul de los botones de estas pantallas. Con letra blanca llega a 5,7:1;
/// el 1E88E5 del login se queda en 3,7:1, por debajo de lo que pide la WCAG
/// para texto normal.
const Color passwordScreensBlue = Color(0xFF1565C0);

/// Un mensaje que el lector de pantalla anuncia en cuanto aparece.
///
/// Un SnackBar desaparece solo y no siempre se anuncia; aquí el mensaje se
/// queda a la vista hasta que cambie, y quien no ve se entera al momento.
class StatusMessage extends StatelessWidget {
  const StatusMessage.error(this.text, {super.key}) : success = false;
  const StatusMessage.success(this.text, {super.key}) : success = true;

  final String text;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final foreground = success
        ? const Color(0xFF1B5E20)
        : const Color(0xFFB71C1C);
    final background = success
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: foreground, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: foreground,
              semanticLabel: success ? 'Hecho' : 'Error',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo de contraseña con botón para verla.
///
/// Poder ver lo escrito ayuda a quien tiene baja visión o temblor en las
/// manos a comprobar que no se equivocó, sobre todo al elegir una nueva.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: !_visible,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          tooltip: _visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    );
  }
}

/// El botón principal de estas pantallas, con su estado de «trabajando».
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: ElevatedButton(
          onPressed: busy ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: passwordScreensBlue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: passwordScreensBlue.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: busy
              ? Semantics(
                  label: 'Enviando',
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}

/// El esqueleto común: barra, herramientas de accesibilidad y el contenido
/// centrado con ancho máximo, como el login.
class PasswordScreenFrame extends StatelessWidget {
  const PasswordScreenFrame({
    super.key,
    required this.appBar,
    required this.toolbar,
    required this.children,
  });

  final PreferredSizeWidget appBar;
  final Widget toolbar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 480 ? 20.0 : 32.0;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          children: [
            toolbar,
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(padding, 24, padding, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
