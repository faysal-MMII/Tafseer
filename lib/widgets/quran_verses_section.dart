import 'package:flutter/material.dart';

class QuranVersesSection extends StatelessWidget {
  final List<String> verses;

  QuranVersesSection({required this.verses});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200], // Light silver background
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Relevant Quranic Verses:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Nastaliq Urdu',
            ),
          ),
          SizedBox(height: 10),
          for (var verse in verses)
            Text(
              verse,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Noto Serif',
              ),
            ),
        ],
      ),
    );
  }
}
