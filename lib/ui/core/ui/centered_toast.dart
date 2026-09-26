import 'dart:async';

import 'package:flutter/material.dart';

/// Un aviso en el centro de la pantalla que se va solo.
///
/// Sustituye al `SnackBar` para confirmar los ajustes del menú de ayuda. El
/// SnackBar sale abajo, que es justo donde están los botones de ese menú, así
/// que el aviso quedaba tapado por ellos y no se leía: se cambiaba un ajuste y
/// parecía que no había pasado nada.
///
/// Va por encima de todo lo demás —incluido el menú— porque se inserta en la
/// capa de overlay después que él. No intercepta toques: se puede seguir
/// usando la pantalla mientras está puesto.
///
/// No se anuncia por su cuenta al lector de pantalla. Quien lo muestra ya
/// llama a `announceForAccessibility`, y anunciarlo dos veces haría que se
/// oyera repetido.
abstract final class CenteredToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  /// Cuánto se queda en pantalla.
  ///
  /// Se calcula con el largo del texto: un mensaje de dos líneas necesita más
  /// tiempo que uno de cuatro palabras, y un tiempo fijo obligaría a elegir
  /// entre dejar corto al largo o eterno al corto.
  static Duration _durationFor(String message) {
    final words = message.trim().split(RegExp(r'\s+')).length;
    final millis = 1600 + words * 220;
    return Duration(milliseconds: millis.clamp(2000, 6000));
  }

  static void show(BuildContext context, String message) {
    final text = message.trim();
    if (text.isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Si ya había uno puesto se retira: dos avisos apilados en el centro se
    // taparían entre ellos, que es el problema que veníamos a resolver.
    _dismiss();

    final entry = OverlayEntry(
      builder: (context) => _ToastBody(message: text),
    );

    _current = entry;
    overlay.insert(entry);

    _timer = Timer(_durationFor(text), _dismiss);
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }

  /// Para las pruebas y para cuando se cierra la pantalla que lo mostró.
  @visibleForTesting
  static void dismissNow() => _dismiss();
}

class _ToastBody extends StatefulWidget {
  const _ToastBody({required this.message});

  final String message;

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 180),
    vsync: this,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: _controller,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: (width - 48).clamp(200.0, 420.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B1B44),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
