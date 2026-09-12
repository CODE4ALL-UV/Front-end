import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 3. Control de flujo — Decisiones, bucles y clases.
///
/// Nota de contenido: el material entregado para la tercera sección de este
/// módulo corresponde a "Clases y programación orientada a objetos", no a
/// "Manejo de errores" como decía el título anterior en la app. El catálogo
/// sigue al contenido.
const CourseModule module3 = CourseModule(
  number: 3,
  title: 'Control de flujo',
  sections: [_seccion1, _seccion2, _seccion3],
);

// ---------------------------------------------------------------------------
// Capítulo 1: Estructuras de decisión
// ---------------------------------------------------------------------------

const CourseSection _seccion1 = CourseSection(
  id: 'm3-s1',
  shortTitle: 'Estructuras\nde decisión',
  videos: [
    SectionVideo(
      title: 'Condicionales anidados',
      youtubeId: 'GRJbJrREmK8',
      duration: '31:34',
      description:
          'Clase 4.1. Decisiones dentro de decisiones y cómo simplificarlas.',
      transcript:
          'Muestra cómo se anidan varios if y, sobre todo, cuándo '
          'conviene sustituir esa anidación por condiciones combinadas '
          'con and y or o por una cadena de elif. Termina con el orden '
          'correcto en que hay que escribir las condiciones para que '
          'ninguna quede inalcanzable.',
    ),
  ],
  moduleNumber: 3,
  number: 1,
  title: 'Estructuras de decisión',
  summary:
      'Operadores de comparación y lógicos, if-else, elif y match-case: lo que '
      'hace que tu programa reaccione.',
  objectives: [
    'Usar los operadores de comparación y lógicos.',
    'Escribir decisiones con if, else y elif.',
    'Aplicar match-case cuando corresponde.',
    'Elegir entre if y match según el caso.',
  ],
  reading: SectionReading(
    title: 'Tomando decisiones: el poder del control de flujo',
    intro:
        'Un programa que solo ejecuta línea por línea es aburrido. Uno que toma '
        'decisiones es inteligente.',
    pages: [
      ReadingPage(
        title: 'Operadores de comparación',
        summary:
            'Comparan dos valores y devuelven verdadero o falso. Son el '
            'cimiento de toda decisión.',
        blocks: [
          ReadingBlock.code(
            title: 'Los seis operadores',
            code:
                '5 == 5      # True   igualdad\n'
                '5 != 3      # True   desigualdad\n'
                '10 > 5      # True   mayor que\n'
                '3 < 7       # True   menor que\n'
                '5 >= 5      # True   mayor o igual\n'
                '3 <= 7      # True   menor o igual\n\n'
                '"manzana" in frutas   # ¿está dentro de la lista?',
            codeCaption:
                'Igual igual compara, admiración igual comprueba que sean '
                'distintos, y los signos mayor y menor comparan tamaños. La '
                'palabra in comprueba si un elemento está dentro de una '
                'colección.',
          ),
          ReadingBlock.callout(
            title: 'No confundas un igual con dos',
            body:
                'Un solo signo igual asigna: x = 5 significa "el valor de x '
                'ahora es 5". Dos signos igual comparan: x == 5 pregunta "¿es x '
                'igual a 5?". Usar uno solo dentro de un if provoca un error de '
                'sintaxis.',
            tone: CalloutTone.danger,
          ),
        ],
      ),
      ReadingPage(
        title: 'Operadores lógicos',
        summary:
            'and, or y not combinan condiciones para expresar lógica compleja.',
        blocks: [
          ReadingBlock.code(
            title: 'and: se deben cumplir todas',
            code:
                'edad = 25\n'
                'tiene_licencia = True\n\n'
                'if edad >= 18 and tiene_licencia:\n'
                '    print("Puedes conducir")\n\n'
                '# Tabla de verdad\n'
                'True and True    # True\n'
                'True and False   # False\n'
                'False and False  # False',
            codeCaption:
                'El operador and solo entrega verdadero cuando todas las '
                'condiciones son verdaderas.',
          ),
          ReadingBlock.code(
            title: 'or: basta con una',
            code:
                'es_fin_de_semana = False\n'
                'es_feriado = True\n\n'
                'if es_fin_de_semana or es_feriado:\n'
                '    print("¡No hay clase!")\n\n'
                'True or False    # True\n'
                'False or False   # False',
            codeCaption:
                'El operador or entrega verdadero si al menos una condición lo '
                'es.',
          ),
          ReadingBlock.code(
            title: 'not: invierte el valor',
            code:
                'esta_lloviendo = False\n\n'
                'if not esta_lloviendo:\n'
                '    print("Puedo salir")\n\n'
                '# Precedencia: primero not, luego and, al final or.\n'
                '# Usa paréntesis para que se lea claro:\n'
                'if (edad >= 18) and (tiene_dinero or tiene_tiempo):\n'
                '    print("Puedes salir")',
            codeCaption:
                'El operador not convierte verdadero en falso y viceversa. El '
                'orden de evaluación es not, después and y por último or; los '
                'paréntesis lo hacen explícito.',
          ),
        ],
      ),
      ReadingPage(
        title: 'If, else y elif',
        summary: 'Una condición, dos caminos, o tantos caminos como necesites.',
        blocks: [
          ReadingBlock.code(
            title: 'Dos caminos',
            code:
                'edad = 15\n\n'
                'if edad >= 18:\n'
                '    print("Eres mayor de edad")\n'
                'else:\n'
                '    print("Eres menor de edad")',
            codeCaption:
                'Si la edad llega a dieciocho imprime que eres mayor de edad; en '
                'caso contrario imprime que eres menor.',
          ),
          ReadingBlock.code(
            title: 'Muchos caminos con elif',
            code:
                'nota = 85\n\n'
                'if nota >= 90:\n'
                '    print("Calificación: A (Excelente)")\n'
                'elif nota >= 80:\n'
                '    print("Calificación: B (Muy bien)")\n'
                'elif nota >= 70:\n'
                '    print("Calificación: C (Bien)")\n'
                'elif nota >= 60:\n'
                '    print("Calificación: D (Pasable)")\n'
                'else:\n'
                '    print("Calificación: F (Reprobado)")',
            codeCaption:
                'Se comprueban rangos de nota de mayor a menor. Con ochenta y '
                'cinco puntos el resultado es la letra B.',
          ),
          ReadingBlock.callout(
            title: 'El orden importa muchísimo',
            body:
                'Python evalúa de arriba hacia abajo y se detiene en el primer '
                'if o elif que sea verdadero. Si tu primera condición captura '
                'todos los casos, las siguientes nunca se ejecutarán aunque '
                'también sean ciertas.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
      ReadingPage(
        title: 'Match-case y cuándo usar cada estructura',
        summary:
            'Desde Python 3.10, match-case ofrece una forma limpia de comparar '
            'una variable contra muchos valores.',
        blocks: [
          ReadingBlock.code(
            title: 'match-case',
            code:
                'estado = "en_camino"\n\n'
                'match estado:\n'
                '    case "pendiente":\n'
                '        print("Tu pedido está siendo preparado")\n'
                '    case "en_camino":\n'
                '        print("Tu pedido está en camino")\n'
                '    case "entregado":\n'
                '        print("Tu pedido ha sido entregado")\n'
                '    case _:\n'
                '        print("Estado desconocido")',
            body:
                'El guion bajo es el caso por defecto: hace lo mismo que un '
                'else.',
            codeCaption:
                'Según el valor de la variable estado se imprime un mensaje '
                'distinto. El último caso, escrito con guion bajo, atrapa '
                'cualquier valor no previsto.',
          ),
          ReadingBlock.code(
            title: 'Varios valores en un mismo caso',
            code:
                'match color:\n'
                '    case "rojo" | "naranja" | "amarillo":\n'
                '        print("Es color cálido")\n'
                '    case "azul" | "verde" | "morado":\n'
                '        print("Es color frío")\n'
                '    case _:\n'
                '        print("Color desconocido")',
            codeCaption:
                'La barra vertical permite agrupar varios valores dentro de un '
                'mismo caso.',
          ),
          ReadingBlock.bullets(
            title: '¿Cuál uso?',
            items: [
              'Usa if-elif-else cuando tengas condiciones complejas con operadores lógicos, o cuando compares rangos con mayor y menor.',
              'Usa match-case cuando compares una sola variable contra varios valores concretos y quieras código más limpio.',
              'Evita anidar demasiados if: suele ser más legible combinar condiciones con and y or.',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          'Si edad vale 20, ¿qué imprime "if edad >= 18 and edad < 30" seguido '
          'de "Eres adulto joven"?',
      options: [
        'No eres adulto joven',
        'Eres adulto joven',
        'Error de sintaxis',
        'No imprime nada',
      ],
      correctIndex: 1,
      explanation: 'Ambas condiciones se cumplen, así que el and es verdadero.',
    ),
    QuizQuestion(
      prompt: '¿Qué hace el operador not en Python?',
      options: [
        'Suma dos valores',
        'Invierte el valor booleano: verdadero pasa a falso y falso a verdadero',
        'Compara si dos valores son diferentes',
        'Multiplica valores lógicos',
      ],
      correctIndex: 1,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuál es la diferencia principal entre = y ==?',
      options: [
        'Hacen lo mismo',
        'Un igual asigna un valor y dos iguales comparan si dos valores son iguales',
        'El de un igual se usa en if y el de dos en bucles',
        'El de dos iguales es más rápido',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          'Si numero vale 15 y el código pregunta primero si es mayor que 20 y '
          'luego si es mayor que 10, ¿qué imprime?',
      options: ['Mayor', 'Intermedio', 'Menor', 'Mayor e Intermedio'],
      correctIndex: 1,
      explanation:
          'La primera condición falla, la segunda se cumple, y Python se '
          'detiene ahí.',
    ),
    QuizQuestion(
      prompt: '¿Cuáles son los operadores lógicos en Python?',
      options: ['and, or, xor', 'and, or, not', 'if, else, elif', '&&, ||, !'],
      correctIndex: 1,
      explanation:
          'Python usa las palabras and, or y not. No existe xor como palabra '
          'clave.',
    ),
    QuizQuestion(
      prompt: '¿Qué representa el guion bajo en un bloque match-case?',
      options: [
        'Una variable temporal',
        'El caso por defecto, equivalente a un else',
        'Un comentario',
        'Un error de sintaxis',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: las decisiones dan vida al código',
    headline: 'Entiende las condiciones, controla el flujo',
    intro:
        'Un programa sin decisiones es una máquina sin voluntad: solo cálculo '
        'lineal. Un programa con decisiones reacciona, responde y se adapta.',
    tips: [
      CapsuleTip(
        title: 'Los operadores lógicos son el lenguaje de la lógica',
        body:
            'and, or y not no son solo símbolos: son con lo que expresas '
            'pensamiento complejo. Domínalos y podrás describir cualquier regla.',
      ),
      CapsuleTip(
        title: 'El orden importa en elif',
        body:
            'Python evalúa de arriba hacia abajo y se detiene en el primero que '
            'es verdadero. Ordena tus condiciones de la más específica a la más '
            'general.',
      ),
      CapsuleTip(
        title: 'Elige la herramienta correcta',
        body:
            'if para lógica compleja, match para opciones simples. No uses un '
            'martillo cuando necesitas un destornillador.',
      ),
    ],
    closing:
        'Las decisiones son lo que separa un programa mediocre de uno '
        'excelente.',
  ),
  example: CodeExample(
    title: 'Sistema de calificación de estudiantes',
    description:
        'Convierte la nota numérica en letra con if-elif, describe la letra con '
        'match-case y combina nota y asistencia con operadores lógicos.',
    code:
        'def obtener_letra_calificacion(nota):\n'
        '    """Convierte una nota de 0 a 100 en letra."""\n'
        '    if nota >= 90:\n'
        '        return "A"\n'
        '    elif nota >= 80:\n'
        '        return "B"\n'
        '    elif nota >= 70:\n'
        '        return "C"\n'
        '    elif nota >= 60:\n'
        '        return "D"\n'
        '    else:\n'
        '        return "F"\n\n\n'
        'def obtener_descripcion(letra):\n'
        '    """Describe la calificación usando match-case."""\n'
        '    match letra:\n'
        '        case "A":\n'
        '            return "Excelente"\n'
        '        case "B":\n'
        '            return "Muy bien"\n'
        '        case "C":\n'
        '            return "Bien"\n'
        '        case "D":\n'
        '            return "Pasable"\n'
        '        case "F":\n'
        '            return "Reprobado"\n'
        '        case _:\n'
        '            return "Calificación inválida"\n\n\n'
        'def evaluar(nombre, nota, asistencia):\n'
        '    # Validar rangos antes de decidir nada\n'
        '    if not (0 <= nota <= 100):\n'
        '        print("Error: la nota debe estar entre 0 y 100")\n'
        '        return\n\n'
        '    letra = obtener_letra_calificacion(nota)\n'
        '    print(f"{nombre}: {nota}/100 → {letra} ({obtener_descripcion(letra)})")\n\n'
        '    # Condiciones combinadas\n'
        '    if nota >= 80 and asistencia >= 90:\n'
        '        print("Excelente desempeño en nota y asistencia")\n'
        '    elif nota >= 70 or asistencia >= 95:\n'
        '        print("Buen desempeño")\n'
        '    else:\n'
        '        print("Desempeño bajo: conviene reforzar")\n\n\n'
        'evaluar("Juan García", 92, 98)\n'
        'evaluar("Ana Martínez", 65, 75)',
    codeCaption:
        'Tres funciones. La primera traduce una nota numérica a letra usando '
        'una cadena de elif. La segunda describe esa letra con match-case. La '
        'tercera valida el rango de la nota y luego combina nota y asistencia '
        'con and y or para dar una recomendación.',
    output:
        'Juan García: 92/100 → A (Excelente)\n'
        'Excelente desempeño en nota y asistencia\n'
        'Ana Martínez: 65/100 → D (Pasable)\n'
        'Desempeño bajo: conviene reforzar',
    steps: [
      ExampleStep(
        code: 'if nota >= 90: ... elif nota >= 80:',
        explanation:
            'Las condiciones van de mayor a menor. Si empezaran al revés, todas '
            'las notas caerían en el primer caso.',
      ),
      ExampleStep(
        code: 'match letra:',
        explanation:
            'Aquí match-case es la mejor opción: se compara una sola variable '
            'contra valores exactos.',
      ),
      ExampleStep(
        code: 'if not (0 <= nota <= 100):',
        explanation:
            'Python permite encadenar comparaciones. El not invierte el '
            'resultado: entra al if cuando la nota está fuera de rango.',
      ),
      ExampleStep(
        code: 'if nota >= 80 and asistencia >= 90:',
        explanation:
            'Con and deben cumplirse las dos condiciones para considerarse '
            'excelente.',
      ),
      ExampleStep(
        code: 'elif nota >= 70 or asistencia >= 95:',
        explanation:
            'Con or basta con destacar en una de las dos para considerarse buen '
            'desempeño.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: los cimientos de una decisión',
    instructions: 'Relaciona cada herramienta con lo que hace.',
    pairs: [
      ConceptPair(
        concept: 'Operadores de comparación',
        definition: 'Comparan dos valores y devuelven verdadero o falso.',
      ),
      ConceptPair(
        concept: 'Operadores lógicos',
        definition: 'Combinan múltiples condiciones con and, or y not.',
      ),
      ConceptPair(
        concept: 'If - Else',
        definition:
            'Ejecuta un bloque de código si la condición es verdadera y otro si '
            'es falsa.',
      ),
      ConceptPair(
        concept: 'Match - Case',
        definition:
            'Compara una variable contra varios valores concretos de forma '
            'limpia.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 2: Bucles y estructuras iterativas
// ---------------------------------------------------------------------------

const CourseSection _seccion2 = CourseSection(
  id: 'm3-s2',
  shortTitle: 'Bucles y\nestructuras\niterativas',
  videos: [
    SectionVideo(
      title: 'Ejercicios de ciclos I',
      youtubeId: '4gUQF2BypNg',
      duration: '10:35',
      description: 'Clase 7.1. Primeros bucles con contador.',
      transcript:
          'Construye bucles sencillos con contador: inicializar la '
          'variable, definir la condición de parada y actualizarla en '
          'cada vuelta. Deja claro por qué olvidar esa actualización '
          'produce un bucle infinito.',
    ),
    SectionVideo(
      title: 'Ejercicios de ciclos II',
      youtubeId: 'oU2_37iYM28',
      duration: '8:31',
      description: 'Clase 7.2. Acumuladores dentro de un bucle.',
      transcript:
          'Trabaja el patrón del acumulador: una variable que va sumando '
          'o multiplicando valores en cada vuelta, y el cuidado con su '
          'valor inicial (cero para sumar, uno para multiplicar).',
    ),
    SectionVideo(
      title: 'Ejercicios de ciclos III',
      youtubeId: '6rd-LhKO1H0',
      duration: '11:25',
      description: 'Clase 7.3. Recorridos con condiciones dentro.',
      transcript:
          'Combina bucles con decisiones: filtrar los elementos que '
          'cumplen una condición, contarlos y quedarse con el mayor o el '
          'menor de una secuencia.',
    ),
    SectionVideo(
      title: 'Ejercicios de ciclos, repaso general',
      youtubeId: 'ziLvinSsVjM',
      duration: '17:38',
      description: 'Clase 8.1. Repaso completo de bucles.',
      transcript:
          'Repaso de todo lo anterior con ejercicios más largos, '
          'incluidos ciclos anidados y el coste que tienen: dos bucles de '
          'diez vueltas son cien iteraciones, y el crecimiento es '
          'multiplicativo.',
    ),
  ],
  moduleNumber: 3,
  number: 2,
  title: 'Bucles y estructuras iterativas',
  summary:
      'For, while, recorrido de colecciones, contadores, acumuladores y ciclos '
      'anidados.',
  objectives: [
    'Repetir código con for y range.',
    'Repetir con while sin caer en bucles infinitos.',
    'Recorrer listas, tuplas, diccionarios y cadenas.',
    'Construir contadores y acumuladores.',
    'Usar ciclos anidados con criterio.',
  ],
  reading: SectionReading(
    title: 'Dominando la repetición: la clave para automatizar',
    intro:
        '¿Escribirías mil líneas de print para imprimir del 1 al 1000? Los '
        'bucles te liberan de la repetición manual.',
    pages: [
      ReadingPage(
        title: 'For: el bucle contado',
        summary:
            'Repite un bloque un número específico de veces. Su compañera '
            'inseparable es la función range.',
        blocks: [
          ReadingBlock.code(
            title: 'La función range',
            code:
                'range(5)         # 0, 1, 2, 3, 4\n'
                'range(1, 6)      # 1, 2, 3, 4, 5\n'
                'range(0, 10, 2)  # 0, 2, 4, 6, 8\n'
                'range(5, 0, -1)  # 5, 4, 3, 2, 1 — cuenta hacia atrás',
            body:
                'El valor final nunca se incluye. El tercer número es el paso.',
            codeCaption:
                'La función range genera secuencias numéricas. Con un argumento '
                'empieza en cero, con dos define inicio y fin, y con tres además '
                'indica de cuánto en cuánto avanza.',
          ),
          ReadingBlock.code(
            title: 'Ejemplos prácticos',
            code:
                '# Tabla de multiplicar\n'
                'tabla = 7\n'
                'for i in range(1, 11):\n'
                '    print(f"{tabla} × {i} = {tabla * i}")\n\n'
                '# Patrón de asteriscos\n'
                'for i in range(1, 6):\n'
                '    print("*" * i)\n\n'
                '# Suma de 1 a 100\n'
                'suma = 0\n'
                'for numero in range(1, 101):\n'
                '    suma += numero\n'
                'print(suma)  # 5050',
            codeCaption:
                'Tres usos del for: generar una tabla de multiplicar del siete, '
                'dibujar un triángulo de asteriscos creciente, y acumular la '
                'suma de los números del uno al cien, que da cinco mil '
                'cincuenta.',
          ),
        ],
      ),
      ReadingPage(
        title: 'While: el bucle condicional',
        summary:
            'Repite mientras una condición sea verdadera. Se detiene cuando '
            'deja de serlo.',
        blocks: [
          ReadingBlock.code(
            title: 'Estructura básica',
            code:
                'contador = 1\n'
                'while contador <= 5:\n'
                '    print(f"Contador: {contador}")\n'
                '    contador += 1   # ¡imprescindible!',
            codeCaption:
                'Mientras el contador sea menor o igual a cinco se imprime su '
                'valor y se le suma uno. Esa suma es lo que permite que el bucle '
                'termine.',
          ),
          ReadingBlock.callout(
            title: 'El error número uno: el bucle infinito',
            body:
                'Si olvidas actualizar la variable de la condición, el while '
                'nunca termina y el programa se cuelga. Cada vez que escribas un '
                'while, pregúntate: ¿cómo termina este bucle?',
            tone: CalloutTone.danger,
          ),
          ReadingBlock.code(
            title: 'Break y continue',
            code:
                'for i in range(1, 6):\n'
                '    if i == 3:\n'
                '        break      # sale del bucle → imprime 1, 2\n'
                '    print(i)\n\n'
                'for i in range(1, 6):\n'
                '    if i == 3:\n'
                '        continue   # salta esta vuelta → imprime 1, 2, 4, 5\n'
                '    print(i)',
            codeCaption:
                'La palabra break abandona el bucle por completo. La palabra '
                'continue se salta solo la vuelta actual y sigue con la '
                'siguiente.',
          ),
          ReadingBlock.bullets(
            title: '¿For o while?',
            items: [
              'Usa for cuando sepas cuántas veces repetir o cuando recorras una colección.',
              'Usa while cuando la parada dependa de una validación o de algo que aún no ha ocurrido.',
              'Ejemplo de while: repetir hasta que el usuario escriba "salir".',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Recorriendo colecciones',
        summary:
            'For brilla cuando recorre listas, tuplas, diccionarios y cadenas.',
        blocks: [
          ReadingBlock.code(
            title: 'Listas y enumerate',
            code:
                'frutas = ["manzana", "platano", "naranja"]\n\n'
                '# Por elemento — lo más común\n'
                'for fruta in frutas:\n'
                '    print(f"Me encanta comer {fruta}")\n\n'
                '# Con índice y elemento a la vez\n'
                'for i, fruta in enumerate(frutas):\n'
                '    print(f"{i}: {fruta}")',
            body:
                'enumerate te entrega la posición y el elemento al mismo tiempo: '
                'es más limpio que usar range(len(lista)).',
            codeCaption:
                'El primer bucle recorre cada fruta directamente. El segundo usa '
                'enumerate para obtener a la vez la posición y el nombre de cada '
                'fruta.',
          ),
          ReadingBlock.code(
            title: 'Diccionarios',
            code:
                'estudiante = {\n'
                '    "nombre": "Juan",\n'
                '    "edad": 20,\n'
                '    "carrera": "Ingeniería"\n'
                '}\n\n'
                'for clave in estudiante:              # solo las claves\n'
                'for valor in estudiante.values():     # solo los valores\n'
                'for clave, valor in estudiante.items():  # ambos — lo más útil\n'
                '    print(f"{clave}: {valor}")',
            codeCaption:
                'Un diccionario se puede recorrer por claves, por valores, o por '
                'ambos a la vez usando el método items, que es la forma más '
                'práctica.',
          ),
          ReadingBlock.code(
            title: 'Cadenas y patrones frecuentes',
            code:
                'for letra in "Python":\n'
                '    print(letra)    # P, y, t, h, o, n\n\n'
                '# Filtrar\n'
                'pares = []\n'
                'for numero in numeros:\n'
                '    if numero % 2 == 0:\n'
                '        pares.append(numero)\n\n'
                '# Buscar el máximo\n'
                'maxima = calificaciones[0]\n'
                'for calificacion in calificaciones:\n'
                '    if calificacion > maxima:\n'
                '        maxima = calificacion',
            codeCaption:
                'Una cadena se recorre carácter por carácter. Dos patrones muy '
                'frecuentes son filtrar los elementos que cumplen una condición '
                'y buscar el valor máximo comparando uno a uno.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Contadores, acumuladores y ciclos anidados',
        summary:
            'Un contador cuenta cuántas veces pasa algo. Un acumulador suma o '
            'multiplica valores a lo largo de las vueltas.',
        blocks: [
          ReadingBlock.code(
            title: 'Contador y acumulador',
            code:
                '# Contador: cuenta ocurrencias\n'
                'contador_pares = 0\n'
                'for numero in numeros:\n'
                '    if numero % 2 == 0:\n'
                '        contador_pares += 1\n\n'
                '# Acumulador: suma valores\n'
                'suma = 0\n'
                'for numero in numeros:\n'
                '    suma += numero\n\n'
                '# Acumulador de producto: empieza en 1, no en 0\n'
                'producto = 1\n'
                'for factor in factores:\n'
                '    producto *= factor',
            body:
                'Ojo con el valor inicial: un acumulador de suma empieza en 0, '
                'pero uno de producto debe empezar en 1.',
            codeCaption:
                'Un contador arranca en cero y suma uno cada vez que se cumple '
                'la condición. Un acumulador de suma también arranca en cero, '
                'pero uno de multiplicación tiene que arrancar en uno.',
          ),
          ReadingBlock.code(
            title: 'Ciclos anidados',
            code:
                '# Triángulo de asteriscos\n'
                'for fila in range(1, 6):\n'
                '    for columna in range(fila):\n'
                '        print("*", end=" ")\n'
                '    print()   # salto de línea\n\n'
                '# Recorrer una matriz\n'
                'matriz = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]\n'
                'total = 0\n'
                'for fila in matriz:\n'
                '    for valor in fila:\n'
                '        total += valor\n'
                'print(total)  # 45',
            codeCaption:
                'Un bucle dentro de otro. El interno se completa entero en cada '
                'vuelta del externo. Así se dibuja un triángulo y se suma toda '
                'una matriz de tres por tres, que da cuarenta y cinco.',
          ),
          ReadingBlock.callout(
            title: 'Los ciclos anidados crecen rápido',
            body:
                'Dos bucles de 10 son 100 vueltas. Dos de 1000 son un millón. '
                'Tres de 100 también son un millón. El crecimiento es '
                'multiplicativo: úsalos con cuidado.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuál es la diferencia principal entre for y while?',
      options: [
        'No hay diferencia',
        'for se usa para números y while para lógica',
        'for repite un número específico de veces y while repite mientras una condición sea verdadera',
        'for es más rápido que while',
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Qué hace break dentro de un bucle?',
      options: [
        'Pausa el bucle',
        'Sale del bucle inmediatamente',
        'Salta a la siguiente iteración',
        'Detiene el programa completo',
      ],
      correctIndex: 1,
      explanation:
          'Para saltar solo una vuelta y seguir con la siguiente se usa '
          'continue, no break.',
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Qué valores genera range(1, 5)?',
      options: ['1, 2, 3, 4, 5', '1, 2, 3, 4', '0, 1, 2, 3, 4', 'Solo el 5'],
      correctIndex: 1,
      explanation: 'El valor final nunca se incluye.',
    ),
    QuizQuestion(
      prompt: '¿Cuál es la ventaja de usar enumerate() al recorrer una lista?',
      options: [
        'Es más rápido',
        'Obtiene tanto el índice como el elemento',
        'Usa menos memoria',
        'Reemplaza la necesidad de bucles',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué es un acumulador?',
      options: [
        'Una variable que cuenta ocurrencias',
        'Una variable que suma o multiplica valores a lo largo de las iteraciones',
        'Un tipo especial de bucle',
        'Una función incorporada de Python',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál es el error más común al escribir un bucle while?',
      options: [
        'Usar demasiadas condiciones',
        'Olvidar actualizar la variable de la condición, creando un bucle infinito',
        'Usar range dentro del while',
        'Indentar el cuerpo del bucle',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: los bucles son tu superpoder',
    headline: 'Repite inteligentemente, no manualmente',
    intro:
        'Mientras otros escriben código repetitivo para 100 casos, tú escribes '
        'un bucle que maneja un millón.',
    tips: [
      CapsuleTip(
        title: 'Elige el bucle correcto',
        body:
            'for para lo conocido, while para lo condicional. La elección '
            'correcta hace tu código elegante; la equivocada lo hace confuso.',
      ),
      CapsuleTip(
        title: 'Actualiza siempre en while',
        body:
            'Un while sin actualización es un bucle infinito. Es el error '
            'número uno de quienes empiezan. Pregúntate siempre: ¿cómo termina?',
      ),
      CapsuleTip(
        title: 'Los ciclos anidados son poderosos pero peligrosos',
        body:
            'Dos bucles de 10 son 100 iteraciones. Tres de 100 son un millón. '
            'El crecimiento es multiplicativo.',
      ),
    ],
    closing:
        'Los bucles son la base de toda automatización: dominarlos significa '
        'procesar cualquier cantidad de datos sin esfuerzo manual.',
  ),
  example: CodeExample(
    title: 'Análisis de calificaciones con contadores y acumuladores',
    description:
        'Un solo recorrido que cuenta aprobados, acumula la suma para el '
        'promedio y encuentra la nota máxima.',
    code:
        'calificaciones = [85, 92, 78, 95, 88, 45, 67]\n\n'
        '# Contadores\n'
        'aprobados = 0\n'
        'reprobados = 0\n\n'
        '# Acumulador\n'
        'suma_notas = 0\n\n'
        '# Búsqueda de máximo y mínimo\n'
        'maxima = calificaciones[0]\n'
        'minima = calificaciones[0]\n\n'
        'for nota in calificaciones:\n'
        '    suma_notas += nota\n\n'
        '    if nota >= 60:\n'
        '        aprobados += 1\n'
        '    else:\n'
        '        reprobados += 1\n\n'
        '    if nota > maxima:\n'
        '        maxima = nota\n'
        '    if nota < minima:\n'
        '        minima = nota\n\n'
        'promedio = suma_notas / len(calificaciones)\n\n'
        'print(f"Total de notas: {len(calificaciones)}")\n'
        'print(f"Aprobados: {aprobados}")\n'
        'print(f"Reprobados: {reprobados}")\n'
        'print(f"Promedio: {promedio:.2f}")\n'
        'print(f"Máxima: {maxima}  Mínima: {minima}")\n\n'
        '# Tabla resumen con ciclo anidado\n'
        'for i, nota in enumerate(calificaciones, 1):\n'
        '    estado = "APROBADO" if nota >= 60 else "REPROBADO"\n'
        '    print(f"{i}. {nota} — {estado}")',
    codeCaption:
        'Un único bucle recorre la lista de notas y al mismo tiempo acumula la '
        'suma, cuenta aprobados y reprobados, y actualiza el máximo y el '
        'mínimo. Después calcula el promedio dividiendo la suma entre la '
        'cantidad de notas y finalmente imprime una tabla numerada con el '
        'estado de cada una.',
    output:
        'Total de notas: 7\n'
        'Aprobados: 5\n'
        'Reprobados: 2\n'
        'Promedio: 78.57\n'
        'Máxima: 95  Mínima: 45\n'
        '1. 85 — APROBADO\n'
        '2. 92 — APROBADO\n'
        '3. 78 — APROBADO\n'
        '4. 95 — APROBADO\n'
        '5. 88 — APROBADO\n'
        '6. 45 — REPROBADO\n'
        '7. 67 — APROBADO',
    steps: [
      ExampleStep(
        code: 'maxima = calificaciones[0]',
        explanation:
            'El máximo arranca con el primer valor real, no con cero: así '
            'funciona incluso con listas de números negativos.',
      ),
      ExampleStep(
        code: 'suma_notas += nota',
        explanation: 'Acumulador: crece con cada vuelta del bucle.',
      ),
      ExampleStep(
        code: 'aprobados += 1',
        explanation:
            'Contador: suma exactamente uno cada vez que se cumple la '
            'condición.',
      ),
      ExampleStep(
        code: 'promedio = suma_notas / len(calificaciones)',
        explanation:
            'El promedio se calcula una sola vez, fuera del bucle, cuando ya se '
            'sumó todo.',
      ),
      ExampleStep(
        code: 'for i, nota in enumerate(calificaciones, 1):',
        explanation:
            'El segundo argumento de enumerate indica desde qué número empezar a '
            'contar: aquí desde 1 en lugar de 0.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: tipos de repetición',
    instructions: 'Relaciona cada estructura con lo que hace.',
    pairs: [
      ConceptPair(
        concept: 'For Loop (repetición contada)',
        definition: 'Repite un bloque de código un número específico de veces.',
      ),
      ConceptPair(
        concept: 'While Loop (repetición condicional)',
        definition: 'Repite mientras una condición sea verdadera.',
      ),
      ConceptPair(
        concept: 'Recorrer colecciones',
        definition:
            'Iterar sobre los elementos de listas, tuplas, diccionarios y '
            'cadenas.',
      ),
      ConceptPair(
        concept: 'Contadores y acumuladores',
        definition:
            'Variables que cuentan ocurrencias o suman valores a lo largo de '
            'las vueltas.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 3: Clases
// ---------------------------------------------------------------------------

const CourseSection _seccion3 = CourseSection(
  id: 'm3-s3',
  shortTitle: 'Clases',
  videos: [
    SectionVideo(
      title: 'Agrupar datos relacionados (parte 1)',
      youtubeId: 'iAQUKvljRHU',
      duration: '10:12',
      description:
          'Clase 11.3. Antesala de los objetos: datos que viajan juntos.',
      transcript:
          'Muestra cómo agrupar en una sola estructura varios datos que '
          'describen la misma cosa, en lugar de tenerlos en variables '
          'sueltas. Es el razonamiento que lleva a las clases: juntar en '
          'un objeto los datos y las operaciones que le corresponden.',
    ),
    SectionVideo(
      title: 'Agrupar datos relacionados (parte 2)',
      youtubeId: 'qMDetw0jjho',
      duration: '6:00',
      description: 'Clase 11.4. Operaciones sobre una estructura de datos.',
      transcript:
          'Define operaciones que trabajan siempre sobre la misma '
          'estructura. Cuando esas operaciones se guardan junto a los '
          'datos, dejan de ser funciones sueltas y se convierten en '
          'métodos de una clase.',
    ),
    SectionVideo(
      title: 'Agrupar datos relacionados (parte 3)',
      youtubeId: 'mqzIHEUiAAA',
      duration: '22:48',
      description: 'Clase 11.5. Ejercicio completo con estructuras de datos.',
      transcript:
          'Ejercicio largo que integra todo lo anterior: crear la '
          'estructura, recorrerla, modificarla y validar los datos antes '
          'de guardarlos. La validación dentro de la propia estructura es '
          'justo lo que en clases se llama encapsulación.',
    ),
  ],
  moduleNumber: 3,
  number: 3,
  title: 'Clases',
  summary:
      'Programación orientada a objetos: atributos, métodos, herencia, '
      'polimorfismo y encapsulación.',
  objectives: [
    'Crear clases y objetos con atributos y métodos.',
    'Entender qué es self y para qué sirve el constructor.',
    'Reutilizar código con herencia y super.',
    'Aplicar polimorfismo y encapsulación.',
  ],
  reading: SectionReading(
    title: 'Clases: del procedural al orientado a objetos',
    intro:
        'Un coche no es solo variables: es un objeto con características '
        '(color, velocidad) y comportamientos (acelerar, frenar). Las clases te '
        'permiten pensar así.',
    pages: [
      ReadingPage(
        title: '¿Qué es una clase?',
        summary:
            'Una clase es un plano. Un objeto es la casa construida con ese '
            'plano.',
        blocks: [
          ReadingBlock.code(
            title: 'Clase y objeto',
            code:
                'class Persona:\n'
                '    pass          # clase vacía por ahora\n\n'
                'juan = Persona()  # juan es un objeto de tipo Persona\n'
                'print(type(juan))',
            body:
                'Puedes construir muchas casas con el mismo plano: muchos '
                'objetos a partir de una misma clase.',
            codeCaption:
                'Se define una clase Persona vacía y después se crea un objeto '
                'llamado juan a partir de ella.',
          ),
          ReadingBlock.bullets(
            title: 'Por qué la POO domina la industria',
            items: [
              'Organiza código complejo de forma lógica.',
              'Permite reutilizar código mediante herencia.',
              'Protege los datos mediante encapsulación.',
              'Crea sistemas escalables y mantenibles.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Atributos, self y el constructor',
        summary:
            'Los atributos guardan el estado del objeto. self es el objeto '
            'actual. __init__ se ejecuta al crearlo.',
        blocks: [
          ReadingBlock.code(
            title: 'El constructor __init__',
            code:
                'class Persona:\n'
                '    def __init__(self, nombre, edad):\n'
                '        self.nombre = nombre   # atributo de instancia\n'
                '        self.edad = edad\n\n'
                'juan = Persona("Juan", 25)\n'
                'maria = Persona("María", 30)\n\n'
                'print(juan.nombre)   # Juan\n'
                'print(maria.edad)    # 30',
            body:
                'El método __init__ se ejecuta automáticamente al crear el '
                'objeto. Cada objeto tiene sus propios atributos, separados de '
                'los demás.',
            codeCaption:
                'La clase Persona guarda un nombre y una edad al crearse. Se '
                'crean dos personas distintas, Juan de veinticinco años y María '
                'de treinta, y cada una conserva sus propios datos.',
          ),
          ReadingBlock.code(
            title: 'Atributos de clase: compartidos por todos',
            code:
                'class Estudiante:\n'
                '    universidad = "MIT"            # atributo de clase\n'
                '    contador_estudiantes = 0\n\n'
                '    def __init__(self, nombre):\n'
                '        self.nombre = nombre       # atributo de instancia\n'
                '        Estudiante.contador_estudiantes += 1\n\n'
                'juan = Estudiante("Juan")\n'
                'maria = Estudiante("María")\n'
                'print(Estudiante.contador_estudiantes)  # 2',
            codeCaption:
                'El nombre de la universidad y el contador pertenecen a la clase '
                'y los comparten todos los estudiantes. El nombre, en cambio, '
                'pertenece a cada objeto.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Métodos: lo que un objeto puede hacer',
        summary:
            'Los métodos son funciones que pertenecen a la clase y representan '
            'comportamientos.',
        blocks: [
          ReadingBlock.code(
            title: 'Definir y usar métodos',
            code:
                'class Persona:\n'
                '    def __init__(self, nombre, edad):\n'
                '        self.nombre = nombre\n'
                '        self.edad = edad\n\n'
                '    def presentarse(self):\n'
                '        return f"Hola, me llamo {self.nombre}"\n\n'
                '    def cumplir_anios(self):\n'
                '        self.edad += 1\n'
                '        return f"{self.nombre} ahora tiene {self.edad} años"\n\n'
                '    def es_adulto(self):\n'
                '        return self.edad >= 18\n\n'
                'juan = Persona("Juan", 25)\n'
                'print(juan.presentarse())     # Hola, me llamo Juan\n'
                'print(juan.cumplir_anios())   # Juan ahora tiene 26 años\n'
                'print(juan.es_adulto())       # True',
            codeCaption:
                'La clase Persona tiene tres métodos: uno que devuelve un '
                'saludo, otro que suma un año a la edad, y otro que responde si '
                'la persona es mayor de edad.',
          ),
          ReadingBlock.callout(
            title: 'self siempre va primero, pero nunca se pasa',
            body:
                'Todos los métodos reciben self como primer parámetro, pero al '
                'llamarlos no lo escribes: Python lo pasa automáticamente. '
                'Escribes juan.presentarse(), no juan.presentarse(juan).',
            tone: CalloutTone.info,
          ),
        ],
      ),
      ReadingPage(
        title: 'Herencia y polimorfismo',
        summary:
            'La herencia evita duplicar código. El polimorfismo permite que el '
            'mismo método actúe distinto en cada clase.',
        blocks: [
          ReadingBlock.code(
            title: 'Herencia',
            code:
                'class Animal:                     # clase padre\n'
                '    def __init__(self, nombre):\n'
                '        self.nombre = nombre\n\n'
                '    def hacer_sonido(self):\n'
                '        return "Sonido genérico"\n\n\n'
                'class Perro(Animal):              # clase hija\n'
                '    def hacer_sonido(self):\n'
                '        return f"{self.nombre} dice: ¡Guau!"\n\n\n'
                'class Gato(Animal):\n'
                '    def hacer_sonido(self):\n'
                '        return f"{self.nombre} dice: Miau"',
            codeCaption:
                'Perro y Gato heredan de Animal, así que reciben gratis el '
                'constructor que guarda el nombre, pero cada uno redefine el '
                'sonido a su manera.',
          ),
          ReadingBlock.code(
            title: 'super(): llamar al padre',
            code:
                'class Vehiculo:\n'
                '    def __init__(self, marca, modelo):\n'
                '        self.marca = marca\n'
                '        self.modelo = modelo\n\n'
                '    def info(self):\n'
                '        return f"{self.marca} {self.modelo}"\n\n\n'
                'class Coche(Vehiculo):\n'
                '    def __init__(self, marca, modelo, puertas):\n'
                '        super().__init__(marca, modelo)   # reutiliza el padre\n'
                '        self.puertas = puertas\n\n'
                '    def info(self):\n'
                '        return f"{super().info()} con {self.puertas} puertas"',
            codeCaption:
                'La clase Coche llama al constructor de Vehículo con super para '
                'no repetir el código de marca y modelo, y añade solo lo suyo: '
                'el número de puertas.',
          ),
          ReadingBlock.code(
            title: 'Polimorfismo: un mensaje, muchas respuestas',
            code:
                'animales = [Gato("Whiskers"), Perro("Rex")]\n\n'
                'for animal in animales:\n'
                '    print(animal.hacer_sonido())\n\n'
                '# Whiskers dice: Miau\n'
                '# Rex dice: ¡Guau!',
            body:
                'El bucle no necesita saber de qué clase es cada animal: cada '
                'objeto responde a su manera.',
            codeCaption:
                'Se recorre una lista con objetos de clases distintas llamando '
                'al mismo método, y cada uno responde con su propio sonido.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Encapsulación y métodos especiales',
        summary:
            'La encapsulación controla qué datos son accesibles desde fuera de '
            'la clase.',
        blocks: [
          ReadingBlock.code(
            title: 'Atributos privados por convención',
            code:
                'class CuentaBancaria:\n'
                '    def __init__(self, titular, saldo):\n'
                '        self.titular = titular\n'
                '        self._saldo = saldo   # el guion bajo indica "privado"\n\n'
                '    def obtener_saldo(self):\n'
                '        return self._saldo\n\n'
                '    def depositar(self, cantidad):\n'
                '        if cantidad > 0:\n'
                '            self._saldo += cantidad\n'
                '            return True\n'
                '        return False\n\n'
                '    def retirar(self, cantidad):\n'
                '        if 0 < cantidad <= self._saldo:\n'
                '            self._saldo -= cantidad\n'
                '            return True\n'
                '        return False',
            body:
                'El saldo no se toca directamente desde fuera: se modifica solo '
                'a través de métodos que validan la operación.',
            codeCaption:
                'La cuenta guarda el saldo con un guion bajo delante para '
                'indicar que es interno, y expone tres métodos: consultar, '
                'depositar comprobando que la cantidad sea positiva, y retirar '
                'comprobando que haya fondos suficientes.',
          ),
          ReadingBlock.code(
            title: 'Properties: getters y setters con validación',
            code:
                'class Persona:\n'
                '    def __init__(self, edad):\n'
                '        self._edad = edad\n\n'
                '    @property\n'
                '    def edad(self):\n'
                '        return self._edad\n\n'
                '    @edad.setter\n'
                '    def edad(self, valor):\n'
                '        if valor >= 0:\n'
                '            self._edad = valor\n'
                '        else:\n'
                '            print("La edad no puede ser negativa")\n\n'
                'persona = Persona(25)\n'
                'persona.edad = 30    # usa el setter\n'
                'persona.edad = -5    # rechazado por la validación',
            codeCaption:
                'Con el decorador property la edad se lee como si fuera un '
                'atributo normal, pero al asignarla pasa por una validación que '
                'rechaza valores negativos.',
          ),
          ReadingBlock.bullets(
            title: 'Métodos especiales (dunder)',
            items: [
              '__str__: cómo se ve el objeto al imprimirlo.',
              '__repr__: cómo se ve para quien programa, al depurar.',
              '__len__: qué devuelve la función len sobre el objeto.',
              '__add__: qué ocurre al sumar dos objetos con el signo más.',
              '__eq__: cómo se comparan dos objetos con doble igual.',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Qué es self en una clase?',
      options: [
        'Una palabra clave especial de Python',
        'El objeto actual sobre el que se está trabajando',
        'Un parámetro que debe pasarse siempre al llamar el método',
        'Una variable global',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué es la herencia en programación orientada a objetos?',
      options: [
        'Pasar variables de una función a otra',
        'Copiar todo el código de una clase a otra',
        'Una clase hija hereda características de una clase padre',
        'Un método que se ejecuta múltiples veces',
      ],
      correctIndex: 2,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt:
          '¿Cuál es la diferencia entre un atributo de instancia y uno de '
          'clase?',
      options: [
        'No hay diferencia',
        'El de instancia pertenece a cada objeto; el de clase lo comparten todos',
        'El atributo de clase es más rápido',
        'Solo existen atributos de instancia',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué hace super()?',
      options: [
        'Crea un objeto super',
        'Llama a métodos de la clase padre',
        'Destruye un objeto',
        'Crea una lista de métodos',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué es el polimorfismo?',
      options: [
        'Una clase con múltiples constructores',
        'Muchas formas: el mismo método actúa distinto en diferentes clases',
        'Una variable que cambia de tipo',
        'Un tipo de herencia',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Para qué sirve el guion bajo al inicio de un atributo?',
      options: [
        'Hace el atributo inaccesible por completo',
        'Indica por convención que el atributo es de uso interno de la clase',
        'Acelera el acceso al atributo',
        'Convierte el atributo en un método',
      ],
      correctIndex: 1,
      explanation:
          'Python no lo bloquea: es una convención que avisa "no toques esto '
          'desde fuera".',
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: las clases modelan el mundo real',
    headline: 'Pensar en objetos, no en procedimientos',
    intro:
        'El salto de pensamiento más importante en programación es pasar de '
        '"escribe código que hace algo" a "crea objetos que hacen cosas".',
    tips: [
      CapsuleTip(
        title: 'Una clase, una responsabilidad',
        body:
            'Si una clase hace más de una cosa, divídela. Una clase Persona no '
            'debería además manejar transacciones bancarias; para eso está la '
            'clase CuentaBancaria.',
      ),
      CapsuleTip(
        title: 'La herencia es poder, úsala con criterio',
        body:
            'No heredes solo porque puedas. Hereda cuando una clase realmente '
            'sea una versión especializada de otra. Un Perro es un Animal. Un '
            'Auto es un Vehículo. Pero una Persona no es un Email.',
      ),
      CapsuleTip(
        title: 'Protege tus datos',
        body:
            'La encapsulación no es paranoia, es profesionalismo. Si un '
            'atributo no debería cambiar directamente, protégelo con guion bajo. '
            'Si quieres validar los cambios, usa property.',
      ),
    ],
    closing:
        'La programación orientada a objetos es el estándar de la industria: '
        'dominarla significa estar listo para proyectos profesionales.',
  ),
  example: CodeExample(
    title: 'Sistema de biblioteca con herencia',
    description:
        'Una clase base y tres clases hijas que la especializan, más la clase '
        'que las gestiona.',
    code:
        'class ElementoBiblioteca:\n'
        '    """Clase base para todos los elementos de la biblioteca."""\n\n'
        '    def __init__(self, titulo, autor, anio):\n'
        '        self.titulo = titulo\n'
        '        self.autor = autor\n'
        '        self.anio = anio\n'
        '        self._disponible = True\n'
        '        self._prestado_a = None\n\n'
        '    @property\n'
        '    def disponible(self):\n'
        '        return self._disponible\n\n'
        '    @property\n'
        '    def detalles(self):\n'
        '        return f"{self.titulo} por {self.autor} ({self.anio})"\n\n'
        '    def __str__(self):\n'
        '        estado = "Disponible" if self._disponible else f"Prestado a {self._prestado_a}"\n'
        '        return f"{self.detalles} - {estado}"\n\n\n'
        'class Libro(ElementoBiblioteca):\n'
        '    def __init__(self, titulo, autor, anio, paginas, genero):\n'
        '        super().__init__(titulo, autor, anio)\n'
        '        self.paginas = paginas\n'
        '        self.genero = genero\n\n'
        '    @property\n'
        '    def detalles(self):\n'
        '        return f"{self.titulo} por {self.autor} ({self.genero}, {self.paginas} págs)"\n\n\n'
        'class DVD(ElementoBiblioteca):\n'
        '    def __init__(self, titulo, autor, anio, minutos, director):\n'
        '        super().__init__(titulo, autor, anio)\n'
        '        self.minutos = minutos\n'
        '        self.director = director\n\n'
        '    @property\n'
        '    def detalles(self):\n'
        '        horas = self.minutos // 60\n'
        '        mins = self.minutos % 60\n'
        '        return f"{self.titulo} dirigida por {self.director} ({horas}h {mins}m)"\n\n\n'
        'class Biblioteca:\n'
        '    def __init__(self, nombre):\n'
        '        self.nombre = nombre\n'
        '        self.elementos = []\n\n'
        '    def agregar(self, elemento):\n'
        '        if isinstance(elemento, ElementoBiblioteca):\n'
        '            self.elementos.append(elemento)\n'
        '            print(f"{elemento.titulo} agregado")\n\n'
        '    def prestar(self, titulo, persona):\n'
        '        for elemento in self.elementos:\n'
        '            if elemento.titulo == titulo and elemento.disponible:\n'
        '                elemento._disponible = False\n'
        '                elemento._prestado_a = persona\n'
        '                print(f"{titulo} prestado a {persona}")\n'
        '                return True\n'
        '        print(f"{titulo} no está disponible")\n'
        '        return False\n\n\n'
        'biblioteca = Biblioteca("Biblioteca Central")\n'
        'biblioteca.agregar(Libro("1984", "George Orwell", 1949, 328, "Ciencia Ficción"))\n'
        'biblioteca.agregar(DVD("Matrix", "Los Wachowski", 1999, 136, "Los Wachowski"))\n\n'
        'biblioteca.prestar("1984", "Juan García")\n\n'
        'for elemento in biblioteca.elementos:\n'
        '    print(elemento)',
    codeCaption:
        'Una clase base guarda título, autor, año y si el elemento está '
        'disponible. Libro y DVD heredan de ella y redefinen cómo se describen. '
        'La clase Biblioteca guarda una lista de elementos, permite agregarlos y '
        'prestarlos. Al imprimir cada elemento se ve su descripción propia y su '
        'estado.',
    output:
        '1984 agregado\n'
        'Matrix agregado\n'
        '1984 prestado a Juan García\n'
        '1984 por George Orwell (Ciencia Ficción, 328 págs) - Prestado a Juan García\n'
        'Matrix dirigida por Los Wachowski (2h 16m) - Disponible',
    steps: [
      ExampleStep(
        code: 'class Libro(ElementoBiblioteca):',
        explanation:
            'El paréntesis indica de qué clase hereda: Libro recibe todo lo de '
            'ElementoBiblioteca.',
      ),
      ExampleStep(
        code: 'super().__init__(titulo, autor, anio)',
        explanation:
            'Llama al constructor del padre para no repetir la asignación de los '
            'tres atributos comunes.',
      ),
      ExampleStep(
        code: '@property\ndef detalles(self):',
        explanation:
            'Cada clase hija redefine detalles: esto es polimorfismo. El mismo '
            'nombre, resultados distintos.',
      ),
      ExampleStep(
        code: 'def __str__(self):',
        explanation:
            'Método especial que define qué se ve al imprimir el objeto con '
            'print.',
      ),
      ExampleStep(
        code: 'if isinstance(elemento, ElementoBiblioteca):',
        explanation:
            'isinstance acepta cualquier clase que herede de la base: sirve '
            'tanto para Libro como para DVD.',
      ),
      ExampleStep(
        code: 'self._disponible = True',
        explanation:
            'El guion bajo marca el atributo como interno: se modifica a través '
            'de los métodos de la clase.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: los pilares de la POO',
    instructions: 'Relaciona cada concepto con su definición.',
    pairs: [
      ConceptPair(
        concept: 'Clase',
        definition:
            'El plano o plantilla que define qué datos tiene un objeto y qué '
            'puede hacer.',
      ),
      ConceptPair(
        concept: 'Herencia',
        definition:
            'Una clase hija recibe los atributos y métodos de una clase padre '
            'sin duplicar código.',
      ),
      ConceptPair(
        concept: 'Polimorfismo',
        definition:
            'El mismo método se comporta de forma distinta según la clase del '
            'objeto.',
      ),
      ConceptPair(
        concept: 'Encapsulación',
        definition:
            'Controlar qué datos son accesibles desde fuera de la clase y '
            'validar sus cambios.',
      ),
    ],
  ),
);
