import 'package:flutter/material.dart';
import '../theme/text_styles.dart';

class HadithDetailScreen extends StatelessWidget {
  final Map<String, dynamic> hadith;

  const HadithDetailScreen({Key? key, required this.hadith}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hadith ${hadith['number']}', style: AppTextStyles.titleText),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          hadith['text'],
          style: AppTextStyles.englishText.copyWith(
            height: 1.5,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
