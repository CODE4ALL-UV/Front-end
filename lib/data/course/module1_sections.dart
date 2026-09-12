import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 1. Preparación — Conociendo Python, El entorno y El factor inglés.
const CourseModule module1 = CourseModule(
  number: 1,
  title: 'Preparación',
  sections: [_seccion1, _seccion2, _seccion3],
);

// ---------------------------------------------------------------------------
// Capítulo 1: Conociendo Python
// ---------------------------------------------------------------------------

const CourseSection _seccion1 = CourseSection(
  id: 'm1-s1',
  shortTitle: 'Conociendo\nPython',
  videos: [
    SectionVideo(
      title: 'Introducción a Python (parte 1)',
      youtubeId: 'Sy6XDw_vV7E',
      duration: '19:10',
      description:
          'Clase 2.2 del curso Fundamentos de programación imperativa.',
      transcript:
          'El video presenta Python como lenguaje interpretado y de '
          'sintaxis clara. Muestra dónde descargarlo, cómo comprobar la '
          'instalación escribiendo python --version en la terminal, y '
          'cómo escribir las primeras instrucciones en el intérprete '
          'interactivo: imprimir texto con print, hacer operaciones '
          'aritméticas y guardar valores en variables. Todo lo que '
          'explica está recogido en la lectura de esta sección.',
    ),
  ],
  moduleNumber: 1,
  number: 1,
  title: 'Conociendo Python',
  summary:
      'Por qué Python es hoy el lenguaje más influyente, cómo instalarlo y '
      'cómo dar tus primeros pasos con el intérprete.',
  objectives: [
    'Explicar por qué Python es relevante en la industria actual.',
    'Descargar e instalar Python en Windows, macOS o Linux.',
    'Preparar el entorno con pip y entornos virtuales.',
    'Usar el intérprete interactivo y ejecutar tu primer archivo .py',
  ],
  reading: SectionReading(
    title: 'Python: el lenguaje que transforma la tecnología',
    intro:
        'Esta lectura recorre por qué Python importa, cómo instalarlo y cómo '
        'usar el intérprete para experimentar sin miedo a equivocarte.',
    pages: [
      ReadingPage(
        title: 'Relevancia del lenguaje Python',
        summary:
            'Python democratiza la programación: su sintaxis clara permite que '
            'principiantes y expertos creen soluciones poderosas.',
        blocks: [
          ReadingBlock.paragraph(
            title: '¿Por qué Python es tan relevante?',
            body:
                'Python se ha convertido en el lenguaje de programación más '
                'influyente del siglo XXI. Su importancia está en que abre la '
                'programación a todo el mundo: con una sintaxis clara y '
                'elegante, tanto quien empieza como quien ya tiene años de '
                'experiencia pueden construir soluciones potentes.',
          ),
          ReadingBlock.bullets(
            title: 'Su versatilidad es incomparable',
            body:
                'Python está presente en casi todas las áreas de la tecnología.',
            items: [
              'Ciencia de datos e inteligencia artificial.',
              'Desarrollo web y servicios en la nube.',
              'Automatización de tareas repetitivas.',
              'Empresas como Google, Netflix, Facebook y SpaceX lo usan en sus operaciones más críticas.',
            ],
          ),
          ReadingBlock.callout(
            title: 'La legibilidad es una decisión de diseño',
            body:
                'Python prioriza que el código se lea bien. Eso hace que sea '
                'más fácil de mantener, de entender y de trabajar en equipo. '
                'En un mundo donde la velocidad de desarrollo importa, puedes '
                'crear prototipos rápido y llevarlos a producción sin '
                'sacrificar calidad.',
            tone: CalloutTone.info,
          ),
        ],
      ),
      ReadingPage(
        title: 'Descarga y puesta en marcha',
        summary:
            'Obtener Python es simple: se descarga desde el sitio oficial y hay '
            'instalador para Windows, macOS y Linux.',
        blocks: [
          ReadingBlock.paragraph(
            title: 'Dónde conseguirlo',
            body:
                'Visita el sitio oficial python.org y descarga la versión más '
                'reciente. El instalador está disponible para Windows, macOS y '
                'Linux.',
          ),
          ReadingBlock.steps(
            title: 'Instalación según tu sistema',
            items: [
              'Windows: ejecuta el instalador descargado. Un paso crucial es marcar la opción "Add Python to PATH" al inicio. Esto permite ejecutar Python desde cualquier línea de comandos sin escribir rutas completas.',
              'macOS: aunque macOS incluye Python, normalmente es una versión antigua. Descarga la versión más reciente desde python.org o usa Homebrew con el comando brew install python3.',
              'Linux: la mayoría de distribuciones ya incluyen Python. Para la versión más nueva usa tu gestor de paquetes; en Ubuntu sería sudo apt-get install python3.',
            ],
          ),
          ReadingBlock.callout(
            title: 'No olvides el PATH',
            body:
                'Si al escribir "python" en la terminal aparece un error, casi '
                'siempre es porque no se marcó "Add Python to PATH" durante la '
                'instalación. Puedes reinstalar y marcar esa casilla.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
      ReadingPage(
        title: 'Preparando la versión instalada',
        summary:
            'Verifica la instalación, actualiza pip y crea un entorno virtual '
            'para cada proyecto.',
        blocks: [
          ReadingBlock.code(
            title: 'Verifica la instalación',
            code: 'python --version',
            body:
                'Abre tu terminal y escribe este comando. Deberías ver algo '
                'como "Python 3.11.0" o superior.',
            codeCaption:
                'Comando python, espacio, dos guiones, version. Muestra la '
                'versión instalada.',
          ),
          ReadingBlock.code(
            title: 'Actualiza pip',
            code: 'python -m pip install --upgrade pip',
            body:
                'Pip es el gestor de paquetes de Python. Te permite instalar '
                'librerías externas que extienden sus capacidades. Sin pip '
                'estarías limitado solo a lo que trae Python de fábrica.',
            codeCaption:
                'Comando python, guion m, pip, install, dos guiones upgrade, '
                'pip. Actualiza el gestor de paquetes.',
          ),
          ReadingBlock.code(
            title: 'Crea un entorno virtual',
            code: 'python -m venv nombre_de_tu_proyecto',
            body:
                'Los entornos virtuales aíslan las dependencias de cada '
                'proyecto y evitan conflictos entre versiones de librerías.',
            codeCaption:
                'Comando python, guion m, venv, seguido del nombre de tu '
                'proyecto. Crea una carpeta con un Python aislado.',
          ),
          ReadingBlock.bullets(
            title: 'Activa el entorno',
            items: [
              r'En Windows: nombre_de_tu_proyecto\Scripts\activate',
              'En macOS o Linux: source nombre_de_tu_proyecto/bin/activate',
              'Verás el nombre del entorno en tu terminal: eso indica que está activo.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Usando el intérprete de Python',
        summary:
            'El intérprete es un entorno interactivo donde escribes código y '
            'ves el resultado al instante.',
        blocks: [
          ReadingBlock.paragraph(
            title: 'Tu mejor aliado para aprender',
            body:
                'Escribe "python" en la terminal y verás el prompt de tres '
                'signos mayor que esperando tu entrada. Ya estás en modo '
                'interactivo: es perfecto para experimentar, probar ideas y '
                'entender cómo funcionan las cosas sin crear un archivo.',
          ),
          ReadingBlock.code(
            title: 'Prueba comandos simples',
            code:
                '>>> print("¡Hola, Python!")\n'
                '¡Hola, Python!\n\n'
                '>>> 2 + 2\n'
                '4\n\n'
                '>>> nombre = "María"\n'
                '>>> print(f"Bienvenida, {nombre}")\n'
                'Bienvenida, María',
            codeCaption:
                'En el intérprete se imprime el saludo Hola Python, luego se '
                'suma dos más dos y responde cuatro, y por último se guarda el '
                'nombre María en una variable y se saluda usando esa variable.',
          ),
          ReadingBlock.steps(
            title: 'De la consola al archivo',
            items: [
              'Sal del intérprete escribiendo exit() y presionando Enter.',
              'Crea un archivo con extensión .py, por ejemplo hola.py',
              'Escribe tu código dentro del archivo y guárdalo.',
              'Ejecútalo desde la terminal con: python hola.py',
            ],
          ),
          ReadingBlock.callout(
            title: 'El flujo siempre es el mismo',
            body:
                'Escribir código, guardar en un archivo, ejecutar. Python se '
                'encarga del resto interpretando línea por línea.',
            tone: CalloutTone.success,
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          '¿Cuál es la razón principal por la cual Python se ha convertido en '
          'el lenguaje de programación más relevante del siglo XXI?',
      options: [
        'Porque fue el primer lenguaje de programación creado',
        'Porque tiene una sintaxis clara y elegante que democratiza la programación, permitiendo que principiantes y expertos creen soluciones poderosas',
        'Porque es el único lenguaje compatible con Windows',
        'Porque no requiere descargar ni instalar nada',
      ],
      correctIndex: 1,
      explanation:
          'La clave de Python es su accesibilidad: una sintaxis legible que no '
          'sacrifica potencia.',
    ),
    QuizQuestion(
      prompt: '¿Para qué se utiliza pip en Python?',
      options: [
        'Para escribir código más rápido',
        'Para gestionar e instalar librerías externas',
        'Para cambiar el color de la terminal',
        'Para ejecutar juegos',
      ],
      correctIndex: 1,
      explanation:
          'Pip es el gestor de paquetes: con él instalas y actualizas las '
          'librerías que extienden Python.',
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt:
          '¿Cuáles son las tres aplicaciones principales de Python mencionadas '
          'en la lectura?',
      options: [
        'Ciencia de datos, inteligencia artificial y desarrollo web',
        'Solo videojuegos',
        'Diseño gráfico exclusivamente',
        'Únicamente automatización de hojas de cálculo',
      ],
      correctIndex: 0,
      explanation:
          'Son las tres áreas que la lectura destaca como territorio natural de '
          'Python.',
    ),
    QuizQuestion(
      prompt:
          '¿Qué comando utilizas para verificar que Python está correctamente '
          'instalado?',
      options: [
        'python --version',
        'python install',
        'pip --check',
        'run python',
      ],
      correctIndex: 0,
      explanation:
          'python --version muestra la versión instalada y confirma que el '
          'sistema encuentra Python.',
    ),
    QuizQuestion(
      prompt:
          'Verdadero o falso: "Los entornos virtuales en Python son '
          'innecesarios para proyectos pequeños".',
      options: ['Verdadero', 'Falso'],
      correctIndex: 1,
      explanation:
          'Falso. Son fundamentales incluso en proyectos pequeños porque evitan '
          'conflictos de dependencias.',
    ),
    QuizQuestion(
      prompt: '¿Cuál es la función de pip?',
      options: [
        'Compilar código Python',
        'Gestionar e instalar librerías externas',
        'Crear archivos ejecutables',
        'Cambiar la versión de Python',
      ],
      correctIndex: 1,
      explanation: 'Pip administra los paquetes y librerías del ecosistema.',
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: Python',
    headline: 'El poder de los nombres descriptivos',
    intro:
        'Cuando escribas código en Python, tómate un momento extra para elegir '
        'nombres claros para tus variables y funciones. Python no solo es fácil '
        'de leer: también premia la claridad.',
    badCode: 'x = 25\ny = "Juan"\n\ndef f(a, b):\n    return a + b',
    badCodeCaption:
        'Variables llamadas equis e i griega, y una función llamada efe con '
        'parámetros a y be. Nadie sabe qué guardan.',
    goodCode:
        'edad_usuario = 25\n'
        'nombre_cliente = "Juan"\n\n'
        'def sumar_numeros(numero1, numero2):\n'
        '    return numero1 + numero2',
    goodCodeCaption:
        'Las mismas variables ahora se llaman edad usuario y nombre cliente, y '
        'la función se llama sumar números con parámetros número uno y número '
        'dos.',
    tips: [
      CapsuleTip(
        title: 'Tu código será más fácil de mantener',
        body:
            'Dentro de seis meses vas a volver a este archivo. Los nombres '
            'claros te ahorran reconstruir mentalmente qué hacía cada cosa.',
      ),
      CapsuleTip(
        title: 'Otras personas lo entenderán rápido',
        body:
            'El código se lee muchas más veces de las que se escribe. Haz que '
            'sea un placer leerlo.',
      ),
      CapsuleTip(
        title: 'Los errores serán más fáciles de encontrar',
        body:
            'Un nombre descriptivo hace evidente cuándo una variable se está '
            'usando para algo que no le corresponde.',
      ),
      CapsuleTip(
        title: 'Bonus: el Zen de Python',
        body:
            'Escribe import this en tu intérprete. Verás una serie de '
            'principios que guían la filosofía del lenguaje. El primero dice '
            '"Beautiful is better than ugly": lo hermoso es mejor que lo feo.',
      ),
    ],
    closing:
        'Recuerda: el código se lee mucho más veces de las que se escribe. Haz '
        'que sea un placer leerlo.',
  ),
  example: CodeExample(
    title: 'Mi primer programa en Python',
    description:
        'Un programa mínimo que imprime mensajes, crea dos variables y las '
        'muestra usando f-strings.',
    code:
        '# Mi primer programa en Python\n'
        'print("¡Bienvenido a Python!")\n'
        'print("Este es mi primer código")\n\n'
        'numero = 10\n'
        'mensaje = "Python es genial"\n'
        'print(f"Número: {numero}")\n'
        'print(f"Mensaje: {mensaje}")',
    codeCaption:
        'El programa imprime dos saludos, guarda el número diez y el texto '
        'Python es genial en dos variables, y luego las imprime dentro de una '
        'frase.',
    output:
        '¡Bienvenido a Python!\n'
        'Este es mi primer código\n'
        'Número: 10\n'
        'Mensaje: Python es genial',
    steps: [
      ExampleStep(
        code: 'print("¡Bienvenido a Python!")',
        explanation: 'Imprime un texto en la pantalla.',
      ),
      ExampleStep(
        code: 'print("Este es mi primer código")',
        explanation: 'Imprime otra línea de texto.',
      ),
      ExampleStep(
        code: 'numero = 10',
        explanation:
            'Crea una variable llamada numero y le asigna el valor 10.',
      ),
      ExampleStep(
        code: 'mensaje = "Python es genial"',
        explanation: 'Crea una variable llamada mensaje con un texto dentro.',
      ),
      ExampleStep(
        code: 'print(f"Número: {numero}")',
        explanation:
            'Imprime el valor de la variable numero dentro del texto usando un '
            'f-string.',
      ),
      ExampleStep(
        code: 'print(f"Mensaje: {mensaje}")',
        explanation: 'Hace lo mismo con la variable mensaje.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: primeros conceptos',
    instructions:
        'Responde las tres preguntas. Puedes volver atrás si necesitas repasar '
        'la lectura.',
    questions: [
      QuizQuestion(
        prompt: '¿Qué hace la función print() en Python?',
        options: [
          'Guarda datos en el disco',
          'Imprime texto en la pantalla',
          'Crea una variable nueva',
          'Instala librerías',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: '¿Cuál es el propósito de las variables en Python?',
        options: [
          'Cambiar el color del texto',
          'Almacenar datos para usarlos después',
          'Ejecutar el programa más rápido',
          'Conectarse a internet',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        prompt: '¿Qué es un f-string en Python?',
        options: [
          'Un tipo de archivo',
          'Una función matemática',
          'Una forma moderna de insertar variables dentro de texto usando llaves',
          'Un error de sintaxis',
        ],
        correctIndex: 2,
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 2: El entorno
// ---------------------------------------------------------------------------

const CourseSection _seccion2 = CourseSection(
  id: 'm1-s2',
  shortTitle: 'El entorno',
  videos: [
    SectionVideo(
      title: 'Introducción a Python (parte 2)',
      youtubeId: 'O0Wnap5kqBQ',
      duration: '37:43',
      description:
          'Clase 2.3 del curso Fundamentos de programación imperativa.',
      transcript:
          'Continúa la introducción trabajando ya sobre archivos .py en '
          'lugar del intérprete. Muestra cómo organizar la carpeta del '
          'proyecto, abrir el editor, escribir un programa completo, '
          'guardarlo y ejecutarlo desde la terminal. También repasa la '
          'lectura de datos con input y la conversión de tipos, que es lo '
          'que necesitas para tu primer Hola Mundo.',
    ),
  ],
  moduleNumber: 1,
  number: 2,
  title: 'El entorno',
  summary:
      'Las herramientas, carpetas y ajustes que necesitas para programar con '
      'comodidad, incluida la configuración de accesibilidad.',
  objectives: [
    'Reconocer qué compone un entorno de programación.',
    'Organizar tus proyectos en una estructura de carpetas clara.',
    'Diferenciar un editor de texto de un IDE.',
    'Ajustar el editor para que sea cómodo para ti.',
    'Crear y ejecutar tu primer "Hola Mundo".',
  ],
  reading: SectionReading(
    title: 'El entorno de Python: tu primer paso como programador',
    intro:
        'Un buen entorno es la diferencia entre frustración y fluidez. Aquí '
        'preparamos el taller antes de empezar a construir.',
    pages: [
      ReadingPage(
        title: 'El entorno',
        summary:
            'El entorno es todo lo que rodea al lenguaje: herramientas, '
            'organización y configuración.',
        blocks: [
          ReadingBlock.paragraph(
            title: '¿Qué es el entorno de programación?',
            body:
                'Es el conjunto de herramientas, espacios y configuraciones que '
                'necesitas para escribir, probar y ejecutar tu código Python. '
                'No es solo la instalación del lenguaje, sino también cómo '
                'organizas tus archivos y cómo configuras tu computadora para '
                'ser productivo.',
          ),
          ReadingBlock.callout(
            title: 'La analogía del carpintero',
            body:
                'Imagina un carpintero intentando trabajar sin un buen taller. '
                'Aunque tenga las herramientas correctas, sin organización y '
                'espacio su trabajo será lento e ineficiente. Con la '
                'programación pasa exactamente lo mismo.',
            tone: CalloutTone.info,
          ),
          ReadingBlock.bullets(
            title: 'Tu entorno incluye varias capas',
            items: [
              'El intérprete de Python, que ya instalaste.',
              'Un editor o IDE para escribir código.',
              'La terminal o línea de comandos para ejecutar programas.',
              'Una estructura de carpetas bien organizada.',
              'Las configuraciones personales que hacen tu espacio cómodo.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Sistema de archivos',
        summary:
            'Todo código vive en archivos, y esos archivos viven en carpetas. '
            'Entender esa estructura es fundamental.',
        blocks: [
          ReadingBlock.code(
            title: 'Estructura recomendada',
            code:
                'Mis_Documentos/\n'
                '└── Proyectos_Python/\n'
                '    ├── Proyecto_1/\n'
                '    │   ├── mi_primer_programa.py\n'
                '    │   ├── datos.txt\n'
                '    │   └── readme.md\n'
                '    ├── Proyecto_2/\n'
                '    │   └── segundo_programa.py\n'
                '    └── Proyecto_3/',
            body:
                'Cada proyecto vive en su propia carpeta. Dentro va el código '
                'Python, los datos que necesita y la documentación. Así tus '
                'archivos no se pierden en un caos de carpetas.',
            codeCaption:
                'Un árbol de carpetas donde Proyectos Python contiene tres '
                'proyectos, y cada proyecto guarda dentro sus propios archivos.',
          ),
          ReadingBlock.bullets(
            title: 'Términos importantes',
            items: [
              'Ruta: la dirección completa de un archivo dentro del sistema.',
              'Extensión: el tipo de archivo. Punto py significa Python, punto txt es texto.',
              'Directorio actual: la carpeta donde estás trabajando en este momento en la terminal.',
            ],
          ),
          ReadingBlock.code(
            title: 'Moverte por la terminal',
            code:
                'cd Proyectos_Python    # Entra a esta carpeta\n'
                'cd Proyecto_1          # Entra a esta subcarpeta\n'
                'ls                     # macOS y Linux: lista archivos\n'
                'dir                    # Windows: lista archivos\n'
                'pwd                    # Muestra dónde estás ahora\n'
                'cd ..                  # Sube una carpeta',
            codeCaption:
                'Comandos de terminal para entrar a carpetas con cd, listar '
                'archivos con ls o dir, ver la ruta actual con pwd y subir un '
                'nivel con cd punto punto.',
          ),
        ],
      ),
      ReadingPage(
        title: '¿Qué es un IDE o editor?',
        summary:
            'Un editor es ligero y solo escribe código. Un IDE integra editor, '
            'terminal, depurador y gestor de proyectos.',
        blocks: [
          ReadingBlock.bullets(
            title: 'Editores de texto',
            body: 'Visual Studio Code, Sublime Text, Notepad++.',
            items: [
              'Ventajas: son rápidos, ocupan poco espacio y son minimalistas.',
              'Desventajas: tienes que configurarlos tú para funciones adicionales.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'IDEs',
            body: 'PyCharm, Spyder, Thonny.',
            items: [
              'Ventajas: todo listo para usar, con muchas funcionalidades incluidas.',
              'Desventajas: pesan más y pueden abrumar al principio.',
            ],
          ),
          ReadingBlock.callout(
            title: 'Para empezar: Visual Studio Code',
            body:
                'Es gratuito, funciona en cualquier sistema operativo, es lo '
                'bastante simple para aprender y lo bastante potente para '
                'proyectos profesionales. Además su terminal está integrada, '
                'así que ejecutas código sin salir del editor.',
            tone: CalloutTone.success,
          ),
          ReadingBlock.steps(
            title: 'Instalar VS Code',
            items: [
              'Entra a code.visualstudio.com',
              'Descarga la versión para tu sistema operativo.',
              'Instálalo como cualquier otra aplicación.',
              'Abre VS Code, ve a Extensiones en la barra izquierda, busca "Python" e instala la extensión oficial de Microsoft.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Configuración para accesibilidad',
        summary:
            'La accesibilidad no es solo para personas con discapacidad: es '
            'hacer que tu entorno sea cómodo para ti, como sea que trabajes '
            'mejor.',
        blocks: [
          ReadingBlock.bullets(
            title: 'Tamaño de fuente',
            body:
                'Si tu vista se cansa rápido, aumenta el tamaño de fuente en '
                'VS Code.',
            items: [
              'Ve a Archivo, luego Preferencias, luego Configuración.',
              'Busca "Font Size".',
              'Cambia el valor: por defecto es 14, puedes ponerlo en 16 o 18.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Temas oscuros o claros',
            body:
                'Trabajar muchas horas frente a la pantalla cansa los ojos. Un '
                'tema oscuro reduce ese cansancio.',
            items: [
              'Ve a Archivo, Preferencias, Tema de color.',
              'Elige un tema oscuro como "Dark+" o "Dracula".',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Espaciado, legibilidad y atajos',
            items: [
              'Line Height: aumenta el espacio entre líneas.',
              'Letter Spacing: añade espacio entre letras si las ves apretadas.',
              'En Preferencias, Atajos de teclado, puedes asignar teclas a las acciones que más uses y depender menos del ratón.',
              'Modo Zen: presiona Control más K y luego Z, o Comando más K y luego Z en macOS, para una pantalla sin distracciones.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Tu primer "Hola Mundo"',
        summary:
            'Vamos a crear la carpeta, el archivo y ejecutar tu primer programa '
            'de principio a fin.',
        blocks: [
          ReadingBlock.code(
            title: 'Paso 1 y 2: carpeta y editor',
            code:
                'mkdir Mi_Primer_Programa\n'
                'cd Mi_Primer_Programa\n'
                'code .',
            body:
                'Creas la carpeta, entras en ella y abres VS Code ahí mismo. El '
                'punto significa "esta carpeta".',
            codeCaption:
                'Comandos mkdir para crear la carpeta, cd para entrar y code '
                'punto para abrir el editor en ese lugar.',
          ),
          ReadingBlock.code(
            title: 'Paso 3 y 4: crea hola_mundo.py y escribe',
            code:
                'print("¡Hola, Mundo!")\n'
                'print("Este es mi primer programa en Python")\n\n'
                'nombre = input("¿Cuál es tu nombre? ")\n'
                'print(f"¡Bienvenido, {nombre}!")',
            codeCaption:
                'El programa imprime dos saludos, luego pregunta tu nombre con '
                'input y finalmente te saluda usando ese nombre.',
          ),
          ReadingBlock.bullets(
            title: 'Paso 5: ejecuta el programa',
            items: [
              'Opción recomendada: presiona el botón de Play verde arriba a la derecha, o Control más F5.',
              'Opción en terminal: abre la terminal integrada con Control más la tecla de acento grave y escribe python hola_mundo.py',
            ],
          ),
          ReadingBlock.callout(
            title: '¡Felicitaciones!',
            body:
                'Acabas de cruzar de ser alguien que aprende sobre programación '
                'a ser alguien que programa. El entorno no se configura una vez '
                'y se olvida: lo irás ajustando conforme crezcas.',
            tone: CalloutTone.success,
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          '¿Cuál es la principal ventaja de VS Code frente a otros editores '
          'para quien empieza?',
      options: [
        'Es más pesado y tiene más funcionalidades avanzadas',
        'Es gratuito, ligero, tiene excelente soporte para Python y su terminal está integrada',
        'Es el único editor que funciona con Python',
        'Requiere más configuración que otros editores',
      ],
      correctIndex: 1,
      explanation:
          'Combina sencillez para aprender con potencia suficiente para '
          'proyectos profesionales.',
    ),
    QuizQuestion(
      prompt: '¿Cuál es la función del comando cd en la terminal?',
      options: [
        'Listar todos los archivos de una carpeta',
        'Navegar entre carpetas, es decir, cambiar de directorio',
        'Crear un nuevo archivo Python',
        'Instalar paquetes de Python',
      ],
      correctIndex: 1,
      explanation: 'cd viene de "change directory": cambiar de directorio.',
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Qué es el entorno de programación?',
      options: [
        'Solo la instalación del lenguaje Python',
        'El conjunto de herramientas, espacios y configuraciones necesarios para escribir, probar y ejecutar código Python',
        'Únicamente la terminal o línea de comandos',
        'El nombre del archivo donde guardas tu código',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál es la estructura recomendada para organizar tus proyectos '
          'Python?',
      options: [
        'Guardar todos los archivos en una sola carpeta sin subcarpetas',
        'Cada proyecto en su propia carpeta con sus respectivos archivos: código, datos y documentación',
        'Usar carpetas solo cuando tengas más de 100 archivos',
        'No importa cómo organices los archivos',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál es la diferencia principal entre un editor de texto y un IDE?',
      options: [
        'El editor es más completo y el IDE es más simple',
        'El IDE solo funciona con Python y el editor con cualquier lenguaje',
        'El IDE incluye editor, terminal, depurador y más de forma integrada; el editor es más simple y ligero',
        'No hay diferencia, son lo mismo',
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt:
          '¿Cuáles son los pasos correctos para ejecutar un programa Python en '
          'VS Code?',
      options: [
        'Escribir el código, guardarlo con Control más S y luego Control más F5',
        'Guardar el archivo con extensión .py y presionar el botón de Play verde',
        'Solo escribir el código, no es necesario guardarlo',
        'Tanto la primera como la segunda opción son correctas',
      ],
      correctIndex: 3,
      explanation:
          'Ambos caminos funcionan: lo esencial es guardar el archivo con '
          'extensión .py antes de ejecutarlo.',
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: organizando tu espacio de trabajo',
    headline: 'La casa del programador: construye tu entorno perfecto',
    intro:
        'Un buen entorno de programación es como tener una casa bien '
        'organizada. No programas en caos, así como no vives en desorden.',
    tips: [
      CapsuleTip(
        title: 'Estructura clara de carpetas',
        body:
            'Cada proyecto en su lugar. Una carpeta "Proyectos_Python" con '
            'subcarpetas por proyecto. Esto te ahorra tiempo buscando archivos.',
      ),
      CapsuleTip(
        title: 'Herramienta adecuada',
        body:
            'VS Code para empezar: simple pero poderoso. No necesitas aprender '
            'cien funcionalidades al principio; necesitas enfocarte en escribir '
            'código.',
      ),
      CapsuleTip(
        title: 'Configuración personal',
        body:
            'Tema oscuro si trabajas de noche, fuente grande si tus ojos se '
            'cansan. Tu comodidad se traduce en más horas productivas.',
      ),
    ],
    closing:
        'El tiempo que inviertas en organizar tu entorno ahora te evitará '
        'frustración después.',
  ),
  example: CodeExample(
    title: 'Organizando tu primer proyecto: una calculadora',
    description:
        'Creamos la estructura de carpetas, abrimos VS Code en el proyecto y '
        'escribimos una calculadora que suma, resta, multiplica y divide.',
    code:
        '# Mi primer proyecto: una calculadora simple\n\n'
        'print("=" * 40)\n'
        'print("CALCULADORA SIMPLE")\n'
        'print("=" * 40)\n\n'
        'numero1 = int(input("Ingresa el primer número: "))\n'
        'numero2 = int(input("Ingresa el segundo número: "))\n\n'
        r'print("\n¿Qué operación deseas realizar?")'
        '\n'
        'print("1. Suma")\n'
        'print("2. Resta")\n'
        'print("3. Multiplicación")\n'
        'print("4. División")\n\n'
        'operacion = input("Elige (1, 2, 3 o 4): ")\n\n'
        'if operacion == "1":\n'
        '    resultado = numero1 + numero2\n'
        r'    print(f"\n{numero1} + {numero2} = {resultado}")'
        '\n'
        'elif operacion == "2":\n'
        '    resultado = numero1 - numero2\n'
        r'    print(f"\n{numero1} - {numero2} = {resultado}")'
        '\n'
        'elif operacion == "3":\n'
        '    resultado = numero1 * numero2\n'
        r'    print(f"\n{numero1} × {numero2} = {resultado}")'
        '\n'
        'elif operacion == "4":\n'
        '    if numero2 != 0:\n'
        '        resultado = numero1 / numero2\n'
        r'        print(f"\n{numero1} ÷ {numero2} = {resultado}")'
        '\n'
        '    else:\n'
        r'        print("\nError: no puedes dividir entre cero")'
        '\n'
        'else:\n'
        r'    print("\nOpción no válida")',
    codeCaption:
        'La calculadora imprime un título, pide dos números, muestra un menú '
        'con cuatro operaciones y según la opción elegida suma, resta, '
        'multiplica o divide. Antes de dividir comprueba que el segundo número '
        'no sea cero.',
    output:
        '========================================\n'
        'CALCULADORA SIMPLE\n'
        '========================================\n'
        'Ingresa el primer número: 10\n'
        'Ingresa el segundo número: 5\n\n'
        '¿Qué operación deseas realizar?\n'
        '1. Suma\n'
        '2. Resta\n'
        '3. Multiplicación\n'
        '4. División\n'
        'Elige (1, 2, 3 o 4): 1\n\n'
        '10 + 5 = 15',
    steps: [
      ExampleStep(
        code: 'mkdir Proyectos_Python',
        explanation: 'Crea la carpeta contenedora de todos tus proyectos.',
      ),
      ExampleStep(
        code: 'cd Proyectos_Python',
        explanation: 'Entra a esa carpeta.',
      ),
      ExampleStep(
        code: 'mkdir Mi_Calculadora && cd Mi_Calculadora',
        explanation: 'Crea la carpeta del proyecto concreto y entra en ella.',
      ),
      ExampleStep(
        code: 'code .',
        explanation:
            'Abre VS Code directamente en el proyecto: es como abrir la puerta '
            'de tu casa de programador.',
      ),
      ExampleStep(
        code: 'print("=" * 40)',
        explanation:
            'Multiplicar un texto por un número lo repite: así dibujas una '
            'línea separadora de 40 caracteres.',
      ),
      ExampleStep(
        code: 'if numero2 != 0:',
        explanation:
            'Antes de dividir se comprueba que el divisor no sea cero, porque '
            'eso provocaría un error.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: preparar el espacio de trabajo',
    instructions:
        'Relaciona cada paso con lo que realmente hace en la terminal.',
    pairs: [
      ConceptPair(
        concept: 'Crear carpetas',
        definition:
            'Usas mkdir para crear una carpeta llamada Proyectos_Python.',
      ),
      ConceptPair(
        concept: 'Entrar a la carpeta',
        definition: 'Usas cd para navegar hacia tu nueva carpeta de proyectos.',
      ),
      ConceptPair(
        concept: 'Crear subcarpeta',
        definition:
            'Creas una carpeta específica para tu primer proyecto, por ejemplo '
            'Mi_Calculadora.',
      ),
      ConceptPair(
        concept: 'Abrir VS Code',
        definition:
            'Abres el editor directamente en tu proyecto con el comando code '
            'seguido de un punto.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 3: El factor inglés
// ---------------------------------------------------------------------------

const CourseSection _seccion3 = CourseSection(
  id: 'm1-s3',
  shortTitle: 'El factor\ninglés',
  videos: [
    SectionVideo(
      title: 'Estructuras de control I',
      youtubeId: 'jWFLFNu87XY',
      duration: '27:49',
      description:
          'Clase 3.2. Las palabras clave en inglés aplicadas a decisiones.',
      transcript:
          'Recorre las palabras reservadas del control de flujo viéndolas '
          'en código real: if para decidir, else y elif para las '
          'alternativas, y los operadores and, or y not para combinar '
          'condiciones. Es la mejor manera de fijar el vocabulario en '
          'inglés de esta sección, porque aparece una y otra vez en '
          'pantalla.',
    ),
    SectionVideo(
      title: 'Estructuras de control II',
      youtubeId: 'twyIQHc7J7Y',
      duration: '8:41',
      description:
          'Clase 3.2, segunda parte. Repaso corto de las mismas palabras clave.',
      transcript:
          'Cierre breve del tema anterior con más ejemplos de if, elif y '
          'else, y una primera mirada a for y while. Sirve para repasar '
          'cómo la indentación decide qué instrucciones pertenecen a cada '
          'bloque.',
    ),
  ],
  moduleNumber: 1,
  number: 3,
  title: 'El factor inglés',
  summary:
      'Las 15 palabras clave que cubren el 95% del código que escribirás, '
      'agrupadas por lo que hacen.',
  objectives: [
    'Reconocer las palabras reservadas de Python y su significado.',
    'Agrupar las palabras clave por su propósito.',
    'Leer código en inglés y entender qué hace.',
  ],
  reading: SectionReading(
    title: 'El inglés que necesitas saber en Python',
    intro:
        'Python usa solo 35 palabras clave. No necesitas ser fluido en inglés '
        'para programar, pero sí reconocer las fundamentales.',
    pages: [
      ReadingPage(
        title: '¿Por qué el inglés importa en Python?',
        summary:
            'Cada palabra reservada y cada función del lenguaje está en inglés: '
            'es el idioma común de la programación.',
        blocks: [
          ReadingBlock.paragraph(
            title: 'Estás comunicándote con la máquina',
            body:
                'Python está construido sobre el inglés. Es como aprender '
                'carpintería: aunque tu lengua materna sea otra, necesitas saber '
                'qué significa "martillo", "clavo" y "madera" en el idioma '
                'internacional del oficio.',
          ),
          ReadingBlock.callout(
            title: 'La buena noticia',
            body:
                'Python usa solo 35 palabras clave, y no necesitas aprenderlas '
                'todas de una vez. Las más comunes aparecerán una y otra vez en '
                'tu código hasta volverse familiares.',
            tone: CalloutTone.success,
          ),
        ],
      ),
      ReadingPage(
        title: 'Palabras clave en Python',
        summary:
            'Son términos reservados que Python reconoce automáticamente y que '
            'no puedes usar como nombres de variables.',
        blocks: [
          ReadingBlock.code(
            title: 'Decidir: if, else, elif',
            code:
                'if edad >= 18:\n'
                '    print("Eres mayor de edad")\n'
                'else:\n'
                '    print("Eres menor de edad")',
            codeCaption:
                'Si la edad es mayor o igual a 18 imprime que eres mayor de '
                'edad; si no, imprime que eres menor de edad.',
          ),
          ReadingBlock.code(
            title: 'Repetir: for y while',
            code:
                'for i in range(5):\n'
                '    print(i)\n\n'
                'while contador < 10:\n'
                '    print(contador)\n'
                '    contador = contador + 1',
            codeCaption:
                'El primer bucle repite cinco veces imprimiendo el contador. El '
                'segundo repite mientras el contador sea menor que diez, '
                'sumando uno en cada vuelta.',
          ),
          ReadingBlock.code(
            title: 'Construir: def, return, class',
            code:
                'def saludar(nombre):\n'
                '    print(f"Hola, {nombre}")\n\n'
                'def suma(a, b):\n'
                '    return a + b\n\n'
                'class Persona:\n'
                '    def __init__(self, nombre):\n'
                '        self.nombre = nombre',
            codeCaption:
                'Se define una función saludar que imprime un saludo, otra '
                'función suma que devuelve la suma de dos valores, y una clase '
                'Persona que guarda un nombre al crearse.',
          ),
          ReadingBlock.code(
            title: 'Controlar errores y flujo: try, except, break, continue',
            code:
                'try:\n'
                '    resultado = 10 / 0\n'
                'except ZeroDivisionError:\n'
                '    print("No puedes dividir entre cero")\n\n'
                'for i in range(10):\n'
                '    if i == 5:\n'
                '        break      # sale del bucle\n'
                '    if i == 3:\n'
                '        continue   # salta a la siguiente vuelta',
            codeCaption:
                'Se intenta dividir diez entre cero; como falla, se captura el '
                'error y se avisa. Después, un bucle sale cuando llega a cinco '
                'y se salta la vuelta cuando vale tres.',
          ),
          ReadingBlock.bullets(
            title: 'Otras palabras que verás a diario',
            items: [
              'import: trae código de otras librerías.',
              'True y False: los valores booleanos, verdadero y falso.',
              'and, or, not: combinan condiciones.',
              'in: verifica si algo existe dentro de una colección.',
              'pass: marcador de posición que no hace nada.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Glosario por categorías',
        summary:
            'Agrupar las palabras por su propósito hace que se memoricen solas.',
        blocks: [
          ReadingBlock.bullets(
            title: 'Conditionals — condicionales',
            items: [
              'if igual a "si".',
              'else igual a "si no".',
              'elif igual a "si no, pero si".',
              'True igual a "verdadero", False igual a "falso".',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Loops — bucles',
            items: [
              'for igual a "para".',
              'while igual a "mientras".',
              'break igual a "rompe", sale del bucle.',
              'continue igual a "continúa", pasa a la siguiente iteración.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Functions — funciones',
            items: [
              'def igual a "define".',
              'return igual a "devuelve".',
              'pass: no hace nada, reserva el lugar.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Data types — tipos de datos',
            items: [
              'int: entero. float: decimal. str: texto.',
              'list: lista. dict: diccionario. tuple: tupla.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Exception handling — manejo de errores',
            items: [
              'try igual a "intenta".',
              'except igual a "excepto".',
              'finally igual a "finalmente".',
              'raise igual a "lanza".',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Memoria visual: agrupa por propósito',
            items: [
              'Decide con if, else, elif.',
              'Repite con for, while.',
              'Construye con def, class.',
              'Controla el flujo con break, continue, return.',
              'Maneja errores con try, except.',
              'Combina lógica con and, or, not.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Practica leyendo código en inglés',
        summary:
            'Leer el código en voz alta, palabra por palabra, acelera muchísimo '
            'la comprensión.',
        blocks: [
          ReadingBlock.code(
            title: 'Lee este fragmento',
            code:
                'if edad >= 18 and tiene_licencia:\n'
                '    print("Puedes conducir")\n'
                'else:\n'
                '    print("No puedes conducir aún")',
            codeCaption:
                'Si la edad es mayor o igual a dieciocho y además tiene '
                'licencia, imprime que puede conducir; si no, imprime que aún '
                'no puede.',
          ),
          ReadingBlock.paragraph(
            title: 'Léelo así, en voz alta',
            body:
                '"If age greater than or equal to 18 and has license: print you '
                'can drive. Else: print you cannot drive yet." Cuando empiezas a '
                'leer código en inglés, automáticamente comprendes mejor qué '
                'hace.',
          ),
          ReadingBlock.callout(
            title: 'Tu kit de herramientas',
            body:
                'Con 15 palabras clave cubres el 95% de lo que escribirás como '
                'principiante. No son opcionales: son el alfabeto de Python. La '
                'barrera del idioma es real, pero se supera con práctica.',
            tone: CalloutTone.success,
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          '¿Cuál es la palabra clave que se utiliza para definir una función en '
          'Python?',
      options: ['class', 'def', 'function', 'define'],
      correctIndex: 1,
      explanation: 'def viene de "define": define una función.',
    ),
    QuizQuestion(
      prompt: '¿Cuál es la diferencia entre if, else y elif?',
      options: [
        'if es para decisiones, else para bucles y elif para funciones',
        'if verifica una condición, else ejecuta si la condición es falsa, elif es otra condición adicional',
        'Son palabras sinónimas, todas hacen lo mismo',
        'Solo if es una palabra clave real',
      ],
      correctIndex: 1,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Para qué sirve la palabra clave for en Python?',
      options: [
        'Para definir funciones',
        'Para repetir un bloque de código múltiples veces',
        'Para tomar decisiones',
        'Para importar módulos',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál de las siguientes NO es una palabra clave de Python?',
      options: ['import', 'return', 'function', 'try'],
      correctIndex: 2,
      explanation:
          'En Python las funciones se definen con def, no con function.',
    ),
    QuizQuestion(
      prompt:
          '¿Cuáles son los operadores lógicos en Python que permiten combinar '
          'condiciones?',
      options: [
        'if, else, elif',
        'and, or, not',
        'for, while, break',
        'print, input, len',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál es la función del bloque try y except?',
      options: [
        'Repite un código múltiples veces',
        'Define una función',
        'Intenta ejecutar código y captura errores si los hay',
        'Importa librerías externas',
      ],
      correctIndex: 2,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: el vocabulario mínimo',
    headline: 'Quince palabras y ya lees código',
    intro:
        'Dominar las palabras clave es la diferencia entre ser un principiante '
        'confundido, para quien cada palabra nueva es un misterio, y un '
        'programador seguro que reconoce patrones al instante.',
    tips: [
      CapsuleTip(
        title: 'Cuando ves for, sabes que algo se repite',
        body:
            'No necesitas leer el resto para saber qué está pasando: la palabra '
            'clave ya te dio el contexto.',
      ),
      CapsuleTip(
        title: 'Cuando ves if, sabes que hay una decisión',
        body:
            'El código se bifurca. Solo tienes que averiguar cuál es la '
            'condición.',
      ),
      CapsuleTip(
        title: 'Cuando ves try, sabes que algo puede fallar',
        body:
            'Quien escribió ese código ya anticipó un error posible. Eso te '
            'dice dónde está el riesgo.',
      ),
      CapsuleTip(
        title: 'Lee tu código en voz alta',
        body:
            'La práctica activa —hablar y leer conscientemente— es muy superior '
            'a la pasiva. Es el mismo truco que funciona al aprender cualquier '
            'idioma.',
      ),
    ],
    closing:
        'Pronto print, if, for y def serán tan familiares como la palabra '
        '"hola".',
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: agrupa las palabras clave',
    instructions:
        'Relaciona cada grupo de palabras clave con el propósito que cumplen.',
    pairs: [
      ConceptPair(
        concept: 'if, else, elif, True, False',
        definition:
            'Tomar decisiones en el código: ejecutar algo solo si se cumple una '
            'condición.',
      ),
      ConceptPair(
        concept: 'for, while, break, continue',
        definition:
            'Repetir un bloque de código múltiples veces hasta cumplir una '
            'condición.',
      ),
      ConceptPair(
        concept: 'def, return, pass',
        definition:
            'Crear bloques de código reutilizable que realizan una tarea '
            'específica.',
      ),
      ConceptPair(
        concept: 'and, or, not, in',
        definition:
            'Combinar condiciones o verificar si algo existe en una colección.',
      ),
    ],
  ),
);
