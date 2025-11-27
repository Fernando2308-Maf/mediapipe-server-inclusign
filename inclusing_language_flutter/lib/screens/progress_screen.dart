import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/lesson_service.dart';
import '../utils/colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _lessonService = LessonService();
  bool _isLoading = true;

  // Progress data by category
  int _completedAlphabet = 0;
  int _totalAlphabet = 27;
  int _completedNumbers = 0;
  int _totalNumbers = 10;
  int _completedGestures = 0;
  int _totalGestures = 21;
  int _completedBasicWords = 0;
  int _totalBasicWords = 10;
  int _completedWordBuilder = 0;
  int _totalWordBuilder = 10;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    try {
      final alphabetCount = await _lessonService.getCompletedLessonsCountByCategory('Alphabet');
      final numbersCount = await _lessonService.getCompletedLessonsCountByCategory('Numbers');
      final gesturesCount = await _lessonService.getCompletedLessonsCountByCategory('Gestures');
      final basicWordsCount = await _lessonService.getCompletedLessonsCountByCategory('Basic Words');
      final wordBuilderCount = await _lessonService.getCompletedLessonsCountByCategory('Word Builder');

      setState(() {
        _completedAlphabet = alphabetCount;
        _completedNumbers = numbersCount;
        _completedGestures = gesturesCount;
        _completedBasicWords = basicWordsCount;
        _completedWordBuilder = wordBuilderCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando progreso: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: Text(
          'Mi Progreso',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall progress summary
                  _buildOverallSummary(),
                  SizedBox(height: 30),

                  // Alphabet progress
                  _buildCategoryProgress(
                    title: 'Alfabeto',
                    emoji: '🔤',
                    completed: _completedAlphabet,
                    total: _totalAlphabet,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 25),

                  // Numbers progress
                  _buildCategoryProgress(
                    title: 'Números',
                    emoji: '🔢',
                    completed: _completedNumbers,
                    total: _totalNumbers,
                    color: AppColors.success,
                  ),
                  SizedBox(height: 25),

                  // Gestures progress
                  _buildCategoryProgress(
                    title: 'Gestos',
                    emoji: '👋',
                    completed: _completedGestures,
                    total: _totalGestures,
                    color: AppColors.accent,
                  ),
                  SizedBox(height: 25),

                  // Basic Words progress
                  _buildCategoryProgress(
                    title: 'Palabras Básicas',
                    emoji: '💬',
                    completed: _completedBasicWords,
                    total: _totalBasicWords,
                    color: const Color(0xFFFF6B6B),
                  ),
                  SizedBox(height: 25),

                  // Word Builder progress
                  _buildCategoryProgress(
                    title: 'Armar Palabras',
                    emoji: '🔤',
                    completed: _completedWordBuilder,
                    total: _totalWordBuilder,
                    color: AppColors.info,
                  ),
                  SizedBox(height: 30),

                  // Overall pie chart
                  _buildOverallPieChart(),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallSummary() {
    final totalCompleted = _completedAlphabet + _completedNumbers + _completedGestures + _completedBasicWords + _completedWordBuilder;
    final totalLessons = _totalAlphabet + _totalNumbers + _totalGestures + _totalBasicWords + _totalWordBuilder;
    final percentage = totalLessons > 0 ? (totalCompleted / totalLessons * 100).round() : 0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Progreso General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 15),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '$totalCompleted de $totalLessons lecciones completadas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryProgress({
    required String title,
    required String emoji,
    required int completed,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (completed / total * 100).round() : 0;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '$completed de $total completadas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Bar chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: total.toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) {
                          return Text(
                            'Completadas',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                          );
                        } else if (value == 1) {
                          return Text(
                            'Pendientes',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: completed.toDouble(),
                        color: color,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: (total - completed).toDouble(),
                        color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 15),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallPieChart() {
    final totalCompleted = _completedAlphabet + _completedNumbers + _completedGestures + _completedBasicWords + _completedWordBuilder;
    final totalLessons = _totalAlphabet + _totalNumbers + _totalGestures + _totalBasicWords + _totalWordBuilder;
    final pending = totalLessons - totalCompleted;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          SizedBox(height: 25),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: [
                  PieChartSectionData(
                    value: _completedAlphabet.toDouble(),
                    title: '$_completedAlphabet\nAlfabeto',
                    color: AppColors.primary,
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: _completedNumbers.toDouble(),
                    title: '$_completedNumbers\nNúmeros',
                    color: AppColors.success,
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: _completedGestures.toDouble(),
                    title: '$_completedGestures\nGestos',
                    color: AppColors.accent,
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: _completedBasicWords.toDouble(),
                    title: '$_completedBasicWords\nPalabras',
                    color: const Color(0xFFFF6B6B),
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: _completedWordBuilder.toDouble(),
                    title: '$_completedWordBuilder\nArmar',
                    color: AppColors.info,
                    radius: 60,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (pending > 0)
                    PieChartSectionData(
                      value: pending.toDouble(),
                      title: '$pending\nPendientes',
                      color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderDarkLight,
                      radius: 60,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Legend
          Wrap(
            spacing: 15,
            runSpacing: 10,
            children: [
              _buildLegendItem('🔤 Alfabeto', AppColors.primary),
              _buildLegendItem('🔢 Números', AppColors.success),
              _buildLegendItem('👋 Gestos', AppColors.accent),
              _buildLegendItem('💬 Palabras Básicas', const Color(0xFFFF6B6B)),
              _buildLegendItem('🔤 Armar Palabras', AppColors.info),
              if (pending > 0)
                _buildLegendItem('Pendientes', AppColors.borderDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}
