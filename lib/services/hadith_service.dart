import 'dart:convert';
import 'package:flutter/services.dart';

class HadithService {
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

  Future<Map<String, dynamic>> searchHadiths(String query) async {
    if (_qaData == null) await initialize();
    query = query.toLowerCase();
    
    try {
      Map<String, dynamic>? bestMatch;
      int bestScore = 0;
      
      print('Searching for query: $query');
      
      // Extract important phrases from query
      Set<String> importantPhrases = {
        'pregnant wife',
        'divorce',
        'divorcing',
        'pregnant',
        'irreconcilable differences'
      }.where((phrase) => query.contains(phrase)).toSet();
      
      for (var category in _qaData!['qa_pairs']) {
        for (var question in category['questions']) {
          int score = 0;
          String questionText = question['question'].toString().toLowerCase();
          
          // Check for important phrases
          for (String phrase in importantPhrases) {
            if (questionText.contains(phrase)) {
              score += 6;
              print('Important phrase match found: "$phrase". Score: $score');
            }
          }
          
          // Check keywords with higher weight for marriage/divorce related terms
          for (String keyword in question['keywords']) {
            keyword = keyword.toLowerCase();
            if (['divorce', 'marriage', 'pregnant', 'wife'].contains(keyword) && 
                query.contains(keyword)) {
              score += 5;
              print('Critical keyword match found: "$keyword". Score: $score');
            } else if (query.contains(keyword)) {
              score += 2;
              print('Regular keyword match found: "$keyword". Score: $score');
            }
          }
          
          // Boost score for questions about divorce/marriage
          if (questionText.contains('divorce') || 
              questionText.contains('marriage') ||
              questionText.contains('pregnant')) {
            score += 3;
            print('Topic relevance boost applied. Score: $score');
          }
          
          if (score > bestScore) {
            bestScore = score;
            bestMatch = question;
            print('New best match found! Question: "${question['question']}" Score: $score');
          }
        }
      }

      if (bestMatch != null && bestScore > 5) {  // Increased threshold
        print('Returning match with score: $bestScore');
        return bestMatch;
      }

      print('No match found above threshold');
      return {
        'hadith_results': {
          'answer': 'I could not find specific hadiths for your question.',
          'hadiths': []
        },
        'quran_results': {
          'answer': 'I could not find specific answers to your question.',
          'verses': []
        }
      };

    } catch (e) {
      print('Error in searchHadiths: $e');
      return {
        'hadith_results': {
          'answer': 'Error processing your query',
          'hadiths': []
        },
        'quran_results': {
          'answer': 'Error processing your query',
          'verses': []
        }
      };
    }
  }
}