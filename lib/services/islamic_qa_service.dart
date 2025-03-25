import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:Tafseer/models/hadith.dart'; // Import the Hadith class

class Question {
  final List<String> keywords;
  final String question;
  final QuranResults quranResults;
  final HadithResults hadithResults;

  Question({
    required this.keywords,
    required this.question,
    required this.quranResults,
    required this.hadithResults,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      keywords: json['keywords'] != null 
        ? List<String>.from(json['keywords'].map((k) => k.toString())) 
        : [],
      question: json['question']?.toString() ?? '',
      quranResults: QuranResults.fromJson(json['quran_results'] ?? {}),
      hadithResults: HadithResults.fromJson(json['hadith_results'] ?? {}),
    );
  }
}

class QuranResults {
  final String answer;
  final List<String> verses;

  QuranResults({required this.answer, required this.verses});

  factory QuranResults.fromJson(Map<String, dynamic> json) => QuranResults(
        answer: json['answer']?.toString() ?? '',
        verses: json['verses'] != null 
          ? List<String>.from(json['verses'].map((v) => v.toString())) 
          : [],
      );
}

class HadithResults {
  final String answer;
  final List<Hadith> hadiths;

  HadithResults({
    required this.answer,
    required this.hadiths,
  });

  factory HadithResults.fromJson(Map<String, dynamic> json) => HadithResults(
    answer: json['answer']?.toString() ?? '',
    hadiths: json['hadiths'] != null 
      ? List<Hadith>.from(
          (json['hadiths'] as List).map((h) => Hadith.fromJson(h))
        )
      : [],
  );
}

class IslamicQAService {
  static List<Question>? _qaData;
  static final Map<String, Map<String, dynamic>> _queryCache = {};
  static bool _shouldPrintLoadedData = true; // Flag to control _printLoadedData

  static void _log(String message, {bool isError = false}) {
    print('${isError ? 'ERROR' : 'INFO'}: $message');
  }

  static Future<void> initialize() async {
    if (_qaData == null) {
      try {
        final String jsonContent = await rootBundle.loadString('assets/data/islamic_qa_merged.json');
        final dynamic parsedJson = json.decode(jsonContent);

        _log('Parsed JSON Type: ${parsedJson.runtimeType}');
        
        _qaData = [];

        if (parsedJson is List) {
          for (var category in parsedJson) {
            _log('Processing category: $category');
            
            if (category is Map && category['qa_pairs'] != null) {
              for (var qaGroup in category['qa_pairs']) {
                if (qaGroup is Map && qaGroup['questions'] != null) {
                  _qaData!.addAll(
                    (qaGroup['questions'] as List)
                        .map((q) => Question.fromJson(q as Map<String, dynamic>))
                        .toList(),
                  );
                }
              }
            }
          }
        } else {
          throw FormatException('Unexpected JSON format');
        }

        _log('QA Data loaded: ${_qaData?.length} questions');
        if (_qaData!.isNotEmpty) {
          _log('First entry sample: ${_qaData?[0].question}');
        }

        // Print loaded data only once during initialization
        if (_shouldPrintLoadedData) {
          _printLoadedData();
          _shouldPrintLoadedData = false; // Disable future calls
        }
      } catch (e, stackTrace) {
        _log('CRITICAL ERROR loading QA data: $e', isError: true);
        _log('StackTrace: $stackTrace', isError: true);
        _qaData = [];
      }
    }
  }

  static void _printLoadedData() {
    if (_qaData != null) {
      for (var question in _qaData!) {
        _log('Loaded Question: ${question.question}');
        _log('Qur\'an Answer: ${question.quranResults.answer}');
        _log('Hadith Count: ${question.hadithResults.hadiths.length}');
      }
    } else {
      _log('No data loaded');
    }
  }

  Future<Map<String, dynamic>> processQuery(String query) async {
    try {
      if (_qaData == null) await initialize();

      if (_qaData == null || _qaData!.isEmpty) {
        _log('CRITICAL: QA Data is empty or failed to load', isError: true);
        return {
          'error': 'Failed to load QA data',
          'quran_answer': '',
          'verses': [],
          'hadiths': []
        };
      }

      // Check cache first
      if (_queryCache.containsKey(query)) {
        _log('Returning cached result for query: $query');
        return _queryCache[query]!;
      }

      query = query.toLowerCase().trim();

      Question? bestMatch;
      double bestScore = 0.0;

      for (var item in _qaData!) {
        double score = _calculateMatchScore(item, query);

        if (score > bestScore) {
          bestScore = score;
          bestMatch = item;
        }
      }

      // Only return result if score meets a threshold
      Map<String, dynamic> result;
      if (bestScore > 2.0) {
        result = {
          'question': bestMatch!.question,
          'quran_answer': bestMatch.quranResults.answer,
          'verses': bestMatch.quranResults.verses,
          'hadiths': bestMatch.hadithResults.hadiths.map((h) => h.text).toList(),
        };
      } else {
        _log('No match found above threshold');
        result = {
          'answer': 'No matching information found.',
          'verses': [],
          'hadiths': []
        };
      }

      // Cache the result
      _queryCache[query] = result;

      _log('Final result for query "$query": $result');
      return result;
    } catch (e) {
      _log('Unexpected error in processQuery: $e', isError: true);
      return {
        'error': 'Unexpected error: $e',
        'quran_answer': '',
        'verses': [],
        'hadiths': []
      };
    }
  }

  double _calculateMatchScore(Question item, String query) {
    double score = 0.0;
    String questionText = item.question.toLowerCase();
    List<String> keywords = item.keywords.map((k) => k.toLowerCase()).toList();

    // Exact match
    if (questionText == query) score += 20.0;

    // Partial match
    if (questionText.contains(query)) score += 10.0;

    // Keyword match
    for (String keyword in keywords) {
      if (query == keyword || keyword.contains(query)) {
        score += 8.0;
      }
    }

    // Word matching
    List<String> queryWords = query.split(' ');
    for (String word in queryWords) {
      if (questionText.contains(word)) score += 3.0;
    }

    return score;
  }
}