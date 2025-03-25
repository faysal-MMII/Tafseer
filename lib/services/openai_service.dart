import 'dart:async';
import 'dart:convert';
import 'config_service.dart';
import 'quran_service.dart';
import 'hadith_service.dart';
import '../models/hadith.dart';
import 'rag_services/quran_rag_service.dart';
import 'rag_services/hadith_rag_service.dart';
import 'package:dart_openai/dart_openai.dart';

class OpenAiService {
  final String apiKey = ConfigService.openAiApiKey;
  final QuranService quranService;
  final HadithService hadithService;
  final QuranRAGService quranRagService;
  final HadithRAGService hadithRagService;

  OpenAiService({
    required this.quranService,
    required this.hadithService,
    required this.quranRagService,
    required this.hadithRagService,
  }) {
    OpenAI.apiKey = apiKey;
  }

  Future<Map<String, dynamic>> generateResponse(String query) async {
    // Add timeout
    final timeout = Duration(seconds: 30);
    try {
      // Fetch verses and hadiths with timeout
      final results = await Future.wait([
        quranService.fetchQuranVerses(query),
        hadithService.searchHadiths(query),
      ]).timeout(timeout);

      final verses = results[0] as List<Map<String, dynamic>>;
      final hadiths = results[1] as List<Hadith>;

      // Debug: Print hadith details
      print('\n=== DEBUG: INITIAL HADITHS ===');
      for (var h in hadiths) {
        if (h is Hadith) {
          print('Hadith Number Type: ${h.hadithNumber.runtimeType}');
          print('Hadith Number toString: ${h.hadithNumber.toString()}');
          print('Hadith Number toJson: ${h.hadithNumber.toJson()}');
          print('Hadith Number toMap: ${h.hadithNumber.toMap()}');
        } else {
          print('Not a Hadith object: ${h.runtimeType}');
        }
        print('---');
      }

      // Convert hadiths to maps
      final hadithMaps = hadiths.map((hadith) {
        if (hadith is Hadith) {
          var map = {
            'text': hadith.text,
            'hadith_number': hadith.hadithNumber.toJson(),
            'grade': hadith.grade ?? '',
            'narrator': hadith.narrator ?? '',
            'collection_id': hadith.collectionId.toString(),
            'chapter_id': hadith.chapterId.toString(),
          };
          print('\n=== DEBUG: HADITH MAP ===');
          print('hadith_number type: ${map['hadith_number'].runtimeType}');
          print('hadith_number value: ${map['hadith_number']}');
          return map;
        } else {
          // Return a default map if not a Hadith object
          return _createDefaultHadithMap();
        }
      }).toList();

      // Make sure verses is properly typed
      final List<Map<String, dynamic>> typedVerses = verses.map((v) {
        if (v is Map<String, dynamic>) {
          return v;
        } else {
          // Convert to the expected format if needed
          return {
            'reference': v['reference']?.toString() ?? '',
            'text': v['text']?.toString() ?? '',
            // Add other fields as needed
          };
        }
      }).toList();

      // Generate responses
      final quranResponse = await _generateQuranResponse(query, typedVerses);
      final hadithResponse = await generateHadithResponse(query, hadithMaps);

      // Debug: Print hadith response details safely
      print('\n=== DEBUG: HADITH RESPONSE ===');
      print('Response type: ${hadithResponse.runtimeType}');
      print('Hadiths type: ${hadithResponse['hadiths']?.runtimeType}');
      if (hadithResponse['hadiths'] is List &&
          (hadithResponse['hadiths'] as List).isNotEmpty) {
        print('First hadith type: ${hadithResponse['hadiths'][0].runtimeType}');
      } else {
        print('No hadiths found in response');
      }

      // Construct the final response
      final response = {
        'quran_results': quranResponse['quran_results'], // Access the nested 'quran_results'
        'hadith_results': hadithResponse, // Use the hadith response directly
      };

      return response;
    } on TimeoutException {
      print('Request timed out');
      return {
        'quran_results': {'answer': '', 'verses': []},
        'hadith_results': {'answer': 'Request timed out', 'hadiths': []}
      };
    } catch (e, stackTrace) {
      print('\n=== ERROR ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stackTrace');

      // Return a valid response structure even in case of error
      return {
        'quran_results': {'answer': '', 'verses': []},
        'hadith_results': {'answer': 'No results found', 'hadiths': []},
      };
    }
  }

  Future<Map<String, dynamic>> generateHadithResponse(
    String query,
    List<Map<String, dynamic>> hadiths,
  ) async {
    try {
      final hadithResponse = await hadithRagService.generateResponse(query, hadiths);
      
      return {
        'answer': _extractContent(hadithResponse['answer']),
        'hadiths': _processHadithList(hadithResponse['hadiths']),
      };
    } catch (e, stackTrace) {
      print('\n=== ERROR in generateHadithResponse ===');
      print('Error message: $e');
      print('Stack trace: $stackTrace');
      
      return {
        'answer': 'Error processing hadith response',
        'hadiths': [],
      };
    }
  }

  String _extractContent(dynamic answer) {
    if (answer == null) return '';

    if (answer is OpenAIChatCompletionChoiceMessageModel) {
      return answer.content?.firstOrNull?.text ?? '';
    }

    return answer.toString();
  }

  List<Map<String, dynamic>> _processHadithList(dynamic hadiths) {
    if (hadiths == null) return [];

    if (hadiths is! List) {
      print('Warning: hadiths is not a List, type: ${hadiths.runtimeType}');
      return [];
    }

    return hadiths.map((h) {
      if (h == null) return _createDefaultHadithMap();

      try {
        return {
          'text': h['text']?.toString() ?? '',
          'hadith_number': _processHadithNumber(h['hadith_number']),
          'grade': h['grade']?.toString() ?? '',
          'narrator': h['narrator']?.toString() ?? '',
        };
      } catch (e) {
        print('Error processing hadith: $e');
        return _createDefaultHadithMap();
      }
    }).toList();
  }

  String _processHadithNumber(dynamic hadithNumber) {
    try {
      if (hadithNumber == null) {
        return "{'book': 0, 'hadith': 0}";  // Note: Using single quotes
      }
      if (hadithNumber is String) {
        // If it's already in the correct format, return as is
        if (hadithNumber.startsWith("{'book'")) return hadithNumber;
        return hadithNumber;
      }
      if (hadithNumber is Map) {
        return "{'book': ${hadithNumber['book']}, 'hadith': ${hadithNumber['hadith']}}";  // Format with single quotes
      }
      return "{'book': 0, 'hadith': 0}";  // Default with single quotes
    } catch (e) {
      print('Error in _processHadithNumber: $e');
      return "{'book': 0, 'hadith': 0}";  // Default with single quotes
    }
  }

  Map<String, dynamic> _createDefaultHadithMap() => {
        'text': '',
        'hadith_number': "{'book': 0, 'hadith': 0}",
        'grade': '',
        'narrator': '',
      };

  Future<Map<String, dynamic>> _generateQuranResponse(
    String query,
    List<Map<String, dynamic>> verses,
  ) async {
    String quranSystemPrompt = """
You are a knowledgeable Islamic scholar explaining Quranic verses.
1. Provide a direct answer to the question using the verses
2. Explain how each verse relates to the question
3. Provide important context for understanding these verses
Keep explanations clear and focused.
""" ;

    String quranUserPrompt = """
Question: $query

Relevant Quranic Verses:
${verses.map((v) => "**Verse ${v['reference']}**: ${v['text']}").join('\n')}

Please provide:
1. A direct answer based on these verses
2. How each verse relates to the question
3. Important context and considerations
""" ;

    final quranCompletion = await OpenAI.instance.chat.create(
      model: "gpt-3.5-turbo",
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(quranSystemPrompt)],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(quranUserPrompt)],
        ),
      ],
    );

    // Updated return statement with 'quran_results' key
    return {
      'quran_results': {
        'answer': quranCompletion.choices.first.message.content?.firstOrNull?.text ?? '',
        'verses': verses.map((v) {
          // Access translation array if it exists
          String text = '';
          if (v.containsKey('translations') && v['translations'] is List && v['translations'].isNotEmpty) {
            text = v['translations'][0]['text'] ?? '';
          } else {
            text = v['text'] ?? '';
          }
          return "$text (${v['verse_key'] ?? v['reference'] ?? ''})";
        }).toList(),
      }
    };
  }
}

class OpenAiServiceException implements Exception {
  final String message;
  final dynamic originalError;

  OpenAiServiceException(this.message, {this.originalError});

  @override
  String toString() =>
      'OpenAiServiceException: $message\nOriginal: $originalError';
}