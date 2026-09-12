import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 2. Fundamentos de Python — Sintaxis, Números y Cadenas de texto.
const CourseModule module2 = CourseModule(
  number: 2,
  title: 'Fundamentos de Python',
  sections: [_seccion1, _seccion2, _seccion3],
);

// ---------------------------------------------------------------------------
// Capítulo 1: Sintaxis
// ---------------------------------------------------------------------------

const CourseSection _seccion1 = CourseSection(
  id: 'm2-s1',
  shortTitle: 'Sintaxis',
  videos: [
    SectionVideo(
      title: 'Explicación del taller 1',
      youtubeId: 'Ti5wcpfJdm4',
      duration: '27:32',
      description:
          'Clase 3. Se escribe código paso a paso cuidando la sintaxis.',
      transcript:
          'El profesor resuelve un taller en vivo escribiendo el programa '
          'desde cero. Es útil para esta sección porque se ve cómo se '
          'eligen los nombres de las variables, cómo la indentación '
          'agrupa el código y dónde conviene poner comentarios. También '
          'aparecen los errores de sintaxis más frecuentes y cómo los '
          'reporta Python.',
    ),
  ],
  moduleNumber: 2,
  number: 1,
  title: 'Sintaxis',
  summary:
      'Las reglas que hacen que Python entienda tu código: variables, '
      'indentación y comentarios.',
  objectives: [
    'Nombrar variables siguiendo las reglas y las buenas prácticas.',
    'Usar la indentación para definir bloques de código.',
    'Escribir comentarios que aporten valor real.',
  ],
  reading: SectionReading(
    title: 'La sintaxis de Python: el código bien escrito',
    intro:
        'La sintaxis es la gramática del lenguaje. Si la escribes mal, Python '
        'no te entiende. La buena noticia es que la de Python es limpia y '
        'lógica.',
    pages: [
      ReadingPage(
        title: 'Variables y nombres',
        summary:
            'Una variable es un contenedor etiquetado donde guardas '
            'información.',
        blocks: [
          ReadingBlock.code(
            title: '¿Qué es una variable?',
            code: 'edad = 25\nnombre = "Juan"\naltura = 1.75',
            body:
                'edad es el nombre de la variable, 25 es el valor, y el signo '
                'igual asigna ese valor a la variable.',
            codeCaption:
                'Se guardan tres datos: el número veinticinco en edad, el texto '
                'Juan en nombre y el decimal uno punto setenta y cinco en '
                'altura.',
          ),
          ReadingBlock.bullets(
            title: 'Reglas obligatorias',
            items: [
              'El nombre debe empezar con una letra o un guion bajo. Correcto: nombre, _edad. Incorrecto: 25nombre.',
              'Solo puede contener letras, números y guiones bajos. Correcto: edad_usuario. Incorrecto: edad-usuario.',
              'Python distingue mayúsculas de minúsculas: nombre y Nombre son variables diferentes.',
              'No puedes usar palabras reservadas: if, for o print no sirven como nombres de variable.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Buenas prácticas',
            items: [
              'Usa nombres descriptivos: edad_usuario es mejor que x.',
              'Usa snake_case, es decir minúsculas separadas por guiones bajos: total_ventas.',
              'Sé consistente con el idioma: todo en español o todo en inglés, pero no mezclado.',
            ],
          ),
          ReadingBlock.callout(
            title: 'Errores frecuentes al nombrar',
            body:
                'No se puede empezar con número, ni usar guiones, ni signos de '
                'exclamación, ni espacios, ni palabras reservadas del lenguaje.',
            tone: CalloutTone.danger,
          ),
        ],
      ),
      ReadingPage(
        title: 'Indentación',
        summary:
            'En Python los espacios al inicio de la línea no son decorativos: '
            'definen qué código está dentro de qué bloque.',
        blocks: [
          ReadingBlock.paragraph(
            title: 'Los espacios reemplazan a las llaves',
            body:
                'En otros lenguajes usas llaves para delimitar bloques. En '
                'Python usas indentación, y el estándar es de 4 espacios por '
                'nivel. Esto responde a la filosofía del lenguaje: el código '
                'debe leerse como se ve.',
          ),
          ReadingBlock.code(
            title: 'La indentación define la estructura',
            code:
                'for i in range(3):\n'
                '    print("Fuera del if")     # se repite 3 veces\n'
                '    if i == 1:\n'
                '        print("Dentro del if")  # se ejecuta 1 vez\n'
                '    print("De nuevo fuera")   # se repite 3 veces\n\n'
                'print("Fin")                  # se ejecuta 1 vez',
            codeCaption:
                'Un bucle que da tres vueltas. Dentro imprime dos mensajes '
                'siempre, y solo cuando el contador vale uno imprime un tercer '
                'mensaje. Al terminar el bucle imprime Fin una sola vez.',
          ),
          ReadingBlock.bullets(
            title: 'Bloques que exigen indentación',
            items: [
              'Funciones, con def.',
              'Condicionales: if, elif, else.',
              'Bucles: for y while.',
              'Clases, con class.',
              'Manejo de errores: try y except.',
            ],
          ),
          ReadingBlock.callout(
            title: 'Errores comunes de indentación',
            body:
                'Mezclar 2 y 4 espacios, olvidar indentar la línea que sigue a '
                'un if, o indentar una línea que no pertenece a ningún bloque. '
                'Cualquiera de los tres detiene el programa.',
            tone: CalloutTone.danger,
          ),
        ],
      ),
      ReadingPage(
        title: 'Comentarios',
        summary:
            'Un comentario es una nota que Python ignora por completo. Es para '
            'ti y para quien lea tu código.',
        blocks: [
          ReadingBlock.code(
            title: 'Las dos formas de comentar',
            code:
                '# Esto es un comentario de una línea\n'
                'edad = 25  # También puedo comentar al final de la línea\n\n'
                '"""\n'
                'Este es un comentario de varias líneas.\n'
                'Perfecto para explicaciones largas.\n'
                '"""',
            codeCaption:
                'Con almohadilla se comenta una línea. Con tres comillas '
                'dobles, al abrir y al cerrar, se comentan varias líneas '
                'seguidas.',
          ),
          ReadingBlock.code(
            title: 'Documentar una función',
            code:
                'def calcular_area_circulo(radio):\n'
                '    """\n'
                '    Calcula el área de un círculo dado su radio.\n\n'
                '    Parámetros:\n'
                '    - radio: float, el radio del círculo\n\n'
                '    Retorna:\n'
                '    - float, el área del círculo\n'
                '    """\n'
                '    import math\n'
                '    return math.pi * radio ** 2',
            codeCaption:
                'Una función que calcula el área de un círculo. Empieza con un '
                'texto entre triples comillas que explica qué recibe y qué '
                'devuelve, y luego multiplica pi por el radio al cuadrado.',
          ),
          ReadingBlock.bullets(
            title: 'Comenta el porqué, no el qué',
            items: [
              'Útil: "Validar que el usuario sea mayor de edad" antes de un if.',
              'Útil: "Esperar 2 segundos antes de reintentar" antes de una pausa.',
              'Inútil: "Incrementar contador" encima de contador = contador + 1. Eso ya se ve.',
              'Inútil: "Asignar nombre" encima de nombre = "Juan".',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          '¿Cuál de los siguientes nombres de variables es válido en Python?',
      options: ['2edad', 'edad-usuario', 'edad_usuario', 'edad usuario'],
      correctIndex: 2,
      explanation:
          'Empieza con letra, solo usa letras y guiones bajos, y no tiene '
          'espacios.',
    ),
    QuizQuestion(
      prompt: '¿Cuál es la indentación estándar recomendada en Python?',
      options: ['2 espacios', '4 espacios', '8 espacios', '1 tabulador'],
      correctIndex: 1,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuál de las siguientes afirmaciones sobre variables es FALSA?',
      options: [
        'El nombre debe empezar con letra o guion bajo',
        'Las variables pueden contener caracteres especiales como arroba',
        'Python distingue mayúsculas: edad no es lo mismo que EDAD',
        'Los nombres descriptivos son mejores que los genéricos',
      ],
      correctIndex: 1,
      explanation:
          'Solo se permiten letras, números y guiones bajos. Nada de arrobas ni '
          'símbolos.',
    ),
    QuizQuestion(
      prompt:
          'En el código "if edad >= 18:" seguido de "print(\'Mayor de edad\')" '
          'sin sangría, ¿qué error hay?',
      options: [
        'El nombre de la variable está incorrecto',
        'Falta indentación en la segunda línea',
        'El símbolo mayor o igual está mal usado',
        'El comentario es incorrecto',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          'Si en el código 1 el print("Fin") está fuera del for y en el código '
          '2 está dentro, ¿cuál es la diferencia?',
      options: [
        'Son exactamente iguales',
        'El código 1 imprime "Fin" una sola vez y el código 2 lo imprime 3 veces',
        'El código 1 no funciona y el código 2 sí',
        'Son sintácticamente diferentes pero funcionalmente iguales',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál es la mejor práctica para nombrar una variable que guarda el '
          'precio final de un producto?',
      options: ['x', 'p', 'pf', 'precio_final'],
      correctIndex: 3,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: la sintaxis es tu herramienta',
    headline: 'Escribe código que habla, no que grita',
    intro:
        'La sintaxis no es un conjunto de reglas arbitrarias: es el lenguaje '
        'que Python entiende. Cuando la dominas, tu código es legible, '
        'mantenible y profesional.',
    tips: [
      CapsuleTip(
        title: 'Nombres significativos',
        body:
            'No seas perezoso. edad_usuario es mejor que x. Tu yo del futuro te '
            'lo agradecerá.',
      ),
      CapsuleTip(
        title: 'Indentación consistente',
        body:
            'Cuatro espacios, siempre. No mezcles espacios con tabuladores. La '
            'indentación no es decorativa: define tu código.',
      ),
      CapsuleTip(
        title: 'Comentarios útiles',
        body:
            'No comentes lo obvio. Comenta el porqué, no el qué. Si alguien lee '
            'contador = contador + 1 ya sabe que incrementas; comenta si hay una '
            'razón especial.',
      ),
    ],
    closing:
        'La sintaxis correcta es el primer paso hacia un código excelente.',
  ),
  example: CodeExample(
    title: 'Un carrito de compras bien escrito',
    description:
        'Nombres descriptivos, indentación consistente y comentarios que '
        'explican decisiones, no lo evidente.',
    code:
        '# Sistema de carrito de compras\n\n'
        'nombre_cliente = "María"\n'
        'productos_carrito = []\n\n'
        'def agregar_producto(carrito, nombre_producto, precio):\n'
        '    """Agrega un producto al carrito de compras."""\n'
        '    # Validar que el precio sea positivo\n'
        '    if precio <= 0:\n'
        '        print("Error: el precio debe ser mayor a 0")\n'
        '        return False\n\n'
        "    producto = {'nombre': nombre_producto, 'precio': precio}\n"
        '    carrito.append(producto)\n'
        '    print(f"{nombre_producto} agregado al carrito")\n'
        '    return True\n\n'
        'def calcular_total(carrito):\n'
        '    """Calcula el total de la compra."""\n'
        '    total = 0\n'
        '    for producto in carrito:\n'
        "        total += producto['precio']\n"
        '    return total\n\n'
        'agregar_producto(productos_carrito, "Laptop", 800.00)\n'
        'agregar_producto(productos_carrito, "Mouse", 25.50)\n'
        'agregar_producto(productos_carrito, "Teclado", 75.00)\n\n'
        'print(f"Cliente: {nombre_cliente}")\n'
        'print(f"Total: {calcular_total(productos_carrito)}")',
    codeCaption:
        'Se define una función que agrega productos al carrito validando que el '
        'precio sea positivo, y otra que recorre el carrito sumando precios. '
        'Después se agregan tres productos y se imprime el total.',
    output:
        'Laptop agregado al carrito\n'
        'Mouse agregado al carrito\n'
        'Teclado agregado al carrito\n'
        'Cliente: María\n'
        'Total: 900.5',
    steps: [
      ExampleStep(
        code: 'nombre_cliente = "María"',
        explanation:
            'Nombre descriptivo: se entiende qué guarda sin leer nada más.',
      ),
      ExampleStep(
        code: '"""Agrega un producto al carrito de compras."""',
        explanation:
            'Docstring: documenta la función en una línea, justo debajo del def.',
      ),
      ExampleStep(
        code: '    if precio <= 0:',
        explanation:
            'Cuatro espacios de indentación: esta línea pertenece a la función.',
      ),
      ExampleStep(
        code: '        return False',
        explanation:
            'Ocho espacios: está dentro del if, que a su vez está dentro de la '
            'función.',
      ),
      ExampleStep(
        code: '    for producto in carrito:',
        explanation:
            'El bucle recorre cada producto de la lista para acumular su precio.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: los tres pilares de la sintaxis',
    instructions: 'Relaciona cada pilar con lo que hace.',
    pairs: [
      ConceptPair(
        concept: 'Variables y nombres',
        definition:
            'Contenedores que almacenan información con nombres significativos.',
      ),
      ConceptPair(
        concept: 'Indentación',
        definition: 'Espacios en blanco que definen bloques de código.',
      ),
      ConceptPair(
        concept: 'Comentarios',
        definition: 'Notas en el código que Python ignora completamente.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 2: Números
// ---------------------------------------------------------------------------

const CourseSection _seccion2 = CourseSection(
  id: 'm2-s2',
  shortTitle: 'Números',
  videos: [
    SectionVideo(
      title: 'Ejercicios con números y condiciones (parte 1)',
      youtubeId: 'Q-UEySBt_hk',
      duration: '22:02',
      description:
          'Clase 4.2. Operadores aritméticos y de comparación en ejercicios.',
      transcript:
          'Resuelve ejercicios que combinan aritmética y comparaciones: '
          'divisiones enteras, residuos con el operador módulo para saber '
          'si un número es par, y redondeos. Es el complemento práctico '
          'de la lectura sobre enteros, decimales y operadores.',
    ),
    SectionVideo(
      title: 'Ejercicios con números y condiciones (parte 2)',
      youtubeId: 'X6bXhRSKinc',
      duration: '11:23',
      description: 'Clase 4.3. Más práctica con operaciones numéricas.',
      transcript:
          'Segunda tanda de ejercicios numéricos, con énfasis en el orden '
          'de las operaciones y en los errores que aparecen al dividir '
          'entre cero o al mezclar enteros con decimales.',
    ),
  ],
  moduleNumber: 2,
  number: 2,
  title: 'Números',
  summary:
      'Enteros y decimales, los seis operadores aritméticos y las operaciones '
      'avanzadas que usarás a diario.',
  objectives: [
    'Distinguir entre int y float y convertir entre ellos.',
    'Aplicar los seis operadores aritméticos de Python.',
    'Usar potencias, raíces, redondeos y la librería math.',
  ],
  reading: SectionReading(
    title: 'Dominando los números: el corazón de la programación',
    intro:
        'Bancos, videojuegos, inteligencia artificial, análisis de datos: todo '
        'gira alrededor de números. Python los trata de forma elegante.',
    pages: [
      ReadingPage(
        title: 'Enteros y decimales',
        summary:
            'Un int es un número sin decimales. Un float tiene punto decimal.',
        blocks: [
          ReadingBlock.code(
            title: 'Números enteros (int)',
            code:
                'edad = 25\n'
                'temperatura_bajo_cero = -15\n'
                'poblacion_mundial = 8000000000',
            body:
                'No tienen límite de tamaño, ocupan menos memoria que los '
                'decimales y son exactos: no hay errores de precisión.',
            codeCaption:
                'Tres enteros: la edad veinticinco, una temperatura de menos '
                'quince y una población de ocho mil millones.',
          ),
          ReadingBlock.code(
            title: 'Números decimales (float)',
            code:
                'precio = 19.99\n'
                'altura = 1.75\n\n'
                '# Cuidado con la precisión\n'
                'resultado = 0.1 + 0.2\n'
                'print(resultado)  # 0.30000000000000004',
            body:
                'Tienen precisión limitada, alrededor de 15 a 17 dígitos '
                'significativos, y pueden arrastrar errores minúsculos. Es un '
                'límite de las computadoras, no un fallo de Python.',
            codeCaption:
                'Se guardan dos decimales. Al sumar cero punto uno más cero '
                'punto dos el resultado no es exactamente cero punto tres, sino '
                'un número con muchos decimales.',
          ),
          ReadingBlock.code(
            title: 'Convertir entre tipos',
            code:
                'float(10)      # 10.0\n'
                'int(7.9)       # 7  — trunca, no redondea\n'
                'int("42")      # 42 — de texto a entero\n'
                'float("3.14")  # 3.14\n'
                'type(19.99)    # <class \'float\'>',
            codeCaption:
                'Se convierte un entero a decimal, un decimal a entero '
                'truncando la parte decimal, y textos a números. La función '
                'type revela de qué tipo es un valor.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Aritmética básica',
        summary: 'Python tiene seis operadores aritméticos principales.',
        blocks: [
          ReadingBlock.code(
            title: 'Los cuatro que ya conoces',
            code:
                '10 + 5    # 15  suma\n'
                '20 - 8    # 12  resta\n'
                '6 * 7     # 42  multiplicación\n'
                '20 / 4    # 5.0 división: SIEMPRE devuelve decimal',
            codeCaption:
                'Suma, resta, multiplicación y división. Ojo: la división '
                'siempre entrega un número decimal, aunque el resultado sea '
                'exacto.',
          ),
          ReadingBlock.code(
            title: 'Los dos que cambian el juego',
            code:
                '20 // 3   # 6  división entera: descarta los decimales\n'
                '20 % 3    # 2  módulo: devuelve el residuo\n\n'
                '# El módulo sirve para saber si un número es par\n'
                'if numero % 2 == 0:\n'
                '    print("Es par")\n'
                'else:\n'
                '    print("Es impar")',
            codeCaption:
                'La división entera con doble barra entrega solo la parte '
                'entera. El módulo, escrito con el símbolo de porcentaje, '
                'entrega el residuo, y por eso sirve para detectar números '
                'pares.',
          ),
          ReadingBlock.callout(
            title: 'División entre cero',
            body:
                'Dividir entre cero provoca un error llamado '
                'ZeroDivisionError y detiene el programa. Valida siempre antes '
                'de dividir.',
            tone: CalloutTone.danger,
          ),
          ReadingBlock.bullets(
            title: 'Orden de operaciones',
            body: 'Python sigue el mismo orden que las matemáticas.',
            items: [
              'Primero los paréntesis.',
              'Después los exponentes.',
              'Luego multiplicación, división, división entera y módulo.',
              'Al final suma y resta.',
              'Ejemplo: 2 + 3 por 4 da 14, pero abrir paréntesis en 2 + 3 y multiplicar por 4 da 20.',
            ],
          ),
          ReadingBlock.code(
            title: 'Asignación compuesta',
            code:
                'x = 10\n'
                'x += 5    # equivale a x = x + 5   → 15\n'
                'x -= 3    # resta                  → 12\n'
                'x *= 2    # multiplica             → 24\n'
                'x /= 2    # divide                 → 12.0',
            codeCaption:
                'Formas abreviadas de actualizar una variable sumándole, '
                'restándole, multiplicándola o dividiéndola.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Operaciones avanzadas',
        summary:
            'Potencias, raíces, redondeos, valores absolutos y la librería math.',
        blocks: [
          ReadingBlock.code(
            title: 'Potencias y raíces',
            code:
                '2 ** 3          # 8   dos elevado a tres\n'
                '10 ** 2         # 100 diez al cuadrado\n'
                '2 ** -1         # 0.5 el inverso\n\n'
                'import math\n'
                'math.sqrt(16)   # 4.0 raíz cuadrada\n'
                '27 ** (1/3)     # 3.0 raíz cúbica con potencias',
            codeCaption:
                'El doble asterisco eleva a una potencia. La función raíz '
                'cuadrada viene en la librería math. Una raíz cúbica se obtiene '
                'elevando a un tercio.',
          ),
          ReadingBlock.code(
            title: 'Redondeos y valor absoluto',
            code:
                'round(3.7)        # 4\n'
                'round(3.14159, 2) # 3.14 — a dos decimales\n'
                'int(3.9)          # 3    — trunca, no redondea\n'
                'abs(-15)          # 15   — valor sin signo\n\n'
                'min([5, 2, 8, 1]) # 1\n'
                'max([5, 2, 8, 1]) # 9 si la lista tuviera 9',
            codeCaption:
                'La función round redondea, opcionalmente a un número de '
                'decimales. La función int trunca. La función abs quita el '
                'signo. Las funciones min y max entregan el menor y el mayor de '
                'una lista.',
          ),
          ReadingBlock.code(
            title: 'Constantes y números aleatorios',
            code:
                'import math\n'
                'math.pi            # 3.141592653589793\n'
                'math.e             # 2.718281828459045\n'
                'math.log10(100)    # 2.0\n\n'
                'import random\n'
                'random.random()       # decimal entre 0 y 1\n'
                'random.randint(1, 10) # entero entre 1 y 10, ambos incluidos\n'
                'random.choice(colores)  # elige un elemento de la lista',
            codeCaption:
                'La librería math trae pi, el número e y logaritmos. La librería '
                'random genera decimales aleatorios, enteros dentro de un rango '
                'y elige elementos al azar de una lista.',
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuál es la diferencia principal entre 20 / 4 y 20 // 4?',
      options: [
        'No hay diferencia, ambos dan el mismo resultado',
        'La barra simple devuelve un decimal (5.0) y la doble barra un entero (5)',
        'La barra simple es para decimales y la doble para enteros negativos',
        'La doble barra es más rápida',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál es el resultado de 20 % 3 en Python?',
      options: ['6', '6.666...', '2', '20'],
      correctIndex: 2,
      explanation: 'El módulo devuelve el residuo: 3 por 6 son 18, y sobran 2.',
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuál de los siguientes es un número float en Python?',
      options: ['10', '-5', '3.14', '0'],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Cuál es el resultado de la operación 2 + 3 * 4 - 1?',
      options: ['19', '13', '23', '12'],
      correctIndex: 1,
      explanation:
          'Primero se multiplica 3 por 4, que da 12. Luego 2 más 12 menos 1 da '
          '13.',
    ),
    QuizQuestion(
      prompt: '¿Para qué sirve el operador módulo en Python?',
      options: [
        'Para multiplicar números',
        'Para obtener el residuo de una división',
        'Para obtener el porcentaje de un número',
        'Para redondear números',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál es la forma correcta de calcular 5 elevado a la potencia 3?',
      options: ['5 ^ 3', '5 ** 3', '5 ^^ 3', 'raiz(5, 3)'],
      correctIndex: 1,
      explanation:
          'Se usa el doble asterisco. La función pow(5, 3) también funciona.',
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: los números no mienten',
    headline: 'Entiende los números, domina la lógica',
    intro:
        'Los números en programación no son solo matemáticas: son información '
        'procesada. Cada cálculo tiene un propósito.',
    tips: [
      CapsuleTip(
        title: 'Elige el tipo correcto',
        body:
            'Si trabajas con dinero, importa cada centavo. Si trabajas con '
            'distancias, los decimales son normales. Elige el tipo que mejor '
            'represente tu dato.',
      ),
      CapsuleTip(
        title: 'Cuidado con la precisión',
        body:
            'Los float tienen limitaciones: 0.1 más 0.2 no es exactamente 0.3. '
            'Para aplicaciones críticas como dinero o ciencia existe el tipo '
            'Decimal.',
      ),
      CapsuleTip(
        title: 'Cada operador resuelve un problema distinto',
        body:
            'La barra simple es división real, la doble barra sirve para '
            'repartir en grupos, y el módulo entrega residuos. No son '
            'intercambiables.',
      ),
    ],
    closing:
        'Los números son el lenguaje con el que tu programa razona sobre el '
        'mundo.',
  ),
  example: CodeExample(
    title: 'Calculadora de compras con descuentos e impuestos',
    description:
        'Recorre una lista de artículos, calcula subtotal, aplica descuento e '
        'impuesto, y reparte el total en cuotas usando división entera y '
        'módulo.',
    code:
        'articulos = [\n'
        "    {'nombre': 'Laptop', 'precio': 800.00, 'cantidad': 1},\n"
        "    {'nombre': 'Mouse', 'precio': 25.50, 'cantidad': 2},\n"
        "    {'nombre': 'Teclado', 'precio': 75.00, 'cantidad': 1}\n"
        ']\n\n'
        'descuento_porcentaje = 10\n'
        'impuesto_porcentaje = 21\n\n'
        'subtotal = 0\n'
        'for articulo in articulos:\n'
        "    subtotal += articulo['precio'] * articulo['cantidad']\n\n"
        'descuento = subtotal * (descuento_porcentaje / 100)\n'
        'subtotal_con_descuento = subtotal - descuento\n'
        'impuesto = round(subtotal_con_descuento * (impuesto_porcentaje / 100), 2)\n'
        'total = subtotal_con_descuento + impuesto\n\n'
        'print(f"Subtotal: {subtotal:.2f}")\n'
        'print(f"Descuento: {descuento:.2f}")\n'
        'print(f"Impuesto: {impuesto:.2f}")\n'
        'print(f"TOTAL A PAGAR: {total:.2f}")\n\n'
        '# Repartir en 12 cuotas con división entera y módulo\n'
        'cuotas = 12\n'
        'cuota_fija = int(total) // cuotas\n'
        'residuo = int(total) % cuotas\n'
        'print(f"En {cuotas} cuotas: {cuota_fija} fijo + {residuo} en la última")',
    codeCaption:
        'Se recorre una lista de artículos multiplicando precio por cantidad '
        'para obtener el subtotal. Luego se aplica un descuento del diez por '
        'ciento, se calcula el impuesto del veintiuno por ciento redondeado a '
        'dos decimales, y por último se reparte el total en doce cuotas usando '
        'división entera y módulo.',
    output:
        'Subtotal: 926.00\n'
        'Descuento: 92.60\n'
        'Impuesto: 174.81\n'
        'TOTAL A PAGAR: 1008.21\n'
        'En 12 cuotas: 84 fijo + 1 en la última',
    steps: [
      ExampleStep(
        code: "subtotal += articulo['precio'] * articulo['cantidad']",
        explanation:
            'Multiplicación y acumulación en la misma línea: el subtotal crece '
            'en cada vuelta del bucle.',
      ),
      ExampleStep(
        code: 'descuento = subtotal * (descuento_porcentaje / 100)',
        explanation:
            'Un porcentaje se aplica dividiendo entre 100 y multiplicando.',
      ),
      ExampleStep(
        code: 'round(subtotal_con_descuento * (impuesto_porcentaje / 100), 2)',
        explanation:
            'round con un segundo argumento redondea a ese número de decimales: '
            'imprescindible cuando hablamos de dinero.',
      ),
      ExampleStep(
        code: 'cuota_fija = int(total) // cuotas',
        explanation:
            'División entera: cuánto paga completo cada cuota, sin decimales.',
      ),
      ExampleStep(
        code: 'residuo = int(total) % cuotas',
        explanation:
            'Módulo: lo que sobra del reparto y se suma a la última cuota.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: operadores en contexto',
    instructions: 'Relaciona cada operador con el problema que resuelve.',
    pairs: [
      ConceptPair(
        concept: 'Barra simple: /',
        definition: 'División real: siempre devuelve un número decimal.',
      ),
      ConceptPair(
        concept: 'Doble barra: //',
        definition:
            'División entera: cuántos grupos completos caben, sin decimales.',
      ),
      ConceptPair(
        concept: 'Porcentaje: %',
        definition:
            'Módulo: el residuo de una división. Sirve para saber si un número '
            'es par o impar.',
      ),
      ConceptPair(
        concept: 'Doble asterisco: **',
        definition: 'Potencia: eleva un número a un exponente.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 3: Cadenas de texto
// ---------------------------------------------------------------------------

const CourseSection _seccion3 = CourseSection(
  id: 'm2-s3',
  shortTitle: 'Cadenas\nde texto',
  videos: [
    SectionVideo(
      title: 'Índices y recorridos (parte 1)',
      youtubeId: 'DlsX6uNlgzo',
      duration: '24:27',
      description:
          'Clase 11.1. Acceder por posición, la misma mecánica de las cadenas.',
      transcript:
          'Explica cómo se accede a los elementos de una secuencia por su '
          'posición, empezando en cero, y cómo se recorren con un bucle. '
          'Es exactamente la mecánica que usan las cadenas de texto para '
          'la indexación y el slicing que estudias en esta sección.',
    ),
    SectionVideo(
      title: 'Índices y recorridos (parte 2)',
      youtubeId: 'LrGNfnGdl1U',
      duration: '21:05',
      description: 'Clase 11.2. Buscar, contar y recorrer secuencias.',
      transcript:
          'Continúa con búsquedas dentro de una secuencia, conteo de '
          'apariciones y recorridos parciales. Los mismos patrones se '
          'aplican a los métodos find, count y al slicing de cadenas.',
    ),
  ],
  moduleNumber: 2,
  number: 3,
  title: 'Cadenas de texto',
  summary:
      'Crear, unir, cortar, buscar y comparar texto: el lenguaje con el que tu '
      'programa habla con las personas.',
  objectives: [
    'Crear y concatenar cadenas usando f-strings.',
    'Aplicar los métodos básicos de transformación y limpieza.',
    'Extraer partes de un texto con indexación y slicing.',
    'Buscar y comparar cadenas.',
  ],
  reading: SectionReading(
    title: 'Dominando las cadenas: el arte de manipular palabras',
    intro:
        'Si los números son el lenguaje de las máquinas, las cadenas son el '
        'lenguaje de las personas. Probablemente pasarás más tiempo con texto '
        'que con números.',
    pages: [
      ReadingPage(
        title: 'Creación y concatenación',
        summary:
            'Una cadena es cualquier texto entre comillas. Unirlas se llama '
            'concatenar.',
        blocks: [
          ReadingBlock.code(
            title: 'Crear cadenas',
            code:
                "nombre = \"Juan\"\n"
                "apellido = 'García'   # comillas simples o dobles, da igual\n"
                'vacio = ""            # cadena vacía\n\n'
                'poema = """\n'
                'Varias líneas\n'
                'se escriben con\n'
                'triple comilla.\n'
                '"""',
            codeCaption:
                'Las cadenas se escriben entre comillas simples o dobles, '
                'indistintamente. Para texto de varias líneas se usan tres '
                'comillas al abrir y al cerrar.',
          ),
          ReadingBlock.code(
            title: 'f-strings: la forma moderna',
            code:
                'nombre = "María"\n'
                'edad = 28\n\n'
                'mensaje = f"Me llamo {nombre} y tengo {edad} años"\n\n'
                '# También admiten expresiones dentro de las llaves\n'
                'precio = 19.99\n'
                'cantidad = 3\n'
                'total = f"Total: {precio * cantidad}"',
            body:
                'Poner una f antes de las comillas permite insertar variables '
                'directamente entre llaves. Es más legible que concatenar con el '
                'signo más.',
            codeCaption:
                'Anteponiendo la letra efe a las comillas se pueden insertar '
                'variables dentro del texto escribiéndolas entre llaves, e '
                'incluso hacer cálculos ahí mismo.',
          ),
          ReadingBlock.code(
            title: 'Otras formas de unir y repetir',
            code:
                'nombre_completo = nombre + " " + apellido   # con el signo más\n'
                '"Hola {}".format(nombre)                    # con format\n\n'
                'print("=" * 50)   # repite un carácter 50 veces\n'
                'print("la" * 3)   # lalala',
            codeCaption:
                'Se puede unir texto con el signo más o con el método format. '
                'Multiplicar un texto por un número lo repite, lo que sirve para '
                'dibujar separadores.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Operaciones básicas',
        summary:
            'Medir, cambiar mayúsculas, limpiar espacios, reemplazar, dividir y '
            'unir.',
        blocks: [
          ReadingBlock.code(
            title: 'Longitud y mayúsculas',
            code:
                'len("Python")          # 6 caracteres\n\n'
                'texto = "Python es Genial"\n'
                'texto.upper()          # PYTHON ES GENIAL\n'
                'texto.lower()          # python es genial\n'
                'texto.capitalize()     # Python es genial\n'
                'texto.title()          # Python Es Genial',
            codeCaption:
                'La función len cuenta caracteres. Los métodos upper y lower '
                'pasan todo a mayúsculas o minúsculas, capitalize solo la '
                'primera letra y title la primera letra de cada palabra.',
          ),
          ReadingBlock.code(
            title: 'Limpiar espacios y reemplazar',
            code:
                'texto = "  Python  "\n'
                'texto.strip()    # "Python"  quita espacios a ambos lados\n'
                'texto.lstrip()   # quita solo a la izquierda\n'
                'texto.rstrip()   # quita solo a la derecha\n\n'
                '"Python es fácil".replace("fácil", "poderoso")\n'
                '# → "Python es poderoso"',
            body:
                'strip es imprescindible al leer datos que escribe una persona: '
                'casi siempre traen espacios de más.',
            codeCaption:
                'El método strip elimina espacios al inicio y al final. El '
                'método replace cambia una parte del texto por otra.',
          ),
          ReadingBlock.code(
            title: 'Dividir y unir',
            code:
                '"manzana,platano,naranja".split(",")\n'
                "# → ['manzana', 'platano', 'naranja']\n\n"
                '"Hola mundo de Python".split()\n'
                "# → ['Hola', 'mundo', 'de', 'Python']\n\n"
                '", ".join(["huevo", "queso", "pan"])\n'
                '# → "huevo, queso, pan"',
            codeCaption:
                'El método split parte un texto en una lista usando un '
                'separador; sin argumentos parte por espacios. El método join '
                'hace lo contrario: une una lista en un solo texto.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Indexación y extracción',
        summary:
            'Cada carácter tiene una posición. Con slicing extraes cualquier '
            'trozo.',
        blocks: [
          ReadingBlock.code(
            title: 'Posiciones, empezando en cero',
            code:
                'texto = "Python"\n\n'
                'texto[0]    # P  primer carácter\n'
                'texto[5]    # n  sexto carácter\n'
                'texto[-1]   # n  último carácter\n'
                'texto[-2]   # o  penúltimo\n\n'
                '# Texto:     P   y   t   h   o   n\n'
                '# Índice:    0   1   2   3   4   5\n'
                '# Negativo: -6  -5  -4  -3  -2  -1',
            codeCaption:
                'Los caracteres se numeran desde cero por la izquierda y desde '
                'menos uno por la derecha. El índice menos uno siempre es el '
                'último carácter.',
          ),
          ReadingBlock.code(
            title: 'Slicing: inicio, fin y paso',
            code:
                'texto[0:2]   # "Py"     desde 0 hasta 2 sin incluir el 2\n'
                'texto[2:]    # "thon"   desde 2 hasta el final\n'
                'texto[:3]    # "Pyt"    desde el inicio hasta el 3\n'
                'texto[::2]   # "Pto"    de dos en dos\n'
                'texto[::-1]  # "nohtyP" invierte la cadena',
            codeCaption:
                'Entre corchetes se indican inicio, fin y paso separados por dos '
                'puntos. El fin nunca se incluye. Un paso de menos uno invierte '
                'el texto.',
          ),
          ReadingBlock.code(
            title: 'Caso práctico: descomponer una fecha',
            code:
                'fecha = "2024-12-25"\n\n'
                'anio = fecha[0:4]   # "2024"\n'
                'mes = fecha[5:7]    # "12"\n'
                'dia = fecha[8:10]   # "25"\n\n'
                'print(f"La fecha es {dia}/{mes}/{anio}")',
            codeCaption:
                'De un texto con formato año guion mes guion día se extraen las '
                'tres partes por posición y se reordenan.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Búsqueda y comparación',
        summary:
            'Saber si algo existe, dónde está, cuántas veces aparece y si dos '
            'textos son iguales.',
        blocks: [
          ReadingBlock.code(
            title: 'Buscar',
            code:
                'texto = "Python es un lenguaje de programación"\n\n'
                'if "Python" in texto:        # True\n'
                '    print("Encontrado")\n\n'
                'texto.find("lenguaje")       # 14 — posición donde empieza\n'
                'texto.find("Java")           # -1 — no existe\n'
                'texto.count("a")             # cuántas veces aparece\n\n'
                '"documento.pdf".endswith(".pdf")   # True\n'
                '"Python es genial".startswith("Python")  # True',
            codeCaption:
                'La palabra in comprueba si un texto está dentro de otro. El '
                'método find devuelve la posición, o menos uno si no lo '
                'encuentra. El método count cuenta apariciones, y startswith y '
                'endswith comprueban el inicio y el final.',
          ),
          ReadingBlock.code(
            title: 'Comparar',
            code:
                '"Python" == "Python"   # True\n'
                '"Python" == "python"   # False — distingue mayúsculas\n\n'
                '# Comparar ignorando mayúsculas\n'
                'if texto1.lower() == texto2.lower():\n'
                '    print("Son iguales")\n\n'
                '"apple" < "banana"     # True — orden alfabético\n\n'
                'nombres = ["Carlos", "Ana", "Beatriz"]\n'
                "nombres.sort()         # ['Ana', 'Beatriz', 'Carlos']",
            codeCaption:
                'El doble igual compara dos textos y distingue mayúsculas. Para '
                'ignorarlas se pasa todo a minúsculas antes. Los operadores '
                'menor y mayor comparan alfabéticamente, y sort ordena una '
                'lista.',
          ),
          ReadingBlock.code(
            title: 'Validar contenido',
            code:
                '"12345".isdigit()    # True  — solo dígitos\n'
                '"Python".isalpha()   # True  — solo letras\n'
                '"Python123".isalnum() # True — letras y números\n'
                '"PYTHON".isupper()   # True\n'
                '"   ".isspace()      # True  — solo espacios',
            codeCaption:
                'Existen métodos que responden verdadero o falso según el '
                'contenido: si son solo dígitos, solo letras, letras y números, '
                'mayúsculas o solo espacios.',
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          'Si texto vale "Python", ¿cuál es el resultado de imprimir texto[1:4]?',
      options: ['Pto', 'yth', 'thon', 'P'],
      correctIndex: 1,
      explanation:
          'Toma los caracteres en las posiciones 1, 2 y 3. La posición 4 no se '
          'incluye.',
    ),
    QuizQuestion(
      prompt:
          '¿Cuál es la forma más moderna y legible de construir el texto "Hola, '
          'Juan! Tienes 25 años"?',
      options: [
        'Concatenando con el signo más',
        'Usando el método format con índices',
        'Usando un f-string: f"Hola, {nombre}! Tienes {edad} años"',
        'Usando el operador de porcentaje al estilo antiguo',
      ],
      correctIndex: 2,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt:
          '¿Cuál de los siguientes métodos elimina espacios al inicio y al '
          'final de una cadena?',
      options: ['remove()', 'delete()', 'strip()', 'clean()'],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: 'Si palabra vale "gato", ¿cuál es el resultado de palabra * 3?',
      options: ['Error', 'La lista con gato tres veces', 'gatogatogato', '3'],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Qué devuelve el método find() cuando no encuentra el texto?',
      options: ['0', 'True', '-1', 'None'],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Qué hace texto[::-1]?',
      options: [
        'Elimina el último carácter',
        'Invierte la cadena completa',
        'Devuelve solo el primer carácter',
        'Provoca un error de sintaxis',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: las cadenas son oro',
    headline: 'Manipula texto como un mago',
    intro:
        'Las cadenas no son solo palabras: son datos que hablan. Cada nombre, '
        'cada mensaje, cada correo es una cadena que tu código puede entender, '
        'buscar, modificar y rearmar.',
    tips: [
      CapsuleTip(
        title: 'Indexación y slicing',
        body:
            'Acceder a partes específicas sin crear cadenas intermedias '
            'innecesarias. texto[0:5] es más elegante y eficiente que concatenar.',
      ),
      CapsuleTip(
        title: 'Búsqueda y validación',
        body:
            'Saber si algo existe con in, dónde está con find y cuántas veces '
            'aparece con count. Son las herramientas de todo programa que '
            'procesa datos.',
      ),
      CapsuleTip(
        title: 'Transformación',
        body:
            'Limpiar con strip, convertir con upper y lower, reemplazar con '
            'replace. Así los datos sucios se vuelven datos limpios.',
      ),
    ],
    closing:
        'Los datos del mundo real nunca vienen perfectos: habrá espacios extra '
        'y mayúsculas inconsistentes. Tus herramientas de cadenas son lo que '
        'hace tu código robusto.',
  ),
  example: CodeExample(
    title: 'Validar y limpiar el registro de un usuario',
    description:
        'Limpia el nombre, valida el correo y formatea el teléfono usando solo '
        'métodos de cadenas.',
    code:
        'def validar_y_limpiar_nombre(nombre):\n'
        '    """Valida y limpia un nombre de usuario."""\n'
        '    nombre = nombre.strip()\n\n'
        '    if len(nombre) == 0:\n'
        '        return None, "El nombre no puede estar vacío"\n'
        '    if len(nombre) < 2:\n'
        '        return None, "El nombre debe tener al menos 2 caracteres"\n\n'
        '    return nombre.title(), "Válido"\n\n\n'
        'def validar_email(email):\n'
        '    """Valida que el email tenga formato correcto."""\n'
        '    email = email.strip().lower()\n\n'
        '    if "@" not in email:\n'
        '        return False, "El email debe contener arroba"\n\n'
        '    partes = email.split("@")\n'
        '    if len(partes) != 2:\n'
        '        return False, "Formato incorrecto"\n\n'
        '    usuario, dominio = partes\n'
        '    if len(usuario) == 0:\n'
        '        return False, "Falta el usuario antes de la arroba"\n'
        '    if "." not in dominio:\n'
        '        return False, "El dominio debe contener un punto"\n\n'
        '    return True, "Válido"\n\n\n'
        'def limpiar_telefono(telefono):\n'
        '    """Deja solo dígitos y aplica el formato final."""\n'
        '    telefono = telefono.replace(" ", "").replace("-", "")\n\n'
        '    if not telefono.isdigit():\n'
        '        return None, "El teléfono debe contener solo dígitos"\n'
        '    if len(telefono) != 10:\n'
        '        return None, "El teléfono debe tener 10 dígitos"\n\n'
        '    return f"({telefono[0:3]}) {telefono[3:6]}-{telefono[6:10]}", "Válido"\n\n\n'
        'print(validar_y_limpiar_nombre("  juan garcia  "))\n'
        'print(validar_email("Juan.Garcia@GMAIL.com"))\n'
        'print(limpiar_telefono("555-123-4567"))',
    codeCaption:
        'Tres funciones de validación. La primera quita espacios y pone el '
        'nombre con mayúscula inicial. La segunda pasa el correo a minúsculas y '
        'comprueba que tenga arroba y punto en el dominio. La tercera elimina '
        'espacios y guiones del teléfono, verifica que queden diez dígitos y lo '
        'devuelve con formato de paréntesis y guion.',
    output:
        "('Juan Garcia', 'Válido')\n"
        "(True, 'Válido')\n"
        "('(555) 123-4567', 'Válido')",
    steps: [
      ExampleStep(
        code: 'nombre = nombre.strip()',
        explanation:
            'Primer paso siempre: quitar los espacios que sobran al inicio y al '
            'final.',
      ),
      ExampleStep(
        code: 'return nombre.title(), "Válido"',
        explanation:
            'title pone en mayúscula la primera letra de cada palabra: "juan '
            'garcia" se convierte en "Juan Garcia".',
      ),
      ExampleStep(
        code: 'email = email.strip().lower()',
        explanation:
            'Los métodos se encadenan: primero limpia y después pasa todo a '
            'minúsculas, porque los correos no distinguen mayúsculas.',
      ),
      ExampleStep(
        code: 'partes = email.split("@")',
        explanation:
            'Partir por la arroba deja el usuario en la posición 0 y el dominio '
            'en la 1.',
      ),
      ExampleStep(
        code: 'telefono.replace(" ", "").replace("-", "")',
        explanation:
            'Dos replace encadenados eliminan espacios y guiones de una sola '
            'pasada.',
      ),
      ExampleStep(
        code: 'f"({telefono[0:3]}) {telefono[3:6]}-{telefono[6:10]}"',
        explanation:
            'Slicing dentro de un f-string: se cortan tres trozos y se arman con '
            'el formato deseado.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: las tres habilidades con cadenas',
    instructions: 'Relaciona cada habilidad con lo que permite hacer.',
    pairs: [
      ConceptPair(
        concept: 'Creación y concatenación',
        definition:
            'Crear cadenas de texto y unirlas usando el signo más o f-strings.',
      ),
      ConceptPair(
        concept: 'Operaciones básicas',
        definition:
            'Métodos para modificar cadenas: mayúsculas, minúsculas y limpieza '
            'de espacios.',
      ),
      ConceptPair(
        concept: 'Indexación y extracción',
        definition:
            'Acceder a caracteres o a partes de una cadena usando índices y '
            'slicing.',
      ),
    ],
  ),
);
