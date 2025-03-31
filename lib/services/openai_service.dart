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
    final timeout = Duration(seconds: 30);
    try {
      final results = await Future.wait([
        quranService.fetchQuranVerses(query),
        hadithService.searchHadiths(query),
      ]).timeout(timeout);

      final verses = results[0] as List<Map<String, dynamic>>;
      final hadiths = results[1] as List<Hadith>;

      // Convert hadiths to maps
      final hadithMaps = hadiths.map((hadith) {
        if (hadith is Hadith) {
          return {
            'text': hadith.text,
            'hadith_number': hadith.hadithNumber.toJson(),
            'grade': hadith.grade ?? '',
            'narrator': hadith.narrator ?? '',
            'collection_id': hadith.collectionId.toString(),
            'chapter_id': hadith.chapterId.toString(),
          };
        } else {
          return _createDefaultHadithMap();
        }
      }).toList();

      // Ensure verses are properly typed
      final List<Map<String, dynamic>> typedVerses = verses.map((v) {
        return {
          'reference': v['reference']?.toString() ?? '',
          'text': v['text']?.toString() ?? '',
        };
      }).toList();

      // Generate responses
      final quranResponse = await _generateQuranResponse(query, typedVerses);
      final hadithResponse = await generateHadithResponse(query, hadithMaps);

      // Construct the final response
      return {
        'quran_results': quranResponse['quran_results'],
        'hadith_results': hadithResponse,
      };
    } on TimeoutException {
      return {
        'quran_results': {'answer': '', 'verses': []},
        'hadith_results': {'answer': 'Request timed out', 'hadiths': []}
      };
    } catch (e, stackTrace) {
      return {
        'quran_results': {'answer': '', 'verses': []},
        'hadith_results': {'answer': 'No results found', 'hadiths': []},
      };
    }
  }

  Future<Stream<String>> streamQuranResponse(String query, List<Map<String, dynamic>> verses) async {
    final quranStream = await OpenAI.instance.chat.createStream(
      model: "gpt-3.5-turbo", // Use the base model without version
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(
            """You are a knowledgeable Islamic scholar explaining Quranic verses.
            1. Provide a direct answer to the question using the verses
            2. Explain how each verse relates to the question
            3. Provide important context for understanding these verses
            Keep explanations clear and focused."""
          )],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(
            """Question: $query
            
            Relevant Quranic Verses:
            ${verses.map((v) => "**Verse ${v['reference']}**: ${v['text']}").join('\n')}
            
            Please provide:
            1. A direct answer based on these verses
            2. How each verse relates to the question
            3. Important context and considerations"""
          )],
        ),
      ],
    );

    return quranStream.transform(
      StreamTransformer.fromHandlers(
        handleData: (response, sink) {
          final content = response.choices.first.delta.content?.firstOrNull?.text ?? '';
          sink.add(content);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> generateHadithResponse(
    String query,
    List<Map<String, dynamic>> hadiths,
  ) async {
    try {
      print("Generating hadith response with ${hadiths.length} hadiths");
      final hadithResponse = await hadithRagService.generateResponse(query, hadiths);
      print("RAW HADITH RESPONSE: $hadithResponse");

      if (hadithResponse['hadiths'] == null) {
        print("WARNING: No hadiths in response");
      } else {
        print("HADITHS IN RESPONSE: ${hadithResponse['hadiths'].runtimeType} with length: ${hadithResponse['hadiths'] is List ? hadithResponse['hadiths'].length : 'not a list'}");
      }

      return {
        'answer': _extractContent(hadithResponse['answer']),
        'hadiths': _processHadithList(hadithResponse['hadiths']),
      };
    } catch (e, stackTrace) {
      print("ERROR in generateHadithResponse: $e");
      print("Stack trace: $stackTrace");
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
        return _createDefaultHadithMap();
      }
    }).toList();
  }

  String _processHadithNumber(dynamic hadithNumber) {
    try {
      if (hadithNumber == null) {
        return "{'book': 0, 'hadith': 0}";  // Default format
      }
      if (hadithNumber is String) {
        return hadithNumber;
      }
      if (hadithNumber is Map) {
        return "{'book': ${hadithNumber['book']}, 'hadith': ${hadithNumber['hadith']}}";  // Format
      }
      return "{'book': 0, 'hadith': 0}";  // Default format
    } catch (e) {
      return "{'book': 0, 'hadith': 0}";  // Default format
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
      model: "gpt-3.5-turbo-16k", // Updated to use the current model without version suffix
      temperature: 0.3,
      maxTokens: 150,
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

    return {
      'quran_results': {
        'answer': quranCompletion.choices.first.message.content?.firstOrNull?.text ?? '',
        'verses': verses.map((v) {
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