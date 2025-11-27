import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../data/lesson_data.dart';
import 'sign_detail_screen.dart';

class DictionaryCategoryScreen extends StatelessWidget {
  final String category;
  final String title;
  final String emoji;

  const DictionaryCategoryScreen({
    super.key,
    required this.category,
    required this.title,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final items = _getItemsForCategory();

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
                    color: Colors.black.withValues(alpha:0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: 10),
                      Text(
                        emoji,
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(width: 60), // Offset for back button
                      Text(
                        '${items.length} elementos disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Grid of items
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildGridItem(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, Map<String, dynamic> item) {
    final displayText = item['letter'] ?? item['number']?.toString() ?? item['name'] ?? item['gesture'];
    final itemEmoji = item['emoji'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SignDetailScreen(
              category: category,
              item: item,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (itemEmoji.isNotEmpty)
              Text(
                itemEmoji,
                style: TextStyle(fontSize: 40),
              )
            else
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getCategoryColor(),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    displayText.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                displayText.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  List<Map<String, dynamic>> _getItemsForCategory() {
    switch (category) {
      case 'alphabet':
        return LessonData.getAlphabetData();
      case 'numbers':
        return LessonData.getNumbersData();
      case 'gestures':
        return LessonData.getGesturesData();
      default:
        return [];
    }
  }
}
