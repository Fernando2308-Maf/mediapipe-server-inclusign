import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/lesson.dart';
import '../services/auth_service.dart';
import '../services/lesson_service.dart';
import '../utils/colors.dart';
import 'profile_screen.dart';
import 'lesson_screen.dart';
import 'dictionary_screen.dart';
import 'practice_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _lessonService = LessonService();
  UserProfile? _currentUser;
  int _selectedIndex = 0;

  // Lesson data
  int _completedLessonsCount = 0;
  int _totalLessons = 27;
  int _completedNumbersCount = 0;
  int _totalNumbers = 10;
  int _completedGesturesCount = 0;
  int _totalGestures = 21;
  int _completedWordsCount = 0;
  int _totalWords = 10;
  Lesson? _nextLesson;
  bool _loadingLessons = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLessonsData();
  }

  Future<void> _loadUserData() async {
    try {
      // Forzar actualización del perfil desde el backend
      await _authService.refreshUserProfile();

      final user = await _authService.getCurrentUser();
      setState(() => _currentUser = user);

      // Check if new user
      if (await _authService.isNewUser()) {
        await _authService.clearNewUserFlag();
        _showWelcomeTutorial();
      }
    } catch (e) {
      _showAlert('Error', 'No se pudo cargar la información del usuario');
    }
  }

  Future<void> _loadLessonsData() async {
    try {
      final completedAlphabetCount = await _lessonService.getCompletedLessonsCountByCategory('Alphabet');
      final completedNumbersCount = await _lessonService.getCompletedLessonsCountByCategory('Numbers');
      final completedGesturesCount = await _lessonService.getCompletedLessonsCountByCategory('Gestures');
      final completedWordsCount = await _lessonService.getCompletedLessonsCountByCategory('Basic Words');
      final nextLesson = await _lessonService.getNextIncompleteLesson();

      setState(() {
        _completedLessonsCount = completedAlphabetCount;
        _completedNumbersCount = completedNumbersCount;
        _completedGesturesCount = completedGesturesCount;
        _completedWordsCount = completedWordsCount;
        _nextLesson = nextLesson;
        _loadingLessons = false;
      });
    } catch (e) {
      setState(() {
        _loadingLessons = false;
      });
    }
  }

  void _showWelcomeTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          '¡Bienvenido a Inclusign! 🤟',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Estamos emocionados de tenerte aquí.\n\n'
          '📖 Comienza con el alfabeto\n'
          '💪 Completa lecciones para ganar XP\n'
          '🔥 Mantén tu racha diaria\n'
          '⚡ Sube de nivel y desbloquea contenido\n\n'
          '¡Empecemos tu viaje en el lenguaje de señas!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('¡Vamos!', style: TextStyle(color: AppColors.primary)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickActions(),
                    const SizedBox(height: 25),
                    _buildLessonsSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _currentUser?.firstName.isNotEmpty == true
                        ? _currentUser!.firstName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.isGuest == true
                          ? '¡Hola, Invitado!'
                          : '¡Hola, ${_currentUser?.firstName ?? "Usuario"}!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _currentUser?.isGuest == true
                          ? 'Modo Invitado'
                          : 'Nivel ${_currentUser?.level ?? 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Streak
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentUser?.streak ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.streakOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Experience
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentUser?.experience ?? 0}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.experienceGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Meta diaria',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    '${_currentUser?.todayProgress ?? 0}/${_currentUser?.dailyGoal ?? 5}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: _currentUser != null
                      ? (_currentUser!.todayProgress / _currentUser!.dailyGoal).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: AppColors.borderDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚀 Acciones Rápidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildContinueLessonCard(),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildActionCard('💪', 'Practicar', 'Repaso', AppColors.accent)),
          ],
        ),
      ],
    );
  }

  Widget _buildContinueLessonCard() {
    if (_loadingLessons) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    final nextLessonTitle = _nextLesson != null ? _nextLesson!.title : 'Letra A';

    return GestureDetector(
      onTap: () {
        if (_nextLesson != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonScreen(lessonId: _nextLesson!.id),
            ),
          ).then((_) {
            _loadUserData(); // Reload user data to update experience
            _loadLessonsData(); // Reload lessons data
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text('📚', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            const Text(
              'Continuar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              nextLessonTitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String emoji, String title, String subtitle, Color color) {
    return GestureDetector(
      onTap: () {
        if (title == 'Practicar') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PracticeScreen()),
          ).then((_) {
            _loadUserData(); // Reload user data to update experience
          });
        } else {
          _showAlert(
            title,
            'Esta función estará disponible pronto.',
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsSection() {
    final progress = _totalLessons > 0 ? _completedLessonsCount / _totalLessons : 0.0;
    final percentage = (progress * 100).round();
    final progressText = '$_completedLessonsCount de $_totalLessons completadas • $percentage%';

    final numbersProgress = _totalNumbers > 0 ? _completedNumbersCount / _totalNumbers : 0.0;
    final numbersPercentage = (numbersProgress * 100).round();
    final numbersProgressText = '$_completedNumbersCount de $_totalNumbers completadas • $numbersPercentage%';

    final gesturesProgress = _totalGestures > 0 ? _completedGesturesCount / _totalGestures : 0.0;
    final gesturesPercentage = (gesturesProgress * 100).round();
    final gesturesProgressText = '$_completedGesturesCount de $_totalGestures completadas • $gesturesPercentage%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📖 Tu Ruta de Aprendizaje',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _showAllLessons,
          child: _buildLessonCard(
            '🔤',
            'Alfabeto en Señas',
            '$_totalLessons lecciones • Básico',
            progress,
            _loadingLessons ? 'Cargando...' : progressText,
            AppColors.success,
            false,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _completedLessonsCount >= 15 ? _showNumberLessons : null,
          child: _buildLessonCard(
            '🔢',
            'Números en Señas',
            '$_totalNumbers lecciones • Básico',
            _completedLessonsCount >= 15 ? numbersProgress : 0.0,
            _loadingLessons
                ? 'Cargando...'
                : _completedLessonsCount >= 15
                    ? numbersProgressText
                    : 'Completa 15 lecciones del alfabeto ($_completedLessonsCount/15)',
            AppColors.info,
            _completedLessonsCount < 15,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _completedNumbersCount >= 5 ? _showGestureLessons : null,
          child: _buildLessonCard(
            '👋',
            'Gestos Básicos',
            '$_totalGestures lecciones • Intermedio',
            _completedNumbersCount >= 5 ? gesturesProgress : 0.0,
            _loadingLessons
                ? 'Cargando...'
                : _completedNumbersCount >= 5
                    ? gesturesProgressText
                    : 'Completa 5 lecciones de números ($_completedNumbersCount/5)',
            AppColors.accent,
            _completedNumbersCount < 5,
          ),
        ),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _completedGesturesCount >= 10 ? _showWordLessons : null,
          child: _buildLessonCard(
            '💬',
            'Palabras Básicas',
            '10 lecciones • Intermedio',
            _completedWordsCount / _totalWords,
            _completedGesturesCount >= 10
                ? '$_completedWordsCount/$_totalWords completadas'
                : 'Completa 10 lecciones de gestos ($_completedGesturesCount/10)',
            AppColors.purple,
            _completedGesturesCount < 10,
            dimmed: _completedGesturesCount < 10,
          ),
        ),
      ],
    );
  }

  void _showAllLessons() async {
    final lessons = await _lessonService.getAllLessons();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      children: [
                        Text('🔤', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Text(
                          'Alfabeto en Señas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _buildLessonListItem(lesson, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _loadUserData(); // Reload user data to update experience
      _loadLessonsData(); // Reload when modal closes
    });
  }

  void _showNumberLessons() async {
    final lessons = await _lessonService.getAllLessons(category: 'Numbers');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      children: [
                        Text('🔢', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Text(
                          'Números en Señas',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _buildLessonListItem(lesson, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _loadUserData(); // Reload user data to update experience
      _loadLessonsData(); // Reload when modal closes
    });
  }

  void _showGestureLessons() async {
    final lessons = await _lessonService.getAllLessons(category: 'Gestures');

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Row(
                      children: [
                        Text('👋', style: TextStyle(fontSize: 28)),
                        SizedBox(width: 12),
                        Text(
                          'Gestos Básicos',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _buildLessonListItem(lesson, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _loadUserData(); // Reload user data to update experience
      _loadLessonsData(); // Reload when modal closes
    });
  }

  void _showWordLessons() async {
    // Cargar las 10 lecciones de palabras básicas (IDs 59-68)
    final List<Lesson> lessons = [];
    for (int i = 59; i <= 68; i++) {
      final lesson = await _lessonService.getLessonById(i);
      if (lesson != null) {
        lessons.add(lesson);
      }
    }

    if (!mounted) return;

    if (lessons.isEmpty) {
      _showAlert('Error', 'No se pudieron cargar las lecciones de palabras básicas');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Palabras Básicas',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$_completedWordsCount/$_totalWords lecciones completadas',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: lessons.length,
                  itemBuilder: (context, index) {
                    final lesson = lessons[index];
                    return _buildLessonListItem(lesson, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _loadUserData(); // Reload user data to update experience
      _loadLessonsData(); // Reload when modal closes
    });
  }

  Widget _buildAdvancedLessonInfo(Lesson lesson) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: AppColors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                '¡Lección Especial Desbloqueada!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildInfoChip('⏱️', '${lesson.estimatedMinutes} min'),
              _buildInfoChip('⭐', '${lesson.experiencePoints} XP'),
              _buildInfoChip('💡', 'Intermedio'),
              _buildInfoChip('🎯', '10 Situaciones'),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Consejos:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '• Selecciona solo 1 GIF por pregunta\n'
                  '• Lee la situación con atención antes de elegir\n'
                  '• Cada intento te presenta situaciones diferentes',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonListItem(Lesson lesson, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: lesson.isCompleted ? AppColors.success : AppColors.border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: lesson.isCompleted ? AppColors.success : AppColors.primary,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              lesson.imageUrl,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          lesson.isCompleted ? '✓ Completada' : '${lesson.experiencePoints} XP',
          style: TextStyle(
            fontSize: 13,
            color: lesson.isCompleted ? AppColors.success : AppColors.secondary,
          ),
        ),
        trailing: Icon(
          lesson.isCompleted ? Icons.check_circle : Icons.play_circle_outline,
          color: lesson.isCompleted ? AppColors.success : AppColors.primary,
          size: 28,
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close modal
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonScreen(lessonId: lesson.id),
            ),
          ).then((_) {
            _loadUserData(); // Reload user data to update experience
            _loadLessonsData(); // Reload lessons data
          });
        },
      ),
    );
  }

  Widget _buildLessonCard(
    String emoji,
    String title,
    String subtitle,
    double progress,
    String progressText,
    Color color,
    bool locked, {
    bool dimmed = false,
  }) {
    return Opacity(
      opacity: dimmed ? 0.5 : (locked ? 0.7 : 1.0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: locked ? AppColors.borderDark : AppColors.border,
          ),
          boxShadow: locked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(30),
                boxShadow: locked
                    ? []
                    : [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    progressText,
                    style: TextStyle(
                      fontSize: 11,
                      color: locked ? AppColors.experienceGold : color,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              locked ? '🔒' : '▶️',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, '🏠', 'Inicio', true),
          _buildNavItem(1, '📖', 'Diccionario', false),
          _buildNavItem(2, '📊', 'Progreso', false),
          _buildNavItem(3, '👤', 'Perfil', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String emoji, String label, bool selected) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DictionaryScreen()),
          );
        } else if (index == 3) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        } else if (index != 0) {
          _showAlert(
            label,
            'Esta sección estará disponible pronto.',
          );
        }
        setState(() => _selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? AppColors.primary : AppColors.secondary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
