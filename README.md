# Code4All · App (Flutter)

Code4All es un **curso de Python accesible** para personas con discapacidad
visual, auditiva o motriz, hecho en la **Universidad del Valle**. Este
repositorio es la aplicación: lo que ven y usan los estudiantes, los docentes y
la coordinación. Está hecha en **Flutter** y hoy se publica como página web en
<https://code4all-web.onrender.com>.

La idea es que cualquier persona pueda aprender a programar sin depender de
otra: quien no ve la pantalla puede escribir en Braille y oír todo lo que pasa;
quien no oye tiene subtítulos y señas en los videos; y quien tiene dificultades
para usar el teclado puede dictar con la voz.

El manual de uso, con guías paso a paso para cada rol, está en
<https://code4all-web.onrender.com/manual.html>.

## Autores

- **Joan Sebastian Saavedra**
- **Daniel Melendez Ramirez**

## Qué puede hacer cada persona

Al iniciar sesión, la app mira el rol que devuelve el servidor y lleva a cada
quien a su pantalla.

### Estudiante

- **Mis cursos.** Ve el Curso general (para todos) y los cursos de sus
  docentes. Se une a uno con el código de 6 letras y números que le da su
  docente, y puede salirse cuando quiera.
- **El curso.** Un mapa de 6 módulos, cada uno con 3 secciones. En cada sección
  sigue una ruta de actividades: lectura, cápsula de conocimiento («así no /
  así sí»), ejemplo de código explicado línea a línea, ejercicio, video, quiz,
  laboratorio y evaluación final (se aprueba con 60 %).
- **Su progreso.** Cada sección muestra cuántas actividades lleva. El avance se
  guarda por curso.
- **El botón «?»** para ajustar la app a su manera: tamaño de texto, colores,
  velocidad de la voz, lengua de señas, si prefiere lecturas, videos o audios,
  y su nivel (básico, medio o avanzado).

### Docente

- **Sus cursos.** Crea cursos (puede empezar copiando lo que ya está editado en
  el Curso general), los renombra, comparte el código, pide uno nuevo si el
  código se filtró y borra los que no tienen estudiantes.
- **Editar el temario.** Para cada sección, edita la lectura, la cápsula, el
  ejemplo, el ejercicio, los videos y las preguntas del quiz y de la
  evaluación. Puede ver la sección como la vería un estudiante y volver a la
  versión original cuando quiera. Lo que edita solo cambia **su** curso.
- **Estadísticas.** Aciertos por sección, las preguntas que más se fallan, las
  más lentas y las actividades completadas. Con «Generar informe» saca un
  resumen en texto listo para copiar.
- **Sus estudiantes.** Primero los que no han empezado y luego los que van más
  atrasados. Puede sacar a un estudiante del curso.

### Coordinación (rol `director`)

- **Estadísticas y estudiantes** de todos los cursos juntos o de uno en
  particular.
- **Docentes.** Ve qué editó cada docente y lo valora con una nota del 1 al 5 y
  un comentario.
- **Revisión del contenido.** Revisa las secciones que los docentes editaron,
  curso por curso, y las aprueba u observa con un comentario. La app avisa
  cuando una sección cambió después de revisarla.
- **El Curso general.** Es la única que lo puede editar.

## Accesibilidad

| Función | Qué hace | Dónde está |
|---|---|---|
| **Lectura en voz alta** | El botón «Escuchar» lee lo que hay en la pantalla. Se puede pausar y seguir donde iba. La velocidad se elige (lenta, media, rápida) y hay una opción de voz más pausada. En el celular usa `flutter_tts` y en la web la voz del navegador. | `lib/ui/core/ui/accessibility_reading_state_widget.dart` |
| **Dictado por voz** | Un micrófono en los campos del login para dictar el correo y la contraseña. Entiende «arroba», «punto», «guion» y «guion bajo», y suena un pitido al empezar y al terminar de escuchar. | `lib/data/services/voice_dictation_service.dart` |
| **Teclado Braille** | Toda la pantalla se vuelve una celda de 6 puntos. La letra se confirma sola y la app dice en voz alta qué se escribió. Con gestos se pone un espacio, se borra o se lee todo; con un teclado físico se usan F, D, S y J, K, L como en una máquina Perkins. Se abre tocando dos veces en cualquier parte del login, con el botón negro y amarillo o desde el menú de perfil. La traducción la hace el servidor ([accessibility](https://github.com/CODE4ALL-UV/accessibility-backend-service)). | `lib/ui/core/ui/braille_keyboard_screen.dart` |
| **6 modos de color** | Claro, oscuro, escala de grises y tres filtros para daltonismo (deuteranopía, protanopía y tritanopía). Las pruebas comprueban que todos cumplan el contraste de WCAG 2.1 (4,5:1 para texto). | `lib/ui/core/themes/app_theme.dart` |
| **Tamaño de texto** | De 90 % a 200 %, en toda la app. La app está probada con el texto al 200 % en pantallas desde 320 px de ancho. | `lib/ui/core/ui/accessibility_text_scale_widget.dart` |
| **Subtítulos** | Los videos muestran los subtítulos reales de YouTube, sincronizados y traducidos al español si el servidor lo tiene configurado. Si no hay, va mostrando la transcripción escrita. Debajo del video está la transcripción completa. | `lib/ui/python_course_content/widgets/section/section_video_screen.dart` |
| **Alfabeto manual (dactilología)** | Un panel que deletrea los subtítulos con una mano dibujada, un lector flotante y un teclado de dactilología que reemplaza al del sistema. | `lib/ui/core/ui/hand_sign_painter_widget.dart` |
| **Práctica con la cámara** | El estudiante hace una letra con la mano y la app le dice qué letra ve o qué dedo le falta estirar. El servidor encuentra los puntos de la mano con MediaPipe ([multimodal](https://github.com/CODE4ALL-UV/multimodal-interaction-backend-service)) y la app decide la letra. La primera vez ofrece una guía en PDF con todas las letras. | `lib/ui/python_course_content/widgets/section/sign_camera_screen.dart` |
| **Lector de pantalla** | Etiquetas en todos los controles y avisos (por ejemplo, el código del curso se lee letra por letra). | En toda la app |

Sobre las señas: es una **aproximación a la dactilología** dibujada en código,
no una interpretación en Lengua de Señas Colombiana, y no reemplaza a un
intérprete. La cámara no reconoce J, Z ni Ñ (se hacen con movimiento) y
confunde algunas letras parecidas, como H y U, o M, N, S y T; en esos casos
muestra las alternativas.

Las preferencias de pantalla (tema y tamaño de texto) se guardan en el
dispositivo y se mantienen aunque se cierre sesión.

## El curso

**El temario vive dentro de la app**, escrito en Dart en
`lib/data/course/module1_sections.dart` … `module6_sections.dart`. El servidor
solo guarda **lo que cada docente edita**, y la app lo pone encima del original.
Así, si el servidor no responde, el estudiante sigue viendo el curso.

| Módulo | Secciones |
|---|---|
| 1. Preparación | Conociendo Python · El entorno · El factor inglés |
| 2. Fundamentos de Python | Sintaxis · Números · Cadenas de texto |
| 3. Control de flujo | Estructuras de decisión · Bucles y estructuras iterativas · Clases |
| 4. Modularización y manejo de datos | Partes de una función · Variables locales y globales · Funciones recursivas (pendiente) |
| 5. Metodología para resolver problemas | Algoritmos · Análisis de problemas · Diseño en pseudocódigo |
| 6. Especialización y futuro | Diseño de interfaces · Componentes de una interfaz · Trabajo colaborativo (pendiente) |

Cada sección se identifica como `m2-s3` (módulo 2, sección 3). El modelo de
datos está en `lib/domain/models/python_course_content/course_catalog_models.dart`.

**El progreso** de cada estudiante se guarda en el dispositivo
(`lib/data/services/course_progress_store.dart`), aparte para cada curso. Además
la app le cuenta al servidor qué actividades terminó y, en los quices, si
acertó cada pregunta y cuánto tardó (nunca qué opción eligió). Con eso se
arman las estadísticas del docente. Si ese envío falla, el estudiante no se
entera y sigue normalmente.

## Cómo habla con el backend

La app solo conoce **una dirección**: la del
[API Gateway](https://github.com/CODE4ALL-UV/Back-end), que reparte cada
petición al microservicio que corresponde. La dirección se pone al compilar:

```bash
flutter run -d chrome --dart-define=BACKEND_URL=https://code4all-gateway.onrender.com
```

Sin `BACKEND_URL`, usa `http://127.0.0.1:8000` (o `http://10.0.2.2:8000` en el
emulador de Android). La dirección **no se lee del `.env`**: solo de
`--dart-define`. Todo pasa por `lib/data/services/api_service.dart`, y una
prueba (`test/no_hardcoded_backend_test.dart`) impide escribir la dirección del
servidor en cualquier otro archivo.

| Para qué | Rutas | Dónde las llama la app |
|---|---|---|
| Cuentas y sesión | `/api/auth/*`, `/api/user/upload-photo` | `lib/data/services/` y las pantallas de `lib/ui/users_management/` |
| Cursos | `/api/courses/*` | `lib/data/course/my_courses_store.dart` |
| Ediciones del temario | `/api/courses/{id}/overrides`, `/api/course/overrides` | `lib/data/course/course_content_store.dart` |
| Respuestas y estadísticas | `/api/analytics/*` | `lib/data/services/learning_analytics_service.dart`, `lib/data/course/course_analytics_store.dart` |
| Panel de la coordinación | `/api/oversight/*` | `lib/data/course/director_oversight_store.dart` |
| Braille | `/api/braille/translate` | `lib/data/services/braille_translation_service.dart` |
| Cámara de señas | `/api/signs/status`, `/api/signs/landmarks` | `lib/data/services/sign_recognition_service.dart` |
| Subtítulos | `/api/youtube/captions` | `lib/youtube_translator_player.dart` |

**Compatibilidad con el servidor anterior.** Mientras no se haga el corte del
monolito (`code4all-api`) al gateway, la app funciona con los dos:

- Si `/api/courses/mine` responde 404, entiende que el servidor no tiene cursos
  por docente y entra directo al curso único, como antes.
- Si Facebook o la recuperación de contraseña responden 404, avisa de que esa
  opción todavía no está disponible en el servidor.

## Inicio de sesión

- **Correo y contraseña.** El registro pide nombre, correo, contraseña (mínimo
  6 caracteres), tipo de discapacidad y rol. Para registrarse como docente o
  director hace falta el **código de invitación** que entrega la coordinación;
  esos códigos los define el servidor.
- **Google.** Con `google_sign_in`. Lee el Client ID del archivo `.env`
  (`GOOGLE_SERVER_CLIENT_ID` o `GOOGLE_CLIENT_ID`) y le manda el token de
  Google al servidor, que lo comprueba.
- **Facebook** (solo en la web). La app lleva a la persona a Facebook, recibe
  un código de vuelta y se lo pasa al servidor, que es el único que conoce la
  clave secreta. Necesita compilar con `--dart-define=FACEBOOK_APP_ID=...`;
  sin eso, el botón avisa de que no está disponible.
- **¿Olvidaste tu contraseña?** El servidor manda un correo con un enlace que
  abre la app en `/?restablecer=<token>`, donde se pone la contraseña nueva.

El token de sesión y los datos básicos se guardan con `flutter_secure_storage`
(`lib/data/services/auth_storage.dart`) y viajan en cada petición como
`Authorization: Bearer <token>`. Se puede cerrar sesión desde cualquier
pantalla.

## Cómo está organizado el código

```
lib/
├── main.dart                 punto de entrada
├── app.dart                  la raíz: qué pantalla se ve según el rol, tema y tamaño de texto
├── data/
│   ├── course/               el temario en Dart y los almacenes de cursos, ediciones,
│   │                         estadísticas y seguimiento de la coordinación
│   ├── models/               las peticiones y respuestas de registro e inicio de sesión
│   └── services/             API, sesión, Google, Facebook, analítica, progreso, Braille,
│                             cámara de señas y dictado
├── domain/models/
│   ├── python_course_content/   el modelo del curso (módulos, secciones, actividades)
│   └── sign_language/           el alfabeto manual y el clasificador de la cámara
├── ui/
│   ├── core/themes/          los 6 temas, el contraste y los tamaños de pantalla
│   ├── core/ui/              piezas compartidas: barra, menú de perfil, voz, teclados
│   ├── courses/              «Mis cursos» del estudiante y del docente
│   ├── python_course_content/   el recorrido del estudiante: módulos, secciones, actividades
│   ├── teacher/              el editor del docente, sus estadísticas y sus estudiantes
│   ├── director/             las pantallas de la coordinación
│   └── users_management/     login, registro y recuperación de contraseña
└── utils/                    utilidades del navegador (URL, sessionStorage)
```

El estado se maneja con **almacenes** (`ChangeNotifier`) de una sola instancia,
como `MyCoursesStore.instance` o `CourseContentStore.instance`, que las
pantallas escuchan. La navegación es sencilla: `app.dart` decide la pantalla
principal según el rol y las demás se abren con `Navigator.push`.

> Al comienzo el proyecto se planteó con MVVM y quedaron carpetas y archivos
> de esa estructura (`view_models/`, archivos `empty_*` y `unused_*`) que hoy
> no se usan. El código que funciona es el que se describe arriba.

## Requisitos

- **Flutter 3.44 o más reciente** (Dart 3.12), canal estable.
- Chrome para correr la versión web.
- Un backend corriendo: el [gateway](https://github.com/CODE4ALL-UV/Back-end)
  en local (por defecto en el puerto 8000) o uno publicado.

```bash
flutter doctor
```

## Correrlo

```bash
flutter pub get
flutter run -d chrome
```

Con un backend publicado y Facebook:

```bash
flutter run -d chrome --dart-define=BACKEND_URL=https://code4all-gateway.onrender.com --dart-define=FACEBOOK_APP_ID=<id-de-la-app>
```

Para compilar la versión web:

```bash
flutter build web --release --dart-define=BACKEND_URL=https://code4all-gateway.onrender.com
```

### Configuración

| Qué | Dónde | Para qué |
|---|---|---|
| `BACKEND_URL` | `--dart-define` | La dirección del backend. |
| `FACEBOOK_APP_ID` | `--dart-define` | El identificador de la app de Facebook (no es secreto). |
| `GOOGLE_SERVER_CLIENT_ID` / `GOOGLE_CLIENT_ID` | archivo `.env` | El Client ID de Google. En la web se usa como `clientId` y en el celular como `serverClientId`. |

El `.env` **tiene que existir**, porque está declarado como asset en
`pubspec.yaml`. Ojo: en la web los assets son públicos, así que ahí solo van
datos que no son secretos, como los Client ID.

Para que Google funcione en local, el origen (por ejemplo
`http://localhost:5000`) tiene que estar autorizado en Google Cloud Console.

## Despliegue en Render

`render.yaml` crea el sitio estático **`code4all-web`**:

1. Descarga Flutter estable.
2. Compila con `flutter build web --release`, pasando `BACKEND_URL` y
   `FACEBOOK_APP_ID` desde las variables del panel de Render.
3. Publica `build/web` y manda todas las rutas a `index.html`, como necesita
   una aplicación de una sola página.

Para cambiar de backend (por ejemplo, el día del corte al gateway) basta con
cambiar `BACKEND_URL` en el panel de Render y volver a desplegar. Los pasos
están en el README del [gateway](https://github.com/CODE4ALL-UV/Back-end).

## Manual de uso y guía del alfabeto

- **`web/manual.html`** es un manual interactivo independiente de Flutter
  (HTML, CSS y JavaScript). Tiene pestañas por rol (primeros pasos, estudiante,
  docente y coordinación) y cada guía muestra los pasos sobre una maqueta de la
  pantalla. Se puede buscar un paso, escucharlo en voz alta, y recuerda qué
  guías ya se completaron. La app lo abre desde el login y desde el menú de
  perfil (`lib/ui/core/ui/user_manual.dart`).
- **`assets/docs/guia_alfabeto_camara.pdf`** es la guía en PDF de las letras
  para la cámara. Se genera con el mismo dibujo de manos que usa la app:

  ```bash
  flutter test tool/sign_guide/generar_guia_test.dart
  ```

## Pruebas

```bash
flutter test
```

Hay 45 archivos de prueba en `test/`, con unas 395 pruebas. Cubren, entre
otras cosas:

- **Accesibilidad:** el teclado Braille, el dictado por voz, pausar y seguir
  la lectura, el tamaño de texto, el menú «?» y que los 6 temas cumplan el
  contraste de WCAG.
- **Señas:** el clasificador de letras, la cámara, el dictado con señas y el
  teclado de dactilología.
- **Sesión:** registro con código de invitación, Facebook, recuperación de
  contraseña y cerrar sesión desde cualquier pantalla.
- **Backend:** la dirección del servidor, las ediciones del temario y los
  cursos (incluido el 404 del servidor anterior).
- **Curso:** que el contenido de los módulos esté completo y bien formado, y
  el cálculo del progreso.
- **Docente y coordinación:** el editor, las estadísticas, el informe y las
  pantallas de revisión.
- **Pantallas de todos los tamaños:** `responsive_matrix_test.dart` recorre la
  app en celular, tablet y computador, en vertical y horizontal, también con
  el texto al 200 %. Con `--dart-define=SHOTS_DIR=<carpeta>` guarda capturas.

En GitHub, cada push o pull request a `main` corre `flutter test --coverage` y
sube la cobertura a Codecov (`.github/workflows/flutter-coverage.yml`).

## Cosas a tener en cuenta

- **Contenido pendiente:** el módulo 6 completo y la sección «Funciones
  recursivas» del módulo 4 todavía no tienen material.
- **El laboratorio no ejecuta Python de verdad.** Es una consola sencilla
  escrita en Dart que entiende `print(...)`, asignaciones y operaciones
  básicas, y compara la salida con la esperada.
- En la pantalla de «Configuración» del menú «?», hoy solo funciona el ajuste de
  tamaño de texto; los demás se manejan desde las otras opciones del mismo
  menú.
- Facebook solo funciona en la web, y la cámara no funciona en Linux de
  escritorio.
- Los identificadores de Android e iOS siguen siendo los de la plantilla
  (`com.example.flutter_code4all`).
- Al cerrar sesión se borra el progreso guardado en el dispositivo (las
  respuestas que ya llegaron al servidor no se pierden).

## Los repositorios de Code4All

| Parte | Repositorio |
|---|---|
| **App (Flutter)** | **este repositorio** |
| API Gateway | [Back-end](https://github.com/CODE4ALL-UV/Back-end) |
| Gestión de usuarios | [user-management-backend-service](https://github.com/CODE4ALL-UV/user-management-backend-service) |
| Curso y contenidos de Python | [course-content-backend-service](https://github.com/CODE4ALL-UV/course-content-backend-service) |
| Ejercicios y evaluación | [assessment-backend-service](https://github.com/CODE4ALL-UV/assessment-backend-service) |
| Progreso y seguimiento | [progress-tracking-backend-service](https://github.com/CODE4ALL-UV/progress-tracking-backend-service) |
| Accesibilidad y adaptación | [accessibility-backend-service](https://github.com/CODE4ALL-UV/accessibility-backend-service) |
| Interacción multimodal | [multimodal-interaction-backend-service](https://github.com/CODE4ALL-UV/multimodal-interaction-backend-service) |
| Infraestructura y dispositivos | [device-management-backend-service](https://github.com/CODE4ALL-UV/device-management-backend-service) |
| Capa de datos compartida (Neon) | [neon-storage-backend-service](https://github.com/CODE4ALL-UV/neon-storage-backend-service) |
