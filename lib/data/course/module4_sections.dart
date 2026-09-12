import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 4. Modularización y manejo de datos.
///
/// Nota de contenido: el material entregado cubre "Partes de una función" y
/// "Variables locales y globales". La tercera sección, "Funciones recursivas",
/// queda declarada y con sus objetivos, a la espera del material.
const CourseModule module4 = CourseModule(
  number: 4,
  title: 'Modularización y Manejo de Datos',
  sections: [_seccion1, _seccion2, _seccion3],
);

// ---------------------------------------------------------------------------
// Capítulo 1: Partes de una función
// ---------------------------------------------------------------------------

const CourseSection _seccion1 = CourseSection(
  id: 'm4-s1',
  shortTitle: 'Partes de\nuna función',
  videos: [
    SectionVideo(
      title: 'Funciones I',
      youtubeId: 'An9m7A8Y4lc',
      duration: '50:24',
      description:
          'Clase 5.1. La clase completa sobre cómo se define una función.',
      transcript:
          'Clase central sobre funciones: cómo se declaran con def, qué '
          'son los parámetros y en qué se diferencian de los argumentos, '
          'cómo devolver un valor con return y qué ocurre cuando una '
          'función no devuelve nada. Cubre casi toda la lectura de esta '
          'sección.',
    ),
    SectionVideo(
      title: 'Funciones II',
      youtubeId: 'g8PaATO2P6M',
      duration: '26:57',
      description:
          'Clase 5.2. Parámetros con valor por defecto y varios retornos.',
      transcript:
          'Segunda parte: parámetros opcionales con valor por defecto, '
          'argumentos pasados por nombre, y funciones que devuelven más '
          'de un valor. También aparece el return anticipado para evitar '
          'anidar condiciones.',
    ),
  ],
  moduleNumber: 4,
  number: 1,
  title: 'Partes de una función',
  summary:
      'Nombre, parámetros, cuerpo y return; valores por defecto, argumentos '
      'variables, docstrings y decoradores.',
  objectives: [
    'Identificar las cuatro partes de una función.',
    'Distinguir parámetro de argumento y usar valores por defecto.',
    'Devolver valores con return, incluidos varios a la vez.',
    'Documentar funciones con docstrings.',
    'Usar *args, **kwargs y decoradores.',
  ],
  reading: SectionReading(
    title: 'Funciones: la construcción del código reutilizable',
    intro:
        'Una función es la diferencia entre repetir el mismo código 100 veces y '
        'escribirlo una vez para usarlo 100 veces. Pero no basta con saber '
        'escribirlas: hay que entender cada parte.',
    pages: [
      ReadingPage(
        title: 'Estructura básica',
        summary:
            'Toda función tiene nombre, parámetros, cuerpo y —casi siempre— un '
            'return.',
        blocks: [
          ReadingBlock.code(
            title: 'El esqueleto',
            code:
                'def nombre_funcion(parametros):\n'
                '    """Docstring: descripción de la función."""\n'
                '    # Cuerpo: el código indentado\n'
                '    return resultado\n\n\n'
                '# Llamar la función\n'
                'resultado = nombre_funcion(argumentos)',
            codeCaption:
                'Se escribe def, el nombre, los parámetros entre paréntesis y '
                'dos puntos. Debajo, indentado, va la documentación y el cuerpo, '
                'y al final return con el resultado.',
          ),
          ReadingBlock.bullets(
            title: 'Elige bien el nombre',
            items: [
              'calcular_promedio: describe qué hace y es legible. Perfecto.',
              'cp: demasiado corto, no describe nada.',
              'calcular_el_promedio_de_numeros: demasiado largo.',
              'CALCULAR_PROMEDIO: rompe la convención, que es minúsculas con guiones bajos.',
            ],
          ),
          ReadingBlock.callout(
            title: 'Parámetro no es lo mismo que argumento',
            body:
                'El parámetro es lo que define la función: en "def sumar(a, b)", '
                'a y b son parámetros. El argumento es lo que pasas al llamarla: '
                'en "sumar(5, 3)", el 5 y el 3 son argumentos.',
            tone: CalloutTone.info,
          ),
        ],
      ),
      ReadingPage(
        title: 'Parámetros y argumentos',
        summary:
            'Posicionales, nombrados y con valor por defecto: tres formas de '
            'pasar datos a una función.',
        blocks: [
          ReadingBlock.code(
            title: 'Posicionales: el orden importa',
            code:
                'def resta(a, b):\n'
                '    return a - b\n\n'
                'resta(10, 3)   # 7\n'
                'resta(3, 10)   # -7  ← orden distinto, resultado distinto',
            codeCaption:
                'Al pasar los argumentos por posición, cambiar el orden cambia '
                'el resultado.',
          ),
          ReadingBlock.code(
            title: 'Nombrados: el orden deja de importar',
            code:
                'def presentar(nombre, edad, ciudad):\n'
                '    return f"{nombre}, {edad} años, vive en {ciudad}"\n\n'
                'presentar("Juan", 25, "Madrid")                    # posicional\n'
                'presentar(nombre="Juan", edad=25, ciudad="Madrid") # nombrado\n'
                'presentar(ciudad="Madrid", nombre="Juan", edad=25) # ¡también vale!',
            codeCaption:
                'Si se indica el nombre de cada parámetro al llamar la función, '
                'el orden ya no importa y el código se lee mejor.',
          ),
          ReadingBlock.code(
            title: 'Valores por defecto',
            code:
                'def saludar(nombre, saludo="Hola"):\n'
                '    return f"{saludo}, {nombre}"\n\n'
                'saludar("Juan")                 # Hola, Juan\n'
                'saludar("Juan", "Buenos días")  # Buenos días, Juan\n\n'
                '# Los parámetros con defecto SIEMPRE van al final\n'
                'def mal(saludo="Hola", nombre):  # ← error de sintaxis\n'
                'def bien(nombre, saludo="Hola"): # ← correcto',
            codeCaption:
                'Un parámetro con valor por defecto se vuelve opcional. Esos '
                'parámetros tienen que ir siempre después de los obligatorios.',
          ),
          ReadingBlock.callout(
            title: 'La trampa de la lista mutable por defecto',
            body:
                'Los valores por defecto se evalúan una sola vez. Si pones una '
                'lista vacía como valor por defecto, esa misma lista se '
                'compartirá entre todas las llamadas y se irá llenando. La '
                'solución es poner None por defecto y crear la lista dentro de '
                'la función.',
            tone: CalloutTone.danger,
          ),
        ],
      ),
      ReadingPage(
        title: 'Return: devolver valores',
        summary:
            'return entrega un resultado y termina la función en ese punto.',
        blocks: [
          ReadingBlock.code(
            title: 'Devolver varios valores',
            code:
                'def obtener_coordenadas():\n'
                '    return 10, 20        # devuelve una tupla\n\n'
                'x, y = obtener_coordenadas()   # se desempaqueta\n\n\n'
                'def obtener_datos():\n'
                '    return {"nombre": "Juan", "edad": 25}\n\n'
                'datos = obtener_datos()\n'
                'print(datos["nombre"])',
            codeCaption:
                'Python permite devolver varios valores separados por comas, que '
                'llegan como una tupla y se pueden repartir en varias variables. '
                'Para muchos datos con nombre, es mejor devolver un diccionario.',
          ),
          ReadingBlock.code(
            title: 'Return anticipado: menos anidación',
            code:
                '# Anidado y difícil de leer\n'
                'def procesar(usuario):\n'
                '    if usuario:\n'
                '        if usuario["activo"]:\n'
                '            if usuario["saldo"] > 0:\n'
                '                return True\n'
                '    return False\n\n\n'
                '# Con return anticipado: mucho más limpio\n'
                'def procesar(usuario):\n'
                '    if not usuario:\n'
                '        return False\n'
                '    if not usuario["activo"]:\n'
                '        return False\n'
                '    if usuario["saldo"] <= 0:\n'
                '        return False\n'
                '    return True',
            body:
                'Descartar los casos inválidos al principio deja el camino feliz '
                'al final, sin niveles de indentación innecesarios.',
            codeCaption:
                'La primera versión anida tres condiciones una dentro de otra. '
                'La segunda descarta cada caso inválido por separado y devuelve '
                'falso de inmediato, dejando el caso válido al final.',
          ),
          ReadingBlock.callout(
            title: 'Sin return, la función devuelve None',
            body:
                'Si una función solo imprime y no tiene return, al asignar su '
                'resultado a una variable obtendrás None. Es un error muy común '
                'al empezar.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
      ReadingPage(
        title: 'Documentación y argumentos variables',
        summary:
            'Un docstring explica la función. *args y **kwargs le dan '
            'flexibilidad total.',
        blocks: [
          ReadingBlock.code(
            title: 'Docstring completo',
            code:
                'def calcular_area_circulo(radio):\n'
                '    """Calcula el área de un círculo.\n\n'
                '    Args:\n'
                '        radio (float): el radio del círculo en unidades.\n\n'
                '    Returns:\n'
                '        float: el área del círculo.\n\n'
                '    Raises:\n'
                '        ValueError: si el radio es negativo.\n'
                '    """\n'
                '    import math\n'
                '    if radio < 0:\n'
                '        raise ValueError("El radio no puede ser negativo")\n'
                '    return math.pi * radio ** 2\n\n\n'
                'help(calcular_area_circulo)   # muestra el docstring',
            codeCaption:
                'El docstring va justo debajo del def, entre triples comillas, y '
                'describe qué recibe la función, qué devuelve y qué errores puede '
                'lanzar. La función help lo muestra.',
          ),
          ReadingBlock.code(
            title: '*args y **kwargs',
            code:
                'def sumar(*numeros):\n'
                '    """Suma cualquier cantidad de números."""\n'
                '    total = 0\n'
                '    for numero in numeros:\n'
                '        total += numero\n'
                '    return total\n\n'
                'sumar(1, 2, 3)        # 6\n'
                'sumar(1, 2, 3, 4, 5)  # 15\n\n\n'
                'def crear_perfil(**datos):\n'
                '    """Crea un perfil con datos variables."""\n'
                '    for clave, valor in datos.items():\n'
                '        print(f"{clave}: {valor}")\n\n'
                'crear_perfil(nombre="Juan", edad=25, ciudad="Madrid")',
            body:
                'Un asterisco recoge argumentos posicionales en una tupla. Dos '
                'asteriscos recogen argumentos nombrados en un diccionario.',
            codeCaption:
                'Con un asterisco delante del parámetro la función acepta '
                'cualquier cantidad de valores sueltos. Con dos asteriscos acepta '
                'cualquier cantidad de pares nombre igual valor.',
          ),
          ReadingBlock.callout(
            title: 'El orden es obligatorio',
            body:
                'Primero los parámetros posicionales, después *args, después los '
                'que tienen valor por defecto, y al final **kwargs. Cualquier '
                'otro orden provoca un error de sintaxis.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
      ReadingPage(
        title: 'Decoradores y buenas prácticas',
        summary:
            'Un decorador es una función que modifica el comportamiento de otra '
            'sin tocar su código.',
        blocks: [
          ReadingBlock.code(
            title: 'Decorador cronometrador',
            code:
                'import time\n\n'
                'def cronometrador(funcion):\n'
                '    def envoltura(*args, **kwargs):\n'
                '        inicio = time.time()\n'
                '        resultado = funcion(*args, **kwargs)\n'
                '        fin = time.time()\n'
                '        print(f"{funcion.__name__} tardó {fin - inicio:.4f} segundos")\n'
                '        return resultado\n'
                '    return envoltura\n\n\n'
                '@cronometrador\n'
                'def tarea_lenta():\n'
                '    time.sleep(2)\n'
                '    return "Hecho"\n\n'
                'tarea_lenta()   # tarea_lenta tardó 2.0015 segundos',
            codeCaption:
                'El decorador envuelve la función original: mide el tiempo '
                'antes y después de ejecutarla, imprime cuánto tardó y devuelve '
                'el resultado original. Se aplica escribiendo arroba seguido del '
                'nombre del decorador encima de la función.',
          ),
          ReadingBlock.bullets(
            title: 'Cuatro reglas para funciones sanas',
            items: [
              'Funciones pequeñas y enfocadas: si necesitas decir "esta función valida, transforma y guarda", necesitas tres funciones.',
              'Usa parámetros en lugar de variables globales: hace la función testeable y predecible.',
              'Nombres descriptivos: calcular_precio_con_iva es mejor que calc.',
              'Documenta lo que no es obvio: si tu función recursiva es lenta para valores grandes, dilo en el docstring.',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuál es la diferencia entre parámetro y argumento?',
      options: [
        'Son lo mismo',
        'El parámetro es lo que define la función y el argumento lo que pasas al llamarla',
        'El argumento define la función y el parámetro es lo que pasas',
        'Los parámetros son siempre números',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué es el scope?',
      options: [
        'Una herramienta para ver el código',
        'El área donde una variable es accesible',
        'Un tipo de función',
        'Un decorador especial',
      ],
      correctIndex: 1,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuál es la función principal de un docstring?',
      options: [
        'Acelerar la ejecución del código',
        'Documentar qué hace la función, qué parámetros recibe y qué devuelve',
        'Proteger la función de cambios',
        'Evitar errores de sintaxis',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál es el orden correcto de parámetros en una función?',
      options: [
        'args, posicionales, keyword, kwargs',
        'Posicionales, *args, keyword con valor por defecto, **kwargs',
        'kwargs, args, keyword, posicionales',
        'Cualquier orden funciona',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué devuelve una función que no tiene return?',
      options: ['0', 'Una cadena vacía', 'None', 'Un error'],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Para qué sirve **kwargs?',
      options: [
        'Para multiplicar los argumentos',
        'Para recibir una cantidad variable de argumentos nombrados en un diccionario',
        'Para hacer la función privada',
        'Para documentar la función',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: funciones, no paredes de código',
    headline: 'La diferencia entre código y arquitectura',
    intro:
        'Un principiante ve una tarea y escribe 100 líneas seguidas. Un '
        'profesional ve la misma tarea y la divide en 5 funciones de 20 líneas. '
        'El segundo código es más fácil de leer, probar, reutilizar y mantener.',
    tips: [
      CapsuleTip(
        title: 'Una función, una responsabilidad',
        body:
            'Si necesitas decir "esta función valida, transforma y guarda", '
            'necesitas tres funciones.',
      ),
      CapsuleTip(
        title: 'Los parámetros son tu contrato',
        body:
            'Son lo que prometes aceptar. Deben estar bien documentados. Si un '
            'parámetro es opcional, dale un valor por defecto.',
      ),
      CapsuleTip(
        title: 'El return es tu promesa de valor',
        body:
            'Dice qué recibirá quien llame la función. Si puede fallar, devuelve '
            'None o lanza una excepción, pero sé consistente.',
      ),
    ],
    closing:
        'Las funciones son el lenguaje con el que hablamos a otros '
        'programadores. Haz que sea claro.',
  ),
  example: CodeExample(
    title: 'Una función con todas sus partes',
    description:
        'Docstring, valores por defecto, validación, return anticipado y '
        '**kwargs trabajando juntos.',
    code:
        'def generar_reporte(titulo, datos, formato="texto", **opciones):\n'
        '    """Genera un reporte a partir de una lista de datos.\n\n'
        '    Args:\n'
        '        titulo (str): encabezado del reporte.\n'
        '        datos (list): valores numéricos a resumir.\n'
        '        formato (str): "texto" o "csv". Por defecto "texto".\n'
        '        **opciones: ajustes extra, por ejemplo decimales=2.\n\n'
        '    Returns:\n'
        '        str: el reporte listo para imprimir, o None si no hay datos.\n'
        '    """\n'
        '    # Return anticipado: descartamos lo inválido primero\n'
        '    if not datos:\n'
        '        print("No hay datos para reportar")\n'
        '        return None\n\n'
        '    decimales = opciones.get("decimales", 2)\n'
        '    total = sum(datos)\n'
        '    promedio = total / len(datos)\n\n'
        '    if formato == "csv":\n'
        '        return f"titulo,total,promedio\\n{titulo},{total},{promedio:.{decimales}f}"\n\n'
        '    lineas = [\n'
        '        f"=== {titulo.upper()} ===",\n'
        '        f"Registros: {len(datos)}",\n'
        '        f"Total:     {total}",\n'
        '        f"Promedio:  {promedio:.{decimales}f}",\n'
        '    ]\n'
        '    return "\\n".join(lineas)\n\n\n'
        'ventas = [1200, 980, 1550, 1340]\n\n'
        'print(generar_reporte("Ventas del trimestre", ventas))\n'
        'print()\n'
        'print(generar_reporte("Ventas", ventas, formato="csv", decimales=1))\n'
        'print()\n'
        'print(generar_reporte("Vacío", []))',
    codeCaption:
        'La función recibe un título, una lista de datos, un formato opcional y '
        'cualquier cantidad de opciones extra. Si la lista está vacía avisa y '
        'devuelve None de inmediato. Si no, calcula total y promedio y devuelve '
        'el reporte en formato de texto o separado por comas según se pida.',
    output:
        '=== VENTAS DEL TRIMESTRE ===\n'
        'Registros: 4\n'
        'Total:     5070\n'
        'Promedio:  1267.50\n'
        '\n'
        'titulo,total,promedio\n'
        'Ventas,5070,1267.5\n'
        '\n'
        'No hay datos para reportar\n'
        'None',
    steps: [
      ExampleStep(
        code:
            'def generar_reporte(titulo, datos, formato="texto", **opciones):',
        explanation:
            'El orden correcto: primero los obligatorios, luego el que tiene '
            'valor por defecto, y al final **kwargs.',
      ),
      ExampleStep(
        code: '"""Genera un reporte a partir de una lista de datos. ..."""',
        explanation:
            'El docstring documenta parámetros y retorno. Es lo que muestra '
            'help() y lo que ve tu editor al autocompletar.',
      ),
      ExampleStep(
        code: 'if not datos:\n    return None',
        explanation:
            'Return anticipado: descartamos el caso inválido al principio y '
            'evitamos anidar el resto del código.',
      ),
      ExampleStep(
        code: 'decimales = opciones.get("decimales", 2)',
        explanation:
            'get lee una opción del diccionario **kwargs y usa 2 si no se pasó '
            'ninguna.',
      ),
      ExampleStep(
        code: 'return "\\n".join(lineas)',
        explanation:
            'Construir una lista y unirla al final es más eficiente que ir '
            'concatenando texto en cada paso.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: anatomía de una función',
    instructions: 'Relaciona cada parte con lo que hace.',
    pairs: [
      ConceptPair(
        concept: 'Definición de función',
        definition:
            'Bloque de código reutilizable identificado con un nombre '
            'específico.',
      ),
      ConceptPair(
        concept: 'Parámetros y argumentos',
        definition:
            'El parámetro es lo que define la función; el argumento es lo que '
            'pasas al llamarla.',
      ),
      ConceptPair(
        concept: 'Return',
        definition: 'Devuelve un valor y termina la ejecución de la función.',
      ),
      ConceptPair(
        concept: 'Docstring',
        definition:
            'Texto entre triples comillas que documenta qué hace la función, '
            'qué recibe y qué devuelve.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 2: Variables locales y globales
// ---------------------------------------------------------------------------

const CourseSection _seccion2 = CourseSection(
  id: 'm4-s2',
  shortTitle: 'Variables\nlocales y\nglobales',
  videos: [
    SectionVideo(
      title: 'Ejercicios con funciones (parte 1)',
      youtubeId: 'nMU2ti3WJJY',
      duration: '28:28',
      description: 'Clase 6.1. Qué variables ve una función y cuáles no.',
      transcript:
          'Al resolver ejercicios se ve con claridad el alcance de las '
          'variables: las que se crean dentro de una función desaparecen '
          'al terminar, y modificar una variable de fuera exige '
          'declararla global. Muestra también el error UnboundLocalError '
          'y por qué aparece.',
    ),
    SectionVideo(
      title: 'Ejercicios con funciones (parte 2)',
      youtubeId: 'EhE40DM31es',
      duration: '18:35',
      description:
          'Clase 6.2. Pasar valores en lugar de usar variables globales.',
      transcript:
          'Continúa con ejercicios donde la solución limpia es pasar los '
          'datos como parámetros y devolver el resultado, en lugar de '
          'compartir variables globales entre funciones.',
    ),
  ],
  moduleNumber: 4,
  number: 2,
  title: 'Variables locales y globales',
  summary:
      'Dónde vive cada variable: scope local, global, la regla LEGB, global, '
      'nonlocal y closures.',
  objectives: [
    'Distinguir variables locales de globales.',
    'Usar global y nonlocal solo cuando corresponde.',
    'Entender el orden de búsqueda LEGB.',
    'Reconocer y escribir closures.',
    'Preferir parámetros y retornos frente a variables globales.',
  ],
  reading: SectionReading(
    title: 'Dominando el scope: el orden invisible del código',
    intro:
        'Imagina dos habitaciones: tu cuarto (local) y la sala (global). Lo que '
        'está en tu cuarto solo lo usas tú. Entender dónde vive una variable es '
        'la clave para escribir código que funcione.',
    pages: [
      ReadingPage(
        title: 'Scope local: tu habitación privada',
        summary:
            'Una variable creada dentro de una función solo existe dentro de esa '
            'función.',
        blocks: [
          ReadingBlock.code(
            title: 'Nace y muere con la función',
            code:
                'def saludar():\n'
                '    nombre = "Juan"   # variable local\n'
                '    print(nombre)     # aquí sí existe\n\n'
                'saludar()      # imprime Juan\n'
                'print(nombre)  # ← error: name "nombre" is not defined',
            body:
                'Cuando la función termina, la variable desaparece de la '
                'memoria.',
            codeCaption:
                'Dentro de la función la variable nombre funciona sin problema, '
                'pero al intentar usarla fuera Python avisa de que no existe.',
          ),
          ReadingBlock.code(
            title: 'Cada llamada crea variables nuevas',
            code:
                'def contar():\n'
                '    contador = 0     # nueva variable en cada llamada\n'
                '    contador += 1\n'
                '    return contador\n\n'
                'print(contar())  # 1\n'
                'print(contar())  # 1  ← no es 2\n'
                'print(contar())  # 1',
            body:
                'Los parámetros también son variables locales: existen solo '
                'mientras dura la función.',
            codeCaption:
                'Cada vez que se llama la función el contador vuelve a empezar '
                'en cero, así que siempre devuelve uno.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Scope global y la palabra global',
        summary:
            'Una variable creada fuera de toda función se puede leer desde '
            'cualquier parte, pero modificarla requiere avisar.',
        blocks: [
          ReadingBlock.code(
            title: 'Leer sí, modificar no',
            code:
                'nombre = "Juan"   # variable global\n\n'
                'def saludar():\n'
                '    print(nombre)   # ✓ puedo LEERLA sin problema\n\n\n'
                'contador = 0\n\n'
                'def incrementar():\n'
                '    contador = contador + 1   # ✗ UnboundLocalError\n'
                '    return contador',
            body:
                'Python ve una asignación y asume que la variable es local. '
                'Luego intenta leer una variable local que todavía no existe.',
            codeCaption:
                'Leer una variable global desde dentro de una función funciona. '
                'Intentar modificarla sin avisar provoca un error, porque Python '
                'la trata como local.',
          ),
          ReadingBlock.code(
            title: 'La palabra clave global',
            code:
                'contador = 0\n\n'
                'def incrementar():\n'
                '    global contador     # "voy a usar la variable global"\n'
                '    contador += 1\n'
                '    return contador\n\n'
                'print(incrementar())  # 1\n'
                'print(incrementar())  # 2\n'
                'print(contador)       # 2',
            body:
                'La declaración global debe ir al inicio de la función, antes de '
                'usar la variable.',
            codeCaption:
                'Declarando global antes de tocar la variable, la función sí '
                'puede modificar el contador que vive fuera, y el valor se '
                'conserva entre llamadas.',
          ),
          ReadingBlock.callout(
            title: 'Solo necesitas global cuando MODIFICAS',
            body:
                'Si únicamente lees la variable, no hace falta declarar nada. '
                'Es un malentendido muy frecuente.',
            tone: CalloutTone.warning,
          ),
        ],
      ),
      ReadingPage(
        title: 'Nonlocal, closures y LEGB',
        summary:
            'nonlocal modifica variables de la función que envuelve. Un closure '
            'es una función que recuerda.',
        blocks: [
          ReadingBlock.code(
            title: 'nonlocal: modificar el scope que envuelve',
            code:
                'def funcion_externa():\n'
                '    x = 10\n\n'
                '    def funcion_interna():\n'
                '        nonlocal x    # modifica la x de la función padre\n'
                '        x = 20\n\n'
                '    funcion_interna()\n'
                '    print(x)   # 20 — sin nonlocal seguiría siendo 10',
            codeCaption:
                'La palabra nonlocal permite que una función anidada modifique '
                'una variable de la función que la contiene.',
          ),
          ReadingBlock.code(
            title: 'Closures: funciones que recuerdan',
            code:
                'def crear_multiplicador(factor):\n'
                '    """Crea una función que multiplica por un factor fijo."""\n'
                '    def multiplicar(numero):\n'
                '        return numero * factor   # recuerda "factor"\n'
                '    return multiplicar\n\n\n'
                'por_2 = crear_multiplicador(2)\n'
                'por_3 = crear_multiplicador(3)\n\n'
                'print(por_2(5))  # 10\n'
                'print(por_3(5))  # 15',
            body: 'Cada closure captura su propia copia del valor.',
            codeCaption:
                'La función externa fabrica funciones. Cada una recuerda el '
                'factor con el que fue creada, así que por dos multiplica por '
                'dos y por tres multiplica por tres.',
          ),
          ReadingBlock.bullets(
            title: 'LEGB: el orden de búsqueda',
            body: 'Cuando Python busca una variable, mira en este orden:',
            items: [
              'L de Local: dentro de la función actual.',
              'E de Enclosing: en la función que la contiene, si está anidada.',
              'G de Global: en el módulo.',
              'B de Built-in: entre las funciones predefinidas de Python.',
            ],
          ),
          ReadingBlock.callout(
            title: 'La trampa de los closures dentro de bucles',
            body:
                'Si creas funciones dentro de un for, todas comparten la misma '
                'variable del bucle y acaban devolviendo el último valor. La '
                'solución es capturar el valor en un parámetro con valor por '
                'defecto, o usar una función fábrica.',
            tone: CalloutTone.danger,
          ),
        ],
      ),
      ReadingPage(
        title: 'Evitar global: el camino profesional',
        summary:
            'Cuanto más local sea una variable, menos posibilidades hay de que '
            'algo la rompa.',
        blocks: [
          ReadingBlock.code(
            title: 'De global a funciones puras',
            code:
                '# ✗ Acoplado y difícil de probar\n'
                'contador = 0\n\n'
                'def incrementar():\n'
                '    global contador\n'
                '    contador += 1\n\n\n'
                '# ✓ Función pura: entra un valor, sale otro\n'
                'def incrementar(contador):\n'
                '    return contador + 1\n\n'
                'contador = 0\n'
                'contador = incrementar(contador)   # 1',
            codeCaption:
                'La primera versión depende de una variable externa y es difícil '
                'de probar. La segunda recibe el valor y devuelve el nuevo: es '
                'predecible y reutilizable.',
          ),
          ReadingBlock.code(
            title: 'O mejor aún: una clase',
            code:
                'class Contador:\n'
                '    def __init__(self):\n'
                '        self.valor = 0\n\n'
                '    def incrementar(self):\n'
                '        self.valor += 1\n\n'
                '    def decrementar(self):\n'
                '        self.valor -= 1\n\n'
                'contador = Contador()\n'
                'contador.incrementar()\n'
                'print(contador.valor)   # 1',
            body:
                'El estado queda encapsulado dentro del objeto, no suelto en el '
                'módulo.',
            codeCaption:
                'Una clase guarda el valor dentro del objeto y expone métodos '
                'para subirlo o bajarlo, sin necesidad de variables globales.',
          ),
          ReadingBlock.bullets(
            title: 'Siete reglas de oro del scope',
            items: [
              'Las variables locales son privadas: viven solo dentro de su función.',
              'Las variables globales son accesibles desde cualquier lugar.',
              'global permite modificar una variable global; úsalo lo mínimo.',
              'nonlocal permite modificar la variable de la función que envuelve.',
              'Prefiere parámetros y retornos: son más limpios que global.',
              'Los closures son poderosos, pero cuidado dentro de bucles.',
              'El orden de búsqueda siempre es LEGB.',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuándo necesitas usar la palabra clave global?',
      options: [
        'Siempre que uses una variable global',
        'Solo cuando LEES una variable global',
        'Solo cuando MODIFICAS una variable global',
        'Nunca, Python lo hace automáticamente',
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Qué es un closure?',
      options: [
        'Una función que termina',
        'Una función que cierra un archivo',
        'Una función que recuerda variables de su ámbito externo',
        'Un tipo de error',
      ],
      correctIndex: 2,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Qué significan las siglas LEGB?',
      options: [
        'List, Enclosing, Global, Built-in',
        'Local, Enclosing, Global, Built-in',
        'Loop, Enclosing, Global, Built-in',
        'Local, Enclose, Global, Bind',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál es la diferencia entre global y nonlocal?',
      options: [
        'No hay diferencia',
        'global modifica variables del módulo y nonlocal las de la función que envuelve',
        'global es más rápido',
        'nonlocal solo funciona dentro de bucles',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Qué ocurre si intentas modificar una variable global dentro de una '
          'función sin declararla?',
      options: [
        'Se modifica sin problema',
        'Python lanza un UnboundLocalError porque la trata como local',
        'La función se detiene silenciosamente',
        'Se crea una copia de la variable global',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Por qué se recomienda evitar las variables globales?',
      options: [
        'Porque ocupan más memoria',
        'Porque cualquier parte del programa puede modificarlas, lo que dificulta probar y depurar',
        'Porque Python las eliminará en futuras versiones',
        'Porque no funcionan dentro de clases',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: el scope es tu guardaespaldas',
    headline: 'Pequeño ámbito, código grande',
    intro:
        'La regla más importante que casi nadie te dice: mantén todo lo más '
        'local posible. Cuanto más local es una variable, menos posibilidades '
        'hay de que algo la rompa.',
    tips: [
      CapsuleTip(
        title: 'Local: el nivel más seguro',
        body:
            'Solo existe dentro de la función. Nadie más puede tocarla. Fácil de '
            'probar y fácil de cambiar.',
      ),
      CapsuleTip(
        title: 'Enclosing: segura, con complejidad moderada',
        body:
            'Útil para funciones especializadas con closures. Ten cuidado '
            'cuando los creas dentro de bucles.',
      ),
      CapsuleTip(
        title: 'Global: el nivel más peligroso',
        body:
            'Cualquiera puede modificarla, es difícil de depurar y frágil ante '
            'cambios. Si escribes una función que modifica una global en cada '
            'llamada, serás tú quien tenga que depurar por qué falla en ciertos '
            'casos.',
      ),
    ],
    closing:
        'Ahórrate el dolor: usa parámetros y returns, y deja las globales para '
        'cuando no haya alternativa.',
  ),
  example: CodeExample(
    title: 'Sistema bancario con scope correcto',
    description:
        'Todo el estado vive encapsulado dentro de la clase. Ni una sola '
        'variable global.',
    code:
        'class Banco:\n'
        '    """Sistema bancario que evita variables globales."""\n\n'
        '    def __init__(self, nombre):\n'
        '        self.nombre = nombre\n'
        '        self._cuentas = {}    # estado privado del objeto\n\n'
        '    # ---- métodos públicos ----\n\n'
        '    def crear_cuenta(self, numero, titular, saldo_inicial=0.0):\n'
        '        if numero in self._cuentas:\n'
        '            print(f"La cuenta {numero} ya existe")\n'
        '            return False\n\n'
        '        self._cuentas[numero] = {"titular": titular, "saldo": saldo_inicial}\n'
        '        print(f"Cuenta {numero} creada para {titular}")\n'
        '        return True\n\n'
        '    def depositar(self, numero, cantidad):\n'
        '        if not self._validar(numero, cantidad):\n'
        '            return False\n\n'
        '        self._cuentas[numero]["saldo"] += cantidad\n'
        '        print(f"Depósito de {cantidad:.2f}. Saldo: {self._saldo(numero):.2f}")\n'
        '        return True\n\n'
        '    def retirar(self, numero, cantidad):\n'
        '        if not self._validar(numero, cantidad):\n'
        '            return False\n\n'
        '        if cantidad > self._saldo(numero):\n'
        '            print(f"Fondos insuficientes. Saldo: {self._saldo(numero):.2f}")\n'
        '            return False\n\n'
        '        self._cuentas[numero]["saldo"] -= cantidad\n'
        '        print(f"Retiro de {cantidad:.2f}. Saldo: {self._saldo(numero):.2f}")\n'
        '        return True\n\n'
        '    # ---- métodos privados: scope interno de la clase ----\n\n'
        '    def _validar(self, numero, cantidad):\n'
        '        if numero not in self._cuentas:\n'
        '            print(f"La cuenta {numero} no existe")\n'
        '            return False\n'
        '        if cantidad <= 0:\n'
        '            print("La cantidad debe ser positiva")\n'
        '            return False\n'
        '        return True\n\n'
        '    def _saldo(self, numero):\n'
        '        return self._cuentas[numero]["saldo"]\n\n\n'
        'def demostrar():\n'
        '    banco = Banco("Banco Central")   # variable LOCAL de esta función\n\n'
        '    banco.crear_cuenta("001", "Juan García", 1000.00)\n'
        '    banco.depositar("001", 500)\n'
        '    banco.retirar("001", 2000)\n'
        '    banco.retirar("001", 300)\n'
        '    # Al terminar la función, "banco" desaparece de la memoria\n\n\n'
        'demostrar()',
    codeCaption:
        'La clase Banco guarda las cuentas en un diccionario interno. Los '
        'métodos públicos crean cuentas, depositan y retiran; los métodos '
        'privados, marcados con guion bajo, validan y consultan el saldo. La '
        'función de demostración crea el banco como variable local, así que al '
        'terminar desaparece.',
    output:
        'Cuenta 001 creada para Juan García\n'
        'Depósito de 500.00. Saldo: 1500.00\n'
        'Fondos insuficientes. Saldo: 1500.00\n'
        'Retiro de 300.00. Saldo: 1200.00',
    steps: [
      ExampleStep(
        code: 'self._cuentas = {}',
        explanation:
            'El estado vive dentro del objeto, no en el módulo. Cada Banco tiene '
            'sus propias cuentas.',
      ),
      ExampleStep(
        code: 'def _validar(self, numero, cantidad):',
        explanation:
            'El guion bajo marca el método como interno: se usa desde dentro de '
            'la clase, no desde fuera.',
      ),
      ExampleStep(
        code: 'if not self._validar(numero, cantidad):\n    return False',
        explanation:
            'Return anticipado reutilizando la validación: ni depositar ni '
            'retirar repiten esas comprobaciones.',
      ),
      ExampleStep(
        code: 'banco = Banco("Banco Central")',
        explanation:
            'Variable local de la función demostrar. Nadie fuera de esa función '
            'puede alcanzarla ni modificarla por accidente.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: dónde vive cada variable',
    instructions: 'Relaciona cada ámbito con su característica.',
    pairs: [
      ConceptPair(
        concept: 'Scope local',
        definition:
            'La variable existe solo dentro de la función y desaparece al '
            'terminar.',
      ),
      ConceptPair(
        concept: 'Scope global',
        definition:
            'La variable vive en el módulo y puede leerse desde cualquier '
            'función.',
      ),
      ConceptPair(
        concept: 'Palabra clave global',
        definition:
            'Permite que una función modifique una variable del módulo, no solo '
            'leerla.',
      ),
      ConceptPair(
        concept: 'Palabra clave nonlocal',
        definition:
            'Permite que una función anidada modifique una variable de la '
            'función que la contiene.',
      ),
      ConceptPair(
        concept: 'Closure',
        definition:
            'Función que recuerda las variables del ámbito donde fue creada.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 3: Funciones recursivas — pendiente de contenido
// ---------------------------------------------------------------------------

const CourseSection _seccion3 = CourseSection(
  id: 'm4-s3',
  shortTitle: 'Funciones\nrecursivas',
  videos: [
    SectionVideo(
      title: 'Explicación del taller 2',
      youtubeId: '1w2wHBcZszw',
      duration: '4:40',
      description: 'Clase 6.3. Enunciado del taller de funciones.',
      transcript:
          'Video corto que plantea el taller de funciones. Sirve como '
          'punto de partida para practicar antes de entrar en recursión.',
    ),
  ],
  moduleNumber: 4,
  number: 3,
  title: 'Funciones recursivas',
  summary:
      'Funciones que se llaman a sí mismas: caso base, caso recursivo y cuándo '
      'conviene usarlas.',
  objectives: [
    'Identificar el caso base y el caso recursivo.',
    'Escribir funciones recursivas sencillas como el factorial.',
    'Comparar una solución recursiva con una iterativa.',
  ],
  hasLaboratory: false,
);
