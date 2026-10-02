import 'package:url_launcher/url_launcher.dart';

/// En la web los recursos de la app se sirven bajo `assets/`, así que la guía
/// se abre en una pestaña nueva y la muestra el visor de PDF del navegador.
Future<bool> openSignGuide(String asset) =>
    launchUrl(Uri.base.resolve('assets/$asset'), webOnlyWindowName: '_blank');
