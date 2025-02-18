import 'dart:convert';
import 'config_service.dart';
import 'quran_service.dart';
import 'hadith_service.dart';
import '../models/hadith.dart';
import 'rag_services/quran_rag_service.dart';
import 'rag_services/hadith_rag_service.dart';
import 'storage/offline_storage_service.dart';
import '../models/offline_response.dart';
import 'package:dart_openai/dart_openai.dart';

class OpenAiService {
  final String apiKey = ConfigService.openAiApiKey;
  final QuranService quranService;
  final HadithService hadithService;
  final QuranRAGService quranRagService;
  final HadithRAGService hadithRagService;
  final OfflineStorageService _offlineStorage = OfflineStorageService();

  OpenAiService({
    required this.quranService,
    required this.hadithService,
    required this.quranRagService,
    required this.hadithRagService,
  }) {
    OpenAI.apiKey = apiKey;
  }

  Future<Map<String, dynamic>> generateResponse(String query) async {
    try {
      // Check offline storage first
      final offlineResponses =
          await _offlineStorage.searchResponses(query, 'ai_response');
      if (offlineResponses.isNotEmpty) {
        return json.decode(offlineResponses.first.response);
      }

      // Fetch verses and hadiths
      final verses = await quranService.fetchQuranVerses(query);
      final hadiths = await hadithService.searchHadiths(query);

      // Debug: Print hadith details
      print('\n=== DEBUG: INITIAL HADITHS ===');
      for (var h in hadiths) {
        print('Hadith Number Type: ${h.hadithNumber.runtimeType}');
        print('Hadith Number toString: ${h.hadithNumber.toString()}');
        print('Hadith Number toJson: ${h.hadithNumber.toJson()}');
        print('Hadith Number toMap: ${h.hadithNumber.toMap()}');
        print('---');
      }

      // Convert hadiths to maps
      final hadithMaps = hadiths.map((hadith) {
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
      }).toList();

      // Generate responses
      final quranResponse = await _generateQuranResponse(query, verses);
      final hadithResponse =
          await hadithRagService.generateResponse(query, hadithMaps);

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
        'hadith_results': {
          'answer': _extractContent(hadithResponse['answer']),
          'hadiths': _processHadithList(hadithResponse['hadiths']),
        },
      };

      // Save response for offline use
      await _offlineStorage.saveResponse(OfflineResponse(
        query: query,
        response: json.encode(response),
        type: 'ai_response',
        timestamp: DateTime.now(),
        references: [],
      ));

      return response;
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
    if (hadithNumber == null) {
      return json.encode({'book': 0, 'hadith': 0});
    }
    if (hadithNumber is String) return hadithNumber;
    if (hadithNumber is Map) return json.encode(hadithNumber);
    return json.encode({'book': 0, 'hadith': 0});
  }

  Map<String, dynamic> _createDefaultHadithMap() => {
        'text': '',
        'hadith_number': json.encode({'book': 0, 'hadith': 0}),
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
""";

    String quranUserPrompt = """
Question: $query

Relevant Quranic Verses:
${verses.map((v) => "**Verse ${v['reference']}**: ${v['text']}").join('\n')}

Please provide:
1. A direct answer based on these verses
2. How each verse relates to the question
3. Important context and considerations
""";

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
        'verses': verses.map((v) => "${v['text']} (${v['reference']})").toList(),
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