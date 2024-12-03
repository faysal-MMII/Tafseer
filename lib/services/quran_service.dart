import 'dart:convert';
import 'package:flutter/services.dart';

class QuranService {
  static Map<String, dynamic>? _qaData;
  
  static Future<void> initialize() async {
    if (_qaData == null) {
      try {
        final String jsonContent = await rootBundle.loadString('assets/data/islamic_qa.json');
        _qaData = json.decode(jsonContent);
        print('QA Data loaded successfully');
      } catch (e) {
        print('Error loading QA data: $e');
        throw e;
      }
    }
  }

  Future<Map<String, dynamic>> searchVerses(String query) async {
    if (_qaData == null) await initialize();
    query = query.toLowerCase();
    
    try {
      Map<String, dynamic>? bestMatch;
      int bestScore = 0;
      
      for (var category in _qaData!['qa_pairs']) {
        for (var question in category['questions']) {
          int score = 0;
          
          for (String keyword in question['keywords']) {
            if (query.contains(keyword.toLowerCase())) {
              score += 2;
            }
          }
          
          if (score > bestScore) {
            bestScore = score;
            bestMatch = question['quran_results']; // Changed this line
          }
        }
      }

      if (bestMatch != null) {
        return {'quran_results': bestMatch};
      }

      return {
        'quran_results': {
          'answer': 'I could not find a specific answer to your question.',
          'verses': []
        }
      };

    } catch (e) {
      print('Error in searchVerses: $e');
      return {
        'quran_results': {
          'answer': 'Error processing your query',
          'verses': []
        }
      };
    }
  }
}