import 'package:flutter_code4all/domain/models/python_course_content/course_catalog_models.dart';

/// Módulo 5. Metodología para resolver problemas.
///
/// Nota de contenido: el material entregado organiza este módulo como
/// Algoritmos, Análisis de problemas y Diseño en pseudocódigo. El catálogo
/// sigue esa secuencia.
const CourseModule module5 = CourseModule(
  number: 5,
  title: 'Metodología para resolver problemas',
  sections: [_seccion1, _seccion2, _seccion3],
);

// ---------------------------------------------------------------------------
// Capítulo 1: Algoritmos
// ---------------------------------------------------------------------------

const CourseSection _seccion1 = CourseSection(
  id: 'm5-s1',
  shortTitle: 'Algoritmos',
  videos: [
    SectionVideo(
      title: 'Resolver problemas paso a paso (parte 1)',
      youtubeId: 'JCD57P63snE',
      duration: '6:52',
      description: 'Clase 8.1. Del enunciado a los pasos.',
      transcript:
          'Toma un enunciado y lo convierte en una secuencia de pasos '
          'antes de escribir código. Es la definición práctica de '
          'algoritmo: un plan claro, finito y que realmente resuelve el '
          'problema.',
    ),
    SectionVideo(
      title: 'Resolver problemas paso a paso (parte 2)',
      youtubeId: 'BAAcMHoKOj4',
      duration: '12:41',
      description:
          'Clase 8.2. Tipos de pasos: secuencia, decisión y repetición.',
      transcript:
          'Segundo ejemplo donde se distinguen los tres tipos de pasos '
          'que forman cualquier algoritmo: los que van en secuencia, los '
          'que dependen de una condición y los que se repiten.',
    ),
  ],
  moduleNumber: 5,
  number: 1,
  title: 'Algoritmos',
  summary:
      'Qué es un algoritmo, qué lo hace bueno, de qué tipos hay y cómo se '
      'representa antes de escribir una línea de código.',
  objectives: [
    'Definir qué es un algoritmo y distinguirlo del código.',
    'Reconocer las cuatro características de un buen algoritmo.',
    'Identificar algoritmos secuenciales, condicionales, iterativos y recursivos.',
    'Representar un algoritmo en pseudocódigo o diagrama de flujo.',
  ],
  reading: SectionReading(
    title: 'Algoritmos: los planos de tu código',
    intro:
        'Un algoritmo es la receta. El código es cuando realmente cocinas. La '
        'receta no es comida, pero sin ella el pastel probablemente salga mal.',
    pages: [
      ReadingPage(
        title: '¿Qué es un algoritmo?',
        summary:
            'Un conjunto de pasos ordenados y lógicos para resolver un '
            'problema. No es código: es el plan antes del código.',
        blocks: [
          ReadingBlock.steps(
            title: 'Algoritmo: cómo llegar a la universidad',
            items: [
              'Despierta a las 7 de la mañana.',
              'Ducha y desayuna: quince minutos.',
              'Toma el transporte hacia la estación.',
              'Espera el bus, máximo diez minutos.',
              'Sube al bus.',
              'Baja en la parada de la universidad.',
              'Camina cinco cuadras.',
              'Llegas a la puerta principal.',
            ],
          ),
          ReadingBlock.steps(
            title: 'Algoritmo: buscar una palabra en un diccionario',
            items: [
              'Abre el diccionario por el medio.',
              'Mira la primera letra de la palabra en esa página.',
              'Si tu palabra viene antes alfabéticamente, abre la mitad izquierda.',
              'Si viene después, abre la mitad derecha.',
              'Repite hasta encontrar la palabra.',
              'Lee la definición.',
            ],
          ),
          ReadingBlock.callout(
            title: 'No son mágicos: son pasos claros',
            body:
                'Todo lo que haces mecánicamente cada día es un algoritmo que ya '
                'tienes interiorizado. Programar es escribirlos para que otra '
                'máquina los siga.',
            tone: CalloutTone.info,
          ),
        ],
      ),
      ReadingPage(
        title: 'Características de un buen algoritmo',
        summary: 'Claridad, finitud, efectividad y eficiencia.',
        blocks: [
          ReadingBlock.bullets(
            title: 'Claridad',
            body: 'Cada paso es claro y sin ambigüedad.',
            items: [
              'Mal: "hacer algo con los números".',
              'Bien: "sumar todos los números pares de la lista".',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Finitud',
            body: 'El algoritmo debe terminar en algún momento.',
            items: [
              'Mal: "repetir infinitamente".',
              'Bien: "repetir mientras queden elementos por procesar".',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Efectividad y eficiencia',
            items: [
              'Efectivo: realmente resuelve el problema. Un algoritmo que nunca termina, o que da resultados incorrectos, no lo es.',
              'Eficiente: usa recursos razonables. Uno que tarda diez horas en procesar cien datos no es práctico.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Tipos de algoritmos',
        summary:
            'Secuenciales, condicionales, iterativos y recursivos: cuatro '
            'formas de organizar los pasos.',
        blocks: [
          ReadingBlock.code(
            title: 'Secuencial: un paso tras otro',
            code:
                'Algoritmo: calcular el área de un rectángulo\n'
                'Entrada: largo y ancho\n\n'
                'Paso 1: recibir el valor del largo\n'
                'Paso 2: recibir el valor del ancho\n'
                'Paso 3: multiplicar largo por ancho\n'
                'Paso 4: mostrar el resultado\n'
                'Fin',
            codeCaption:
                'Los pasos se ejecutan en orden, uno después de otro, sin '
                'bifurcaciones ni repeticiones.',
          ),
          ReadingBlock.code(
            title: 'Condicional: el camino se bifurca',
            code:
                'Algoritmo: determinar si un número es par o impar\n'
                'Entrada: un número\n\n'
                'Paso 1: recibir el número\n'
                'Paso 2: ¿el número es divisible entre 2?\n'
                '        SÍ → mostrar "Es par"\n'
                '        NO → mostrar "Es impar"\n'
                'Paso 3: Fin',
            codeCaption:
                'Algunos pasos solo se ejecutan si se cumple una condición.',
          ),
          ReadingBlock.code(
            title: 'Iterativo: algunos pasos se repiten',
            code:
                'Algoritmo: sumar los primeros 10 números naturales\n\n'
                'Paso 1: crear una variable suma = 0\n'
                'Paso 2: crear una variable contador = 1\n'
                'Paso 3: mientras contador sea menor o igual a 10:\n'
                '        - sumar contador a suma\n'
                '        - incrementar contador\n'
                'Paso 4: mostrar suma\n'
                'Paso 5: Fin',
            codeCaption:
                'Un bloque de pasos se repite mientras se cumpla una condición.',
          ),
          ReadingBlock.code(
            title: 'Recursivo: la función se llama a sí misma',
            code:
                'Algoritmo: calcular factorial (5! = 5×4×3×2×1)\n'
                'Entrada: número n\n\n'
                'Paso 1: ¿n es 0 o 1?\n'
                '        SÍ → retornar 1          (caso base)\n'
                '        NO → retornar n × factorial(n-1)\n'
                'Paso 2: Fin',
            body:
                'El caso base es lo que impide que la recursión sea infinita.',
            codeCaption:
                'El algoritmo se invoca a sí mismo con un valor más pequeño '
                'hasta llegar al caso base, que devuelve uno y detiene la '
                'cadena.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Formas de representar un algoritmo',
        summary:
            'Pseudocódigo, diagrama de flujo o código real: tres niveles de '
            'concreción.',
        blocks: [
          ReadingBlock.code(
            title: 'Pseudocódigo',
            code:
                'Algoritmo: buscar un número en una lista\n'
                'Entrada: lista de números, número a buscar\n'
                'Salida: posición del número, o -1 si no existe\n\n'
                'INICIO\n'
                '    posición ← -1\n'
                '    PARA cada índice en la lista HACER\n'
                '        SI lista[índice] == número_buscado ENTONCES\n'
                '            posición ← índice\n'
                '            SALIR\n'
                '        FIN SI\n'
                '    FIN PARA\n'
                '    RETORNAR posición\n'
                'FIN',
            codeCaption:
                'Se escribe en lenguaje casi natural, con palabras como INICIO, '
                'PARA, SI y RETORNAR. No se ejecuta en la computadora: se ejecuta '
                'en tu cabeza.',
          ),
          ReadingBlock.code(
            title: 'El mismo algoritmo en código real',
            code:
                'def buscar_numero(lista, numero_buscado):\n'
                '    posicion = -1\n'
                '    for indice in range(len(lista)):\n'
                '        if lista[indice] == numero_buscado:\n'
                '            posicion = indice\n'
                '            break\n'
                '    return posicion',
            codeCaption:
                'La misma lógica, ahora escrita en Python y lista para '
                'ejecutarse.',
          ),
          ReadingBlock.bullets(
            title: 'Algoritmo frente a código',
            items: [
              'El algoritmo es independiente del lenguaje; el código depende de Python, JavaScript o el que uses.',
              'El algoritmo describe el qué y el cómo conceptualmente; el código lo implementa.',
              'El algoritmo se puede escribir en papel; el código necesita una computadora para ejecutarse.',
              'El algoritmo es la idea y el plan; el código es la realización de ese plan.',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt:
          '¿Cuál es la principal diferencia entre un algoritmo y un código?',
      options: [
        'El algoritmo es más rápido que el código',
        'El algoritmo es independiente del lenguaje y el código no',
        'El código es solo para Python y el algoritmo para todos',
        'Son exactamente lo mismo',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál de las siguientes opciones describe mejor un algoritmo?',
      options: [
        'Un programa que se ejecuta en la computadora',
        'Un conjunto de instrucciones ordenadas para resolver un problema',
        'Un error en el código',
        'Una herramienta de programación',
      ],
      correctIndex: 1,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuáles son las cuatro características de un buen algoritmo?',
      options: [
        'Rapidez, belleza, longitud y color',
        'Claridad, finitud, efectividad y eficiencia',
        'Compilación, ejecución, depuración y despliegue',
        'Entrada, proceso, salida y error',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          'En un algoritmo recursivo, ¿qué impide que la recursión sea '
          'infinita?',
      options: [
        'La velocidad del procesador',
        'El caso base, que devuelve un valor sin volver a llamarse',
        'El número de parámetros',
        'La indentación',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál de estas NO es una forma válida de representar un algoritmo?',
      options: [
        'Pseudocódigo',
        'Diagrama de flujo',
        'Código real en un lenguaje de programación',
        'El resultado que imprime el programa',
      ],
      correctIndex: 3,
      explanation:
          'La salida es el resultado de ejecutar el algoritmo, no una forma de '
          'representarlo.',
    ),
    QuizQuestion(
      prompt: '¿Qué tipo de algoritmo repite un bloque de pasos?',
      options: ['Secuencial', 'Condicional', 'Iterativo', 'Descriptivo'],
      correctIndex: 2,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: piensa primero, codifica después',
    headline:
        'Los algoritmos son la diferencia entre un programador y un ingeniero',
    intro:
        'Un programador escribe código que "funciona". Un ingeniero piensa en '
        'algoritmos antes de tocar el teclado.',
    tips: [
      CapsuleTip(
        title: 'Son independientes de la moda',
        body:
            'Hoy usas Python, mañana Rust. Pero los algoritmos funcionan igual '
            'en ambos: lo que aprendes no caduca.',
      ),
      CapsuleTip(
        title: 'Son la base de la optimización',
        body:
            'La diferencia entre un segundo y una hora no está en la CPU: está '
            'en el algoritmo.',
      ),
      CapsuleTip(
        title: 'Son más fáciles de depurar',
        body:
            'Un algoritmo claro produce código claro, y el código claro tiene '
            'menos errores.',
      ),
    ],
    closing:
        'Antes de escribir la primera línea, escribe los pasos. Te ahorrará '
        'horas.',
  ),
  example: CodeExample(
    title: 'Del pseudocódigo al código: recomendar libros',
    description:
        'Problema: recomendar libros a un usuario basándose en los géneros que '
        'ya le gustan. Primero el algoritmo, después el código.',
    code:
        'def recomendar_libros(libros_usuario, base_datos, num_recomendaciones=5):\n'
        '    """Recomienda libros según los géneros que el usuario ya lee.\n\n'
        '    Args:\n'
        '        libros_usuario: lista de libros que el usuario ya leyó.\n'
        '        base_datos: lista de todos los libros disponibles.\n'
        '        num_recomendaciones: cuántos libros recomendar.\n\n'
        '    Returns:\n'
        '        list: los libros recomendados, mejor calificados primero.\n'
        '    """\n'
        '    # 1. Extraer los géneros que le gustan\n'
        '    generos_usuario = set()\n'
        '    for libro in libros_usuario:\n'
        "        generos_usuario.add(libro['genero'])\n\n"
        '    # 2. Títulos ya leídos, para no repetirlos\n'
        "    titulos_leidos = {libro['titulo'] for libro in libros_usuario}\n\n"
        '    # 3. Buscar libros del mismo género que aún no ha leído\n'
        '    recomendaciones = []\n'
        '    for libro in base_datos:\n'
        "        if libro['genero'] in generos_usuario and libro['titulo'] not in titulos_leidos:\n"
        '            recomendaciones.append(libro)\n\n'
        '    # 4. Ordenar por calificación, de mayor a menor\n'
        "    recomendaciones.sort(key=lambda x: x['calificacion'], reverse=True)\n\n"
        '    # 5. Devolver solo los primeros N\n'
        '    return recomendaciones[:num_recomendaciones]\n\n\n'
        'libros_usuario = [\n'
        "    {'titulo': 'El Quijote', 'genero': 'Clásico'},\n"
        "    {'titulo': '1984', 'genero': 'Ciencia Ficción'},\n"
        "    {'titulo': 'El Hobbit', 'genero': 'Fantasía'}\n"
        ']\n\n'
        'base_datos = [\n'
        "    {'titulo': 'Orgullo y Prejuicio', 'genero': 'Clásico', 'calificacion': 4.8},\n"
        "    {'titulo': 'Fundación', 'genero': 'Ciencia Ficción', 'calificacion': 4.9},\n"
        "    {'titulo': 'El Señor de los Anillos', 'genero': 'Fantasía', 'calificacion': 4.9},\n"
        "    {'titulo': 'Neuromante', 'genero': 'Ciencia Ficción', 'calificacion': 4.6},\n"
        "    {'titulo': 'Crepúsculo', 'genero': 'Romance', 'calificacion': 3.2}\n"
        ']\n\n'
        'for i, libro in enumerate(recomendar_libros(libros_usuario, base_datos, 3), 1):\n'
        '    print(f"{i}. {libro[\'titulo\']} ({libro[\'genero\']}) - {libro[\'calificacion\']}")',
    codeCaption:
        'La función reúne los géneros que le gustan al usuario, arma un '
        'conjunto con lo que ya leyó, recorre la base de datos buscando libros '
        'del mismo género que aún no haya leído, los ordena por calificación de '
        'mayor a menor y devuelve solo los primeros. Después se imprimen las '
        'tres mejores recomendaciones.',
    output:
        '1. Fundación (Ciencia Ficción) - 4.9\n'
        '2. El Señor de los Anillos (Fantasía) - 4.9\n'
        '3. Neuromante (Ciencia Ficción) - 4.6',
    steps: [
      ExampleStep(
        code: 'generos_usuario = set()',
        explanation:
            'Un conjunto elimina duplicados automáticamente: si el usuario tiene '
            'tres libros de fantasía, el género aparece una sola vez.',
      ),
      ExampleStep(
        code: "titulos_leidos = {libro['titulo'] for libro in libros_usuario}",
        explanation:
            'Comprensión de conjunto: arma en una línea la colección de títulos '
            'ya leídos, para descartarlos después.',
      ),
      ExampleStep(
        code: "if libro['genero'] in generos_usuario and ...",
        explanation:
            'Dos condiciones con and: mismo género Y no leído todavía. Este es '
            'el paso 3 del pseudocódigo.',
      ),
      ExampleStep(
        code:
            "recomendaciones.sort(key=lambda x: x['calificacion'], reverse=True)",
        explanation:
            'Ordena por el campo calificación. reverse=True pone las mejores '
            'primero.',
      ),
      ExampleStep(
        code: 'return recomendaciones[:num_recomendaciones]',
        explanation:
            'Slicing sobre la lista: se devuelven solo los primeros N '
            'resultados.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: tipos de algoritmo',
    instructions: 'Relaciona cada tipo con su descripción.',
    pairs: [
      ConceptPair(
        concept: 'Secuencial',
        definition: 'Los pasos se ejecutan uno tras otro, en orden.',
      ),
      ConceptPair(
        concept: 'Condicional',
        definition:
            'Algunos pasos se ejecutan solo si se cumple una condición.',
      ),
      ConceptPair(
        concept: 'Iterativo',
        definition: 'Algunos pasos se repiten varias veces.',
      ),
      ConceptPair(
        concept: 'Recursivo',
        definition:
            'El algoritmo se llama a sí mismo hasta llegar a un caso base.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 2: Análisis de problemas
// ---------------------------------------------------------------------------

const CourseSection _seccion2 = CourseSection(
  id: 'm5-s2',
  shortTitle: 'Análisis de\nproblemas',
  videos: [
    SectionVideo(
      title: 'Analizar antes de codificar (parte 1)',
      youtubeId: 'D3TYsAtm7IM',
      duration: '24:17',
      description: 'Clase 8.3. Entradas, salidas y casos extremos.',
      transcript:
          'Antes de programar, identifica qué datos entran, qué debe '
          'salir y qué situaciones poco frecuentes podrían romper la '
          'solución. Es el método de análisis que describe la lectura de '
          'esta sección.',
    ),
    SectionVideo(
      title: 'Analizar antes de codificar (parte 2)',
      youtubeId: '5uY3XslgI60',
      duration: '16:52',
      description: 'Clase 8.4. Descomponer un problema grande.',
      transcript:
          'Parte un problema grande en subproblemas manejables y los '
          'resuelve uno a uno. También revisa qué restricciones impone el '
          'enunciado y cómo comprobar que la solución es correcta.',
    ),
  ],
  moduleNumber: 5,
  number: 2,
  title: 'Análisis de problemas',
  summary:
      'Desglosa, entiende y conquista: comprender el problema antes de escribir '
      'una sola línea.',
  objectives: [
    'Aplicar los cinco pilares del análisis de problemas.',
    'Identificar entradas, procesos y salidas.',
    'Descomponer un problema grande en subproblemas.',
    'Detectar restricciones y casos extremos.',
  ],
  reading: SectionReading(
    title: 'Análisis de problemas: entender antes de hacer',
    intro:
        'Un cirujano no opera sin estudios previos. Un ingeniero no construye '
        'un puente sin analizar el suelo. Un programador no debería escribir '
        'código sin analizar el problema.',
    pages: [
      ReadingPage(
        title: 'Los cinco pilares',
        summary:
            'Comprensión, descomposición, identificación de datos, '
            'restricciones y validación.',
        blocks: [
          ReadingBlock.callout(
            title: 'La estadística que duele',
            body:
                'La mayoría de los errores en programación vienen de una mala '
                'comprensión del problema, no de errores de código. Pasar treinta '
                'minutos analizando te ahorra horas depurando. El código sin '
                'análisis es como un taxi sin GPS: anda, pero se pierde.',
            tone: CalloutTone.warning,
          ),
          ReadingBlock.bullets(
            title: 'Los cinco pilares',
            items: [
              'Comprensión: ¿realmente entiendes qué se te pide? Lee el problema dos o tres veces.',
              'Descomposición: divide el problema grande en subproblemas pequeños.',
              'Identificación de datos: ¿qué información tienes y cuál necesitas?',
              'Restricciones: ¿hay limitaciones de tiempo, memoria o reglas especiales?',
              'Validación: ¿cómo sabrás que tu solución es correcta?',
            ],
          ),
          ReadingBlock.steps(
            title: 'Cómo leer un enunciado',
            items: [
              'Lee completo, sin hacer nada. Absorbe el contexto general.',
              'Identifica las palabras clave: verbos como agregar, buscar, listar, vender, reportar.',
              'Haz preguntas: ¿cuántos elementos como máximo? ¿dónde se guardan los datos? ¿qué pasa si no existe lo que busco?',
              'Resume el problema en tus propias palabras, en una o dos frases.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Entrada, proceso y salida',
        summary:
            'Una de las herramientas más poderosas: separar qué entra, qué pasa '
            'y qué sale.',
        blocks: [
          ReadingBlock.code(
            title: 'Ejemplo: sistema de librería',
            code:
                'ENTRADA (INPUT)\n'
                '├─ Título del libro (texto)\n'
                '├─ Autor (texto)\n'
                '├─ ISBN (identificador único)\n'
                '├─ Precio (número decimal)\n'
                '└─ Cantidad en inventario (entero)\n\n'
                'PROCESO (LÓGICA)\n'
                '├─ Validar que los datos no estén vacíos\n'
                '├─ Verificar que el ISBN sea único\n'
                '├─ Guardar en la estructura de datos\n'
                '└─ Actualizar el inventario\n\n'
                'SALIDA (OUTPUT)\n'
                '├─ Confirmación: "Libro agregado exitosamente"\n'
                '├─ Lista de libros\n'
                '├─ Resultado de la búsqueda\n'
                '└─ Reporte de ventas',
            codeCaption:
                'Un esquema en tres columnas: qué datos entran, qué hace el '
                'sistema con ellos y qué devuelve al usuario.',
          ),
          ReadingBlock.code(
            title: 'Descomposición en subproblemas',
            code:
                'PROBLEMA GRANDE: sistema de gestión de librería\n\n'
                'SUBPROBLEMA 1: gestionar libros\n'
                '├─ Agregar libro\n'
                '├─ Buscar libro\n'
                '└─ Listar libros\n\n'
                'SUBPROBLEMA 2: gestionar inventario\n'
                '├─ Actualizar cantidad\n'
                '├─ Verificar disponibilidad\n'
                '└─ Alertar si el stock está bajo\n\n'
                'SUBPROBLEMA 3: gestionar ventas\n'
                '├─ Registrar venta\n'
                '├─ Reducir inventario\n'
                '└─ Calcular total\n\n'
                'SUBPROBLEMA 4: generar reportes',
            body: 'Ahora cada subproblema es manejable. Divide y conquistarás.',
            codeCaption:
                'El problema grande se abre en cuatro subproblemas, y cada uno '
                'en tres o cuatro tareas concretas.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Restricciones y casos extremos',
        summary:
            'Las restricciones son límites reales. Los casos extremos son los '
            'que rompen el código frágil.',
        blocks: [
          ReadingBlock.bullets(
            title: 'Tipos de restricciones',
            items: [
              'Funcionales: no puede haber dos libros con el mismo ISBN; no se puede vender más de lo que hay en stock; el precio no puede ser negativo.',
              'De rendimiento: buscar un libro debe tardar menos de un segundo incluso con cien mil libros.',
              'De negocio: solo el dueño ve reportes; los empleados pueden vender pero no eliminar.',
              'Técnicas: debe funcionar en Windows, Mac y Linux, y sin conexión a internet.',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Casos extremos: ¿qué pasa si...?',
            items: [
              'Al agregar: ¿el título está vacío? ¿el ISBN ya existe? ¿el precio es cero o negativo?',
              'Al buscar: ¿no existe? ¿la búsqueda está vacía? ¿la base de datos está vacía?',
              'Al vender: ¿el stock es cero? ¿piden más unidades de las que hay? ¿dos ventas simultáneas del mismo libro?',
              'Al reportar: ¿no hubo ventas ese día? ¿el período solicitado está vacío?',
            ],
          ),
          ReadingBlock.bullets(
            title: 'Errores comunes al analizar',
            items: [
              'Asumir sin preguntar: "supongo que los datos van en una lista".',
              'No pensar en casos extremos: código que funciona con diez libros y falla con diez mil.',
              'Especificar de más: pedir una base de datos replicada cuando bastaba un archivo.',
              'Cambiar requisitos sin actualizar el análisis.',
              'No validar el análisis con nadie antes de empezar.',
            ],
          ),
        ],
      ),
      ReadingPage(
        title: 'Técnicas que funcionan',
        summary:
            'Los cinco porqués, los casos de uso y la matriz de '
            'responsabilidades.',
        blocks: [
          ReadingBlock.code(
            title: 'Los cinco porqués',
            code:
                'Problema: "Los empleados quieren buscar libros rápido"\n\n'
                '¿Por qué? → Porque a veces hay muchos clientes.\n'
                '¿Por qué? → Porque si no buscan rápido, pierden ventas.\n'
                '¿Por qué? → Porque el cliente se impacienta y se va.\n'
                '¿Por qué? → Porque hay otras librerías cerca.\n'
                '¿Por qué? → Porque el mercado es competitivo.\n\n'
                'CONCLUSIÓN: la búsqueda rápida es crítica.\n'
                'Necesitas un índice eficiente, no búsqueda lineal.',
            codeCaption:
                'Preguntar por qué cinco veces seguidas lleva de un síntoma '
                'superficial a la causa real, y esa causa cambia la decisión '
                'técnica.',
          ),
          ReadingBlock.code(
            title: 'Caso de uso: vender un libro',
            code:
                'Actor: empleado\n'
                'Precondición: empleado registrado, hay libros en inventario\n\n'
                'PASOS\n'
                '1. El empleado abre el sistema.\n'
                '2. Elige la opción "Realizar venta".\n'
                '3. Ingresa el título o el ISBN.\n'
                '4. El sistema busca y muestra el libro.\n'
                '5. El empleado ingresa la cantidad.\n'
                '6. El empleado confirma la venta.\n'
                '7. El sistema reduce el inventario.\n'
                '8. El sistema muestra el recibo.\n\n'
                'EXCEPCIONES\n'
                '- Si el libro no existe → mostrar "No encontrado".\n'
                '- Si el stock es menor a lo pedido → "Stock insuficiente".',
            codeCaption:
                'Un caso de uso describe paso a paso cómo una persona interactúa '
                'con el sistema, incluidas las situaciones en que algo sale mal.',
          ),
          ReadingBlock.bullets(
            title: 'Valida tu análisis antes de programar',
            body: 'Si respondes "no" a cualquiera, necesitas analizar más.',
            items: [
              '¿Puedo explicar el problema a otra persona en dos minutos?',
              '¿Sé exactamente qué entrada espero?',
              '¿Sé exactamente qué salida debo producir?',
              '¿He identificado todas las funciones principales?',
              '¿Sé cómo validar que mi solución funciona?',
              '¿He considerado los casos extremos y las restricciones?',
            ],
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuál es el propósito principal del análisis de problemas?',
      options: [
        'Escribir código lo más rápido posible',
        'Entender completamente el problema antes de codificar',
        'Impresionar al jefe con documentación',
        'Cumplir requisitos escolares',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Cuál de las siguientes NO es parte del análisis de problemas?',
      options: [
        'Identificación de entradas y salidas',
        'Descomposición en subproblemas',
        'Escribir código Python inmediatamente',
        'Identificar restricciones y casos extremos',
      ],
      correctIndex: 2,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Cuáles son los cinco pilares del análisis de problemas?',
      options: [
        'Escribir, compilar, ejecutar, probar y desplegar',
        'Comprensión, descomposición, identificación de datos, restricciones y validación',
        'Entrada, proceso, salida, error y log',
        'Planear, diseñar, codificar, documentar y vender',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué es un caso extremo (edge case)?',
      options: [
        'El código más complejo del programa',
        'Una situación poco frecuente que puede romper una solución mal pensada',
        'El último paso de un algoritmo',
        'Un error de sintaxis',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Para qué sirve la técnica de los cinco porqués?',
      options: [
        'Para escribir cinco versiones del código',
        'Para llegar de un síntoma superficial a la causa real del requisito',
        'Para dividir el equipo en cinco grupos',
        'Para documentar cinco casos de prueba',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          'Descomponer "sistema de gestión de librería" en gestionar libros, '
          'inventario, ventas y reportes es un ejemplo de:',
      options: [
        'Validación',
        'Descomposición en subproblemas',
        'Identificación de restricciones',
        'Refactorización',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: piensa como detective',
    headline: 'Antes de escribir, investiga',
    intro:
        'Cuando tienes un problema por resolver, no es hora de programar: es '
        'hora de ser detective. Un detective lee el caso completo, hace '
        'preguntas, busca pistas, identifica patrones y solo después señala al '
        'culpable.',
    tips: [
      CapsuleTip(
        title: 'La mayoría de los errores vienen del mal análisis',
        body:
            'Escribiste el código que pedían, pero no era lo que necesitaban. '
            'Eso no se arregla depurando.',
      ),
      CapsuleTip(
        title: 'El buen análisis vale más que el código bonito',
        body:
            'Código feo que funciona vale más que código bonito que no resuelve '
            'el problema real.',
      ),
      CapsuleTip(
        title: 'Analizar duele; no analizar duele más',
        body:
            'Treinta minutos de esfuerzo ahora equivalen a varias horas de '
            'dolor después.',
      ),
    ],
    closing:
        'Un programador novato lee el problema a medias, abre el editor y se '
        'frustra. Uno experimentado piensa primero.',
  ),
  example: CodeExample(
    title: 'Del análisis al código: carrito de compras',
    description:
        'Analizamos entradas, restricciones y casos extremos, y solo después '
        'escribimos las clases.',
    code:
        'class Producto:\n'
        '    """Un producto del catálogo."""\n\n'
        '    def __init__(self, id, nombre, precio, stock):\n'
        '        self.id = id\n'
        '        self.nombre = nombre\n'
        '        self.precio = precio\n'
        '        self.stock = stock\n\n'
        '    def hay_disponible(self, cantidad):\n'
        '        # RESTRICCIÓN: no se puede vender más de lo que hay\n'
        '        return self.stock >= cantidad\n\n\n'
        'class ItemCarrito:\n'
        '    """Un producto dentro del carrito, con su cantidad."""\n\n'
        '    def __init__(self, producto, cantidad):\n'
        '        self.producto = producto\n'
        '        self.cantidad = cantidad\n\n'
        '    def subtotal(self):\n'
        '        return self.producto.precio * self.cantidad\n\n\n'
        'class Carrito:\n'
        '    def __init__(self, usuario_id):\n'
        '        self.usuario_id = usuario_id\n'
        '        self.items = []\n'
        '        self.descuento = 0\n'
        '        self.tasa_impuesto = 0.16\n\n'
        '    def agregar_producto(self, producto, cantidad):\n'
        '        # CASO EXTREMO: cantidad no positiva\n'
        '        if cantidad <= 0:\n'
        '            print("Error: la cantidad debe ser positiva")\n'
        '            return False\n\n'
        '        # CASO EXTREMO: stock insuficiente\n'
        '        if not producto.hay_disponible(cantidad):\n'
        '            print(f"Error: solo hay {producto.stock} disponibles")\n'
        '            return False\n\n'
        '        # CASO EXTREMO: el producto ya está en el carrito\n'
        '        for item in self.items:\n'
        '            if item.producto.id == producto.id:\n'
        '                nueva = item.cantidad + cantidad\n'
        '                if not producto.hay_disponible(nueva):\n'
        '                    print(f"Error: no hay stock para {nueva} unidades")\n'
        '                    return False\n'
        '                item.cantidad = nueva\n'
        '                return True\n\n'
        '        self.items.append(ItemCarrito(producto, cantidad))\n'
        '        print(f"{producto.nombre} agregado al carrito")\n'
        '        return True\n\n'
        '    def calcular_totales(self):\n'
        '        # CASO EXTREMO: carrito vacío\n'
        '        if not self.items:\n'
        '            return {"subtotal": 0, "impuesto": 0, "total": 0}\n\n'
        '        subtotal = sum(item.subtotal() for item in self.items)\n'
        '        despues_descuento = subtotal - subtotal * self.descuento\n'
        '        impuesto = despues_descuento * self.tasa_impuesto\n\n'
        '        return {\n'
        '            "subtotal": round(subtotal, 2),\n'
        '            "impuesto": round(impuesto, 2),\n'
        '            "total": round(despues_descuento + impuesto, 2),\n'
        '        }\n\n\n'
        'laptop = Producto(1, "Laptop XYZ", 999.99, 10)\n'
        'mouse = Producto(2, "Mouse Inalámbrico", 25.00, 50)\n\n'
        'carrito = Carrito(usuario_id="user123")\n'
        'carrito.agregar_producto(laptop, 1)\n'
        'carrito.agregar_producto(mouse, 2)\n'
        'carrito.agregar_producto(laptop, 20)   # más que el stock\n\n'
        'carrito.descuento = 0.10\n'
        'print(carrito.calcular_totales())',
    codeCaption:
        'Tres clases construidas a partir del análisis. Producto sabe si tiene '
        'stock suficiente. ItemCarrito calcula su subtotal. Carrito valida cada '
        'caso extremo antes de agregar, y calcula totales devolviendo ceros '
        'cuando está vacío. Al final se intenta agregar veinte laptops cuando '
        'solo quedan nueve y el sistema lo rechaza.',
    output:
        'Laptop XYZ agregado al carrito\n'
        'Mouse Inalámbrico agregado al carrito\n'
        'Error: no hay stock para 21 unidades\n'
        "{'subtotal': 1049.99, 'impuesto': 151.2, 'total': 1096.19}",
    steps: [
      ExampleStep(
        code: 'if cantidad <= 0:',
        explanation:
            'Primer caso extremo detectado en el análisis: cantidades cero o '
            'negativas.',
      ),
      ExampleStep(
        code: 'if not producto.hay_disponible(cantidad):',
        explanation:
            'Restricción funcional del análisis: nunca sobrevender. Se valida '
            'antes de tocar el carrito.',
      ),
      ExampleStep(
        code:
            'for item in self.items:\n    if item.producto.id == producto.id:',
        explanation:
            'Caso extremo que solo aparece al analizar: agregar dos veces el '
            'mismo producto debe sumar cantidades, no duplicar la línea.',
      ),
      ExampleStep(
        code: 'if not self.items:\n    return {...ceros...}',
        explanation:
            'Carrito vacío: sin esta guarda, calcular el promedio o el total '
            'rompería el programa.',
      ),
      ExampleStep(
        code: 'sum(item.subtotal() for item in self.items)',
        explanation:
            'Acumula los subtotales en una sola expresión, apoyándose en el '
            'método que ya definió ItemCarrito.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: las etapas del análisis',
    instructions: 'Relaciona cada etapa con lo que produce.',
    pairs: [
      ConceptPair(
        concept: 'Comprensión',
        definition:
            'Un resumen del problema en tus propias palabras y una lista de '
            'preguntas por resolver.',
      ),
      ConceptPair(
        concept: 'Entrada, proceso y salida',
        definition:
            'Un esquema de qué datos entran, qué se hace con ellos y qué se '
            'devuelve.',
      ),
      ConceptPair(
        concept: 'Descomposición',
        definition:
            'Un problema grande convertido en subproblemas pequeños y '
            'manejables.',
      ),
      ConceptPair(
        concept: 'Restricciones',
        definition:
            'Los límites funcionales, de rendimiento, de negocio y técnicos que '
            'la solución debe respetar.',
      ),
      ConceptPair(
        concept: 'Casos extremos',
        definition:
            'La lista de situaciones poco frecuentes que romperían una solución '
            'mal pensada.',
      ),
    ],
  ),
);

// ---------------------------------------------------------------------------
// Capítulo 3: Diseño en pseudocódigo
// ---------------------------------------------------------------------------

const CourseSection _seccion3 = CourseSection(
  id: 'm5-s3',
  shortTitle: 'Diseño en\npseudocódigo',
  videos: [
    SectionVideo(
      title: 'Del diseño al programa: proyecto final',
      youtubeId: 'y3XM6vPDSWU',
      duration: '38:33',
      description: 'Clase 13.1. Presentación del proyecto final.',
      transcript:
          'Recorre el diseño de un programa completo antes de escribirlo: '
          'qué hace cada parte, cómo se conectan y en qué orden se '
          'construyen. Es el ejercicio de pseudocódigo llevado a un '
          'proyecto de verdad.',
    ),
  ],
  moduleNumber: 5,
  number: 3,
  title: 'Diseño en pseudocódigo',
  summary:
      'El puente entre entender el problema y escribir el código: pensar en voz '
      'alta, con estructura.',
  objectives: [
    'Explicar qué es el pseudocódigo y para qué sirve.',
    'Escribir pseudocódigo con el nivel de detalle correcto.',
    'Usar las estructuras de pseudocódigo: asignación, condicionales, bucles y funciones.',
    'Traducir pseudocódigo a Python.',
  ],
  reading: SectionReading(
    title: 'Pseudocódigo: el lenguaje humano de la lógica',
    intro:
        'El pseudocódigo no se ejecuta en una computadora: se ejecuta en tu '
        'mente y en la de otros programadores. Es el puente entre el análisis y '
        'el código real.',
    pages: [
      ReadingPage(
        title: '¿Qué es el pseudocódigo?',
        summary:
            'Una representación de un algoritmo en lenguaje casi natural, sin '
            'las reglas estrictas de un lenguaje de programación.',
        blocks: [
          ReadingBlock.code(
            title: 'La analogía de la receta',
            code:
                'RECETA (pseudocódigo)        COCINA (Python)\n'
                '1. Precalienta el horno      temp = 350\n'
                '2. Mezcla ingredientes       mezcla = mezclar(harina, huevo)\n'
                '3. Vierte en el molde        molde.agregar(mezcla)\n'
                '4. Hornea 30 minutos         horno.cocinar(molde, tiempo=30)\n'
                '5. Deja enfriar              esperar(10)',
            body: 'Ambas llegan al mismo pastel.',
            codeCaption:
                'A la izquierda, los pasos escritos como una receta. A la '
                'derecha, los mismos pasos escritos como código ejecutable.',
          ),
          ReadingBlock.bullets(
            title: 'Tres verdades del pseudocódigo',
            items: [
              'Es más legible que el código: no tiene sintaxis confusa, es casi español.',
              'Es independiente del lenguaje: funciona igual si luego programas en Python, JavaScript o C++.',
              'Es más fácil de revisar: alguien sin experiencia en programación puede entenderlo y validar la lógica contigo.',
            ],
          ),
          ReadingBlock.callout(
            title: 'Sin pseudocódigo versus con pseudocódigo',
            body:
                'Sin él: empiezas a programar, te pierdes a mitad del código, no '
                'sabes hacia dónde vas, el resultado es caótico. Con él: tienes '
                'un mapa claro, el código casi se escribe solo y cometes menos '
                'errores.',
            tone: CalloutTone.success,
          ),
        ],
      ),
      ReadingPage(
        title: 'Características de un buen pseudocódigo',
        summary:
            'Claridad, independencia del lenguaje y el nivel correcto de '
            'abstracción.',
        blocks: [
          ReadingBlock.code(
            title: 'Claridad: sin ambigüedad',
            code:
                '❌ MAL\n'
                'hacer algo con los números\n\n'
                '✓ BIEN\n'
                'PARA cada número en la lista HACER\n'
                '    SI número > promedio ENTONCES\n'
                '        incluir en resultado\n'
                '    FIN SI\n'
                'FIN PARA',
            codeCaption:
                'La versión mala no dice qué hacer. La buena describe el '
                'recorrido, la condición y qué se guarda.',
          ),
          ReadingBlock.code(
            title: 'El nivel correcto de abstracción',
            code:
                '❌ DEMASIADO VAGO\n'
                'Procesar datos\n\n'
                '✓ CORRECTO\n'
                'PARA cada fila en el archivo HACER\n'
                '    Extraer nombre y edad\n'
                '    SI edad >= 18 ENTONCES\n'
                '        Agregar a la lista de adultos\n'
                '    FIN SI\n'
                'FIN PARA\n\n'
                '❌ DEMASIADO DETALLADO\n'
                'Abrir archivo\n'
                'Leer línea 1\n'
                'Dividir por coma\n'
                'Acceder al índice 0...',
            body:
                'Ni tan alto que nadie entienda, ni tan bajo que ya sea código.',
            codeCaption:
                'Tres versiones del mismo paso. La primera no dice nada útil, la '
                'tercera ya es código disfrazado, y la del medio es el nivel '
                'adecuado.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Elementos del pseudocódigo',
        summary:
            'Asignación, entrada y salida, condicionales, bucles, arreglos y '
            'funciones.',
        blocks: [
          ReadingBlock.code(
            title: 'Variables, entrada y salida',
            code:
                'edad ← 25                     // asignar valor\n'
                'nombre ← "Juan"\n'
                'total ← 0\n'
                'lista ← []                    // lista vacía\n\n'
                'LEER edad                     // entrada del usuario\n'
                'MOSTRAR "Hola " + nombre      // salida a pantalla\n'
                'ESCRIBIR resultado EN archivo // salida a archivo',
            codeCaption:
                'La flecha hacia la izquierda asigna un valor. LEER recibe datos '
                'del usuario y MOSTRAR los imprime en pantalla.',
          ),
          ReadingBlock.code(
            title: 'Condicionales y bucles',
            code:
                'SI edad < 13 ENTONCES\n'
                '    MOSTRAR "Niño"\n'
                'SINO SI edad < 18 ENTONCES\n'
                '    MOSTRAR "Adolescente"\n'
                'SINO\n'
                '    MOSTRAR "Adulto"\n'
                'FIN SI\n\n'
                'MIENTRAS contador < 10 HACER\n'
                '    MOSTRAR contador\n'
                '    contador ← contador + 1\n'
                'FIN MIENTRAS\n\n'
                'PARA cada estudiante EN lista_estudiantes HACER\n'
                '    MOSTRAR nombre del estudiante\n'
                'FIN PARA\n\n'
                'REPETIR\n'
                '    LEER numero\n'
                'HASTA que numero >= 1 Y numero <= 10',
            codeCaption:
                'Las decisiones se escriben con SI, SINO SI y SINO, siempre '
                'cerradas con FIN SI. Los bucles usan MIENTRAS, PARA o REPETIR '
                'HASTA, y también se cierran explícitamente.',
          ),
          ReadingBlock.code(
            title: 'Funciones',
            code:
                'FUNCIÓN sumar(a, b)\n'
                '    resultado ← a + b\n'
                '    RETORNAR resultado\n'
                'FIN FUNCIÓN\n\n'
                'total ← sumar(5, 3)\n\n'
                '// Comentario de una línea\n'
                '/* Comentario\n'
                '   de varias líneas */',
            codeCaption:
                'Una función se abre con FUNCIÓN, su nombre y sus parámetros, '
                'devuelve un valor con RETORNAR y se cierra con FIN FUNCIÓN.',
          ),
        ],
      ),
      ReadingPage(
        title: 'Del pseudocódigo al código',
        summary:
            'La estructura general y la traducción final a Python, lado a lado.',
        blocks: [
          ReadingBlock.code(
            title: 'Estructura general',
            code:
                'ALGORITMO: [nombre descriptivo]\n'
                'ENTRADA: [qué datos recibe]\n'
                'SALIDA: [qué datos produce]\n\n'
                'INICIO\n'
                '    // Declarar variables\n'
                '    variable1 ← 0\n\n'
                '    // Lógica principal\n'
                '    SI condición ENTONCES\n'
                '        // acciones\n'
                '    FIN SI\n\n'
                '    PARA cada elemento HACER\n'
                '        // procesar\n'
                '    FIN PARA\n\n'
                '    MOSTRAR resultado\n'
                'FIN',
            codeCaption:
                'Todo pseudocódigo empieza declarando nombre, entrada y salida, '
                'y después desarrolla la lógica entre INICIO y FIN.',
          ),
          ReadingBlock.bullets(
            title: 'Pseudocódigo frente a Python',
            items: [
              'Pseudocódigo: alto nivel, conceptual. Python: específico y ejecutable.',
              'Pseudocódigo: fácil de revisar en papel. Python: necesita un editor.',
              'Pseudocódigo: sin errores de sintaxis. Python: cualquier tecla de más rompe el programa.',
              'Pseudocódigo: dos o tres páginas. Python: diez o más.',
              'Pseudocódigo: cualquiera lo entiende. Python: solo quien programa.',
              'Pseudocódigo: veinte minutos de trabajo. Python: una o dos horas.',
            ],
          ),
          ReadingBlock.callout(
            title: 'La clave',
            body:
                'El pseudocódigo guía la escritura del código. Si lo sigues, el '
                'código apenas tendrá errores de lógica: solo quedarán los de '
                'sintaxis, que el editor te señala al instante.',
            tone: CalloutTone.success,
          ),
        ],
      ),
    ],
  ),
  quiz: [
    QuizQuestion(
      prompt: '¿Cuál es la principal ventaja del pseudocódigo?',
      options: [
        'Es más rápido que el código real',
        'Se ejecuta directamente en la computadora',
        'Es independiente del lenguaje de programación',
        'Elimina la necesidad de programar',
      ],
      correctIndex: 2,
    ),
    QuizQuestion(
      prompt: '¿Cuál es el nivel correcto de abstracción para el pseudocódigo?',
      options: [
        'Extremadamente detallado, como el código real',
        'Tan vago que nadie lo entienda',
        'Claro y lógico, sin detalles técnicos innecesarios',
        'Solo con diagramas, sin palabras',
      ],
      correctIndex: 2,
    ),
  ],
  finalEvaluation: [
    QuizQuestion(
      prompt: '¿Qué símbolo se usa en pseudocódigo para asignar un valor?',
      options: [
        'Dos puntos seguidos de igual',
        'Una flecha hacia la izquierda',
        'Doble igual',
        'Un punto y coma',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Por qué el pseudocódigo ahorra tiempo?',
      options: [
        'Porque se ejecuta más rápido que Python',
        'Porque reescribir pseudocódigo incorrecto es mucho más barato que depurar código incorrecto',
        'Porque no requiere pensar',
        'Porque lo genera automáticamente el editor',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt:
          '¿Cuál de estas líneas es pseudocódigo correcto y no código real?',
      options: [
        'for i in range(len(lista)):',
        'PARA cada elemento EN lista HACER',
        'lista.append(elemento)',
        'if x == 5: print(x)',
      ],
      correctIndex: 1,
    ),
    QuizQuestion(
      prompt: '¿Qué debe declarar todo pseudocódigo al inicio?',
      options: [
        'El lenguaje de programación que se usará',
        'El nombre del algoritmo, su entrada y su salida',
        'El nombre del programador',
        'La versión de Python',
      ],
      correctIndex: 1,
    ),
  ],
  capsule: KnowledgeCapsule(
    title: 'Cápsula de conocimiento: pensar en voz alta',
    headline: 'Antes de teclear, piensa en español',
    intro:
        'El pseudocódigo no es un paso extra: es la diferencia entre programar '
        '—escribir código sin saber bien qué haces— y diseñar —pensar la '
        'solución antes de implementarla—.',
    tips: [
      CapsuleTip(
        title: 'Es más rápido que depurar',
        body:
            'Quince minutos escribiendo pseudocódigo te ahorran una hora de '
            'depuración. El código incorrecto es difícil de arreglar; el '
            'pseudocódigo incorrecto se reescribe en dos minutos.',
      ),
      CapsuleTip(
        title: 'Es comunicación',
        body:
            'Puedes mostrar tu lógica a alguien que no programa y verificar si '
            'es correcta antes de escribir una línea. Otra persona puede '
            'traducir tu pseudocódigo si a ti te falta tiempo.',
      ),
      CapsuleTip(
        title: 'Es independencia',
        body:
            'Aprendes pseudocódigo una vez y lo usas en cualquier lenguaje. Si '
            'cambias de Python a JavaScript, la lógica es la misma: solo cambian '
            'los detalles.',
      ),
    ],
    closing: 'La esencia no cambia con la sintaxis. Ese es todo el punto.',
  ),
  example: CodeExample(
    title: 'Pseudocódigo y su traducción: préstamo de biblioteca',
    description:
        'Primero la lógica en pseudocódigo, después exactamente la misma lógica '
        'en Python.',
    code:
        '# PSEUDOCÓDIGO\n'
        '#\n'
        '# FUNCIÓN realizar_prestamo(libros, prestamos)\n'
        '#     LEER id_libro, rut_usuario\n'
        '#     libro ← BUSCAR libro.id == id_libro EN libros\n'
        '#     SI libro == NULO ENTONCES\n'
        '#         MOSTRAR "Libro no encontrado"; RETORNAR\n'
        '#     FIN SI\n'
        '#     SI libro.estado != "disponible" ENTONCES\n'
        '#         MOSTRAR "No está disponible"; RETORNAR\n'
        '#     FIN SI\n'
        '#     prestamo ← CREAR con fecha de hoy y vencimiento en 14 días\n'
        '#     AGREGAR prestamo a prestamos\n'
        '#     libro.estado ← "prestado"\n'
        '#     MOSTRAR "Préstamo realizado"\n'
        '# FIN FUNCIÓN\n\n'
        '# TRADUCCIÓN A PYTHON\n'
        'from datetime import datetime, timedelta\n\n\n'
        'class Libro:\n'
        '    def __init__(self, id, titulo, autor):\n'
        '        self.id = id\n'
        '        self.titulo = titulo\n'
        '        self.autor = autor\n'
        '        self.estado = "disponible"\n\n\n'
        'class Prestamo:\n'
        '    def __init__(self, libro_id, rut_usuario):\n'
        '        self.libro_id = libro_id\n'
        '        self.rut_usuario = rut_usuario\n'
        '        self.fecha_prestamo = datetime.now()\n'
        '        self.fecha_vencimiento = datetime.now() + timedelta(days=14)\n'
        '        self.devuelto = False\n\n\n'
        'def realizar_prestamo(libros, prestamos, id_libro, rut_usuario):\n'
        '    """Presta un libro si existe y está disponible."""\n'
        '    # SI libro == NULO ENTONCES ...\n'
        '    libro = next((l for l in libros if l.id == id_libro), None)\n'
        '    if libro is None:\n'
        '        print("Libro no encontrado")\n'
        '        return False\n\n'
        '    # SI libro.estado != "disponible" ENTONCES ...\n'
        '    if libro.estado != "disponible":\n'
        '        print(f"{libro.titulo} no está disponible")\n'
        '        return False\n\n'
        '    # prestamo ← CREAR ...\n'
        '    prestamo = Prestamo(id_libro, rut_usuario)\n'
        '    prestamos.append(prestamo)\n'
        '    libro.estado = "prestado"\n\n'
        '    print(f"Préstamo realizado: {libro.titulo}")\n'
        '    print(f"Devolver antes del {prestamo.fecha_vencimiento.date()}")\n'
        '    return True\n\n\n'
        'catalogo = [\n'
        '    Libro(1, "El Quijote", "Miguel de Cervantes"),\n'
        '    Libro(2, "1984", "George Orwell"),\n'
        ']\n'
        'prestamos = []\n\n'
        'realizar_prestamo(catalogo, prestamos, 1, "12.345.678-9")\n'
        'realizar_prestamo(catalogo, prestamos, 1, "98.765.432-1")\n'
        'realizar_prestamo(catalogo, prestamos, 99, "11.111.111-1")',
    codeCaption:
        'Arriba, el pseudocódigo describe la lógica del préstamo paso a paso. '
        'Abajo, la misma lógica en Python: se busca el libro, se comprueba que '
        'exista y esté disponible, se crea el préstamo con vencimiento a '
        'catorce días y se marca el libro como prestado. Las tres llamadas '
        'finales muestran el caso exitoso, el libro ya prestado y el libro '
        'inexistente.',
    output:
        'Préstamo realizado: El Quijote\n'
        'Devolver antes del 2024-02-09\n'
        'El Quijote no está disponible\n'
        'Libro no encontrado',
    steps: [
      ExampleStep(
        code: '# SI libro == NULO ENTONCES MOSTRAR ... RETORNAR',
        explanation:
            'Cada línea del pseudocódigo se convierte en un bloque de Python. '
            'Dejar el comentario al lado hace la traducción verificable.',
      ),
      ExampleStep(
        code: 'libro = next((l for l in libros if l.id == id_libro), None)',
        explanation:
            'La instrucción BUSCAR del pseudocódigo se traduce a next con un '
            'generador: devuelve el primero que coincide, o None.',
      ),
      ExampleStep(
        code: 'if libro is None:\n    return False',
        explanation:
            'Return anticipado: el pseudocódigo decía RETORNAR, y aquí se '
            'respeta exactamente.',
      ),
      ExampleStep(
        code: 'datetime.now() + timedelta(days=14)',
        explanation:
            '"Vencimiento en 14 días" del pseudocódigo se convierte en una suma '
            'de fechas con timedelta.',
      ),
      ExampleStep(
        code: 'libro.estado = "prestado"',
        explanation:
            'La asignación con flecha del pseudocódigo pasa a ser un signo igual '
            'en Python.',
      ),
    ],
  ),
  exercise: SectionExercise(
    title: 'Ejercicio: estructuras del pseudocódigo',
    instructions: 'Relaciona cada estructura con lo que representa.',
    pairs: [
      ConceptPair(
        concept: 'Flecha hacia la izquierda',
        definition: 'Asignación: guardar un valor dentro de una variable.',
      ),
      ConceptPair(
        concept: 'SI ... ENTONCES ... SINO ... FIN SI',
        definition:
            'Decisión: ejecutar un bloque u otro según se cumpla una condición.',
      ),
      ConceptPair(
        concept: 'MIENTRAS ... HACER ... FIN MIENTRAS',
        definition: 'Repetición mientras una condición siga siendo verdadera.',
      ),
      ConceptPair(
        concept: 'PARA cada ... EN ... HACER',
        definition: 'Recorrido de todos los elementos de una colección.',
      ),
      ConceptPair(
        concept: 'FUNCIÓN ... RETORNAR ... FIN FUNCIÓN',
        definition:
            'Bloque reutilizable que recibe parámetros y devuelve un resultado.',
      ),
    ],
  ),
);
