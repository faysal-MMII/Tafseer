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
      print('DEBUG: HadithRAGService called with ${hadiths.length} hadiths for query: $query');
      
      if (hadiths.isEmpty) {
        print('DEBUG: HadithRAGService received empty hadiths list!');
        return {
          "answer": "No relevant hadiths found for this question.",
          "hadiths": [],
        };
      }

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

      print('DEBUG: Formatted hadith context length: ${hadithContext.length}');

      // Step 2: Call OpenAI API
      print('DEBUG: Calling OpenAI API...');
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
        maxTokens: 500,
      );

      final answer = response.choices.first.message.content?.first?.text ?? '';
      print('DEBUG: HadithRAGService OpenAI response length: ${answer.length}');
      print('DEBUG: HadithRAGService OpenAI response preview: ${answer.length > 100 ? answer.substring(0, 100) : answer}...');

      // Step 3: Process Hadiths for Response
      // It limits to the first 3 hadiths for the final response, as in your original code.
      final processedHadiths = hadiths.take(3).map((h) {
        final hadithNumber = h['hadith_number']; 

        return {
          'text': h['text'] ?? '',
          'hadith_number': hadithNumber, 
          'grade': h['grade'] ?? '',
          'narrator': h['narrator'] ?? '',
        };
      }).toList();

      print('DEBUG: Processed ${processedHadiths.length} hadiths for response');

      final result = {
        "answer": answer,
        "hadiths": processedHadiths,
      };

      print('DEBUG: HadithRAGService returning result with answer length: ${answer.length}, hadiths count: ${processedHadiths.length}');
      
      return result;
    } catch (e, stackTrace) {
      print('ERROR in HadithRAGService: $e');
      print('Stack trace: $stackTrace');
      return {
        "answer": "I apologize, but I encountered an error processing your question.",
        "hadiths": [],
      };
    }
  }
}