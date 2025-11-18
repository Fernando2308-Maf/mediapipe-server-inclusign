import 'package:flutter/material.dart';
import 'dart:math';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../data/lesson_data.dart';
import '../widgets/media_display.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _lessonService = LessonService();
  final _authService = AuthService();

  List<Exercise> _practiceExercises = [];
  int _currentExerciseIndex = 0;
  int _score = 0;
  bool _loadingExercises = true;
  bool _showingIntro = true;

  // Estados del ejercicio
  String? _selectedAnswer;
  List<String> _selectedGestures = [];
  bool _hasAnswered = false;

  // Cache de GIFs
  Map<String, String> _gestureGifs = {};

  // Mapeo de índice de ejercicio -> categoría
  Map<int, String> _exerciseCategories = {};

  @override
  void initState() {
    super.initState();
    _loadPracticeExercises();
  }

  Future<void> _loadGifsForExercises(List<Exercise> exercises) async {
    // Cargar GIFs para ejercicios de Palabras Básicas
    // Estos ejercicios muestran las opciones como GIFs en cuadrícula
    for (int i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final category = _exerciseCategories[i];

      // Solo para ejercicios de Basic Words
      if (category == 'Basic Words') {
        for (var gestureName in exercise.options) {
          if (!_gestureGifs.containsKey(gestureName)) {
            try {
              final gifBase64 = await LessonData.loadSingleGestoVideo(gestureName, silent: true);
              if (gifBase64.isNotEmpty) {
                _gestureGifs[gestureName] = gifBase64;
                print('✅ GIF cargado para opción: $gestureName');
              }
            } catch (e) {
              print('⚠️ No se pudo cargar GIF para $gestureName: $e');
            }
          }
        }
      }
    }
  }

  Future<void> _loadPracticeExercises() async {
    setState(() => _loadingExercises = true);

    try {
      final random = Random();
      final allExercises = <Exercise>[];

      // Obtener usuario ID para verificar qué lecciones ha completado
      final usuarioID = await _lessonService.getUsuarioID();

      // Obtener progresión del usuario
      final progresion = usuarioID != null
          ? await _lessonService.getProgresionUsuario(usuarioID)
          : null;

      final completedLessons = progresion?.nivelesCompletados ?? [];

      // Función helper para obtener ejercicios de lecciones completadas
      // Los ejercicios vienen EXACTAMENTE como están en las lecciones
      Future<List<Exercise>> getRandomExercisesFromCategory(String category, int count) async {
        print('📚 Cargando lecciones de categoría: $category');
        final lessons = await LessonData.getLessonsByCategory(category);
        final completedLessonsInCategory = lessons.where((l) => completedLessons.contains(l.id)).toList();

        print('✅ Lecciones completadas en $category: ${completedLessonsInCategory.length}');

        if (completedLessonsInCategory.isEmpty) return [];

        // Tomar SOLO los ejercicios evaluables (con opciones)
        // Filtrar ejercicios de "presentación" que no tienen opciones
        final exercises = <Exercise>[];
        for (var lesson in completedLessonsInCategory) {
          for (var exercise in lesson.exercises) {
            // Solo tomar ejercicios que tengan opciones (son evaluables)
            if (exercise.options.isNotEmpty) {
              // Para alfabeto, cargar el GIF si no está cargado
              if (category == 'Alphabet' && exercise.imageBase64.isEmpty && lesson.letter.isNotEmpty) {
                final gifBase64 = await LessonData.loadAbecedarioImageByLetter(lesson.letter);

                // Crear un nuevo ejercicio con el GIF cargado
                final exerciseWithGif = Exercise(
                  id: exercise.id,
                  type: exercise.type,
                  question: exercise.question,
                  correctAnswer: exercise.correctAnswer,
                  options: exercise.options,
                  imageBase64: gifBase64,
                  imageUrl: exercise.imageUrl,
                  hintText: exercise.hintText,
                  points: exercise.points,
                );
                exercises.add(exerciseWithGif);
              } else {
                exercises.add(exercise);
              }
            }
          }
        }

        print('📝 Ejercicios evaluables en $category: ${exercises.length}');

        if (exercises.isEmpty) return [];

        // Mezclar y tomar los primeros 'count' ejercicios
        exercises.shuffle(random);
        final selectedExercises = exercises.take(count).toList();

        print('🎯 Ejercicios seleccionados de $category: ${selectedExercises.length}');

        return selectedExercises;
      }

      // Obtener 2 ejercicios aleatorios de cada categoría
      final alphabetExercises = await getRandomExercisesFromCategory('Alphabet', 2);
      final numberExercises = await getRandomExercisesFromCategory('Numbers', 2);
      final gestureExercises = await getRandomExercisesFromCategory('Gestures', 2);
      final wordsExercises = await getRandomExercisesFromCategory('Basic Words', 2);

      // Rastrear la categoría de cada ejercicio
      int currentIndex = 0;
      for (var _ in alphabetExercises) {
        _exerciseCategories[currentIndex++] = 'Alphabet';
      }
      for (var _ in numberExercises) {
        _exerciseCategories[currentIndex++] = 'Numbers';
      }
      for (var _ in gestureExercises) {
        _exerciseCategories[currentIndex++] = 'Gestures';
      }
      for (var _ in wordsExercises) {
        _exerciseCategories[currentIndex++] = 'Basic Words';
      }

      allExercises.addAll(alphabetExercises);
      allExercises.addAll(numberExercises);
      allExercises.addAll(gestureExercises);
      allExercises.addAll(wordsExercises);

      // Mezclar todos los ejercicios y reconstruir el mapeo
      final tempMap = <int, String>{};
      for (int i = 0; i < allExercises.length; i++) {
        tempMap[i] = _exerciseCategories[i]!;
      }

      allExercises.shuffle(random);

      // Reconstruir el mapeo después de mezclar
      _exerciseCategories.clear();
      final List<String> categoriesInOrder = [];
      for (int i = 0; i < allExercises.length; i++) {
        categoriesInOrder.add(tempMap[i]!);
      }

      // Ahora necesitamos rastrear qué categoría corresponde a cada ejercicio mezclado
      // Crear un mapa temporal con los ejercicios originales
      final Map<Exercise, String> exerciseToCategory = {};
      currentIndex = 0;
      for (var ex in alphabetExercises) {
        exerciseToCategory[ex] = 'Alphabet';
      }
      for (var ex in numberExercises) {
        exerciseToCategory[ex] = 'Numbers';
      }
      for (var ex in gestureExercises) {
        exerciseToCategory[ex] = 'Gestures';
      }
      for (var ex in wordsExercises) {
        exerciseToCategory[ex] = 'Basic Words';
      }

      // Reconstruir el mapeo basado en el orden mezclado
      for (int i = 0; i < allExercises.length; i++) {
        _exerciseCategories[i] = exerciseToCategory[allExercises[i]]!;
      }

      // Cargar GIFs solo para las opciones (Palabras Básicas)
      // Los ejercicios YA vienen con su imageBase64 desde las lecciones
      await _loadGifsForExercises(allExercises);

      setState(() {
        _practiceExercises = allExercises;
        _loadingExercises = false;
      });

      if (allExercises.isEmpty) {
        _showNoExercisesDialog();
      }
    } catch (e) {
      print('❌ Error cargando ejercicios de repaso: $e');
      setState(() => _loadingExercises = false);
      _showErrorDialog();
    }
  }

  void _showNoExercisesDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Sin lecciones completadas',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Necesitas completar algunas lecciones primero para poder practicar.\n\n¡Empieza con el alfabeto!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Entendido', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Error', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Hubo un error al cargar los ejercicios de repaso.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showIntroDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            const Text('💪 ', style: TextStyle(fontSize: 28)),
            const Text(
              'Modo Repaso',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Bienvenido al Modo Repaso!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Este es un mini examen diseñado para reforzar tu aprendizaje.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 15),
              _buildInfoPoint('🎯', 'Retos', '${_practiceExercises.length} ejercicios aleatorios de todas las categorías'),
              const SizedBox(height: 10),
              _buildInfoPoint('⚡', 'Recompensa', 'Gana XP por cada respuesta correcta'),
              const SizedBox(height: 10),
              _buildInfoPoint('🎓', 'Aprendizaje', 'Refuerza lo que ya has aprendido'),
              const SizedBox(height: 10),
              _buildInfoPoint('🔥', 'Objetivo', 'Pon a prueba tu memoria y velocidad'),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Text(
                  '💡 Tip: No te preocupes si fallas, esto es solo para practicar. ¡Lo importante es seguir aprendiendo!',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Center(
                child: Text(
                  '¡Mucha suerte! 🍀',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Volver al home
            },
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _showingIntro = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '¡Comenzar!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _checkAnswer() {
    if (_hasAnswered) return;

    final currentExercise = _practiceExercises[_currentExerciseIndex];
    final currentCategory = _exerciseCategories[_currentExerciseIndex] ?? '';
    bool correct = false;

    // Verificar según la categoría del ejercicio
    if (currentCategory == 'Basic Words') {
      // Ejercicio de selección de GIF (Palabras Básicas)
      correct = _selectedGestures.length == 1 &&
                _selectedGestures[0] == currentExercise.correctAnswer;
    } else {
      // Ejercicio de opción múltiple normal (Alfabeto, Números, Gestos)
      correct = _selectedAnswer == currentExercise.correctAnswer;
    }

    if (correct) {
      _score += currentExercise.points;
    }

    setState(() => _hasAnswered = true);

    // Avanzar automáticamente después de 1.5 segundos
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _nextExercise();
      }
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _practiceExercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _selectedAnswer = null;
        _selectedGestures.clear();
        _hasAnswered = false;
      });
    } else {
      _completePractice();
    }
  }

  Future<void> _completePractice() async {
    // Guardar la experiencia ganada
    final usuarioID = await _lessonService.getUsuarioID();

    if (usuarioID != null && _score > 0) {
      print('💾 Guardando ${_score} XP de modo repaso al perfil del usuario...');

      try {
        // Usar completarNivel con nivel 0 y resultado 'fallo' para solo agregar XP
        // sin marcar ninguna lección como completada
        await _lessonService.completarNivel(
          usuarioID: usuarioID,
          nivel: 0, // Nivel especial para repaso (no marca lección como completada)
          exito: false, // false = no marca como completado, solo suma XP
          experienciaGanada: _score,
        );

        // Actualizar el perfil para reflejar la nueva experiencia
        await _authService.refreshUserProfile();

        print('✅ XP de repaso guardado exitosamente');
      } catch (e) {
        print('❌ Error guardando XP de repaso: $e');
      }
    }

    if (!mounted) return;

    final totalPoints = _practiceExercises.fold<int>(0, (sum, ex) => sum + ex.points);
    final percentage = ((_score / totalPoints) * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '¡Repaso Completado! 🎉',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Completaste $_currentExerciseIndex ejercicios de repaso',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 5),
                Text(
                  '+$_score XP',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.experienceGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                percentage >= 80
                    ? '¡Excelente trabajo! Dominas muy bien el contenido.'
                    : percentage >= 60
                        ? '¡Bien hecho! Sigue practicando para mejorar.'
                        : '¡No te desanimes! La práctica hace al maestro.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver al Inicio', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reiniciar repaso con nuevos ejercicios aleatorios
              setState(() {
                _currentExerciseIndex = 0;
                _score = 0;
                _showingIntro = true;
                _selectedAnswer = null;
                _selectedGestures.clear();
                _hasAnswered = false;
                _gestureGifs.clear(); // Limpiar cache de GIFs
                _exerciseCategories.clear(); // Limpiar mapeo de categorías
              });
              _loadPracticeExercises(); // Esto generará nuevos ejercicios aleatorios
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Nuevo Repaso', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExercises) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_practiceExercises.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text(
            'No hay ejercicios disponibles',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    if (_showingIntro) {
      Future.microtask(() => _showIntroDialog());
    }

    final currentExercise = _practiceExercises[_currentExerciseIndex];

    // Los ejercicios de Palabras Básicas usan selección de GIFs
    final currentCategory = _exerciseCategories[_currentExerciseIndex] ?? '';
    final isBasicWordsExercise = currentCategory == 'Basic Words';


    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Modo Repaso 💪',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentExerciseIndex + 1}/${_practiceExercises.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso
            LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / _practiceExercises.length,
              backgroundColor: AppColors.borderDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 6,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Renderizar según la categoría del ejercicio
                    if (isBasicWordsExercise)
                      // Para Palabras Básicas: cuadrícula de GIFs (igual que lecciones 59-68)
                      ...[
                        // Pregunta con instrucción
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.touch_app, color: AppColors.purple, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Selecciona 1 GIF',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                currentExercise.question,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Vista previa de gestos seleccionados
                        if (_selectedGestures.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '✅ Seleccionado:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedGestures[0],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_selectedGestures.isNotEmpty) const SizedBox(height: 20),
                        // Cuadrícula de GIFs
                        _buildGestureOptions(currentExercise),
                      ]
                    else
                      // Para Alfabeto, Números, Gestos: imagen + pregunta + opciones
                      ...[
                        // Pregunta
                        Text(
                          currentExercise.question,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        // Imagen o Emoji
                        Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: currentExercise.imageBase64.isNotEmpty
                              ? MediaDisplay(
                                  base64Content: currentExercise.imageBase64,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.contain,
                                )
                              : Text(
                                  currentExercise.imageUrl,
                                  style: const TextStyle(fontSize: 100),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                        const SizedBox(height: 30),
                        // Opciones de texto
                        _buildMultipleChoiceOptions(currentExercise),
                      ],
                    const SizedBox(height: 20),
                    // Botón verificar
                    if (!_hasAnswered)
                      ElevatedButton(
                        onPressed: (_selectedAnswer != null || _selectedGestures.isNotEmpty)
                            ? _checkAnswer
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Verificar Respuesta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Feedback
                    if (_hasAnswered)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (_selectedAnswer == currentExercise.correctAnswer ||
                                  (_selectedGestures.isNotEmpty &&
                                      _selectedGestures[0] == currentExercise.correctAnswer))
                              ? AppColors.success.withOpacity(0.2)
                              : AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_selectedAnswer == currentExercise.correctAnswer ||
                                    (_selectedGestures.isNotEmpty &&
                                        _selectedGestures[0] == currentExercise.correctAnswer))
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (_selectedAnswer == currentExercise.correctAnswer ||
                                      (_selectedGestures.isNotEmpty &&
                                          _selectedGestures[0] == currentExercise.correctAnswer))
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: (_selectedAnswer == currentExercise.correctAnswer ||
                                      (_selectedGestures.isNotEmpty &&
                                          _selectedGestures[0] == currentExercise.correctAnswer))
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                (_selectedAnswer == currentExercise.correctAnswer ||
                                        (_selectedGestures.isNotEmpty &&
                                            _selectedGestures[0] == currentExercise.correctAnswer))
                                    ? '¡Correcto! +${currentExercise.points} XP'
                                    : 'Incorrecto. La respuesta era: ${currentExercise.correctAnswer}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(Exercise exercise) {
    return Column(
      children: exercise.options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == exercise.correctAnswer;
        final showCorrect = _hasAnswered && isCorrect;
        final showIncorrect = _hasAnswered && isSelected && !isCorrect;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: _hasAnswered
                ? null
                : () {
                    setState(() => _selectedAnswer = option);
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: showCorrect
                    ? AppColors.success.withOpacity(0.2)
                    : showIncorrect
                        ? AppColors.error.withOpacity(0.2)
                        : isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showCorrect
                      ? AppColors.success
                      : showIncorrect
                          ? AppColors.error
                          : isSelected
                              ? AppColors.primary
                              : AppColors.border,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: showCorrect
                          ? AppColors.success
                          : showIncorrect
                              ? AppColors.error
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                      border: Border.all(
                        color: showCorrect
                            ? AppColors.success
                            : showIncorrect
                                ? AppColors.error
                                : isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: showCorrect || showIncorrect
                        ? Icon(
                            showCorrect ? Icons.check : Icons.close,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: showCorrect || showIncorrect
                            ? AppColors.textPrimary
                            : isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGestureOptions(Exercise exercise) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: exercise.options.length,
      itemBuilder: (context, index) {
        final gesture = exercise.options[index];
        final isSelected = _selectedGestures.contains(gesture);
        final isCorrect = gesture == exercise.correctAnswer;
        final showCorrect = _hasAnswered && isCorrect;
        final showIncorrect = _hasAnswered && isSelected && !isCorrect;

        return InkWell(
          onTap: _hasAnswered
              ? null
              : () {
                  setState(() {
                    _selectedGestures.clear();
                    _selectedGestures.add(gesture);
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: showCorrect
                  ? AppColors.success.withOpacity(0.2)
                  : showIncorrect
                      ? AppColors.error.withOpacity(0.2)
                      : isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showCorrect
                    ? AppColors.success
                    : showIncorrect
                        ? AppColors.error
                        : isSelected
                            ? AppColors.primary
                            : AppColors.border,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _gestureGifs.containsKey(gesture)
                        ? MediaDisplay(
                            base64Content: _gestureGifs[gesture]!,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    gesture,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
