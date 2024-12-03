import 'dart:convert';
import 'package:flutter/services.dart';

class IslamicQAService {
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

  Future<Map<String, dynamic>> processQuery(String query) async {
    if (_qaData == null) await initialize();
    query = query.toLowerCase();
    
    Map<String, dynamic>? bestMatch;
    int bestScore = 0;
    
    // Split query into words for better matching
    List<String> queryWords = query.split(' ');
    
    for (var category in _qaData!['qa_pairs']) {
      for (var question in category['questions']) {
        int score = 0;
        
        // Check exact phrase match first
        if (question['question'].toLowerCase().contains(query)) {
          score += 10;  // Highest priority for exact matches
        }
        
        // Check each keyword with more weight for important terms
        for (String keyword in question['keywords']) {
          keyword = keyword.toLowerCase();
          if (query.contains(keyword)) {
            // Give more weight to important keywords
            if (keyword == 'ramadan' || keyword == 'prepare' || 
                keyword == 'fasting' || keyword == 'ready') {
              score += 5;
            } else {
              score += 2;
            }
          }
        }
        
        // Check word by word
        for (String word in queryWords) {
          if (question['question'].toLowerCase().contains(word)) {
            score += 1;
          }
        }
        
        if (score > bestScore) {
          bestScore = score;
          bestMatch = {
            'answer': question['answer'],
            'verses': question['related_verses'] ?? [],
            'hadiths': question['related_hadiths'] ?? []
          };
        }
      }
    }
    
    return bestMatch ?? {
      'answer': 'I apologize, but I could not find a specific answer to your question.',
      'verses': [],
      'hadiths': []
    };
  }
}