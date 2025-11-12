import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SignDetailScreen extends StatelessWidget {
  final String category;
  final Map<String, dynamic> item;

  const SignDetailScreen({
    super.key,
    required this.category,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = item['letter'] ?? item['number']?.toString() ?? item['name'] ?? item['gesture'];
    final description = item['description'] ?? 'Sin descripción disponible';
    final itemEmoji = item['emoji'] ?? '';
    final gifPath = _getGifPath();

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
                  if (itemEmoji.isNotEmpty) ...[
                    Text(
                      itemEmoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      displayText.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
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
                    // GIF Display
                    Container(
                      width: double.infinity,
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: gifPath.isNotEmpty
                              ? Image.asset(
                                  gifPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            itemEmoji,
                                            style: const TextStyle(fontSize: 80),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            'GIF no disponible',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    itemEmoji,
                                    style: const TextStyle(fontSize: 80),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Instructions Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: _getCategoryColor(),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'Cómo se hace',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Practice Tip
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
                                  'Practica frente a un espejo para perfeccionar el gesto',
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

  Color _getCategoryColor() {
    switch (category) {
      case 'alphabet':
        return AppColors.success;
      case 'numbers':
        return AppColors.info;
      case 'gestures':
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  String _getGifPath() {
    switch (category) {
      case 'alphabet':
        final letter = item['letter'];
        return 'assets/gifs/abecedario/$letter.gif';
      case 'numbers':
        // Numbers don't have GIF files, will use emoji instead
        return '';
      case 'gestures':
        final name = (item['gesture'] ?? item['name']) as String;
        final normalizedName = name.toUpperCase().replaceAll(' ', '_');
        return 'assets/gifs/gestos/$normalizedName.gif';
      default:
        return '';
    }
  }
}
