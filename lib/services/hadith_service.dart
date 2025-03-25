import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hadith.dart'; 
import 'hadith_collector_service.dart';
import 'openai_service.dart'; 

class HadithService {
  static final HadithService _instance = HadithService._internal();
  static bool _initialized = false;
  static Map<String, dynamic>? _hadithData;
  final HadithCollectorService _collector = HadithCollectorService();
  OpenAiService? _openAiService;

  factory HadithService({OpenAiService? openAiService}) {
    if (openAiService != null) {
      _instance.openAiService = openAiService;
    }
    return _instance;
  }

  HadithService._internal();

  set openAiService(OpenAiService service) {
    _openAiService ??= service;
  }

  String formatHadithNumber(Map<String, dynamic> map) {
    return "${map['book']}:${map['hadith']}";
  }

  Future<void> loadHadithData() async {
    if (_hadithData != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/nawawi.json');
      _hadithData = json.decode(jsonString);
    } catch (e) {
      print('Error loading Hadith data: $e');
      throw Exception('Failed to load Hadith data');
    }
  }

  String getCollectionName() {
    return _hadithData?['hadiths']['collection'] ?? 'Forty Hadith of Imam Nawawi';
  }

  Future<Hadith> fetchHadith(int number) async {
    await loadHadithData();

    try {
      final hadithList = _hadithData!['hadiths']['hadiths'] as List;
      final hadithData = hadithList.firstWhere(
        (h) => h['hadith'] == number,
        orElse: () => throw Exception('Hadith not found'),
      );

      return Hadith.fromMap({
        'id': hadithData['hadith'],
        'collection_id': 1,
        'chapter_id': 1,
        'hadith_number': formatHadithNumber({'book': 0, 'hadith': hadithData['hadith']}),
        'text': hadithData['text'],
        'arabic_text': null,
        'grade': null,
        'narrator': null,
        'keywords': null,
      });
    } catch (e) {
      print('Error fetching hadith $number: $e');
      throw Exception('Failed to fetch hadith');
    }
  }

  Future<List<Hadith>> searchHadiths(String query) async {
    try {
      print("HadithService: Searching for hadiths with query: '$query'");
      
      // Get results using the collector method
      final results = await _collector.getHadithsWithRelevance(query);
      print("HadithService: Found ${results.length} relevant hadiths");

      for (var hadith in results) {
        print("Hadith score: ${hadith['score']}, Collection: ${hadith['collection']}, Number: ${hadith['number']}");
        print("Text excerpt: ${hadith['text'].substring(0, min(50, hadith['text'].length))}...");
      }

      return results.map((hadith) {
        return Hadith(
          id: 0,
          collectionId: 0,
          chapterId: 0,
          hadithNumber: HadithNumber.fromDynamic(hadith['number']),
          text: hadith['text'],
          arabicText: hadith['arabic'],
          grade: hadith['grade'], 
          narrator: _extractNarrator(hadith['text']),
          keywords: null,
        );
      }).toList();
    } catch (e) {
      print('Error searching hadiths: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> searchHadithsWithExplanation(String query) async {
    try {
      print("HadithService: Searching for hadiths with explanation for query: '$query'");
      
      // Use the collector method
      final hadiths = await _collector.getHadithsWithRelevance(query);
      
      if (hadiths.isEmpty) {
        print("No relevant hadiths found for query: '$query'");
        return {
          'answer': "I couldn't find any relevant hadiths that directly address this topic. Consider rephrasing your question or exploring the Quran section for guidance on this matter.",
          'hadiths': [],
        };
      }

      // Print scores for debugging
      print("Hadith scores: ${hadiths.map((h) => h['score']).toList()}");

      // Prepare compact hadiths for OpenAI to save tokens
      final compactHadiths = hadiths.map((h) {
        final String text = h['text'];
        String trimmedText;
        
        // First, try to extract most relevant part based on query terms
        trimmedText = _extractRelevantSegment(text, query);
        
        // If that doesn't work well, use standard truncation with ellipsis
        if (trimmedText.length > 500) {
          trimmedText = _getExcerpt(text, 500);
        }
        
        return {
          'collection': h['collection'],
          'number': h['number'],
          'text': trimmedText,
          'score': h['score'],
        };
      }).toList();

      print("Sending ${compactHadiths.length} compact hadiths to explanation generator");
      
      // Get explanation from OpenAI with compact hadiths to save tokens
      final explanation = await _generateExplanation(query, compactHadiths);

      // Return full hadiths to the UI
      return {
        'answer': explanation,
        'hadiths': hadiths.map((h) => {
          'collection': h['collection'],
          'number': h['number'],
          'text': h['text'],
          'score': h['score'],
        }).toList(),
      };
    } catch (e) {
      print('Error in searchHadithsWithExplanation: $e');
      return {
        'answer': 'Could not generate explanation at this time.',
        'hadiths': [],
      };
    }
  }

  Future<String> _generateExplanation(String query, List<Map<String, dynamic>> hadiths) async {
    if (_openAiService == null) {
      print("OpenAiService is not initialized.");
      throw Exception('OpenAiService is not initialized.');
    }
    
    if (hadiths.isEmpty) {
      return "No relevant hadiths were found for this question.";
    }
    
    try {
      final hadithTexts = hadiths.map((h) => 
        "- ${h['collection']} ${h['number']}: ${h['text']}").join("\n\n");
      
      final prompt = '''
Query: $query

Relevant Hadiths:
$hadithTexts

Based on these hadiths, please provide a comprehensive answer to the query.
''';

      print("Sending query to OpenAI service");
      final response = await _openAiService!.generateHadithResponse(query, hadiths);
      print("Received response from OpenAI service");
      
      if (response != null && response.containsKey('hadith_results') && response['hadith_results'].containsKey('answer')) {
        String answer = response['hadith_results']['answer'];
        // Make sure we don't return a truncated answer
        if (answer.endsWith('...') || answer.endsWith('…')) {
          answer += " (Note: The full explanation may contain additional details. Please refer to the complete hadith text for more information.)";
        }
        return answer;
      } else {
        print("Invalid response format from OpenAI: $response");
        return "I found some relevant hadiths but couldn't generate a proper explanation. Please check the hadiths listed below.";
      }
    } catch (e) {
      print("Error generating explanation: $e");
      return "An error occurred while generating the explanation. Please check the hadiths listed below for guidance.";
    }
  }

  // Extract a relevant segment of text based on query terms
  String _extractRelevantSegment(String text, String query) {
    final List<String> queryTerms = query.toLowerCase().split(' ')
        .where((term) => term.length > 3)
        .toList();
    
    // If no meaningful terms, return first 500 chars
    if (queryTerms.isEmpty) {
      return _getExcerpt(text, 500);
    }
    
    // Find positions of all query terms in the text
    List<int> positions = [];
    for (String term in queryTerms) {
      int pos = text.toLowerCase().indexOf(term);
      if (pos >= 0) {
        positions.add(pos);
      }
    }
    
    // If no terms found, return first 500 chars
    if (positions.isEmpty) {
      return _getExcerpt(text, 500);
    }
    
    // Find the median position to focus on the most relevant part
    positions.sort();
    int medianPos = positions[positions.length ~/ 2];
    
    // Extract text around the median position
    int startPos = (medianPos - 250) < 0 ? 0 : medianPos - 250;
    int endPos = (startPos + 500) > text.length ? text.length : startPos + 500;
    
    // Adjust to avoid cutting in the middle of words
    while (startPos > 0 && text[startPos] != ' ') {
      startPos--;
    }
    
    while (endPos < text.length - 1 && text[endPos] != ' ') {
      endPos++;
    }
    
    String result = text.substring(startPos, endPos);
    
    // Add ellipsis if we've truncated
    if (startPos > 0) {
      result = "..." + result;
    }
    
    if (endPos < text.length) {
      result = result + "...";
    }
    
    return result;
  }
  
  // Get a clean excerpt of specified length
  String _getExcerpt(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    
    // Find a good breaking point near the maxLength
    int endPos = maxLength;
    while (endPos > maxLength - 20 && endPos < text.length && text[endPos] != ' ' && text[endPos] != '.') {
      endPos++;
    }
    
    // If we found a period, break there
    if (endPos < text.length && text[endPos] == '.') {
      return text.substring(0, endPos + 1);
    }
    
    // Otherwise break at a space
    if (endPos >= text.length || text[endPos] != ' ') {
      endPos = maxLength;
      while (endPos > 0 && text[endPos] != ' ') {
        endPos--;
      }
    }
    
    return text.substring(0, endPos) + "...";
  }

  String _extractNarrator(String text) {
    if (text.startsWith('Narrated ')) {
      final narratorEnd = text.indexOf(':');
      if (narratorEnd != -1) {
        return text.substring(9, narratorEnd).trim();
      }
    }
    return '';
  }
  
  // Helper function for substring length check
  int min(int a, int b) {
    return a < b ? a : b;
  }
}