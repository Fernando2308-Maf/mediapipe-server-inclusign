import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import '../models/lesson.dart';
import '../services/api_service.dart';

/// Datos hardcodeados de las 27 lecciones del alfabeto (A-Z + Ñ)
/// Basado en la implementación del proyecto MAUI
///
/// NOTA: Los GIFs se cargan desde assets locales (assets/gifs/) para:
/// - Carga instantánea sin depender de MongoDB
/// - Sin timeouts ni problemas de red
/// - Mejor experiencia de usuario
class LessonData {
  static final ApiService _apiService = ApiService();

  // Caché en memoria para evitar recargas
  static final Map<String, String> _abecedarioCache = {};
  static final Map<String, String> _gestosCache = {};
  static final Map<String, String> _numerosCache = {};

  /// Métodos públicos para acceder a los datos desde el diccionario
  static List<Map<String, dynamic>> getAlphabetData() => _alphabetData;
  static List<Map<String, dynamic>> getNumbersData() => _numbersData;
  static List<Map<String, dynamic>> getGesturesData() => _gesturesData;

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

  /// Datos de las 10 lecciones de números (0-9)
  static final List<Map<String, dynamic>> _numbersData = [
    {
      'number': '0',
      'emoji': '👌',
      'description':
          'Forma un círculo u óvalo con todos los dedos juntos tocando el pulgar. Todos los dedos deben tocarse formando la forma del número cero.',
      'wrongOptions': [
        'Puño cerrado completamente',
        'Solo índice y pulgar formando círculo',
        'Mano abierta con dedos separados'
      ]
    },
    {
      'number': '1',
      'emoji': '☝️',
      'description':
          'Levanta solo el dedo índice apuntando hacia arriba. Los demás dedos (pulgar, medio, anular y meñique) deben estar cerrados en un puño.',
      'wrongOptions': [
        'Pulgar levantado en lugar del índice',
        'Índice y medio levantados juntos',
        'Todos los dedos extendidos'
      ]
    },
    {
      'number': '2',
      'emoji': '✌️',
      'description':
          'Levanta el índice y el medio formando una V. Ambos dedos deben estar extendidos y separados. El pulgar, anular y meñique permanecen cerrados.',
      'wrongOptions': [
        'Dedos juntos sin separación',
        'Solo un dedo levantado',
        'Tres dedos levantados'
      ]
    },
    {
      'number': '3',
      'emoji': '🤟',
      'description':
          'Extiende el pulgar, índice y medio. Los tres dedos deben estar separados y extendidos. El anular y meñique permanecen doblados hacia la palma.',
      'wrongOptions': [
        'Solo dos dedos extendidos',
        'Cuatro dedos extendidos',
        'Dedos completamente juntos'
      ]
    },
    {
      'number': '4',
      'emoji': '🖖',
      'description':
          'Levanta cuatro dedos (índice, medio, anular y meñique) con el pulgar doblado hacia la palma. Los cuatro dedos deben estar juntos y extendidos.',
      'wrongOptions': [
        'Pulgar también extendido (5 dedos)',
        'Solo tres dedos levantados',
        'Dedos separados en forma de V'
      ]
    },
    {
      'number': '5',
      'emoji': '🖐️',
      'description':
          'Extiende todos los dedos de la mano completamente abiertos y separados. Los cinco dedos deben estar estirados formando una estrella.',
      'wrongOptions': [
        'Dedos juntos sin separación',
        'Solo cuatro dedos extendidos',
        'Mano cerrada en puño'
      ]
    },
    {
      'number': '6',
      'emoji': '🤙',
      'description':
          'Extiende el pulgar y el meñique mientras mantienes el índice, medio y anular doblados. Los dos dedos extendidos deben apuntar en direcciones opuestas.',
      'wrongOptions': [
        'Solo el meñique extendido',
        'Pulgar e índice extendidos',
        'Todos los dedos cerrados'
      ]
    },
    {
      'number': '7',
      'emoji': '🤘',
      'description':
          'Levanta el índice y el meñique mientras mantienes el pulgar sobre el medio y anular. Los dos dedos levantados deben estar bien separados.',
      'wrongOptions': [
        'Solo el índice levantado',
        'Índice y medio levantados',
        'Todos los dedos extendidos'
      ]
    },
    {
      'number': '8',
      'emoji': '🤟',
      'description':
          'Extiende el pulgar, índice y meñique. Los tres dedos deben estar separados mientras el medio y anular permanecen doblados hacia la palma.',
      'wrongOptions': [
        'Solo pulgar y meñique extendidos',
        'Todos los dedos extendidos',
        'Solo índice y meñique extendidos'
      ]
    },
    {
      'number': '9',
      'emoji': '👌',
      'description':
          'Une la punta del pulgar con la punta del índice formando un círculo. Los otros tres dedos (medio, anular y meñique) deben estar extendidos hacia arriba.',
      'wrongOptions': [
        'Todos los dedos formando círculo',
        'Solo índice levantado',
        'Pulgar y medio formando círculo'
      ]
    },
  ];

  /// Datos de la lección avanzada: Palabras Básicas (Lecciones 59-68)
  /// Cada lección tiene 3 ejercicios con DIFERENTES respuestas correctas
  static final List<Map<String, dynamic>> _basicWordsLessons = [
    // Lección 59: Saludos Básicos
    {
      'title': 'Saludos Básicos',
      'emoji': '👋',
      'exercises': [
        {
          'question': '📖 Es por la mañana y ves a alguien.\n\n¿Qué gesto usas para saludar?',
          'correctGesture': 'BUENOS DIAS',
          'explanation': 'En la mañana se usa BUENOS DIAS para saludar.',
          'points': 5,
        },
        {
          'question': '🎯 Ves a alguien por primera vez en el día.\n\n¿Cómo lo saludas de manera general?',
          'correctGesture': 'HOLA',
          'explanation': 'HOLA es el saludo básico universal.',
          'points': 10,
        },
        {
          'question': '🔥 Después de saludar, quieres saber cómo está.\n\n¿Qué preguntas?',
          'correctGesture': 'COMO ESTAS',
          'explanation': 'COMO ESTAS se usa para preguntar por el estado de alguien.',
          'points': 10,
        },
      ],
    },
    // Lección 60: Expresiones de Cortesía
    {
      'title': 'Expresiones de Cortesía',
      'emoji': '🙏',
      'exercises': [
        {
          'question': '📖 Alguien te ayudó con algo.\n\n¿Cómo le respondes?',
          'correctGesture': 'GRACIAS',
          'explanation': 'GRACIAS expresa gratitud cuando alguien te ayuda.',
          'points': 5,
        },
        {
          'question': '🎯 Necesitas pedir un favor de manera educada.\n\n¿Qué palabra usas?',
          'correctGesture': 'PORFAVOR',
          'explanation': 'PORFAVOR hace tus peticiones más amables.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres despedirte y desearle lo mejor a alguien.\n\n¿Qué gesto usas?',
          'correctGesture': 'CUIDATE MUCHO',
          'explanation': 'CUIDATE MUCHO es una despedida afectuosa.',
          'points': 10,
        },
      ],
    },
    // Lección 61: Presentación Personal
    {
      'title': 'Presentación Personal',
      'emoji': '🤝',
      'exercises': [
        {
          'question': '📖 Conoces a alguien nuevo.\n\n¿Cómo empiezas la conversación?',
          'correctGesture': 'HOLA',
          'explanation': 'HOLA es el primer paso para presentarte.',
          'points': 5,
        },
        {
          'question': '🎯 Quieres decir tu nombre.\n\n¿Qué gesto usas antes de tu nombre?',
          'correctGesture': 'MI NOMBRE ES',
          'explanation': 'MI NOMBRE ES se usa antes de decir tu nombre.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres saber el nombre de la otra persona.\n\n¿Qué le preguntas?',
          'correctGesture': 'CUAL ES TU NOMBRE',
          'explanation': 'CUAL ES TU NOMBRE pregunta por el nombre de alguien.',
          'points': 10,
        },
      ],
    },
    // Lección 62: Respuestas y Confirmaciones
    {
      'title': 'Respuestas y Confirmaciones',
      'emoji': '✅',
      'exercises': [
        {
          'question': '📖 Alguien te pregunta si estás de acuerdo.\n\n¿Cómo respondes afirmativamente?',
          'correctGesture': 'SI',
          'explanation': 'SI se usa para afirmar o estar de acuerdo.',
          'points': 5,
        },
        {
          'question': '🎯 No estás de acuerdo con algo.\n\n¿Qué gesto haces?',
          'correctGesture': 'NO',
          'explanation': 'NO se usa para negar o no estar de acuerdo.',
          'points': 10,
        },
        {
          'question': '🔥 Comprendiste perfectamente la explicación.\n\n¿Cómo lo indicas?',
          'correctGesture': 'ENTIENDO',
          'explanation': 'ENTIENDO muestra que has comprendido la información.',
          'points': 10,
        },
      ],
    },
    // Lección 63: Comunicando Dificultades
    {
      'title': 'Comunicando Dificultades',
      'emoji': '🤔',
      'exercises': [
        {
          'question': '📖 No comprendes lo que te dijeron.\n\n¿Qué señas indicas?',
          'correctGesture': 'NO ENTIENDO',
          'explanation': 'NO ENTIENDO indica que necesitas que te lo expliquen de nuevo.',
          'points': 5,
        },
        {
          'question': '🎯 Quieres saber el motivo de algo.\n\n¿Qué preguntas?',
          'correctGesture': 'POR QUE',
          'explanation': 'POR QUE se usa para preguntar la razón de algo.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres ofrecer tu ayuda a alguien.\n\n¿Qué le dices?',
          'correctGesture': 'PUEDO AYUDARTE',
          'explanation': 'PUEDO AYUDARTE ofrece tu ayuda a alguien que lo necesita.',
          'points': 10,
        },
      ],
    },
    // Lección 64: Despedidas
    {
      'title': 'Despedidas',
      'emoji': '👋',
      'exercises': [
        {
          'question': '📖 Es de noche y te vas a dormir.\n\n¿Cómo te despides?',
          'correctGesture': 'BUENAS NOCHES',
          'explanation': 'BUENAS NOCHES se usa para despedirse en la noche.',
          'points': 5,
        },
        {
          'question': '🎯 Te vas pero te verás con la persona mañana.\n\n¿Qué gesto usas?',
          'correctGesture': 'BUENOS DIAS',
          'explanation': 'Puedes usar BUENOS DIAS anticipando el próximo encuentro.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres desearle lo mejor al despedirte.\n\n¿Qué le dices?',
          'correctGesture': 'CUIDATE MUCHO',
          'explanation': 'CUIDATE MUCHO es una despedida afectuosa.',
          'points': 10,
        },
      ],
    },
    // Lección 65: Identificación de Personas
    {
      'title': 'Identificación de Personas',
      'emoji': '👤',
      'exercises': [
        {
          'question': '📖 Quieres saber quién es alguien.\n\n¿Qué preguntas?',
          'correctGesture': 'QUIEN',
          'explanation': 'QUIEN se usa para preguntar la identidad de alguien.',
          'points': 5,
        },
        {
          'question': '🎯 Quieres identificarte ante alguien.\n\n¿Qué gesto usas?',
          'correctGesture': 'MI NOMBRE ES',
          'explanation': 'MI NOMBRE ES te permite identificarte.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres saber si alguien es sordo.\n\n¿Qué le preguntas?',
          'correctGesture': 'ERES SORDO',
          'explanation': 'ERES SORDO pregunta sobre la condición auditiva de alguien.',
          'points': 10,
        },
      ],
    },
    // Lección 66: Tipos de Personas
    {
      'title': 'Tipos de Personas',
      'emoji': '👥',
      'exercises': [
        {
          'question': '📖 Quieres indicar que alguien es sordo.\n\n¿Qué gesto usas?',
          'correctGesture': 'SORDO',
          'explanation': 'SORDO identifica a una persona con discapacidad auditiva.',
          'points': 5,
        },
        {
          'question': '🎯 Quieres indicar que alguien puede oír.\n\n¿Qué señas haces?',
          'correctGesture': 'OYENTE',
          'explanation': 'OYENTE identifica a una persona que puede escuchar.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres preguntar si pueden comunicarse.\n\n¿Qué gestos usas?',
          'correctGesture': 'PODEMOS HABLAR',
          'explanation': 'PODEMOS HABLAR pregunta sobre la posibilidad de comunicarse.',
          'points': 10,
        },
      ],
    },
    // Lección 67: Interacción Social
    {
      'title': 'Interacción Social',
      'emoji': '💬',
      'exercises': [
        {
          'question': '📖 Conoces a alguien nuevo y quieres ser amable.\n\n¿Qué le dices después de HOLA?',
          'correctGesture': 'HOLA GUSTO CONOCERTE',
          'explanation': 'HOLA GUSTO CONOCERTE expresa que te alegra conocer a alguien.',
          'points': 5,
        },
        {
          'question': '🎯 Quieres proponer tener una conversación.\n\n¿Qué gestos usas?',
          'correctGesture': 'PODEMOS HABLAR',
          'explanation': 'PODEMOS HABLAR propone iniciar una conversación.',
          'points': 10,
        },
        {
          'question': '🔥 Quieres agradecer a alguien.\n\n¿Qué gesto haces?',
          'correctGesture': 'GRACIAS',
          'explanation': 'GRACIAS expresa gratitud.',
          'points': 10,
        },
      ],
    },
    // Lección 68: Situaciones Cotidianas
    {
      'title': 'Situaciones Cotidianas',
      'emoji': '🌟',
      'exercises': [
        {
          'question': '📖 Es tu primer día en un lugar nuevo.\n\n¿Cómo saludas?',
          'correctGesture': 'HOLA',
          'explanation': 'HOLA es el saludo apropiado para situaciones nuevas.',
          'points': 5,
        },
        {
          'question': '🎯 Alguien te explicó algo difícil y ahora lo entiendes.\n\n¿Qué le dices primero?',
          'correctGesture': 'GRACIAS',
          'explanation': 'GRACIAS agradece la ayuda recibida.',
          'points': 10,
        },
        {
          'question': '🔥 Luego quieres confirmar que comprendiste.\n\n¿Qué gesto haces?',
          'correctGesture': 'ENTIENDO',
          'explanation': 'ENTIENDO confirma tu comprensión.',
          'points': 10,
        },
      ],
    },
  ];

  /// Datos de las 10 lecciones de Armar Palabras (Lecciones 69-78)
  /// El usuario debe formar palabras usando el teclado de alfabeto
  static final List<Map<String, dynamic>> _wordBuilderLessons = [
    // Lección 69: Palabras de 3 letras
    {
      'title': 'Palabras Simples - 3 Letras',
      'emoji': '🔤',
      'targetWord': 'SOL',
      'hint': 'Una estrella brillante en el cielo',
    },
    // Lección 70: Animales
    {
      'title': 'Animales - 4 Letras',
      'emoji': '🐕',
      'targetWord': 'PERRO',
      'hint': 'Mejor amigo del hombre',
    },
    // Lección 71: Familia
    {
      'title': 'Familia - 4 Letras',
      'emoji': '👨',
      'targetWord': 'PAPA',
      'hint': 'Figura paterna en la familia',
    },
    // Lección 72: Familia 2
    {
      'title': 'Familia - 4 Letras',
      'emoji': '👩',
      'targetWord': 'MAMA',
      'hint': 'Figura materna en la familia',
    },
    // Lección 73: Colores
    {
      'title': 'Colores - 4 Letras',
      'emoji': '🔴',
      'targetWord': 'ROJO',
      'hint': 'Color del fuego y la sangre',
    },
    // Lección 74: Naturaleza
    {
      'title': 'Naturaleza - 4 Letras',
      'emoji': '🌙',
      'targetWord': 'LUNA',
      'hint': 'Brilla en la noche',
    },
    // Lección 75: Emociones
    {
      'title': 'Emociones - 4 Letras',
      'emoji': '❤️',
      'targetWord': 'AMOR',
      'hint': 'Sentimiento profundo de cariño',
    },
    // Lección 76: Casa
    {
      'title': 'Hogar - 4 Letras',
      'emoji': '🏠',
      'targetWord': 'CASA',
      'hint': 'Lugar donde vives',
    },
    // Lección 77: Alimentos
    {
      'title': 'Alimentos - 3 Letras',
      'emoji': '🍞',
      'targetWord': 'PAN',
      'hint': 'Alimento básico hecho de harina',
    },
    // Lección 78: Líquidos
    {
      'title': 'Líquidos - 4 Letras',
      'emoji': '💧',
      'targetWord': 'AGUA',
      'hint': 'Líquido vital para la vida',
    },
  ];

  /// Datos de las 21 lecciones de gestos básicos
  static final List<Map<String, dynamic>> _gesturesData = [
    {
      'gesture': 'HOLA',
      'emoji': '👋',
      'description':
          'Levanta tu mano a la altura del hombro con la palma hacia afuera. Mueve la mano de lado a lado suavemente varias veces.',
      'wrongOptions': [
        'Mano cerrada moviéndose',
        'Palma hacia adentro',
        'Mano quieta sin movimiento'
      ]
    },
    {
      'gesture': 'BUENOS DIAS',
      'emoji': '👋',
      'description':
          'Levanta tu mano a la altura del hombro con la palma hacia afuera. Abre y cierra los dedos varias veces como un abanico.',
      'wrongOptions': [
        'Mano moviéndose de lado a lado',
        'Puño cerrado',
        'Palma hacia abajo'
      ]
    },
    {
      'gesture': 'PORFAVOR',  // En MongoDB: "PORFAVOR" (sin espacio)
      'emoji': '🙏',
      'description':
          'Coloca tu mano abierta sobre tu pecho con la palma hacia abajo. Mueve la mano en círculos pequeños sobre el pecho.',
      'wrongOptions': [
        'Manos juntas como en oración',
        'Mano estática en el pecho',
        'Ambas manos moviéndose'
      ]
    },
    {
      'gesture': 'GRACIAS',
      'emoji': '🙏',
      'description':
          'Coloca los dedos de tu mano cerca de tus labios con la palma hacia tu cara. Luego mueve la mano hacia adelante alejándola de tu cara.',
      'wrongOptions': [
        'Mano quieta en los labios',
        'Movimiento hacia arriba',
        'Ambas manos moviéndose'
      ]
    },
    {
      'gesture': 'BUENAS NOCHES',
      'emoji': '🤝',
      'description':
          'Extiende tu mano abierta con la palma hacia abajo a la altura del pecho. Mueve la mano hacia adelante ligeramente.',
      'wrongOptions': [
        'Palma hacia arriba',
        'Mano cerrada',
        'Movimiento circular'
      ]
    },
    {
      'gesture': 'COMO ESTAS',
      'emoji': '🙏',
      'description':
          'Cierra tu mano en un puño y colócala sobre tu pecho. Mueve el puño en círculos sobre el pecho varias veces.',
      'wrongOptions': [
        'Mano abierta en el pecho',
        'Puño estático',
        'Movimiento lineal'
      ]
    },
    {
      'gesture': 'SI',
      'emoji': '👍',
      'description':
          'Cierra tu mano en un puño y muévela hacia arriba y abajo como si estuvieras asintiendo con la mano.',
      'wrongOptions': [
        'Pulgar hacia arriba estático',
        'Movimiento de lado a lado',
        'Mano abierta'
      ]
    },
    {
      'gesture': 'NO',
      'emoji': '🙅',
      'description':
          'Extiende el índice y el medio juntos. Mueve estos dos dedos de lado a lado como negando.',
      'wrongOptions': [
        'Dedos separados en V',
        'Movimiento vertical',
        'Solo un dedo moviéndose'
      ]
    },
    {
      'gesture': 'PUEDO AYUDARTE',
      'emoji': '🆘',
      'description':
          'Coloca tu puño cerrado sobre tu palma abierta extendida. Levanta ambas manos juntas hacia arriba.',
      'wrongOptions': [
        'Solo una mano levantada',
        'Manos separadas',
        'Movimiento hacia abajo'
      ]
    },
    {
      'gesture': 'HOLA GUSTO CONOCERTE',
      'emoji': '👌',
      'description':
          'Une el pulgar con el índice formando un círculo. Los otros tres dedos están extendidos. Este gesto significa que todo está bien.',
      'wrongOptions': [
        'Pulgar hacia arriba',
        'Todos los dedos formando círculo',
        'Puño cerrado'
      ]
    },
    {
      'gesture': 'CUAL ES TU NOMBRE',
      'emoji': '👎',
      'description':
          'Cierra tu mano en un puño y extiende el pulgar hacia abajo. El pulgar apunta hacia el suelo.',
      'wrongOptions': [
        'Pulgar hacia arriba',
        'Pulgar horizontal',
        'Mano abierta'
      ]
    },
    {
      'gesture': 'MI NOMBRE ES',
      'emoji': '😊',
      'description':
          'Coloca tus manos abiertas cerca de tu pecho con las palmas hacia ti. Mueve ambas manos hacia arriba varias veces mostrando alegría.',
      'wrongOptions': [
        'Manos hacia abajo',
        'Solo una mano moviéndose',
        'Puños cerrados'
      ]
    },
    {
      'gesture': 'ENTIENDO',
      'emoji': '😢',
      'description':
          'Coloca ambas manos abiertas frente a tu cara con los dedos extendidos. Mueve las manos hacia abajo lentamente como si fueran lágrimas cayendo.',
      'wrongOptions': [
        'Movimiento hacia arriba',
        'Manos en el pecho',
        'Puños cerrados'
      ]
    },
    {
      'gesture': 'NO ENTIENDO',
      'emoji': '🍽️',
      'description':
          'Forma una "C" con tu mano y colócala cerca de tu garganta. Mueve la mano hacia abajo por el cuello hacia el pecho.',
      'wrongOptions': [
        'Movimiento hacia arriba',
        'Mano en la boca',
        'Ambas manos moviéndose'
      ]
    },
    {
      'gesture': 'OYENTE',
      'emoji': '💧',
      'description':
          'Extiende tu índice y pásalo por tu garganta de arriba hacia abajo, como si estuvieras señalando el camino del agua.',
      'wrongOptions': [
        'Dedo horizontal',
        'Todos los dedos extendidos',
        'Movimiento circular'
      ]
    },
    {
      'gesture': 'SORDO',
      'emoji': '😴',
      'description':
          'Coloca ambas manos abiertas con las palmas hacia ti cerca de tu pecho. Deja caer las manos hacia abajo mostrando fatiga.',
      'wrongOptions': [
        'Manos hacia arriba',
        'Solo una mano',
        'Puños cerrados'
      ]
    },
    {
      'gesture': 'ERES SORDO',
      'emoji': '😖',
      'description':
          'Extiende ambos índices apuntando uno hacia el otro. Mueve los dedos hacia adentro y afuera repetidamente sin tocarse.',
      'wrongOptions': [
        'Dedos tocándose',
        'Solo un dedo',
        'Dedos estáticos'
      ]
    },
    {
      'gesture': 'PODEMOS HABLAR',
      'emoji': '🏠',
      'description':
          'Junta las puntas de tus dedos formando un triángulo (techo). Luego separa las manos hacia los lados manteniendo la forma de casa.',
      'wrongOptions': [
        'Manos planas juntas',
        'Dedos separados',
        'Puños cerrados'
      ]
    },
    {
      'gesture': 'POR QUE',
      'emoji': '👨‍👩‍👧‍👦',
      'description':
          'Forma una "F" con ambas manos (pulgar e índice formando círculo). Mueve las manos en círculo hasta que los meñiques se toquen.',
      'wrongOptions': [
        'Manos estáticas',
        'Solo una mano moviéndose',
        'Círculo completo sin tocarse'
      ]
    },
    {
      'gesture': 'QUIEN',
      'emoji': '🤝',
      'description':
          'Entrelaza los dedos índices de ambas manos como si se estuvieran saludando. Luego invierte la posición (mano derecha arriba, luego izquierda arriba).',
      'wrongOptions': [
        'Índices sin tocarse',
        'Solo una inversión',
        'Todos los dedos entrelazados'
      ]
    },
    {
      'gesture': 'CUIDATE MUCHO',
      'emoji': '❤️',
      'description':
          'Extiende el pulgar, índice y meñique mientras mantienes doblados el medio y el anular. La mano queda como "I love you" en lenguaje de señas.',
      'wrongOptions': [
        'Solo pulgar y meñique extendidos',
        'Todos los dedos extendidos',
        'Solo el índice extendido'
      ]
    },
  ];

  /// Cargar un GIF del abecedario desde assets locales
  static Future<String> loadAbecedarioImageByLetter(String letra) async {
    // Si ya está en caché, retornar inmediatamente
    if (_abecedarioCache.containsKey(letra)) {
      return _abecedarioCache[letra]!;
    }

    try {
      // Mapeo especial para la letra Ñ (evita problemas de codificación)
      String fileName = letra;
      if (letra == 'Ñ' || letra == 'ñ') {
        fileName = 'ENYE';
      }

      // Cargar GIF desde assets locales
      final path = 'assets/gifs/abecedario/$fileName.gif';
      final ByteData data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();

      // Convertir a base64 para mantener compatibilidad con código existente
      final base64String = base64Encode(bytes);

      _abecedarioCache[letra] = base64String;
      print('✅ GIF cargado desde assets para letra: $letra');

      return base64String;
    } catch (e) {
      print('❌ Error cargando GIF de letra "$letra" desde assets: $e');
      print('   Verifica que el archivo assets/gifs/abecedario/$letra.gif exista');
    }

    return ''; // Retornar vacío si falla
  }

  /// Cargar GIFs/imágenes del abecedario desde MongoDB (TODAS a la vez)
  /// NOTA: Este método NO se usa al inicio para evitar timeout
  static Future<void> loadAbecedarioImages() async {
    if (_abecedarioCache.isNotEmpty) return; // Ya están cargadas

    try {
      print('🔄 Cargando GIFs del abecedario desde MongoDB...');
      final abecedario = await _apiService.getAbecedario();
      for (var item in abecedario) {
        final letra = item['nombre'] as String?;
        final contenido = item['contenido'] as String?;
        final convertidoAGif = item['convertidoAGif'] as bool? ?? false;

        if (letra != null && contenido != null) {
          _abecedarioCache[letra] = contenido;
          if (convertidoAGif) {
            print('✅ GIF cargado para letra: $letra');
          } else {
            print('✅ Media cargado para letra: $letra');
          }
        }
      }
      print('✅ Medios del abecedario cargados: ${_abecedarioCache.length}');
    } catch (e) {
      print('❌ Error cargando medios del abecedario: $e');
      // No lanzar error - continuar con emojis si falla
    }
  }

  /// Cargar TODOS los GIFs de gestos desde MongoDB de una sola vez
  static Future<void> loadGestosVideos() async {
    if (_gestosCache.isNotEmpty) {
      print('ℹ️ GIFs de gestos ya están cargados en caché (${_gestosCache.length ~/ 7} gestos)');
      return; // Ya están cargados
    }

    try {
      print('🔄 ==========================================');
      print('🔄 CARGANDO TODOS LOS GIFs DE GESTOS DESDE MONGODB');
      print('🔄 ==========================================');

      final gestos = await _apiService.getGestos();

      if (gestos.isEmpty) {
        print('❌ NO SE ENCONTRARON GESTOS EN MONGODB');
        return;
      }

      print('📋 Total de gestos encontrados en MongoDB: ${gestos.length}');
      final nombresEncontrados = <String>[];
      int gifsCargados = 0;

      for (var item in gestos) {
        final nombre = item['nombre'] as String?;
        final contenido = item['contenido'] as String?;
        final convertidoAGif = item['convertidoAGif'] as bool? ?? false;
        final extension = item['extension'] as String? ?? '';

        if (nombre != null && contenido != null) {
          final nombreLimpio = nombre.trim();
          nombresEncontrados.add(nombreLimpio);

          // Guardar con TODAS las variaciones para máxima compatibilidad
          final variaciones = [
            nombreLimpio,
            nombreLimpio.toUpperCase(),
            nombreLimpio.toLowerCase(),
            nombreLimpio.replaceAll(' ', '_'),
            nombreLimpio.replaceAll(' ', ''),
            nombreLimpio.replaceAll(' ', '_').toUpperCase(),
            nombreLimpio.replaceAll(' ', '').toUpperCase(),
          ];

          for (final v in variaciones) {
            _gestosCache[v] = contenido;
          }

          if (convertidoAGif) {
            print('  ✅ GIF #${gifsCargados + 1}: "$nombreLimpio" ($extension)');
          } else {
            print('  ✅ Media #${gifsCargados + 1}: "$nombreLimpio" ($extension)');
          }
          gifsCargados++;
        }
      }

      print('');
      print('📝 Nombres cargados: ${nombresEncontrados.join(", ")}');
      print('✅ TOTAL: $gifsCargados GIFs cargados exitosamente');
      print('✅ Entradas en caché: ${_gestosCache.length} (con variaciones)');
      print('🔄 ==========================================');
    } catch (e) {
      print('❌ ERROR CARGANDO GIFs DE GESTOS: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      // No lanzar error - continuar con emojis si falla
    }
  }

  /// Cargar un GIF de gesto desde assets locales
  static Future<String> loadSingleGestoVideo(String gestoNombre, {bool silent = false}) async {
    // Si ya está en caché, retornar inmediatamente
    if (_gestosCache.containsKey(gestoNombre)) {
      if (!silent) print('✅ GIF encontrado en caché para: "$gestoNombre"');
      return _gestosCache[gestoNombre]!;
    }

    try {
      // Normalizar el nombre para el path del archivo
      // "BUENOS DIAS" -> "BUENOS_DIAS.gif"
      final nombreArchivo = gestoNombre.replaceAll(' ', '_').toUpperCase();
      final path = 'assets/gifs/gestos/$nombreArchivo.gif';

      if (!silent) print('🔄 Cargando GIF desde assets: $path');

      // Cargar GIF desde assets locales
      final ByteData data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();

      // Convertir a base64 para mantener compatibilidad
      final base64String = base64Encode(bytes);

      // Guardar en caché con el nombre original
      _gestosCache[gestoNombre] = base64String;

      if (!silent) print('✅ GIF cargado desde assets para gesto: "$gestoNombre"');

      return base64String;
    } catch (e) {
      if (!silent) {
        print('❌ Error cargando GIF de gesto "$gestoNombre" desde assets: $e');
        final nombreArchivo = gestoNombre.replaceAll(' ', '_').toUpperCase();
        print('   Verifica que el archivo assets/gifs/gestos/$nombreArchivo.gif exista');
      }
    }

    return ''; // Retornar vacío si falla
  }

  /// Cargar un GIF de número desde assets locales
  static Future<String> loadNumeroImage(String numero, {bool silent = false}) async {
    // Si ya está en caché, retornar inmediatamente
    if (_numerosCache.containsKey(numero)) {
      if (!silent) print('✅ GIF encontrado en caché para número: "$numero"');
      return _numerosCache[numero]!;
    }

    try {
      // El nombre del archivo es simplemente el número (0.gif, 1.gif, etc.)
      final path = 'assets/gifs/numeros/$numero.gif';

      if (!silent) print('🔄 Cargando GIF de número desde assets: $path');

      // Cargar GIF desde assets locales
      final ByteData data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();

      // Convertir a base64 para mantener compatibilidad
      final base64String = base64Encode(bytes);

      // Guardar en caché con el número original
      _numerosCache[numero] = base64String;

      if (!silent) print('✅ GIF cargado desde assets para número: "$numero"');

      return base64String;
    } catch (e) {
      if (!silent) {
        print('❌ Error cargando GIF de número "$numero" desde assets: $e');
        print('   Verifica que el archivo assets/gifs/numeros/$numero.gif exista');
      }
    }

    return ''; // Retornar vacío si falla
  }

  /// Inicializar sistema de lecciones
  /// Los GIFs ahora se cargan desde assets locales (rápido e instantáneo)
  static Future<void> initializeAllData() async {
    print('✅ Sistema de lecciones inicializado');
    print('📦 Los GIFs se cargarán desde assets locales cuando se necesiten');
    // No se necesita precarga - los assets locales cargan instantáneamente
  }

  /// Sistema de precarga en background - carga todos los GIFs uno por uno
  /// sin bloquear la UI del usuario
  static Future<void> _preloadAllMediaInBackground() async {
    print('🚀 ==========================================');
    print('🚀 INICIANDO PRECARGA EN BACKGROUND');
    print('🚀 ==========================================');

    // Ejecutar en background sin bloquear
    Future.microtask(() async {
      try {
        // 1. Precargar abecedario (27 letras)
        await _preloadAbecedario();

        // 2. Precargar gestos (21 gestos)
        await _preloadGestos();

        print('🎉 ==========================================');
        print('🎉 PRECARGA COMPLETADA EXITOSAMENTE');
        print('🎉 Total: ${_abecedarioCache.length} letras + ${_gestosCache.length ~/ 7} gestos');
        print('🎉 ==========================================');
      } catch (e) {
        print('❌ Error en precarga background: $e');
      }
    });
  }

  /// Precargar todas las letras del abecedario una por una
  static Future<void> _preloadAbecedario() async {
    if (_abecedarioCache.isNotEmpty) {
      print('ℹ️ Abecedario ya está en caché, omitiendo precarga');
      return;
    }

    print('📚 Precargando ABECEDARIO (27 letras)...');
    final letras = _alphabetData.map((d) => d['letter'] as String).toList();

    int cargadas = 0;
    for (final letra in letras) {
      try {
        final contenido = await loadAbecedarioImageByLetter(letra);
        if (contenido.isNotEmpty) {
          cargadas++;
          print('  📝 [$cargadas/${letras.length}] "$letra" ✅');
        } else {
          print('  📝 [$cargadas/${letras.length}] "$letra" ⚠️ (vacío)');
        }
      } catch (e) {
        print('  📝 [$cargadas/${letras.length}] "$letra" ❌ (error: $e)');
      }
    }

    print('✅ Abecedario completado: $cargadas/${letras.length} letras cargadas');
  }

  /// Precargar todos los gestos uno por uno
  static Future<void> _preloadGestos() async {
    if (_gestosCache.isNotEmpty) {
      print('ℹ️ Gestos ya están en caché, omitiendo precarga');
      return;
    }

    print('🎭 Precargando GESTOS (21 gestos)...');
    final gestos = _gesturesData.map((d) => d['gesture'] as String).toList();

    int cargados = 0;
    for (final gesto in gestos) {
      try {
        // Usar silent: true para reducir logs durante precarga
        final contenido = await loadSingleGestoVideo(gesto, silent: true);
        if (contenido.isNotEmpty) {
          cargados++;
          print('  🎬 [$cargados/${gestos.length}] "$gesto" ✅');
        } else {
          print('  🎬 [$cargados/${gestos.length}] "$gesto" ⚠️ (vacío)');
        }
      } catch (e) {
        print('  🎬 [$cargados/${gestos.length}] "$gesto" ❌ (error: $e)');
      }
    }

    print('✅ Gestos completados: $cargados/${gestos.length} gestos cargados');
  }

  /// Debug: Comparar gestos esperados vs. gestos en MongoDB
  static Future<void> debugCompareGestos() async {
    print('\n🔍 === DEBUG: COMPARACIÓN DE GESTOS ===');

    // Obtener todos los gestos de MongoDB
    final gestos = await _apiService.getGestos();
    final nombresEnMongoDB = gestos
        .map((g) => (g['nombre'] as String?)?.trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    // Obtener todos los gestos esperados en el código
    final nombresEsperados = _gesturesData
        .map((g) => g['gesture'] as String)
        .toList();

    print('📝 Gestos esperados en el código (${nombresEsperados.length}):');
    for (int i = 0; i < nombresEsperados.length; i++) {
      print('   Lección ${38 + i}: "${nombresEsperados[i]}"');
    }

    print('\n📚 Gestos en MongoDB (${nombresEnMongoDB.length}):');
    for (final nombre in nombresEnMongoDB) {
      print('   - "$nombre"');
    }

    print('\n❌ Gestos que faltan en MongoDB:');
    for (int i = 0; i < nombresEsperados.length; i++) {
      final esperado = nombresEsperados[i];
      final found = nombresEnMongoDB.any((mongo) =>
          mongo.toUpperCase() == esperado.toUpperCase() ||
          mongo.replaceAll(' ', '_').toUpperCase() == esperado.replaceAll(' ', '_').toUpperCase() ||
          mongo.replaceAll(' ', '').toUpperCase() == esperado.replaceAll(' ', '').toUpperCase());

      if (!found) {
        print('   Lección ${38 + i}: "$esperado" ⚠️');
      }
    }

    print('\n✅ === FIN DEBUG ===\n');
  }

  /// Generar todas las lecciones del alfabeto con sus ejercicios
  /// NOTA: Los GIFs se cargan bajo demanda, no al inicio
  static Future<List<Lesson>> generateAlphabetLessons() async {
    return _alphabetData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final letter = data['letter'] as String;
      // Usar imagen del cache si ya está, sino usar vacío (se cargará después)
      final imageBase64 = _abecedarioCache[letter] ?? '';

      return Lesson(
        id: index + 1,
        title: 'Lección ${index + 1}',
        category: 'Alphabet',
        letter: letter,
        description: data['description'],
        imageUrl: data['emoji'],
        imageBase64: imageBase64,  // Vacío inicialmente, se carga bajo demanda
        order: index + 1,
        experiencePoints: 25, // 5 + 10 + 10 = 25 puntos totales
        difficulty: DifficultyLevel.basic,
        estimatedMinutes: 5,
        exercises: _generateExercises(data, index + 1, imageBase64),
        learningTips: _generateTips(letter),
      );
    }).toList();
  }

  /// Generar todas las lecciones de números con sus ejercicios
  static Future<List<Lesson>> generateNumberLessons() async {
    final lessons = <Lesson>[];

    for (var entry in _numbersData.asMap().entries) {
      final index = entry.key;
      final data = entry.value;
      final number = data['number'] as String;

      // Cargar el GIF del número desde assets
      final imageBase64 = await loadNumeroImage(number, silent: true);

      lessons.add(Lesson(
        id: 28 + index, // Empezar después de las 27 lecciones del alfabeto
        title: 'Lección ${28 + index}',
        category: 'Numbers',
        letter: number,
        description: data['description'],
        imageUrl: data['emoji'],
        imageBase64: imageBase64, // GIF cargado desde assets
        order: index + 1,
        experiencePoints: 25, // 5 + 10 + 10 = 25 puntos totales
        difficulty: DifficultyLevel.basic,
        estimatedMinutes: 5,
        exercises: _generateNumberExercises(data, 28 + index, imageBase64),
        learningTips: _generateNumberTips(number),
      ));
    }

    return lessons;
  }

  /// Generar las 10 lecciones de palabras básicas (59-68)
  /// Cada lección ahora tiene 3 ejercicios con DIFERENTES respuestas correctas
  static Future<List<Lesson>> generateBasicWordLessons() async {
    // Cargar TODOS los GIFs disponibles para tener opciones
    print('💬 Cargando GIFs para Palabras Básicas...');
    final allGestureNames = _gesturesData.map((g) => g['gesture'] as String).toList();
    for (var gesture in allGestureNames) {
      if (!_gestosCache.containsKey(gesture)) {
        await loadSingleGestoVideo(gesture, silent: true);
      }
    }

    // Crear las 10 lecciones (una por cada entrada en _basicWordsLessons)
    return _basicWordsLessons.asMap().entries.map((entry) {
      final index = entry.key;
      final lessonData = entry.value;
      final lessonId = 59 + index; // Lecciones 59-68

      final exercisesData = List<Map<String, dynamic>>.from(lessonData['exercises']);

      // Crear 3 ejercicios para esta lección, cada uno con DIFERENTE respuesta correcta
      final exercises = <Exercise>[];

      for (int i = 0; i < exercisesData.length; i++) {
        final exerciseData = exercisesData[i];
        final correctGesture = exerciseData['correctGesture'] as String;

        // Crear opciones diferentes para cada ejercicio (respuesta correcta + 3 incorrectas)
        final wrongGestures = allGestureNames.where((g) => g != correctGesture).toList();
        wrongGestures.shuffle();
        final List<String> gestureOptions = [
          correctGesture,
          ...wrongGestures.take(3),
        ]..shuffle();

        exercises.add(Exercise(
          id: i + 1,
          type: ExerciseType.multipleChoice,
          question: exerciseData['question'],
          correctAnswer: correctGesture,
          options: gestureOptions,
          imageUrl: lessonData['emoji'],
          imageBase64: '',
          hintText: exerciseData['explanation'],
          points: exerciseData['points'],
        ));
      }

      // Obtener todas las respuestas correctas únicas para esta lección
      final uniqueGestures = exercisesData
          .map((e) => e['correctGesture'] as String)
          .toSet()
          .join(', ');

      return Lesson(
        id: lessonId,
        title: 'Lección $lessonId',
        category: 'Basic Words',
        letter: uniqueGestures, // Lista de gestos únicos en esta lección
        description: lessonData['title'],
        imageUrl: lessonData['emoji'],
        imageBase64: '',
        order: lessonId,
        experiencePoints: 25, // 5 + 10 + 10 = 25 XP por lección
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 3,
        exercises: exercises,
        learningTips: [
          '🎯 Lee cada situación con atención',
          '🧠 Observa los GIFs cuidadosamente',
          '💡 Solo necesitas seleccionar 1 GIF por pregunta',
          '✨ Cada pregunta tiene una respuesta DIFERENTE',
        ],
      );
    }).toList();
  }

  /// Generar las 10 lecciones de Armar Palabras (69-78)
  /// El usuario forma palabras seleccionando letras del alfabeto
  static Future<List<Lesson>> generateWordBuilderLessons() async {
    // Cargar TODOS los GIFs del alfabeto para el teclado
    print('🔤 Cargando GIFs del alfabeto para Armar Palabras...');

    // Cargar todos los GIFs del alfabeto (A-Z, Ñ)
    for (var letterData in _alphabetData) {
      final letter = letterData['letter'] as String;
      if (!_abecedarioCache.containsKey(letter)) {
        await loadAbecedarioImageByLetter(letter);
      }
    }

    // Crear las 10 lecciones
    final lessons = <Lesson>[];

    for (var entry in _wordBuilderLessons.asMap().entries) {
      final index = entry.key;
      final lessonData = entry.value;
      final lessonId = 69 + index; // Lecciones 69-78
      final targetWord = lessonData['targetWord'] as String;

      // Crear un solo ejercicio de tipo wordBuilder por lección
      final exercise = Exercise(
        id: 1,
        type: ExerciseType.wordBuilder,
        question: 'Forma la palabra usando las letras del alfabeto en lenguaje de señas',
        correctAnswer: targetWord,
        options: _alphabetData.map((e) => e['letter'] as String).toList(), // Todas las letras disponibles
        imageUrl: lessonData['emoji'],
        imageBase64: '',
        hintText: lessonData['hint'],
        points: 25,
      );

      lessons.add(Lesson(
        id: lessonId,
        title: 'Lección $lessonId',
        category: 'Word Builder',
        letter: targetWord,
        description: lessonData['title'],
        imageUrl: lessonData['emoji'],
        imageBase64: '',
        order: lessonId,
        experiencePoints: 25,
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 5,
        exercises: [exercise],
        learningTips: [
          '🔤 Observa cada letra del alfabeto cuidadosamente',
          '👆 Toca las letras en el orden correcto para formar la palabra',
          '💡 Usa la pista si necesitas ayuda',
          '🎯 Puedes ver el GIF de cada letra antes de seleccionarla',
        ],
      ));
    }

    return lessons;
  }

  /// Generar todas las lecciones de gestos con sus ejercicios
  static Future<List<Lesson>> generateGestureLessons() async {
    // Los GIFs deberían estar precargados en background
    // Si el caché está vacío, el usuario verá emojis temporalmente

    if (_gestosCache.isEmpty) {
      print('⚠️ Caché de gestos aún vacío (precarga en progreso...)');
    }

    return _gesturesData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final gesture = data['gesture'] as String;
      final lessonId = 38 + index;

      // Buscar el GIF correspondiente en el cache
      // Primero intentar búsqueda exacta, luego variaciones
      String videoBase64 = _gestosCache[gesture] ?? '';

      // Si no se encontró, intentar con variaciones
      if (videoBase64.isEmpty) {
        final variaciones = [
          gesture.toUpperCase(),
          gesture.toLowerCase(),
          gesture.replaceAll(' ', '_'),
          gesture.replaceAll(' ', ''),
          gesture.replaceAll(' ', '_').toUpperCase(),
          gesture.replaceAll(' ', '').toUpperCase(),
        ];

        for (final variacion in variaciones) {
          if (_gestosCache.containsKey(variacion)) {
            videoBase64 = _gestosCache[variacion]!;
            print('📌 Lección $lessonId - GIF encontrado con variación "$variacion" para gesto "$gesture"');
            break;
          }
        }
      }

      if (videoBase64.isEmpty) {
        print('❌ Lección $lessonId - NO SE ENCONTRÓ GIF PARA: "$gesture"');
        print('   Claves en caché (primeras 10): ${_gestosCache.keys.take(10).join(", ")}');
        print('   Total claves en caché: ${_gestosCache.length}');
        print('   Se usará emoji como fallback 😔');
      } else {
        print('✅ Lección $lessonId - GIF asignado para: "$gesture"');
      }

      return Lesson(
        id: 38 + index, // Empezar después de las 37 lecciones (27 alfabeto + 10 números)
        title: 'Lección ${38 + index}',
        category: 'Gestures',
        letter: gesture,
        description: data['description'],
        imageUrl: data['emoji'],
        imageBase64: videoBase64, // Video desde el cache
        order: index + 1,
        experiencePoints: 25, // 5 + 10 + 10 = 25 puntos totales
        difficulty: DifficultyLevel.intermediate,
        estimatedMinutes: 6,
        exercises: _generateGestureExercises(data, 38 + index, videoBase64),
        learningTips: _generateGestureTips(gesture),
      );
    }).toList();
  }

  /// Generar los 3 ejercicios para una lección de números
  static List<Exercise> _generateNumberExercises(Map<String, dynamic> data, int lessonId, String imageBase64) {
    final number = data['number'];
    final emoji = data['emoji'];
    final description = data['description'];
    final wrongOptions = List<String>.from(data['wrongOptions']);

    return [
      // Ejercicio 1: Practice (Ver y Aprender)
      Exercise(
        id: 1,
        type: ExerciseType.practice,
        question: '¡Aprende esta seña! (Número $number)',
        correctAnswer: description,
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Observa cuidadosamente cómo se forma esta seña con las manos.',
        points: 5,
      ),

      // Ejercicio 2: Sign Recognition (¿Qué número es este?)
      Exercise(
        id: 2,
        type: ExerciseType.signRecognition,
        question: '¿Qué número representa esta seña?',
        correctAnswer: number,
        options: _generateNumberOptions(number),
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Recuerda la posición de los dedos que acabas de aprender.',
        points: 10,
      ),

      // Ejercicio 3: Multiple Choice (¿Cómo se hace?)
      Exercise(
        id: 3,
        type: ExerciseType.multipleChoice,
        question: '¿Cómo se hace esta seña? (Número $number)',
        correctAnswer: description,
        options: [description, ...wrongOptions]..shuffle(),
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Piensa en la descripción que leíste en el primer ejercicio.',
        points: 10,
      ),
    ];
  }

  /// Generar opciones de números para el ejercicio de reconocimiento
  static List<String> _generateNumberOptions(String correctNumber) {
    final allNumbers = _numbersData.map((d) => d['number'] as String).toList();
    allNumbers.remove(correctNumber);
    allNumbers.shuffle();

    final options = [correctNumber, ...allNumbers.take(3)];
    options.shuffle();

    return options;
  }

  /// Generar tips de aprendizaje para números
  static List<String> _generateNumberTips(String number) {
    final commonTips = [
      'Practica frente a un espejo para ver tu mano desde la perspectiva del observador',
      'Los números en lengua de señas son fundamentales para la comunicación',
      'Asegúrate de que tus dedos estén en la posición correcta antes de continuar',
    ];

    return commonTips;
  }

  /// Generar los 3 ejercicios para una lección de gestos
  static List<Exercise> _generateGestureExercises(Map<String, dynamic> data, int lessonId, String videoBase64) {
    final gesture = data['gesture'];
    final emoji = data['emoji'];
    final description = data['description'];
    final wrongOptions = List<String>.from(data['wrongOptions']);

    return [
      // Ejercicio 1: Practice (Ver y Aprender con GIF animado)
      Exercise(
        id: 1,
        type: ExerciseType.practice,
        question: '¡Aprende este gesto! ($gesture)',
        correctAnswer: description,
        imageUrl: videoBase64.isEmpty ? emoji : '', // Usar emoji solo si no hay GIF
        imageBase64: videoBase64, // GIF animado en loop
        hintText: 'Observa cuidadosamente cómo se realiza este gesto en la animación.',
        points: 5,
      ),

      // Ejercicio 2: Sign Recognition (¿Qué gesto es este? - con GIF)
      Exercise(
        id: 2,
        type: ExerciseType.signRecognition,
        question: '¿Qué significa este gesto?',
        correctAnswer: gesture,
        options: _generateGestureOptions(gesture),
        imageUrl: videoBase64.isEmpty ? emoji : '', // Usar emoji solo si no hay GIF
        imageBase64: videoBase64, // GIF animado en loop
        hintText: 'Recuerda el nombre del gesto que acabas de aprender',
        points: 10,
      ),

      // Ejercicio 3: Instruction Recognition (¿Cómo se hace? - con GIF)
      Exercise(
        id: 3,
        type: ExerciseType.multipleChoice,
        question: '¿Cómo se hace el gesto para "$gesture"?',
        correctAnswer: description,
        options: [description, ...wrongOptions],
        imageUrl: videoBase64.isEmpty ? emoji : '', // Usar emoji solo si no hay GIF
        imageBase64: videoBase64, // GIF animado en loop
        hintText: 'Lee cuidadosamente las instrucciones y observa la animación',
        points: 10,
      ),
    ];
  }

  /// Generar opciones de gestos para el ejercicio de reconocimiento
  static List<String> _generateGestureOptions(String correctGesture) {
    final allGestures = _gesturesData.map((d) => d['gesture'] as String).toList();
    allGestures.remove(correctGesture);
    allGestures.shuffle();

    final options = [correctGesture, ...allGestures.take(3)];
    options.shuffle();

    return options;
  }

  /// Generar tips de aprendizaje para gestos
  static List<String> _generateGestureTips(String gesture) {
    final commonTips = [
      'Los gestos en lengua de señas involucran movimiento, no solo posición de manos',
      'Practica los gestos varias veces para desarrollar memoria muscular',
      'Observa cuidadosamente la dirección y velocidad del movimiento',
    ];

    return commonTips;
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
        question: '¡Aprende esta seña! (Letra $letter)',
        correctAnswer: description,
        imageUrl: emoji,
        imageBase64: imageBase64,
        hintText: 'Observa cuidadosamente cómo se forma esta seña con las manos.',
        points: 5,
      ),

      // Ejercicio 2: Sign Recognition (¿Qué letra es esta?)
      Exercise(
        id: 2,
        type: ExerciseType.signRecognition,
        question: '¿Qué letra representa esta seña?',
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
        question: '¿Cómo se hace esta seña? (Letra $letter)',
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
    // Buscar en alfabeto (IDs 1-27)
    if (id >= 1 && id <= 27) {
      final lessons = await generateAlphabetLessons();
      try {
        final lesson = lessons.firstWhere((lesson) => lesson.id == id);

        // Cargar GIF desde MongoDB para esta letra específica
        if (lesson.letter.isNotEmpty) {
          final imageBase64 = await loadAbecedarioImageByLetter(lesson.letter);

          // Actualizar la lección con el GIF cargado
          if (imageBase64.isNotEmpty) {
            // Actualizar ejercicios con el nuevo GIF
            final updatedExercises = lesson.exercises.map((exercise) {
              return Exercise(
                id: exercise.id,
                type: exercise.type,
                question: exercise.question,
                correctAnswer: exercise.correctAnswer,
                options: exercise.options,
                imageBase64: imageBase64, // GIF desde MongoDB
                points: exercise.points,
                hintText: exercise.hintText,
              );
            }).toList().cast<Exercise>();

            return Lesson(
              id: lesson.id,
              title: lesson.title,
              category: lesson.category,
              letter: lesson.letter,
              description: lesson.description,
              imageUrl: lesson.imageUrl,
              imageBase64: imageBase64, // GIF desde MongoDB
              videoUrl: lesson.videoUrl,
              gifUrl: lesson.gifUrl,
              order: lesson.order,
              experiencePoints: lesson.experiencePoints,
              difficulty: lesson.difficulty,
              isCompleted: lesson.isCompleted,
              isLocked: lesson.isLocked,
              exercises: updatedExercises,
              learningTips: lesson.learningTips,
              estimatedMinutes: lesson.estimatedMinutes,
            );
          }
        }

        return lesson;
      } catch (e) {
        return null;
      }
    }

    // Buscar en números (IDs 28-37)
    if (id >= 28 && id <= 37) {
      final lessons = await generateNumberLessons();
      try {
        return lessons.firstWhere((lesson) => lesson.id == id);
      } catch (e) {
        return null;
      }
    }

    // Lecciones de palabras básicas (IDs 59-68)
    if (id >= 59 && id <= 68) {
      final lessons = await generateBasicWordLessons();
      try {
        return lessons[id - 59]; // Índice 0-9 para IDs 59-68
      } catch (e) {
        return null;
      }
    }

    // Lecciones de Armar Palabras (IDs 69-78)
    if (id >= 69 && id <= 78) {
      final lessons = await generateWordBuilderLessons();
      try {
        return lessons[id - 69]; // Índice 0-9 para IDs 69-78
      } catch (e) {
        return null;
      }
    }

    // Buscar en gestos (IDs 38-58)
    if (id >= 38 && id <= 58) {
      // Los GIFs deberían estar precargados en background
      // Si no está, cargar solo este gesto específico
      final lessons = await generateGestureLessons();
      try {
        final lesson = lessons.firstWhere((lesson) => lesson.id == id);

        // Intentar buscar el GIF en caché primero
        String videoBase64 = '';
        if (lesson.letter.isNotEmpty) {
          // Buscar con variaciones en el caché
          final variaciones = [
            lesson.letter,
            lesson.letter.toUpperCase(),
            lesson.letter.toLowerCase(),
            lesson.letter.replaceAll(' ', '_'),
            lesson.letter.replaceAll(' ', ''),
          ];

          for (final v in variaciones) {
            if (_gestosCache.containsKey(v)) {
              videoBase64 = _gestosCache[v]!;
              break;
            }
          }

          // Si no está en caché, cargar individualmente (fallback)
          if (videoBase64.isEmpty) {
            print('⚠️ GIF no encontrado en caché, intentando carga individual...');
            videoBase64 = await loadSingleGestoVideo(lesson.letter);
          }

          // Actualizar la lección con el GIF cargado
          if (videoBase64.isNotEmpty) {
            // Actualizar ejercicios con el nuevo GIF
            final updatedExercises = lesson.exercises.map((exercise) {
              return Exercise(
                id: exercise.id,
                type: exercise.type,
                question: exercise.question,
                correctAnswer: exercise.correctAnswer,
                options: exercise.options,
                imageBase64: videoBase64, // GIF desde MongoDB
                points: exercise.points,
                hintText: exercise.hintText,
              );
            }).toList().cast<Exercise>();

            return Lesson(
              id: lesson.id,
              title: lesson.title,
              category: lesson.category,
              letter: lesson.letter,
              description: lesson.description,
              imageUrl: lesson.imageUrl,
              imageBase64: videoBase64, // GIF desde MongoDB
              videoUrl: lesson.videoUrl,
              gifUrl: lesson.gifUrl,
              order: lesson.order,
              experiencePoints: lesson.experiencePoints,
              difficulty: lesson.difficulty,
              isCompleted: lesson.isCompleted,
              isLocked: lesson.isLocked,
              exercises: updatedExercises,
              learningTips: lesson.learningTips,
              estimatedMinutes: lesson.estimatedMinutes,
            );
          }
        }

        return lesson;
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  /// Obtener todas las lecciones por categoría
  static Future<List<Lesson>> getLessonsByCategory(String category) async {
    if (category.toLowerCase() == 'alphabet') {
      return await generateAlphabetLessons();
    }
    if (category.toLowerCase() == 'numbers') {
      return await generateNumberLessons();
    }
    if (category.toLowerCase() == 'gestures' || category.toLowerCase() == 'gestos') {
      // Los GIFs deberían estar precargados en background desde el login
      return await generateGestureLessons();
    }
    if (category.toLowerCase() == 'basic words' || category.toLowerCase() == 'palabras básicas' || category.toLowerCase() == 'palabras basicas') {
      // Lecciones 59-68: Palabras Básicas
      return await generateBasicWordLessons();
    }
    if (category.toLowerCase() == 'word builder' || category.toLowerCase() == 'armar palabras') {
      // Lecciones 69-78: Armar Palabras
      return await generateWordBuilderLessons();
    }
    return [];
  }
}
