class StaticMessages {
  StaticMessages._();
  // Aquí centralizamos todos los textos estáticos de la aplicación para facilitar su mantenimiento y futuras traducciones
  // Mensajes de Accesibilidad para los lectores de pantalla

  // Widget Social Buttons for Register and Login Screens
  static const String googleButtonLabel = 'Iniciar sesión con Google';
  static const String googleButtonHint =
      'Doble toque para autenticarse con su cuenta de Google';

  static const String facebookButtonLabel = 'Iniciar sesión con Facebook';
  static const String facebookButtonHint =
      'Doble toque para autenticarse con su cuenta de Facebook';

  // Widget AccesibilityFab
  static const String accessibilityButtonLabel =
      'Botón de asistencia. Presione para abrir el menú de soporte en Lengua de Señas o ajustes visuales'; //Cambiar modo visual de la aplicación

  static const String accessibilityButtonHint =
      'Doble toque para desplegar las opciones de accesibilidad'; //Alterna entre modo claro, modo oscuro y contrastes de daltonismo.

  static const String navSettingsLabel =
      'Configuración del sistema y accesibilidad';
  static const String navSettingsHint =
      'Doble toque para abrir los ajustes de visualización';

  // Widget MultimodalFooterBar
  static const String navPreviousLabel = 'Ir a la lección anterior';
  static const String navPreviousHint = 'Doble toque para regresar';

  static const String navPlayLabel =
      'Reproducir contenido multimedia del curso';
  static const String navStopLabel = 'Pausar asistente';
  static const String navPlayHint =
      'Doble toque para iniciar o pausar el audio explicativo';
  static const String navStopHint = 'Detener la lectura de la pantalla';

  // Pausar guarda el punto donde va la voz; reanudar sigue desde ahí. Se
  // dicen por separado para que quien escucha sepa que no va a volver a
  // empezar desde el principio.
  static const String navPauseLabel = 'Pausar asistente';
  static const String navPauseHint =
      'Doble toque para pausar la lectura donde va';
  static const String navResumeLabel = 'Reanudar asistente';
  static const String navResumeHint =
      'Doble toque para seguir leyendo desde donde se pausó';

  static const String navNextLabel = 'Ir a la siguiente lección';
  static const String navNextHint = 'Doble toque para avanzar';
}
