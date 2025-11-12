import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../utils/colors.dart';
import '../widgets/media_display.dart';

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
    final correct = _selectedAnswer == exercise.correctAnswer;

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
                Navigator.of(context).pop(); // Cerrar diálogo

                // Obtener todas las lecciones de la categoría actual
                final currentCategory = _currentLesson!.category;
                final allLessons = await _lessonService.getAllLessons(category: currentCategory);

                // Buscar la siguiente lección en orden (por ID)
                Lesson? nextLesson;
                for (int i = 0; i < allLessons.length; i++) {
                  if (allLessons[i].id == _currentLesson!.id && i + 1 < allLessons.length) {
                    nextLesson = allLessons[i + 1];
                    break;
                  }
                }

                if (nextLesson != null && mounted) {
                  // Reemplazar la pantalla actual con la siguiente lección
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LessonScreen(lessonId: nextLesson!.id),
                    ),
                  );
                } else {
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
    switch (exercise.type) {
      case ExerciseType.practice:
        return _buildPracticeExercise(exercise);
      case ExerciseType.signRecognition:
        return _buildSignRecognitionExercise(exercise);
      case ExerciseType.multipleChoice:
        return _buildMultipleChoiceExercise(exercise);
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
