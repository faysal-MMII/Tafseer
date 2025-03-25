import 'package:flutter/material.dart';

class SearchResultWidget extends StatelessWidget {
  final Map<String, dynamic> searchResult;

  const SearchResultWidget({Key? key, required this.searchResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add null checks and default values
    final String question = searchResult['question'] ?? 'No question found';
    final String quranAnswer = searchResult['quran_answer'] ?? 'No Quranic answer found';
    final String hadithAnswer = searchResult['hadith_answer'] ?? 'No Hadith answer found';
    final List<dynamic> verses = searchResult['verses'] ?? [];
    final List<dynamic> hadiths = searchResult['hadiths'] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the question
          Text(
            'Question: $question',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 10),

          // Display the Quranic answer
          Text(
            'Quranic Answer: $quranAnswer',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          // Display related Quranic verses if available
          if (verses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Related Verses:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...verses.map((verse) => Text(verse.toString())).toList(),
          ],

          const SizedBox(height: 10),

          // Display the Hadith answer
          Text(
            'Hadith Answer: $hadithAnswer',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          // Display related Hadiths if available
          if (hadiths.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Related Hadiths:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...hadiths.map((hadith) => Text(hadith.toString())).toList(),
          ],
        ],
      ),
    );
  }
}