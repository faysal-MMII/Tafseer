import 'package:dart_openai/dart_openai.dart';

class QuranRAGService {
  final String apiKey;
  
  QuranRAGService({required this.apiKey}) {
    OpenAI.apiKey = apiKey;
  }

  Future<Map<String, dynamic>> generateResponse(
    String query,
    List<Map<String, dynamic>> verses,
  ) async {
    try {
      final verseContext = verses.map((v) =>
          "Verse ${v['verse_key']}:\n${v['text']}").join('\n\n');
          
      final response = await OpenAI.instance.chat.create(
        // Use a default value if ConfigService isn't available or doesn't have the property
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "You are a knowledgeable Islamic scholar providing interpretations of Quranic verses.",
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """Question: $query
Based on these Quranic verses, provide a comprehensive answer:
$verseContext""",
              ),
            ],
          ),
        ],
        temperature: 0.7,
        maxTokens: 500,
      );

      final formattedVerses = verses.map((v) {
        String translation = '';

        if (v.containsKey('translations') && v['translations'] is List && v['translations'].isNotEmpty) {
          translation = v['translations'][0]['text'] ?? '';
        } else if (v.containsKey('translation')) {
          translation = v['translation'] ?? '';
        } else if (v.containsKey('text')) {
          translation = v['text'] ?? '';
        }

        return "$translation (${v['verse_key']})";
      }).toList();

      return {
        "quran_results": {
          "answer": response.choices.first.message.content?.first?.text ?? '',
          "verses": formattedVerses,
        }
      };
    } catch (e) {
      print('Error in QuranRAGService.generateResponse: $e');
      return {
        "quran_results": {
          "answer": "I apologize, but I encountered an error processing your question.",
          "verses": [],
        }
      };
    }
  }
}