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
  final List<String> _selectedGestures = []; // Gestos seleccionados en orden

  // Para las lecciones 69-78: Armar Palabras
  final List<String> _selectedLetters = []; // Letras seleccionadas en orden
  List<String> _keyboardLetters = []; // Orden fijo del teclado (no cambia durante el ejercicio)

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
      // Para lecciones 69-78 (armar palabras), verificar que hay letras seleccionadas
      if (widget.lessonId >= 69 && widget.lessonId <= 78) {
        if (_selectedLetters.isEmpty) {
          _showAlert('Forma una palabra', 'Por favor selecciona letras para formar la palabra');
          return;
        }
      } else if (_selectedAnswer == null && (widget.lessonId < 59 || widget.lessonId > 68)) {
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
    } else if (widget.lessonId >= 69 && widget.lessonId <= 78) {
      // Para lecciones 69-78 (armar palabras), verificar que formó la palabra correcta
      final formedWord = _selectedLetters.join();
      correct = formedWord == exercise.correctAnswer;
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
      _selectedLetters.clear(); // Para lecciones 69-78
      _keyboardLetters.clear(); // Limpiar el orden del teclado para regenerarlo
    });
  }

  Future<void> _completeLesson() async {
    final totalPoints = _currentLesson!.experiencePoints;
    final percentage = (_score / totalPoints * 100).round();

    final resultado = await _lessonService.completeLesson(
      lessonId: _currentLesson!.id,
      score: _score,
      totalPoints: totalPoints,
    );

    // Verificar si se completó la meta diaria
    bool metaDiariaCompletada = false;
    if (resultado is Map && resultado['metaDiariaCompletada'] == true) {
      metaDiariaCompletada = true;
    }

    // Verificar si se completó toda la categoría
    bool categoriaCompletada = false;
    if (percentage == 100) {
      categoriaCompletada = await _checkCategoryCompletion(_currentLesson!.category);
    }

    if (!mounted) return;

    // Si se completó la meta diaria, mostrar diálogo especial primero
    if (metaDiariaCompletada) {
      await _showDailyGoalDialog();
    }

    // Si se completó toda la categoría, mostrar felicitaciones
    if (categoriaCompletada) {
      await _showCategoryCompletionDialog(_currentLesson!.category);
    }

    // Mostrar diálogo de completado
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          percentage == 100 ? '¡Perfecto! 🎉' : 'Intenta de nuevo',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: percentage == 100 ? AppColors.success : AppColors.error,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              percentage == 100
                  ? '¡Has completado la lección con 3/3 correctas!'
                  : 'Necesitas responder todas las preguntas correctamente (3/3)',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('⚡', style: TextStyle(fontSize: 24)),
                SizedBox(width: 5),
                Text(
                  '+$_score XP',
                  style: TextStyle(
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
            child: Text('Volver al Inicio', style: TextStyle(color: AppColors.primary)),
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
              child: Text('Reintentar Lección', style: TextStyle(color: AppColors.error)),
            ),
          if (percentage == 100)
            TextButton(
              onPressed: () async {
                // Obtener todas las lecciones de la categoría actual
                final currentCategory = _currentLesson!.category;
                final allLessons = await _lessonService.getAllLessons(category: currentCategory);

                // Buscar la siguiente lección por ID (no por índice)
                Lesson? nextLesson;

                // Para lecciones de "Basic Words" (IDs 59-68)
                if (currentCategory == 'Basic Words' && _currentLesson!.id >= 59 && _currentLesson!.id <= 67) {
                  // Buscar la siguiente lección por ID consecutivo
                  final nextId = _currentLesson!.id + 1;
                  nextLesson = await _lessonService.getLessonById(nextId);
                } else {
                  // Para otras categorías, buscar en el array
                  for (int i = 0; i < allLessons.length; i++) {
                    if (allLessons[i].id == _currentLesson!.id && i + 1 < allLessons.length) {
                      nextLesson = allLessons[i + 1];
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
              child: Text('Continuar', style: TextStyle(color: AppColors.success)),
            ),
        ],
      ),
    );
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
        content: Text(message, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDailyGoalDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Meta Diaria Completada!',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '5/5',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Lecciones completadas hoy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),
            Text(
              '¡Felicitaciones!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Has alcanzado tu meta diaria de 5 lecciones.\n\n¡Sigue así y dominarás el lenguaje de señas!',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.experienceGold.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.experienceGold, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎁', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recompensa especial',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '+15 XP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.experienceGold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'BONUS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              '¡Genial!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  /// Verificar si se completaron todas las lecciones de una categoría
  Future<bool> _checkCategoryCompletion(String category) async {
    try {
      final completedCount = await _lessonService.getCompletedLessonsCountByCategory(category);
      final allLessons = await _lessonService.getAllLessons(category: category);

      return completedCount == allLessons.length;
    } catch (e) {
      return false;
    }
  }

  /// Mostrar diálogo de felicitaciones por completar toda una categoría
  Future<void> _showCategoryCompletionDialog(String category) async {
    String categoryName = '';
    String emoji = '';
    String encouragement = '';

    switch (category) {
      case 'Alphabet':
        categoryName = 'el Alfabeto';
        emoji = '🔤';
        encouragement = '¡Ahora puedes deletrear cualquier palabra en lenguaje de señas!';
        break;
      case 'Numbers':
        categoryName = 'los Números';
        emoji = '🔢';
        encouragement = '¡Ahora puedes contar y expresar cantidades con tus manos!';
        break;
      case 'Gestures':
        categoryName = 'los Gestos';
        emoji = '👋';
        encouragement = '¡Ya puedes comunicarte con saludos y frases básicas!';
        break;
      case 'Basic Words':
        categoryName = 'las Palabras Básicas';
        emoji = '💬';
        encouragement = '¡Tu vocabulario en lenguaje de señas está creciendo!';
        break;
      default:
        categoryName = 'esta categoría';
        emoji = '🎯';
        encouragement = '¡Sigue así, estás aprendiendo muy bien!';
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Row(
          children: [
            Text(emoji, style: TextStyle(fontSize: 32)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Categoría Completada!',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha:0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '100%',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'COMPLETADO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                '¡Felicitaciones!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Has completado todas las lecciones de $categoryName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha:0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  encouragement,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 15),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '¡Sigue aprendiendo! Explora otras categorías',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(
              '¡Continuar!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
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
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_currentLesson == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).cardTheme.color,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Lección', style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Text(
            'Lección no encontrada',
            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 18),
          ),
        ),
      );
    }

    final exercise = _currentLesson!.exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / _currentLesson!.exercises.length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: Theme.of(context).cardTheme.color,
                title: Text('¿Salir?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                content: Text(
                  'Perderás tu progreso en esta lección.',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancelar', style: TextStyle(color: AppColors.secondary)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Salir', style: TextStyle(color: AppColors.error)),
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
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Ejercicio ${_currentExerciseIndex + 1}/${_currentLesson!.exercises.length}',
              style: TextStyle(color: AppColors.secondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 15),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.experienceGold,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '⚡ $_score/${_currentLesson!.experiencePoints}',
              style: TextStyle(
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
                padding: EdgeInsets.all(20),
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
      case ExerciseType.wordBuilder:
        return _buildWordBuilderExercise(exercise);
      default:
        return SizedBox();
    }
  }

  Widget _buildPracticeExercise(Exercise exercise) {
    return Column(
      children: [
        // Imagen o Emoji grande
        Container(
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
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
                  style: TextStyle(fontSize: 120),
                ),
        ),
        SizedBox(height: 30),
        // Título
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '📖 Ver y Aprender',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 20),
        // Descripción
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Cómo hacer la seña:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                exercise.correctAnswer,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        // Tips
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('💡', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Consejo',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Practica frente a un espejo para ver tu mano desde la perspectiva del observador.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.info,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            exercise.question,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 30),
        // Imagen o Emoji
        Container(
          padding: EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
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
                  style: TextStyle(fontSize: 100),
                ),
        ),
        SizedBox(height: 30),
        // Opciones
        ...exercise.options.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectAnswer = option == exercise.correctAnswer;
          final showAsCorrect = _answerVerified && isCorrectAnswer;
          final showAsWrong = _answerVerified && isSelected && !_isCorrect;

          return Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: _buildOptionButton(
              option,
              isSelected,
              showAsCorrect,
              showAsWrong,
            ),
          );
        }),
        SizedBox(height: 20),
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                exercise.question,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15),
              exercise.imageBase64.isNotEmpty
                  ? MediaDisplay(
                      base64Content: exercise.imageBase64,
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      exercise.imageUrl,
                      style: TextStyle(fontSize: 80),
                    ),
            ],
          ),
        ),
        SizedBox(height: 30),
        // Opciones
        ...exercise.options.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectAnswer = option == exercise.correctAnswer;
          final showAsCorrect = _answerVerified && isCorrectAnswer;
          final showAsWrong = _answerVerified && isSelected && !_isCorrect;

          return Padding(
            padding: EdgeInsets.only(bottom: 15),
            child: _buildDescriptionOption(
              option,
              isSelected,
              showAsCorrect,
              showAsWrong,
            ),
          );
        }),
        SizedBox(height: 20),
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
        padding: EdgeInsets.all(20),
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
        padding: EdgeInsets.all(18),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 20),
                Text(
                  'Cargando gestos...',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.purple.withValues(alpha:0.5)),
              ),
              child: Column(
                children: [
                  Row(
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
                  SizedBox(height: 12),
                  Text(
                    exercise.question,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Gestos seleccionados (vista previa)
            if (_selectedGestures.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Seleccionados:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedGestures.asMap().entries.map((entry) {
                        final index = entry.key;
                        final gesture = entry.value;
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                gesture,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    if (!_answerVerified)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGestures.clear();
                          });
                        },
                        icon: Icon(Icons.refresh, size: 16, color: AppColors.error),
                        label: Text(
                          'Reiniciar selección',
                          style: TextStyle(fontSize: 12, color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ),
            if (_selectedGestures.isNotEmpty) SizedBox(height: 20),

            // Cuadrícula de GIFs - continuado en siguiente parte...
            _buildGestureGrid(exercise, gestureGifs, correctGestures),

            SizedBox(height: 20),

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
          backgroundColor = AppColors.success.withValues(alpha:0.1);
        } else if (showAsWrong) {
          borderColor = AppColors.error;
          backgroundColor = AppColors.error.withValues(alpha:0.1);
        } else if (showAsMissed) {
          borderColor = AppColors.warning;
          backgroundColor = AppColors.warning.withValues(alpha:0.1);
        } else if (isSelected) {
          borderColor = AppColors.primary;
          backgroundColor = AppColors.primary.withValues(alpha:0.1);
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
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: backgroundColor.withValues(alpha:0.9),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: Text(
                        gestureName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
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
                            color: Colors.black.withValues(alpha:0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$selectionOrder',
                          style: TextStyle(
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
                      padding: EdgeInsets.all(4),
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
        // Error silenciado intencionalmente - continuar con otros gestos
      }
    }

    return gifs;
  }

  // Helper para cargar GIFs del alfabeto
  Future<Map<String, String>> _loadAlphabetGifs(List<String> letters) async {
    final Map<String, String> gifs = {};

    for (final letter in letters) {
      try {
        final gif = await LessonData.loadAbecedarioImageByLetter(letter);
        if (gif.isNotEmpty) {
          gifs[letter] = gif;
        }
      } catch (e) {
        // Error silenciado intencionalmente - continuar con otras letras
      }
    }

    return gifs;
  }

  // Método para construir el ejercicio de Armar Palabras (lecciones 69-78)
  Widget _buildWordBuilderExercise(Exercise exercise) {
    return FutureBuilder<Map<String, String>>(
      future: _loadAlphabetGifs(exercise.options),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 20),
                Text(
                  'Cargando alfabeto...',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              'Error cargando alfabeto',
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        final letterGifs = snapshot.data!;
        final targetWord = exercise.correctAnswer;

        return Column(
          children: [
            // Instrucciones y palabra objetivo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.construction, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Arma la palabra',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha:0.5), width: 2),
                    ),
                    child: Text(
                      targetWord,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (exercise.hintText.isNotEmpty)
                    Text(
                      '💡 ${exercise.hintText}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha:0.9),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Letras seleccionadas (vista previa de la palabra que está formando)
            if (_selectedLetters.isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Tu palabra:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedLetters.map((letter) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    if (!_answerVerified)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                if (_selectedLetters.isNotEmpty) {
                                  _selectedLetters.removeLast();
                                }
                              });
                            },
                            icon: Icon(Icons.backspace, size: 16, color: AppColors.warning),
                            label: Text(
                              'Borrar última',
                              style: TextStyle(fontSize: 12, color: AppColors.warning),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedLetters.clear();
                              });
                            },
                            icon: Icon(Icons.refresh, size: 16, color: AppColors.error),
                            label: Text(
                              'Reiniciar',
                              style: TextStyle(fontSize: 12, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (_selectedLetters.isNotEmpty) SizedBox(height: 20),

            // Teclado de alfabeto (cuadrícula de letras)
            _buildAlphabetKeyboard(letterGifs, targetWord),

            SizedBox(height: 20),

            // Feedback
            if (_answerVerified) _buildFeedback(),

            // Hint
            if (_showHint && !_answerVerified) _buildHint(exercise.hintText),
          ],
        );
      },
    );
  }

  // Teclado de alfabeto como cuadrícula
  Widget _buildAlphabetKeyboard(Map<String, String> letterGifs, String targetWord) {
    // Si ya tenemos el orden del teclado guardado, usarlo
    // Si no, generarlo y guardarlo (solo la primera vez para cada ejercicio)
    if (_keyboardLetters.isEmpty) {
      // Obtener solo las letras únicas necesarias para formar la palabra
      final uniqueLetters = targetWord.split('').toSet().toList();
      // Agregar algunas letras adicionales como distracción
      final allLetters = letterGifs.keys.toList()..shuffle();
      _keyboardLetters = [
        ...uniqueLetters,
        ...allLetters.take(10).where((l) => !uniqueLetters.contains(l)),
      ]..shuffle();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: _keyboardLetters.length,
      itemBuilder: (context, index) {
        final letter = _keyboardLetters[index];
        final gifBase64 = letterGifs[letter] ?? '';
        final isInTarget = targetWord.contains(letter);

        Color borderColor = AppColors.border;
        Color backgroundColor = AppColors.cardBackground;

        if (_answerVerified) {
          if (isInTarget) {
            borderColor = AppColors.success;
            backgroundColor = AppColors.success.withValues(alpha:0.1);
          }
        }

        return GestureDetector(
          onTap: _answerVerified
              ? null
              : () {
                  setState(() {
                    _selectedLetters.add(letter);
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: gifBase64.isNotEmpty
                  ? MediaDisplay(
                      base64Content: gifBase64,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
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
          SizedBox(width: 15),
          Expanded(
            child: Text(
              _isCorrect ? '¡Correcto! 🎉' : 'Incorrecto. Inténtalo de nuevo la próxima vez.',
              style: TextStyle(
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡', style: TextStyle(fontSize: 24)),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pista:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  hintText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
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
                icon: Icon(Icons.lightbulb_outline),
                label: Text(_showHint ? 'Ocultar Pista' : 'Ver Pista'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.border : AppColors.borderLight),
                  minimumSize: const Size(0, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          if (canShowHint) SizedBox(width: 15),
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
                style: TextStyle(
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
