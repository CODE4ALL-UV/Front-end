import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) async {
  final Uri uri = Uri.parse(url);
  // Funciona en Web (abre pestaña), Android/iOS (abre navegador externo)
  if (await canLaunchUrl(uri)) {
    return await launchUrl(
      uri, 
      mode: LaunchMode.externalApplication, // Garantiza abrir en pestaña o app externa
    );
  }
  return false;
}

/* OJO CODIGO VIEJO DEPRECADO, NO USAR
import 'dart:html' as html;

Future<bool> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
*/