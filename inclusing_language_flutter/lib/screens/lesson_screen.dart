import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../utils/colors.dart';
import '../widgets/media_display.dart';
import '../data/lesson_data.dart';

class LessonScreen extends StatefulWidget {
  final int lessonId;

  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _lessonService = LessonService();

  Lesson? _currentLesson;
  int _currentExerciseIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  String? _selectedAnswer;
  bool _answerVerified = false;
  bool _isCorrect = false;
  bool _showHint = false;

  // Para la lección 59: Constructor de Frases
  List<String> _selectedGestures = []; // Gestos seleccionados en orden
  Map<String, String> _gestureGifs = {}; // Mapeo de nombre -> base64 GIF

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final lesson = await _lessonService.getLessonById(widget.lessonId);
      setState(() {
        _currentLesson = lesson;
        _isLoading = false;
      });

      if (lesson == null) {
        _showAlert('Error', 'No se pudo cargar la lección');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showAlert('Error', 'Ocurrió un error: ${e.toString()}');
    }
  }

  void _handleNext() {
    final exercise = _currentLesson!.exercises[_currentExerciseIndex];

    // Para Practice, solo continuar al siguiente
    if (exercise.type == ExerciseType.practice) {
      _score += exercise.points;
      setState(() {
        _currentExerciseIndex++;
        _resetExerciseState();
      });
      return;
    }

    // Para otros ejercicios, primero verificar
    if (!_answerVerified) {
      if (_selectedAnswer == null) {
        _showAlert('Selecciona una opción', 'Por favor selecciona una respuesta antes de continuar');
        return;
      }
      _verifyAnswer();
    } else {
      // Pasar al siguiente ejercicio
      if (_currentExerciseIndex < _currentLesson!.exercises.length - 1) {
        setState(() {
          _currentExerciseIndex++;
          _resetExerciseState();
        });
      } else {
        // Finalizar lección
        _completeLesson();
      }
    }
  }

  void _verifyAnswer() {
    final exercise = _currentLesson!.exercises[_currentExerciseIndex];

    // Para lecciones 59-68 (palabras básicas), verificar que seleccionó exactamente 1 GIF correcto
    bool correct;
    if (widget.lessonId >= 59 && widget.lessonId <= 68) {
      // Solo hay 1 gesto correcto por ejercicio
      correct = _selectedGestures.length == 1 && _selectedGestures[0] == exercise.correctAnswer;
    } else {
      // Lecciones normales
      correct = _selectedAnswer == exercise.correctAnswer;
    }

    setState(() {
      _answerVerified = true;
      _isCorrect = correct;
      if (correct) {
        _score += exercise.points;
      }
    });
  }

  void _resetExerciseState() {
    setState(() {
      _selectedAnswer = null;
      _answerVerified = false;
      _isCorrect = false;
      _showHint = false;
      _selectedGestures.clear(); // Para lección 59
    });
  }

  Future<void> _completeLesson() async {
    final totalPoints = _currentLesson!.experiencePoints;
    final percentage = (_score / totalPoints * 100).round();

    // Guardar en API
    print('🎯 Intentando guardar lección ${_currentLesson!.id} - Score: $_score/$totalPoints ($percentage%)');

    final saved = await _lessonService.completeLesson(
      lessonId: _currentLesson!.id,
      score: _score,
      totalPoints: totalPoints,
    );

    print('💾 Resultado de guardado: ${saved ? "ÉXITO" : "FALLÓ"}');

    if (!mounted) return;

    // Mostrar diálogo de completado
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          percentage == 100 ? '¡Perfecto! 🎉' : 'Intenta de nuevo',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: percentage == 100 ? AppColors.success : AppColors.error,
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
              percentage == 100
                  ? '¡Has completado la lección con 3/3 correctas!'
                  : 'Necesitas responder todas las preguntas correctamente (3/3)',
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
          if (percentage < 100)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Recargar la lección para reintentar
                setState(() {
                  _currentExerciseIndex = 0;
                  _score = 0;
                  _resetExerciseState();
                });
              },
              child: const Text('Reintentar Lección', style: TextStyle(color: AppColors.error)),
            ),
          if (percentage == 100)
            TextButton(
              onPressed: () async {
                print('🔍 Buscando siguiente lección...');
                print('📚 Lección actual: ID=${_currentLesson!.id}, Categoría=${_currentLesson!.category}');

                // Obtener todas las lecciones de la categoría actual
                final currentCategory = _currentLesson!.category;
                final allLessons = await _lessonService.getAllLessons(category: currentCategory);

                print('📋 Total lecciones en categoría "$currentCategory": ${allLessons.length}');

                // Buscar la siguiente lección por ID (no por índice)
                Lesson? nextLesson;

                // Para lecciones de "Basic Words" (IDs 59-68)
                if (currentCategory == 'Basic Words' && _currentLesson!.id >= 59 && _currentLesson!.id <= 67) {
                  // Buscar la siguiente lección por ID consecutivo
                  final nextId = _currentLesson!.id + 1;
                  print('🔄 Buscando siguiente lección de Basic Words: ID $nextId');
                  nextLesson = await _lessonService.getLessonById(nextId);

                  if (nextLesson != null) {
                    print('✅ Siguiente lección encontrada: ${nextLesson.title}');
                  } else {
                    print('❌ No se encontró la lección con ID $nextId');
                  }
                } else {
                  print('🔍 Buscando en array de lecciones (método estándar)');
                  // Para otras categorías, buscar en el array
                  for (int i = 0; i < allLessons.length; i++) {
                    if (allLessons[i].id == _currentLesson!.id && i + 1 < allLessons.length) {
                      nextLesson = allLessons[i + 1];
                      print('✅ Siguiente lección encontrada: ${nextLesson!.title}');
                      break;
                    }
                  }
                }

                // Cerrar el diálogo primero
                if (!mounted) return;
                Navigator.of(context).pop();

                // Esperar un momento para que el diálogo se cierre completamente
                await Future.delayed(const Duration(milliseconds: 100));

                // Ahora navegar con el context válido
                if (!mounted) return;

                if (nextLesson != null) {
                  print('➡️ Navegando a siguiente lección: ${nextLesson.title}');
                  // Reemplazar la pantalla actual con la siguiente lección
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(lessonId: nextLesson!.id),
                    ),
                  );
                } else {
                  print('🏠 No hay más lecciones, regresando al home');
                  // No hay más lecciones en esta categoría, regresar al home
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Continuar', style: TextStyle(color: AppColors.success)),
            ),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    final exercise = _currentLesson!.exercises[_currentExerciseIndex];

    if (exercise.type == ExerciseType.practice) {
      return 'Continuar';
    }

    if (!_answerVerified) {
      return 'Verificar';
    }

    if (_currentExerciseIndex < _currentLesson!.exercises.length - 1) {
      return 'Siguiente';
    }

    return 'Finalizar';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_currentLesson == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Lección', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: Text(
            'Lección no encontrada',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
        ),
      );
    }

    final exercise = _currentLesson!.exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / _currentLesson!.exercises.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppColors.cardBackground,
                title: const Text('¿Salir?', style: TextStyle(color: AppColors.textPrimary)),
                content: const Text(
                  'Perderás tu progreso en esta lección.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.secondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Salir', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          children: [
            Text(
              _currentLesson!.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Ejercicio ${_currentExerciseIndex + 1}/${_currentLesson!.exercises.length}',
              style: const TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.experienceGold,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '⚡ $_score/${_currentLesson!.experiencePoints}',
              style: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.borderDark,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildExerciseContent(exercise),
              ),
            ),
            _buildFooter(exercise),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseContent(Exercise exercise) {
    // Para lecciones 59-68 (Palabras Básicas), usar UI especial con GIFs
    if (widget.lessonId >= 59 && widget.lessonId <= 68) {
      return _buildGestureSelectionExercise(exercise);
    }

    switch (exercise.type) {
      case ExerciseType.practice:
        return _buildPracticeExercise(exercise);
      case ExerciseType.signRecognition:
        return _buildSignRecognitionExercise(exercise);
      case ExerciseType.multipleChoice:
        return _buildMultipleChoiceExercise(exercise);
      case ExerciseType.matching:
        return _buildGestureSelectionExercise(exercise);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPracticeExercise(Exercise exercise) {
    return Column(
      children: [
        // Imagen o Emoji grande
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: exercise.imageBase64.isNotEmpty
              ? MediaDisplay(
                  base64Content: exercise.imageBase64,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                )
              : Text(
                  exercise.imageUrl,
                  style: const TextStyle(fontSize: 120),
                ),
        ),
        const SizedBox(height: 30),
        // Título
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '📖 Ver y Aprender',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Descripción
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Cómo hacer la seña:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                exercise.correctAnswer,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.borderDark,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Consejo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Practica frente a un espejo para ver tu mano desde la perspectiva del observador.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignRecognitionExercise(Exercise exercise) {
    return Column(
      children: [
        // Pregunta
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            exercise.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
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
          child: exercise.imageBase64.isNotEmpty
              ? MediaDisplay(
                  base64Content: exercise.imageBase64,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                )
              : Text(
                  exercise.imageUrl,
                  style: const TextStyle(fontSize: 100),
                ),
        ),
        const SizedBox(height: 30),
        // Opciones
        ...exercise.options.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectAnswer = option == exercise.correctAnswer;
          final showAsCorrect = _answerVerified && isCorrectAnswer;
          final showAsWrong = _answerVerified && isSelected && !_isCorrect;

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildOptionButton(
              option,
              isSelected,
              showAsCorrect,
              showAsWrong,
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        // Feedback
        if (_answerVerified) _buildFeedback(),
        // Hint
        if (_showHint && !_answerVerified) _buildHint(exercise.hintText),
      ],
    );
  }

  Widget _buildMultipleChoiceExercise(Exercise exercise) {
    return Column(
      children: [
        // Pregunta con letra
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                exercise.question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              exercise.imageBase64.isNotEmpty
                  ? MediaDisplay(
                      base64Content: exercise.imageBase64,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      exercise.imageUrl,
                      style: const TextStyle(fontSize: 80),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Opciones
        ...exercise.options.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectAnswer = option == exercise.correctAnswer;
          final showAsCorrect = _answerVerified && isCorrectAnswer;
          final showAsWrong = _answerVerified && isSelected && !_isCorrect;

          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: _buildDescriptionOption(
              option,
              isSelected,
              showAsCorrect,
              showAsWrong,
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        // Feedback
        if (_answerVerified) _buildFeedback(),
        // Hint
        if (_showHint && !_answerVerified) _buildHint(exercise.hintText),
      ],
    );
  }

  Widget _buildOptionButton(
    String option,
    bool isSelected,
    bool showAsCorrect,
    bool showAsWrong,
  ) {
    Color backgroundColor = AppColors.cardBackground;
    Color borderColor = AppColors.border;

    if (showAsCorrect) {
      backgroundColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (showAsWrong) {
      backgroundColor = AppColors.error;
      borderColor = AppColors.error;
    } else if (isSelected) {
      backgroundColor = AppColors.primary;
      borderColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: _answerVerified
          ? null
          : () {
              setState(() {
                _selectedAnswer = option;
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: (showAsCorrect || showAsWrong || isSelected) ? Colors.white : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDescriptionOption(
    String option,
    bool isSelected,
    bool showAsCorrect,
    bool showAsWrong,
  ) {
    Color backgroundColor = AppColors.cardBackground;
    Color borderColor = AppColors.border;

    if (showAsCorrect) {
      backgroundColor = AppColors.success;
      borderColor = AppColors.success;
    } else if (showAsWrong) {
      backgroundColor = AppColors.error;
      borderColor = AppColors.error;
    } else if (isSelected) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.2);
      borderColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: _answerVerified
          ? null
          : () {
              setState(() {
                _selectedAnswer = option;
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          option,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: (showAsCorrect || showAsWrong) ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // Método especial para lección 59: Constructor de Frases
  Widget _buildGestureSelectionExercise(Exercise exercise) {
    return FutureBuilder<Map<String, String>>(
      future: _loadGestureGifs(exercise.options),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 20),
                Text(
                  'Cargando gestos...',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Error cargando gestos',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        final gestureGifs = snapshot.data!;
        final correctGestures = exercise.correctAnswer.split(',');

        return Column(
          children: [
            // Pregunta y contexto
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
                    exercise.question,
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

            // Gestos seleccionados (vista previa)
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
                      '✅ Seleccionados:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedGestures.asMap().entries.map((entry) {
                        final index = entry.key;
                        final gesture = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                gesture,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    if (!_answerVerified)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGestures.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 16, color: AppColors.error),
                        label: const Text(
                          'Reiniciar selección',
                          style: TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            if (_selectedGestures.isNotEmpty) const SizedBox(height: 20),

            // Cuadrícula de GIFs - continuado en siguiente parte...
            _buildGestureGrid(exercise, gestureGifs, correctGestures),

            const SizedBox(height: 20),

            // Feedback
            if (_answerVerified) _buildFeedback(),

            // Hint
            if (_showHint && !_answerVerified) _buildHint(exercise.hintText),
          ],
        );
      },
    );
  }

  // Cuadrícula de GIFs interactivos
  Widget _buildGestureGrid(Exercise exercise, Map<String, String> gestureGifs, List<String> correctGestures) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemCount: exercise.options.length,
      itemBuilder: (context, index) {
        final gestureName = exercise.options[index];
        final gifBase64 = gestureGifs[gestureName] ?? '';
        final isSelected = _selectedGestures.contains(gestureName);
        final selectionOrder = isSelected ? _selectedGestures.indexOf(gestureName) + 1 : null;

        // Verificación de respuesta
        final isCorrectGesture = correctGestures.contains(gestureName);
        final showAsCorrect = _answerVerified && isCorrectGesture && isSelected;
        final showAsWrong = _answerVerified && !isCorrectGesture && isSelected;
        final showAsMissed = _answerVerified && isCorrectGesture && !isSelected;

        Color borderColor = AppColors.border;
        Color backgroundColor = AppColors.cardBackground;

        if (showAsCorrect) {
          borderColor = AppColors.success;
          backgroundColor = AppColors.success.withOpacity(0.1);
        } else if (showAsWrong) {
          borderColor = AppColors.error;
          backgroundColor = AppColors.error.withOpacity(0.1);
        } else if (showAsMissed) {
          borderColor = AppColors.warning;
          backgroundColor = AppColors.warning.withOpacity(0.1);
        } else if (isSelected) {
          borderColor = AppColors.primary;
          backgroundColor = AppColors.primary.withOpacity(0.1);
        }

        return GestureDetector(
          onTap: _answerVerified
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      // Deseleccionar
                      _selectedGestures.clear();
                    } else {
                      // Seleccionar solo este (limpiar otros primero)
                      _selectedGestures.clear();
                      _selectedGestures.add(gestureName);
                    }
                    _selectedAnswer = _selectedGestures.isNotEmpty ? _selectedGestures[0] : null;
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor, width: 3),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: gifBase64.isNotEmpty
                            ? MediaDisplay(
                                base64Content: gifBase64,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor.withOpacity(0.9),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Text(
                        gestureName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (selectionOrder != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected && !_answerVerified
                            ? AppColors.primary
                            : showAsCorrect
                                ? AppColors.success
                                : AppColors.error,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$selectionOrder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_answerVerified)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: showAsCorrect
                            ? AppColors.success
                            : showAsWrong
                                ? AppColors.error
                                : showAsMissed
                                    ? AppColors.warning
                                    : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        showAsCorrect
                            ? Icons.check
                            : showAsWrong
                                ? Icons.close
                                : showAsMissed
                                    ? Icons.lightbulb_outline
                                    : Icons.circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper para cargar GIFs
  Future<Map<String, String>> _loadGestureGifs(List<String> gestureNames) async {
    final Map<String, String> gifs = {};

    for (final name in gestureNames) {
      try {
        final gif = await LessonData.loadSingleGestoVideo(name, silent: true);
        if (gif.isNotEmpty) {
          gifs[name] = gif;
        }
      } catch (e) {
        print('Error cargando GIF para $name: $e');
      }
    }

    return gifs;
  }

  Widget _buildFeedback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCorrect ? AppColors.success : AppColors.error,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              _isCorrect ? '¡Correcto! 🎉' : 'Incorrecto. Inténtalo de nuevo la próxima vez.',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(String hintText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.borderDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pista:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hintText,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(Exercise exercise) {
    final canShowHint = exercise.type != ExerciseType.practice && !_answerVerified;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canShowHint)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showHint = !_showHint),
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(_showHint ? 'Ocultar Pista' : 'Ver Pista'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.border),
                  minimumSize: const Size(0, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          if (canShowHint) const SizedBox(width: 15),
          Expanded(
            flex: canShowHint ? 2 : 1,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
