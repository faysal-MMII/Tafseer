import 'package:flutter/material.dart';
import '../services/hadith_service.dart';
import '../services/openai_service.dart';
import '../models/hadith.dart';
import '../services/rag_services/hadith_rag_service.dart';
import '../services/rag_services/quran_rag_service.dart';
import '../services/quran_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/text_styles.dart';
import 'package:sqflite/sqflite.dart';
import '../services/firestore_service.dart';

class HadithSection extends StatefulWidget {
  final String? query;
  final List<Hadith> hadiths;
  final Database db;
  final OpenAiService openAiService;
  final FirestoreService? firestoreService;

  HadithSection({
    this.query,
    required this.hadiths,
    required this.db,
    required this.openAiService,
    this.firestoreService,
  });

  @override
  _HadithSectionState createState() => _HadithSectionState();
}

class _HadithSectionState extends State<HadithSection> {
  final QuranService _quranService = QuranService();
  late OpenAiService _openAiService;
  late final HadithService _hadithService;
  final QuranRAGService _quranRagService = QuranRAGService(
    apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
  );
  final HadithRAGService _hadithRagService = HadithRAGService(
    apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
  );

  bool _isLoading = false;
  HadithResponse? _aiResponse;
  String? _error;
  List<Hadith> _retrievedHadiths = [];

  @override
  void initState() {
    super.initState();
    print('=== HadithSection Debug ===');
    print('OpenAI Service: ${widget.openAiService}');
    print('=========================');

    print('Initializing HadithSection with query: ${widget.query}');

    _hadithService = HadithService(widget.db);
    _hadithService.debugDatabase();
    _openAiService = widget.openAiService;

    if (widget.hadiths.isEmpty && widget.query != null && widget.query!.isNotEmpty) {
      print('Starting search for query: ${widget.query}');
      _fetchHadithsAndAiResponse(widget.query!);
    }
  }

  // *** Integrated _fetchHadithsAndAiResponse function ***
  Future<void> _fetchHadithsAndAiResponse(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic>? existingAnswer;
      if (widget.firestoreService != null) {
        existingAnswer = await widget.firestoreService?.findSimilarQuestion(query);
      }

      if (existingAnswer != null) {
        final answer = existingAnswer['answer'] as String?;
        final hadiths = existingAnswer['hadiths'] as List<dynamic>?;

        if (answer != null && hadiths != null) {
          // If hadiths contains full Hadith objects
          if (hadiths.isNotEmpty && hadiths.first is Map<String, dynamic> && hadiths.first.containsKey('text')) {
            setState(() {
              _retrievedHadiths = hadiths
                  .map((h) => Hadith.fromMap(h as Map<String, dynamic>))
                  .toList();
              _isLoading = false;
            });
            return;
          }
        }
      }

      _retrievedHadiths = await searchHadiths(query);

      if (_retrievedHadiths.isEmpty) {
        final response = await _openAiService.generateResponse(query);
        print('Raw response from OpenAI: $response');

        if (response.containsKey('hadith_results')) {
          final hadithResults = response['hadith_results'];
          if (hadithResults != null && hadithResults is Map<String, dynamic>) {
            setState(() {
              _aiResponse = HadithResponse.fromMap(hadithResults);
            });
          } else {
            throw Exception('Invalid hadith_results format: ${hadithResults.runtimeType}');
          }
        } else {
          throw Exception('No hadith_results found in the response');
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error in _fetchHadithsAndAiResponse: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<List<Hadith>> searchHadiths(String userInput) async {
    try {
      return await _hadithService.searchHadiths(userInput);
    } catch (e) {
      print('Search error: $e');
      await _hadithService.validateDatabaseState();
      rethrow;
    }
  }

  Widget _buildHadithItem(Hadith hadith) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hadith ${hadith.hadithNumber ?? "N/A"}',
                style: AppTextStyles.titleText,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(hadith.text, style: AppTextStyles.englishText),
          if (hadith.arabicText != null) ...[
            SizedBox(height: 8),
            Text(
              hadith.arabicText!,
              style: AppTextStyles.arabicText,
              textAlign: TextAlign.right,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _hadithService.database,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorBox(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.query != null && widget.query!.isNotEmpty)
                Text(
                  'Hadiths related to: "${widget.query}"',
                  style: AppTextStyles.titleText.copyWith(fontSize: 18),
                ),
              SizedBox(height: 10),
              if (_retrievedHadiths.isNotEmpty) ...[
                for (var hadith in _retrievedHadiths)
                  _buildHadithItem(hadith),
              ] else ...[
                if (_isLoading) ...[
                  Center(child: CircularProgressIndicator()),
                ] else if (_error != null) ...[
                  _buildErrorBox(),
                ] else if (_aiResponse != null) ...[
                  _buildAiResponse(),
                ] else ...[
                  Text(
                    'No Hadiths found for "${widget.query}".',
                    style: AppTextStyles.englishText.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAiResponse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hadith Section:',
          style: AppTextStyles.titleText.copyWith(fontSize: 18),
        ),
        SizedBox(height: 10),
        Text(
          _aiResponse!.answer ?? 'No answer provided.',
          style: AppTextStyles.englishText,
        ),
        SizedBox(height: 10),
        if (_aiResponse!.hadiths.isNotEmpty) ...[
          Text(
            'Relevant Hadiths:',
            style: AppTextStyles.titleText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 10),
          for (var hadith in _aiResponse!.hadiths)
            Text(
              hadith['text'],
              style: AppTextStyles.englishText,
            ),
        ],
      ],
    );
  }

  Widget _buildErrorBox([String? errorMessage]) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFADBD8),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFE74C3C),
            width: 4,
          ),
        ),
      ),
      child: Text(
        errorMessage ?? 'Error: $_error',
        style: AppTextStyles.englishText.copyWith(color: Color(0xFFC0392B)),
      ),
    );
  }
}