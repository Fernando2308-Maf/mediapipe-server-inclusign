import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'dictionary_category_screen.dart';

class DictionaryScreen extends StatelessWidget {
  const DictionaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    '📖 Diccionario',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Explora el lenguaje de señas',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildCategoryCard(
                      context,
                      '🔤',
                      'Abecedario',
                      '27 letras (A-Z + Ñ)',
                      'Aprende cada letra del alfabeto en lenguaje de señas',
                      AppColors.success,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DictionaryCategoryScreen(
                              category: 'alphabet',
                              title: 'Abecedario',
                              emoji: '🔤',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryCard(
                      context,
                      '🔢',
                      'Números',
                      '10 números (0-9)',
                      'Aprende los números del 0 al 9 en lenguaje de señas',
                      AppColors.info,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DictionaryCategoryScreen(
                              category: 'numbers',
                              title: 'Números',
                              emoji: '🔢',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryCard(
                      context,
                      '👋',
                      'Gestos',
                      '21 gestos básicos',
                      'Aprende gestos y frases comunes del día a día',
                      AppColors.accent,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DictionaryCategoryScreen(
                              category: 'gestures',
                              title: 'Gestos',
                              emoji: '👋',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Text('💡', style: TextStyle(fontSize: 40)),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Consejo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Practica frente a un espejo para perfeccionar cada gesto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
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

  Widget _buildCategoryCard(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
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
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 35)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.secondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
