import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dónde está publicada la política de privacidad y tratamiento de datos.
///
/// El archivo es `web/privacidad.html`: Flutter lo copia tal cual a
/// `build/web` y Render lo sirve junto a la app, igual que el manual. Esta
/// dirección solo se usa fuera del navegador, donde no hay una página desde la
/// que resolver la ruta.
const String privacyPolicyPublicUrl =
    'https://code4all-web.onrender.com/privacidad.html';

/// La dirección de la política. En la web se resuelve contra la página
/// actual: así funciona igual en Render que con `flutter run` en local.
Uri privacyPolicyUri() => kIsWeb
    ? Uri.base.resolve('privacidad.html')
    : Uri.parse(privacyPolicyPublicUrl);

/// Abre la política en una pestaña nueva (web) o en el navegador (móvil).
///
/// Hay que llamarla directamente desde el toque, sin esperar nada antes: el
/// navegador solo deja abrir pestañas en respuesta a un gesto.
Future<bool> openPrivacyPolicy() async {
  try {
    return await launchUrl(
      privacyPolicyUri(),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}
