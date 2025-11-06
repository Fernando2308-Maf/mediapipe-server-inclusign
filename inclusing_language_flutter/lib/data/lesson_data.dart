import '../models/lesson.dart';
import '../services/api_service.dart';

/// Datos hardcodeados de las 27 lecciones del alfabeto (A-Z + Ñ)
/// Basado en la implementación del proyecto MAUI
class LessonData {
  static final ApiService _apiService = ApiService();
  static Map<String, String> _abecedarioCache = {};
  static final List<Map<String, dynamic>> _alphabetData = [
    {
      'letter': 'A',
      'emoji': '🤟',
      'description':
          'Cierra tu mano en un puño y levanta el pulgar hacia arriba. El pulgar debe apuntar hacia el cielo mientras los demás dedos permanecen cerrados.',
      'wrongOptions': [
        'Mano abierta con todos los dedos extendidos',
        'Puño cerrado sin pulgar visible',
        'Índice y pulgar formando un círculo'
      ]
    },
    {
      'letter': 'B',
      'emoji': '🖐️',
      'description':
          'Extiende todos los dedos juntos hacia arriba con la palma hacia adelante. El pulgar debe estar pegado a la palma. Los dedos deben estar derechos y juntos.',
      'wrongOptions': [
        'Dedos separados en forma de estrella',
        'Solo tres dedos extendidos',
        'Mano cerrada con pulgar arriba'
      ]
    },
    {
      'letter': 'C',
      'emoji': '👌',
      'description':
          'Curva tu mano formando la letra "C" con la palma mirando hacia afuera. Los dedos deben estar curvados como una media luna. El espacio entre el pulgar y los dedos forma la C.',
      'wrongOptions': [
        'Puño completamente cerrado',
        'Círculo perfecto con índice y pulgar',
        'Dedos rectos apuntando hacia arriba'
      ]
    },
    {
      'letter': 'D',
      'emoji': '☝️',
      'description':
          'Levanta el dedo índice apuntando hacia arriba. Une el pulgar con los dedos medio, anular y meñique formando un círculo. El índice debe estar completamente recto.',
      'wrongOptions': [
        'Todos los dedos extendidos',
        'Puño cerrado con pulgar arriba',
        'Solo el meñique levantado'
      ]
    },
    {
      'letter': 'E',
      'emoji': '✊',
      'description':
          'Cierra todos los dedos en un puño con el pulgar sobre los dedos. Los dedos deben estar doblados hacia la palma y el pulgar descansa sobre ellos.',
      'wrongOptions': [
        'Pulgar hacia arriba',
        'Dedos extendidos',
        'Puño con pulgar dentro'
      ]
    },
    {
      'letter': 'F',
      'emoji': '👌',
      'description':
          'Junta la punta del pulgar con la punta del índice formando un círculo. Los otros tres dedos (medio, anular, meñique) deben estar extendidos y separados hacia arriba.',
      'wrongOptions': [
        'Todos los dedos cerrados',
        'Solo el índice y medio unidos',
        'Mano completamente abierta'
      ]
    },
    {
      'letter': 'G',
      'emoji': '👈',
      'description':
          'Extiende el índice y el pulgar horizontalmente apuntando hacia un lado. Los demás dedos deben estar cerrados. Forma una "L" acostada.',
      'wrongOptions': [
        'Solo el pulgar extendido',
        'Índice apuntando hacia arriba',
        'Todos los dedos cerrados'
      ]
    },
    {
      'letter': 'H',
      'emoji': '✌️',
      'description':
          'Extiende el índice y el medio juntos horizontalmente. El pulgar, anular y meñique deben estar doblados. Los dos dedos extendidos deben estar juntos y paralelos.',
      'wrongOptions': [
        'Dedos en forma de V separados',
        'Solo un dedo extendido',
        'Tres dedos extendidos'
      ]
    },
    {
      'letter': 'I',
      'emoji': '🤙',
      'description':
          'Levanta solo el dedo meñique apuntando hacia arriba. Todos los demás dedos incluyendo el pulgar deben estar cerrados en un puño.',
      'wrongOptions': [
        'Índice levantado',
        'Pulgar y meñique extendidos',
        'Todos los dedos cerrados'
      ]
    },
    {
      'letter': 'J',
      'emoji': '🤙',
      'description':
          'Levanta el meñique y dibuja una "J" en el aire con un movimiento. Comienza con el meñique hacia arriba y mueve la mano hacia abajo y luego en gancho.',
      'wrongOptions': [
        'Meñique estático sin movimiento',
        'Movimiento circular con la mano',
        'Índice dibujando en el aire'
      ]
    },
    {
      'letter': 'K',
      'emoji': '✌️',
      'description':
          'Levanta el índice y el medio formando una V. Coloca el pulgar entre ambos dedos tocando el medio. El anular y meñique deben estar cerrados.',
      'wrongOptions': [
        'V simple sin pulgar',
        'Tres dedos extendidos',
        'Dedos juntos sin separación'
      ]
    },
    {
      'letter': 'L',
      'emoji': '🤞',
      'description':
          'Extiende el pulgar e índice formando una "L" perpendicular. El índice debe apuntar hacia arriba y el pulgar hacia un lado. Los demás dedos cerrados.',
      'wrongOptions': [
        'Dedos formando círculo',
        'Todos los dedos extendidos',
        'Dedos paralelos'
      ]
    },
    {
      'letter': 'M',
      'emoji': '✊',
      'description':
          'Cierra la mano en puño y coloca el pulgar entre el meñique, anular y medio. Los tres primeros dedos deben descansar sobre el pulgar.',
      'wrongOptions': [
        'Pulgar afuera del puño',
        'Cuatro dedos sobre el pulgar',
        'Puño simple sin pulgar visible'
      ]
    },
    {
      'letter': 'N',
      'emoji': '✊',
      'description':
          'Forma un puño y coloca el pulgar entre el índice y medio. Solo dos dedos (índice y medio) descansan sobre el pulgar.',
      'wrongOptions': [
        'Tres dedos sobre el pulgar',
        'Pulgar completamente escondido',
        'Todos los dedos extendidos'
      ]
    },
    {
      'letter': 'Ñ',
      'emoji': '🤟',
      'description':
          'Similar a la N pero agrega un movimiento ondulatorio hacia los lados. Forma la N y mueve la mano ligeramente de lado a lado representando la tilde.',
      'wrongOptions': [
        'N estática sin movimiento',
        'Movimiento vertical',
        'Círculos con la mano'
      ]
    },
    {
      'letter': 'O',
      'emoji': '👌',
      'description':
          'Une todos los dedos con el pulgar formando un círculo perfecto u óvalo. Todos los dedos deben tocarse en las puntas formando la O.',
      'wrongOptions': [
        'Solo índice y pulgar unidos',
        'Dedos separados',
        'Puño cerrado'
      ]
    },
    {
      'letter': 'P',
      'emoji': '👇',
      'description':
          'Similar a la K pero apuntando hacia abajo. El índice y medio forman V invertida, con el pulgar entre ellos, y la mano apunta al suelo.',
      'wrongOptions': [
        'K apuntando hacia arriba',
        'Todos los dedos hacia abajo',
        'Solo un dedo apuntando'
      ]
    },
    {
      'letter': 'Q',
      'emoji': '👇',
      'description':
          'Similar a la G pero apuntando hacia abajo. El índice y pulgar extendidos forman una L que apunta al suelo.',
      'wrongOptions': [
        'G horizontal normal',
        'Pulgar hacia arriba',
        'Dedos apuntando a los lados'
      ]
    },
    {
      'letter': 'R',
      'emoji': '🤞',
      'description':
          'Cruza el dedo medio sobre el índice. Ambos dedos deben estar extendidos y el medio cruza por encima del índice. Los demás dedos cerrados.',
      'wrongOptions': [
        'Dedos paralelos sin cruzar',
        'Índice sobre el medio',
        'Todos los dedos cruzados'
      ]
    },
    {
      'letter': 'S',
      'emoji': '✊',
      'description':
          'Cierra la mano en un puño con el pulgar sobre los dedos. El pulgar debe estar al frente cubriendo los demás dedos.',
      'wrongOptions': [
        'Pulgar hacia arriba',
        'Pulgar escondido dentro',
        'Dedos extendidos'
      ]
    },
    {
      'letter': 'T',
      'emoji': '👍',
      'description':
          'Forma un puño y coloca el pulgar entre el índice y medio, pero el pulgar debe sobresalir un poco hacia afuera.',
      'wrongOptions': [
        'Pulgar completamente dentro',
        'Pulgar arriba como señal de OK',
        'Todos los dedos extendidos'
      ]
    },
    {
      'letter': 'U',
      'emoji': '✌️',
      'description':
          'Levanta el índice y medio juntos y rectos apuntando hacia arriba. Deben estar completamente pegados. Los demás dedos cerrados.',
      'wrongOptions': [
        'Dedos separados en V',
        'Tres dedos levantados',
        'Dedos horizontales'
      ]
    },
    {
      'letter': 'V',
      'emoji': '✌️',
      'description':
          'Levanta el índice y medio separados formando una "V". Los dedos deben estar bien separados. El pulgar, anular y meñique cerrados.',
      'wrongOptions': [
        'Dedos juntos sin separación',
        'Tres dedos en V',
        'V invertida hacia abajo'
      ]
    },
    {
      'letter': 'W',
      'emoji': '🖖',
      'description':
          'Extiende el índice, medio y anular separados formando una W. Los tres dedos deben estar separados. El meñique y pulgar cerrados.',
      'wrongOptions': [
        'Solo dos dedos levantados',
        'Cuatro dedos extendidos',
        'Dedos juntos sin separación'
      ]
    },
    {
      'letter': 'X',
      'emoji': '☝️',
      'description':
          'Dobla el índice formando un gancho curvo. El dedo debe estar curvado como una X. Los demás dedos cerrados con el pulgar sobre ellos.',
      'wrongOptions': [
        'Índice completamente recto',
        'Todos los dedos curvos',
        'Puño completamente cerrado'
      ]
    },
    {
      'letter': 'Y',
      'emoji': '🤙',
      'description':
          'Extiende el pulgar y el meñique hacia afuera. Los dedos medio, anular e índice deben estar cerrados. Forma una Y con los dos dedos extendidos.',
      'wrongOptions': [
        'Solo el meñique extendido',
        'Solo el pulgar extendido',
        'Todos los dedos cerrados'
      ]
    },
    {
      'letter': 'Z',
      'emoji': '☝️',
      'description':
          'Extiende el índice y dibuja una "Z" en el aire con un movimiento. Mueve el dedo haciendo la forma de la Z: diagonal hacia abajo, horizontal, y diagonal hacia abajo.',
      'wrongOptions': [
        'Índice estático sin movimiento',
        'Movimiento circular',
        'Línea recta vertical'
      ]
    },
  ];

  /// Cargar imágenes del abecedario desde MongoDB
  static Future<void> loadAbecedarioImages() async {
    try {
      final abecedario = await _apiService.getAbecedario();
      for (var item in abecedario) {
        final letra = item['nombre'] as String?;
        final contenido = item['contenido'] as String?;
        if (letra != null && contenido != null) {
          _abecedarioCache[letra] = contenido;
        }
      }
      print('✅ Imágenes del abecedario cargadas: ${_abecedarioCache.length}');
    } catch (e) {
      print('❌ Error cargando imágenes del abecedario: $e');
    }
  }

  /// Generar todas las lecciones del alfabeto con sus ejercicios
  static Future<List<Lesson>> generateAlphabetLessons() async {
    // Cargar imágenes si no están en cache
    if (_abecedarioCache.isEmpty) {
      await loadAbecedarioImages();
    }

    return _alphabetData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final letter = data['letter'] as String;
      final imageBase64 = _abecedarioCache[letter] ?? '';

      return Lesson(
        id: index + 1,
        title: 'Letra $letter',
        category: 'Alphabet',
        letter: letter,
        description: data['description'],
        imageUrl: data['emoji'],
        imageBase64: imageBase64,  // Imagen desde MongoDB
        order: index + 1,
        experiencePoints: 25, // 5 + 10 + 10 = 25 puntos totales
        difficulty: DifficultyLevel.basic,
        estimatedMinutes: 5,
        exercises: _generateExercises(data, index + 1, imageBase64),
        learningTips: _generateTips(letter),
      );
    }).toList();
  }

  /// Generar los 3 ejercicios para una lección
  static List<Exercise> _generateExercises(Map<String, dynamic> data, int lessonId, String imageBase64) {
    final letter = data['letter'];
    final emoji = data['emoji'];
    final description = data['description'];
    final wrongOptions = List<String>.from(data['wrongOptions']);

    return [
      // Ejercicio 1: Practice (Ver y Aprender)
      Exercise(
        id: 1,
        type: ExerciseType.practice,
        question: '¡Aprende la letra $letter!',
        correctAnswer: description,
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Observa cuidadosamente cómo se forma esta letra con las manos.',
        points: 5,
      ),

      // Ejercicio 2: Sign Recognition (¿Qué letra es esta?)
      Exercise(
        id: 2,
        type: ExerciseType.signRecognition,
        question: '¿Qué letra representa este signo?',
        correctAnswer: letter,
        options: _generateLetterOptions(letter),
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Recuerda la posición de los dedos que acabas de aprender.',
        points: 10,
      ),

      // Ejercicio 3: Multiple Choice (¿Cómo se hace?)
      Exercise(
        id: 3,
        type: ExerciseType.multipleChoice,
        question: '¿Cómo se hace la seña para la letra $letter?',
        correctAnswer: description,
        options: [description, ...wrongOptions]..shuffle(),
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Piensa en la descripción que leíste en el primer ejercicio.',
        points: 10,
      ),
    ];
  }

  /// Generar opciones de letras para el ejercicio de reconocimiento
  static List<String> _generateLetterOptions(String correctLetter) {
    final allLetters = _alphabetData.map((d) => d['letter'] as String).toList();
    allLetters.remove(correctLetter);
    allLetters.shuffle();

    final options = [correctLetter, ...allLetters.take(3)];
    options.shuffle();

    return options;
  }

  /// Generar tips de aprendizaje
  static List<String> _generateTips(String letter) {
    final commonTips = [
      'Practica frente a un espejo para ver tu mano desde la perspectiva del observador',
      'Mantén la posición durante 3-5 segundos para desarrollar memoria muscular',
      'Asegúrate de que tus dedos estén en la posición correcta antes de continuar',
    ];

    return commonTips;
  }

  /// Obtener lección por ID
  static Future<Lesson?> getLessonById(int id) async {
    final lessons = await generateAlphabetLessons();
    try {
      return lessons.firstWhere((lesson) => lesson.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtener todas las lecciones por categoría
  static Future<List<Lesson>> getLessonsByCategory(String category) async {
    if (category.toLowerCase() == 'alphabet') {
      return await generateAlphabetLessons();
    }
    // Futuro: Numbers, Words
    return [];
  }
}
