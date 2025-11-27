import '../models/mongodb_models.dart';
import '../models/lesson.dart';
import '../data/lesson_data.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class LessonService {
  static final LessonService _instance = LessonService._internal();
  factory LessonService() => _instance;
  LessonService._internal();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  /// Obtener todos los niveles
  Future<List<Nivel>> getAllNiveles() async {
    final nivelesData = await _apiService.getNiveles();
    return nivelesData.map((data) => Nivel.fromJson(data)).toList();
  }

  /// Obtener nivel por ID
  Future<Nivel?> getNivelById(int nivelID) async {
    final data = await _apiService.getNivelById(nivelID);
    if (data != null) {
      return Nivel.fromJson(data);
    }
    return null;
  }

  /// Obtener progresión del usuario
  Future<Progresion?> getProgresionUsuario(String usuarioID) async {
    final data = await _apiService.getProgresion(usuarioID);
    if (data != null) {
      return Progresion.fromJson(data);
    }
    return null;
  }

  /// Completar un nivel
  Future<bool> completarNivel({
    required String usuarioID,
    required int nivel,
    required bool exito,
    int experienciaGanada = 0,
  }) async {
    final resultado = exito ? 'exito' : 'fallo';
    return await _apiService.completarNivel(usuarioID, nivel, resultado, experienciaGanada: experienciaGanada);
  }

  /// Registrar un intento
  Future<bool> registrarIntento({
    required String usuarioID,
    required int nivel,
    required bool exito,
  }) async {
    final resultado = exito ? 'exito' : 'fallo';
    return await _apiService.registrarIntento(usuarioID, nivel, resultado);
  }

  /// Obtener el siguiente nivel incompleto
  Future<Nivel?> getNextIncompleteNivel(String usuarioID) async {
    try {
      final progresion = await getProgresionUsuario(usuarioID);
      if (progresion == null) return null;

      // Buscar el siguiente nivel no completado
      final niveles = await getAllNiveles();
      for (var nivel in niveles) {
        if (!progresion.nivelesCompletados.contains(nivel.nivelID)) {
          return nivel;
        }
      }

      // Si todos están completados, retornar el último
      return niveles.isNotEmpty ? niveles.last : null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener cantidad de niveles completados
  Future<int> getCompletedNivelesCount(String usuarioID) async {
    try {
      final progresion = await getProgresionUsuario(usuarioID);
      return progresion?.nivelesCompletados.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtener estadísticas del usuario
  Future<Estadisticas?> getUserStats(String usuarioID) async {
    try {
      final progresion = await getProgresionUsuario(usuarioID);
      return progresion?.estadisticas;
    } catch (e) {
      return null;
    }
  }

  /// Actualizar progresión
  Future<bool> updateProgresion(String usuarioID, Progresion progresion) async {
    return await _apiService.updateProgresion(usuarioID, progresion.toJson());
  }

  /// Obtener usuario ID desde el email (helper)
  Future<String?> getUsuarioID() async {
    // Primero intentar desde storage
    var usuarioID = await _storageService.getSecure('usuario_id');
    if (usuarioID != null && usuarioID.isNotEmpty) {
      return usuarioID;
    }

    // Si no está en storage, verificar email
    final email = await _authService.getUserEmail();

    if (email == null) {
      return null;
    }

    // Para invitados, retornar null para que no intenten guardar
    if (email == 'guest@signlearn.com') {
      return null;
    }

    // MIGRATION: Para usuarios existentes sin usuarioID almacenado,
    // buscarlo en la colección Usuarios por correo
    try {
      final usuario = await _apiService.getUsuarioByEmail(email);
      if (usuario != null && usuario['usuarioID'] != null) {
        usuarioID = usuario['usuarioID'] as String;
        // Guardar en storage para futuras consultas
        await _storageService.setSecure('usuario_id', usuarioID);
        return usuarioID;
      }
    } catch (e) {
      // Error handled silently
    }

    return null;
  }

  // ==================== MÉTODOS PARA LECCIONES LOCALES ====================

  /// Obtener todas las lecciones del alfabeto (datos locales)
  Future<List<Lesson>> getAllLessons({String category = 'Alphabet'}) async {
    final lessons = await LessonData.getLessonsByCategory(category);

    // Marcar lecciones como completadas según progresión del usuario
    final usuarioID = await getUsuarioID();
    if (usuarioID != null) {
      final progresion = await getProgresionUsuario(usuarioID);
      if (progresion != null) {
        return lessons.map((lesson) {
          final isCompleted = progresion.nivelesCompletados.contains(lesson.id);
          return Lesson(
            id: lesson.id,
            title: lesson.title,
            category: lesson.category,
            letter: lesson.letter,
            description: lesson.description,
            imageUrl: lesson.imageUrl,
            videoUrl: lesson.videoUrl,
            gifUrl: lesson.gifUrl,
            order: lesson.order,
            experiencePoints: lesson.experiencePoints,
            difficulty: lesson.difficulty,
            isCompleted: isCompleted,
            isLocked: false, // Por ahora todas desbloqueadas
            exercises: lesson.exercises,
            learningTips: lesson.learningTips,
            estimatedMinutes: lesson.estimatedMinutes,
          );
        }).toList();
      }
    }

    return lessons;
  }

  /// Obtener lección por ID (con datos locales)
  Future<Lesson?> getLessonById(int id) async {
    final lesson = await LessonData.getLessonById(id);
    if (lesson == null) return null;

    // Marcar como completada si está en progresión
    final usuarioID = await getUsuarioID();
    if (usuarioID != null) {
      final progresion = await getProgresionUsuario(usuarioID);
      if (progresion != null) {
        final isCompleted = progresion.nivelesCompletados.contains(lesson.id);
        return Lesson(
          id: lesson.id,
          title: lesson.title,
          category: lesson.category,
          letter: lesson.letter,
          description: lesson.description,
          imageUrl: lesson.imageUrl,
          videoUrl: lesson.videoUrl,
          gifUrl: lesson.gifUrl,
          order: lesson.order,
          experiencePoints: lesson.experiencePoints,
          difficulty: lesson.difficulty,
          isCompleted: isCompleted,
          isLocked: false,
          exercises: lesson.exercises,
          learningTips: lesson.learningTips,
          estimatedMinutes: lesson.estimatedMinutes,
        );
      }
    }

    return lesson;
  }

  /// Completar una lección (guardar en API)
  /// Retorna bool si es éxito/fallo normal, o Map con info de meta diaria si se completa
  Future<dynamic> completeLesson({
    required int lessonId,
    required int score,
    required int totalPoints,
  }) async {
    final usuarioID = await getUsuarioID();

    if (usuarioID == null || usuarioID.isEmpty) {
      return false;
    }

    // Determinar si fue exitoso (100% = todas las preguntas correctas)
    final exito = score == totalPoints; // Requiere 100% (3/3 correctas)

    // Registrar el intento
    try {
      await registrarIntento(
        usuarioID: usuarioID,
        nivel: lessonId,
        exito: exito,
      );
    } catch (e) {
      // Error handled silently
    }

    // Acumular experiencia siempre (incluso si no fue exitoso)
    Map<String, dynamic>? metaDiariaInfo;
    try {
      final resultado = await _apiService.completarNivel(
        usuarioID,
        lessonId,
        exito ? 'exito' : 'fallo',
        experienciaGanada: score,
      );

      // Verificar si se completó la meta diaria
      if (resultado && exito) {
        // Recargar progresión para obtener info actualizada
        final progresion = await getProgresionUsuario(usuarioID);
        if (progresion != null) {
          metaDiariaInfo = {
            'leccionesCompletadasHoy': progresion.leccionesCompletadasHoy,
            'metaDiariaCompletada': progresion.leccionesCompletadasHoy == 5,
          };
        }
      }
    } catch (e) {
      // Error handled silently
    }

    // Actualizar el perfil del usuario con la nueva experiencia
    try {
      await AuthService().refreshUserProfile();
    } catch (e) {
      // Error handled silently
    }

    // Si se completó la meta diaria, retornar info adicional
    if (metaDiariaInfo != null && metaDiariaInfo['metaDiariaCompletada'] == true) {
      return {
        'exito': exito,
        'metaDiariaCompletada': true,
        'leccionesCompletadasHoy': metaDiariaInfo['leccionesCompletadasHoy'],
      };
    }

    return exito; // Retorna true solo si fue 100% exitoso
  }

  /// Obtener siguiente lección incompleta (busca en todas las categorías)
  Future<Lesson?> getNextIncompleteLesson() async {
    // Obtener lecciones del alfabeto
    final alphabetLessons = await getAllLessons(category: 'Alphabet');

    // Buscar primera lección incompleta del alfabeto
    for (final lesson in alphabetLessons) {
      if (!lesson.isCompleted) {
        return lesson;
      }
    }

    // Si todas las del alfabeto están completadas, buscar en números
    final numberLessons = await getAllLessons(category: 'Numbers');
    for (final lesson in numberLessons) {
      if (!lesson.isCompleted) {
        return lesson;
      }
    }

    // Si todas las de números están completadas, buscar en gestos
    final gestureLessons = await getAllLessons(category: 'Gestures');
    for (final lesson in gestureLessons) {
      if (!lesson.isCompleted) {
        return lesson;
      }
    }

    // Si todas las de gestos están completadas, buscar en palabras básicas
    final basicWordsLessons = await getAllLessons(category: 'Basic Words');
    for (final lesson in basicWordsLessons) {
      if (!lesson.isCompleted) {
        return lesson;
      }
    }

    // Si todas están completadas, retornar null (no hay más lecciones)
    return null;
  }

  /// Obtener progreso de lecciones (porcentaje completado)
  Future<double> getLessonsProgress() async {
    final usuarioID = await getUsuarioID();
    if (usuarioID == null) return 0.0;

    final completedCount = await getCompletedNivelesCount(usuarioID);
    final lessons = await LessonData.generateAlphabetLessons();
    final totalLessons = lessons.length;

    if (totalLessons == 0) return 0.0;
    return completedCount / totalLessons;
  }

  /// Obtener cantidad de lecciones completadas
  Future<int> getCompletedLessonsCount() async {
    final usuarioID = await getUsuarioID();
    if (usuarioID == null) return 0;

    return await getCompletedNivelesCount(usuarioID);
  }

  /// Obtener cantidad de lecciones completadas por categoría
  Future<int> getCompletedLessonsCountByCategory(String category) async {
    final usuarioID = await getUsuarioID();
    if (usuarioID == null) return 0;

    final progresion = await getProgresionUsuario(usuarioID);
    if (progresion == null) return 0;

    // Obtener todas las lecciones de la categoría
    final allLessons = await LessonData.getLessonsByCategory(category);

    // Contar cuántas de esas lecciones están en nivelesCompletados
    int count = 0;
    for (final lesson in allLessons) {
      if (progresion.nivelesCompletados.contains(lesson.id)) {
        count++;
      }
    }

    return count;
  }
}
