import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_code4all/ui/core/themes/app_theme.dart';

import 'sign_guide_opener_io.dart'
    if (dart.library.js_interop) 'sign_guide_opener_web.dart'
    as opener;

/// La guía en PDF: cómo hacer cada letra para que la cámara la reconozca.
///
/// Se genera con `flutter test tool/sign_guide/generar_guia_test.dart` a
/// partir de la misma tabla que usa el reconocimiento.
const String signGuideAsset = 'assets/docs/guia_alfabeto_camara.pdf';

/// Abre la guía: en la web, en una pestaña nueva con el visor del navegador;
/// en el móvil, con el visor de PDF del sistema.
///
/// Hay que llamarla directamente desde el toque de un botón, sin esperar
/// nada antes: el navegador solo deja abrir pestañas en respuesta a un gesto.
Future<bool> openSignGuide() => opener.openSignGuide(signGuideAsset);

/// Recuerda en el dispositivo si ya se ofreció la guía.
///
/// Se ofrece una vez, al entrar por primera vez a la cámara. Después queda el
/// botón: avisar cada vez sería una ventana más que cerrar antes de empezar.
class SignGuidePrompt {
  const SignGuidePrompt();

  static const _key = 'sign_guide_offered';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Si toca ofrecerla. Si el almacenamiento no responde (modo privado del
  /// navegador, pruebas), no se insiste: el botón sigue a la vista.
  Future<bool> shouldOffer() async {
    try {
      return await _storage.read(key: _key) == null;
    } catch (_) {
      return false;
    }
  }

  Future<void> markOffered() async {
    try {
      await _storage.write(key: _key, value: '1');
    } catch (_) {}
  }
}

/// El aviso de la primera vez.
Future<void> showSignGuideDialog(
  BuildContext context, {
  Future<bool> Function() open = openSignGuide,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.menu_book_outlined),
      title: const Text('Antes de empezar'),
      content: const Text(
        'Hay una guía en PDF con cómo hacer cada letra para que la cámara '
        'la reconozca: dedo a dedo, con un dibujo de cada una y qué corregir '
        'si lee otra.\n\nLa tienes siempre en el botón «Guía del alfabeto».',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Ahora no'),
        ),
        FilledButton.icon(
          onPressed: () {
            // Primero se abre (es el gesto del usuario), después se cierra.
            open();
            Navigator.of(dialogContext).pop();
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Abrir la guía'),
        ),
      ],
    ),
  );
}

/// El botón de la guía, siempre a la vista en la pantalla de la cámara.
class SignGuideButton extends StatelessWidget {
  const SignGuideButton({super.key, this.open = openSignGuide});

  final Future<bool> Function() open;

  @override
  Widget build(BuildContext context) {
    final accent = AppContrast.readableOn(
      context.messageColors.infoForeground,
      context.colorScheme.surface,
      AppContrast.text,
    );

    return Semantics(
      hint: 'Abre un PDF con cómo hacer cada letra para la cámara',
      child: OutlinedButton.icon(
        onPressed: () async {
          final opened = await open();
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo abrir la guía.')),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          minimumSize: const Size(0, AppMetrics.minTapTarget),
        ),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Guía del alfabeto (PDF)'),
      ),
    );
  }
}
