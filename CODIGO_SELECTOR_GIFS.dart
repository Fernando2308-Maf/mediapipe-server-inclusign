// ========================================================================
// CÓDIGO PARA AGREGAR A lesson_screen.dart
// ========================================================================
// Agregar este método después del método _buildMultipleChoiceExercise
// (alrededor de la línea 674)
// ========================================================================

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
                      'Toca los GIFs en orden',
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

          // Cuadrícula de GIFs
          GridView.builder(
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
                            _selectedGestures.remove(gestureName);
                          } else {
                            // Seleccionar
                            _selectedGestures.add(gestureName);
                          }
                          // Actualizar _selectedAnswer para el sistema de verificación
                          _selectedAnswer = _selectedGestures.join(',');
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
                      // GIF
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
                          // Nombre del gesto
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

                      // Número de orden (si está seleccionado)
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

                      // Íconos de verificación
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
          ),
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

// Método helper para cargar los GIFs de los gestos
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

// ========================================================================
// TAMBIÉN NECESITAS MODIFICAR EL MÉTODO _verifyAnswer()
// Busca el método _verifyAnswer() y reemplázalo con este:
// ========================================================================

void _verifyAnswer() {
  final exercise = _currentLesson!.exercises[_currentExerciseIndex];

  // Para lección 59, comparar las listas
  bool correct;
  if (widget.lessonId == 59) {
    final correctGestures = exercise.correctAnswer.split(',');
    final selectedGestures = (_selectedAnswer ?? '').split(',').where((s) => s.isNotEmpty).toList();

    // Verificar que sean exactamente los mismos gestos (sin importar el orden para ejercicio 2 y 3)
    if (exercise.id == 1) {
      // Ejercicio 1: orden importa
      correct = _selectedGestures.join(',') == correctGestures.join(',');
    } else {
      // Ejercicio 2 y 3: solo verificar que contenga todos los gestos correctos
      correct = correctGestures.every((g) => selectedGestures.contains(g)) &&
                selectedGestures.length == correctGestures.length;
    }
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

// ========================================================================
// TAMBIÉN NECESITAS MODIFICAR EL MÉTODO _resetExerciseState()
// Busca _resetExerciseState() y agrega estas líneas al final:
// ========================================================================

void _resetExerciseState() {
  setState(() {
    _selectedAnswer = null;
    _answerVerified = false;
    _isCorrect = false;
    _showHint = false;
    _selectedGestures.clear(); // AGREGAR ESTA LÍNEA
  });
}
