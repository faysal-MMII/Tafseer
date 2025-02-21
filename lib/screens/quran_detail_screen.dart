import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class QuranDetailScreen extends StatelessWidget {
  final int surahNumber;
  final String surahName; // Add surahName parameter
  final List<dynamic> verses; // Changed from List<Map<String, dynamic>>

  const QuranDetailScreen({
    Key? key, 
    required this.surahNumber,
    required this.surahName, // Include surahName in the constructor
    required this.verses,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surah $surahNumber: $surahName', style: AppTextStyles.titleText), // Update title to include surahName
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: verses.length,
        itemBuilder: (context, index) {
          final verse = verses[index] as Map<String, dynamic>; // Cast here
          return Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verse ${verse['verse']}',
                  style: AppTextStyles.titleText.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  verse['text'],
                  style: AppTextStyles.englishText.copyWith(
                    height: 1.5,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}