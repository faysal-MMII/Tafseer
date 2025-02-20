import 'package:dart_openai/dart_openai.dart';
import 'dart:convert';

class HadithRAGService {
  final String apiKey;

  HadithRAGService({required this.apiKey}) {
    OpenAI.apiKey = apiKey;
  }

  Future<Map<String, dynamic>> generateResponse(
    String query,
    List<Map<String, dynamic>> hadiths,
  ) async {
    try {
      // Step 1: Format Hadith Context
      final hadithContext = hadiths.map((h) {
        final hadithNum = h['hadith_number'];
        String numberStr;
        try {
          if (hadithNum is String) {
            // If it's already a string, try to parse it as JSON
            final Map<String, dynamic> parsed = json.decode(hadithNum);
            numberStr = "${parsed['book']}:${parsed['hadith']}";
          } else if (hadithNum is Map) {
            numberStr = "${hadithNum['book']}:${hadithNum['hadith']}";
          } else {
            numberStr = 'Unknown';
          }
        } catch (e) {
          print('Error parsing hadith_number: $e');
          numberStr = 'Unknown';
        }
        return "Hadith Number $numberStr:\n${h['text']}";
      }).join('\n\n');

      // Step 2: Call OpenAI API
      final response = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                "You are a knowledgeable Islamic scholar providing guidance based on authentic hadiths.",
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                """Question: $query

                Based on these hadiths, provide a clear and practical answer:
                $hadithContext""",
              ),
            ],
          ),
        ],
        temperature: 0.7,
        maxTokens: 350,
      );

      // Step 3: Process Hadiths for Response
      final processedHadiths = hadiths.take(3).map((h) {
        final hadithNumber = h['hadith_number']; // If hadith_number is already a Map, keep it as a Map

        return {
          'text': h['text'] ?? '',
          'hadith_number': hadithNumber, // Don't convert to string, keep as Map or original type
          'grade': h['grade'] ?? '',
          'narrator': h['narrator'] ?? '',
        };
      }).toList();

      return {
        "answer": response.choices.first.message.content?.first?.text ?? '',
        "hadiths": processedHadiths,
      };
    } catch (e) {
      print('Error in HadithRAGService: $e');
      return {
        "answer": "I apologize, but I encountered an error processing your question.",
        "hadiths": [],
      };
    }
  }
}