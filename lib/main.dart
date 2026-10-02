import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/launch_link.dart';

Future<void> main() async {
  // Antes que nada: el enlace del correo para cambiar la contraseña y la
  // vuelta de Facebook llegan en la dirección. Se guardan y se limpia la
  // barra antes de que Flutter la lea como si fuera una ruta.
  LaunchLink.capture();
  await dotenv.load(fileName: '.env');
  runApp(const App());
}
