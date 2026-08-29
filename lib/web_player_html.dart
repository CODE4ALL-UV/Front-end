// Web implementation that embeds a simple browser-like frame inside the app.
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

Widget youtubeIframe(String id) {
  final embedUrl = 'https://www.youtube.com/embed/$id?rel=0&playsinline=1';

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'La reproducción embebida no está disponible en esta configuración web.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final Uri url = Uri.parse('https://www.youtube.com/watch?v=$id');
                
                // Abre el enlace en una nueva pestaña (Web) o en la app de YouTube/Navegador (Móvil)
                if (await canLaunchUrl(url)) {
                  await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              child: const Text('Abrir video en YouTube'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este bloque mantiene la pantalla de la app abierta y evita la redirección.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
