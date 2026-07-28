import 'package:url_launcher/url_launcher.dart';

Future<bool> openExternalUrl(String url) {
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
