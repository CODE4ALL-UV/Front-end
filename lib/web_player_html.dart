// Web implementation that embeds a simple browser-like frame inside the app.
import 'dart:html' as html;
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
              onPressed: () {
                html.window.open(
                  'https://www.youtube.com/watch?v=$id',
                  '_blank',
                );
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
