import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class HadithDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hadith;
  final String searchQuery;

  const HadithDetailScreen({
    Key? key, 
    required this.hadith,
    this.searchQuery = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith ${hadith['number']}', style: AppTextStyles.titleText),
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hadith ${hadith['number']}',
                style: AppTextStyles.titleText.copyWith(fontSize: 20),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hadith['text'] ?? 'No text available',
                  style: AppTextStyles.englishText.copyWith(
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
              ),
              if (searchQuery.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Search: "$searchQuery"',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}