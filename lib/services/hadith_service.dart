import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hadith.dart'; 
import 'hadith_collector_service.dart';
import 'openai_service.dart'; 

// Helper function to debug hadith processing
void debugHadithProcessing(dynamic hadithData, String stage) {
  print('\n==== DEBUG HADITH PROCESSING ($stage) ====');
  if (hadithData is Map) {
    print('Type: Map');
    hadithData.forEach((key, value) {
      print('$key: (${value.runtimeType}) $value');
    });

    // Special check for hadith_number
    if (hadithData.containsKey('hadith_number')) {
      print('HADITH_NUMBER FOCUS: ${hadithData['hadith_number']} (${hadithData['hadith_number'].runtimeType})');
    }
  } else if (hadithData is List) {
    print('Type: List with ${hadithData.length} items');
    if (hadithData.isNotEmpty) {
      print('First item type: ${hadithData.first.runtimeType}');
    }
  } else {
    print('Type: ${hadithData.runtimeType}');
    print('Value: $hadithData');
  }
  print('=============================\n');
}

class HadithService {
  static final HadithService _instance = HadithService._internal();
  static bool _initialized = false;
  static Map<String, dynamic>? _hadithData;
  final HadithCollectorService _collector = HadithCollectorService();
  OpenAiService? _openAiService;  // Change to nullable

  // Update the factory constructor to accept OpenAiService
  factory HadithService({OpenAiService? openAiService}) {
    if (openAiService != null) {
      _instance.openAiService = openAiService; // Set the OpenAiService instance
    }
    return _instance;
  }

  HadithService._internal();

  // Add setter for OpenAiService
  set openAiService(OpenAiService service) {
    _openAiService ??= service;  // Only set if not already set
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
      final results = await _collector.getHadiths(query);

      // Take only first 3 results
      return results.take(3).map((hadith) {
        String text = hadith['text'];

        return Hadith(
          id: 0,
          collectionId: 0,
          chapterId: 0,
          hadithNumber: HadithNumber.fromDynamic(hadith['number']),
          text: text,
          arabicText: hadith['arabic'],
          grade: hadith['grade'], 
          narrator: _extractNarrator(text),
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
      final hadiths = await _collector.getHadiths(query);

      // Prepare hadith context for OpenAI
      final limitedHadiths = hadiths.take(3).map((h) {
        String text = h['text'];

        if (text.length > 500) {
          text = text.substring(0, 497) + "...";
        }

        return {
          'collection': h['collection'],
          'number': h['number'],
          'text': text,
        };
      }).toList();

      // Get explanation from OpenAI
      final explanation = await _generateExplanation(query, limitedHadiths);

      return {
        'answer': explanation,
        'hadiths': limitedHadiths,
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
    // Use the OpenAI service here to generate the explanation
    if (_openAiService == null) {
      throw Exception('OpenAiService is not initialized.');
    }
    final response = await _openAiService!.generateResponse(query); 
    return response['hadith_results']['answer'] ?? 'No explanation available.';
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
}