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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(25),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 10),
                  if (itemEmoji.isNotEmpty) ...[
                    Text(
                      itemEmoji,
                      style: TextStyle(fontSize: 28),
                    ),
                    SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      displayText.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GIF Display
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
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
                                            style: TextStyle(fontSize: 80),
                                          ),
                                          SizedBox(height: 10),
                                          Text(
                                            'GIF no disponible',
                                            style: TextStyle(
                                              color: Theme.of(context).textTheme.bodySmall?.color,
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
                                    style: TextStyle(fontSize: 80),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    // Instructions Section
                    Container(
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
                              Container(
                                padding: EdgeInsets.all(10),
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
                              SizedBox(width: 15),
                              Text(
                                'Cómo se hace',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Practice Tip
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
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
                                    color: Theme.of(context).textTheme.bodySmall?.color,
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
        String letter = item['letter'];
        // Mapeo especial para la letra Ñ
        if (letter == 'Ñ' || letter == 'ñ') {
          letter = 'ENYE';
        }
        return 'assets/gifs/abecedario/$letter.gif';
      case 'numbers':
        final number = item['number']?.toString() ?? '';
        return number.isNotEmpty ? 'assets/gifs/numeros/$number.gif' : '';
      case 'gestures':
        final name = (item['gesture'] ?? item['name']) as String;
        final normalizedName = name.toUpperCase().replaceAll(' ', '_');
        return 'assets/gifs/gestos/$normalizedName.gif';
      default:
        return '';
    }
  }
}
