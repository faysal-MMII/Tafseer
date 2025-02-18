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
      // Prepare context for OpenAI
      final verseContext = verses.map((v) =>
          "Verse ${v['verse_key']}:\n${v['text']}").join('\n\n');

      // Call OpenAI API
      final response = await OpenAI.instance.chat.create(
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
        maxTokens: 350,
      );

      return {
        "answer": response.choices.first.message.content?.first?.text ?? '',
        "verses": verses.take(3).toList(),
      };
    } catch (e) {
      return {
        "answer": "I apologize, but I encountered an error processing your question.",
        "verses": [],
      };
    }
  }
}