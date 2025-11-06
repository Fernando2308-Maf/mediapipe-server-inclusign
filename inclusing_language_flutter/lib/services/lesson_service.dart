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
  }) async {
    final resultado = exito ? 'exito' : 'fallo';
    return await _apiService.completarNivel(usuarioID, nivel, resultado);
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
    print('🔍 [LessonService] Buscando usuarioID...');

    // Primero intentar desde storage
    var usuarioID = await _storageService.getSecure('usuario_id');
    if (usuarioID != null && usuarioID.isNotEmpty) {
      print('✓ [LessonService] UsuarioID encontrado en storage: $usuarioID');
      return usuarioID;
    }

    print('⚠️ [LessonService] No se encontró usuarioID en storage');

    // Si no está en storage, verificar email
    final email = await _authService.getUserEmail();
    print('📧 [LessonService] Email del usuario: $email');

    if (email == null) {
      print('❌ [LessonService] No se pudo obtener email');
      return null;
    }

    // Para invitados, retornar null para que no intenten guardar
    if (email == 'guest@signlearn.com') {
      print('👤 [LessonService] Usuario invitado detectado');
      return null;
    }

    // MIGRATION: Para usuarios existentes sin usuarioID almacenado,
    // buscarlo en la colección Usuarios por correo
    print('🔄 [LessonService] Intentando obtener usuarioID desde API por email...');
    try {
      final usuario = await _apiService.getUsuarioByEmail(email);
      if (usuario != null && usuario['usuarioID'] != null) {
        usuarioID = usuario['usuarioID'] as String;
        // Guardar en storage para futuras consultas
        await _storageService.setSecure('usuario_id', usuarioID);
        print('✅ [LessonService] UsuarioID obtenido y guardado: $usuarioID');
        return usuarioID;
      } else {
        print('❌ [LessonService] Usuario no encontrado en API');
      }
    } catch (e) {
      print('❌ [LessonService] Error al buscar usuarioID: $e');
    }

    print('❌ [LessonService] No se pudo obtener usuarioID');
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
  Future<bool> completeLesson({
    required int lessonId,
    required int score,
    required int totalPoints,
  }) async {
    print('📚 [LessonService] Iniciando completar lección $lessonId');

    final usuarioID = await getUsuarioID();
    print('👤 [LessonService] UsuarioID obtenido: $usuarioID');

    if (usuarioID == null || usuarioID.isEmpty) {
      print('❌ [LessonService] ERROR: No se pudo obtener usuarioID');
      return false;
    }

    // Determinar si fue exitoso (score >= 60%)
    final percentage = (score / totalPoints * 100).round();
    final exito = percentage >= 60;
    print('📊 [LessonService] Porcentaje: $percentage% - Éxito: $exito');

    // Registrar el intento
    print('📝 [LessonService] Registrando intento...');
    final intentoRegistrado = await registrarIntento(
      usuarioID: usuarioID,
      nivel: lessonId,
      exito: exito,
    );
    print('✓ [LessonService] Intento registrado: $intentoRegistrado');

    // Si fue exitoso, completar el nivel
    if (exito) {
      print('🏆 [LessonService] Completando nivel...');
      final nivelCompletado = await completarNivel(
        usuarioID: usuarioID,
        nivel: lessonId,
        exito: true,
        experienciaGanada: score, // Enviar la experiencia ganada
      );
      print('✓ [LessonService] Nivel completado: $nivelCompletado');

      // Actualizar el perfil del usuario con la nueva experiencia
      if (nivelCompletado) {
        print('🔄 [LessonService] Actualizando perfil del usuario...');
        await AuthService().refreshUserProfile();
        print('✓ [LessonService] Perfil actualizado');
      }

      return nivelCompletado;
    }

    return intentoRegistrado; // Intento registrado aunque no haya sido exitoso
  }

  /// Obtener siguiente lección incompleta
  Future<Lesson?> getNextIncompleteLesson() async {
    final lessons = await getAllLessons();
    for (final lesson in lessons) {
      if (!lesson.isCompleted) {
        return lesson;
      }
    }
    // Si todas están completadas, retornar la primera
    return lessons.isNotEmpty ? lessons.first : null;
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
}
