import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dónde está publicado el manual de uso.
///
/// El archivo es `web/manual.html`: Flutter lo copia tal cual a `build/web` y
/// Render lo sirve junto a la app. Esta dirección solo se usa fuera del
/// navegador, donde no hay una página desde la que resolver la ruta.
const String userManualPublicUrl =
    'https://code4all-web.onrender.com/manual.html';

/// La dirección del manual, abierta en la parte del rol de quien lo pide.
///
/// En la web se resuelve contra la página actual, como la guía del alfabeto:
/// así funciona igual en Render que con `flutter run` en local. El ancla
/// (`#estudiante`, `#docente`, `#director` o `#inicio`) es la que entiende el
/// manual para abrir directamente las guías de ese rol.
Uri userManualUri({String? role}) {
  final base = kIsWeb
      ? Uri.base.resolve('manual.html')
      : Uri.parse(userManualPublicUrl);
  return base.replace(fragment: _section(role));
}

String _section(String? role) {
  switch ((role ?? '').trim().toLowerCase()) {
    case 'estudiante':
      return 'estudiante';
    case 'docente':
      return 'docente';
    case 'director':
      return 'director';
    default:
      return 'inicio';
  }
}

/// Abre el manual en una pestaña nueva (web) o en el navegador (móvil).
///
/// Hay que llamarla directamente desde el toque, sin esperar nada antes: el
/// navegador solo deja abrir pestañas en respuesta a un gesto.
Future<bool> openUserManual({String? role}) async {
  try {
    return await launchUrl(
      userManualUri(role: role),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    return false;
  }
}
