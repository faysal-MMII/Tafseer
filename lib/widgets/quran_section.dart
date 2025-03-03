import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../services/openai_service.dart';
import '../services/rag_services/quran_rag_service.dart';
import '../services/hadith_service.dart';
import '../services/config_service.dart';
import '../services/rag_services/hadith_rag_service.dart';
import '../models/hadith.dart';
import '../services/firestore_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/text_styles.dart';
import 'dart:math';
import 'dart:convert';

String stripHtmlTags(String text) {
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  text = text.replaceAll('"', '"')
      .replaceAll('&', '&')
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll(' ', ' ');
  return text.trim();
}

class QuranSection extends StatefulWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final QuranService quranService;
  final QuranRAGService quranRAGService; // FIXED: Consistent capitalization
  final FirestoreService? firestoreService;

  const QuranSection({
    super.key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.quranService,
    required this.quranRAGService, // FIXED: Consistent capitalization
    this.firestoreService,
  });

  @override
  State<QuranSection> createState() => _QuranSectionState();
}

class _QuranSectionState extends State<QuranSection> {
  bool _isLoading = false;
  Map<String, dynamic>? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('QuranSection initState called');
    print('Initial Query: ${widget.query}');

    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchVerses(widget.query!);
    }
  }

  @override
  void didUpdateWidget(QuranSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != null && widget.query!.isNotEmpty) {
      _searchVerses(widget.query!);
    }
  }

  Future<void> _searchVerses(String query) async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if we have a cached answer in Firestore
      Map<String, dynamic>? existingAnswer;
      if (mounted && widget.firestoreService != null) {
        existingAnswer = await widget.firestoreService?.findSimilarQuestion(query);
      }

      if (!mounted) return;

      if (existingAnswer != null) {
        final answer = existingAnswer['answer'] as String?;
        final verses = existingAnswer['quranVerses'] as List<dynamic>?;

        if (mounted && answer != null && verses != null) {
          setState(() {
            _response = {
              'quran_results': {
                'answer': answer,
                'verses': verses,
              }
            };
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;

      // Step 1: Fetch verses using the existing QuranService
      final verses = await widget.quranService.fetchQuranVerses(query);
      
      if (!mounted) return;
      
      if (verses.isEmpty) {
        setState(() {
          _response = {
            'quran_results': {
              'answer': 'No relevant Quranic verses found for your question.',
              'verses': [],
            }
          };
          _isLoading = false;
        });
        return;
      }

      // Step 2: Generate the response using QuranRAGService
      final response = await widget.quranRAGService.generateResponse(query, verses); // FIXED: Consistent capitalization

      if (!mounted) return;
      
      setState(() {
        _response = response;
        _isLoading = false;
      });

      // Cache the response in Firestore if available
      if (widget.firestoreService != null) {
        await widget.firestoreService?.saveQA(
          question: query,
          answer: response['quran_results']?['answer'] ?? '',
          quranVerses: List<String>.from(response['quran_results']?['verses'] ?? []),
          hadiths: [],
        );
      }

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorBox();
    }

    if (widget.answer.isEmpty && widget.verses.isEmpty && _response == null) {
      return Center(
        child: Text(
          'No Qur\'anic evidence found',
          style: AppTextStyles.englishText.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }

    final explanation = widget.answer.isNotEmpty
        ? widget.answer
        : _response?['quran_results']?['answer'] ?? '';
    final verses = widget.verses.isNotEmpty
        ? widget.verses
        : _response?['quran_results']?['verses'] ?? [];

    // Debug print statements
    print('DEBUG - explanation length: ${explanation.length}');
    print('DEBUG - verses length: ${verses.length}');
    print('DEBUG - first verse: ${verses.isNotEmpty ? verses.first : "N/A"}');
    // FIXED: Explicitly specify int type for min function
    print('DEBUG - explanation content: ${explanation.substring(0, min<int>(50, explanation.length))}...');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.symmetric(vertical: 20),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0xFFD1D1D1),
            offset: Offset(5, 5),
            blurRadius: 10,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quranic Evidence',
                style: AppTextStyles.titleText.copyWith(fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (explanation.isNotEmpty) ...[
            Text(
              'Answer',
              style: AppTextStyles.titleText.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                explanation,
                style: AppTextStyles.englishText,
              ),
            ),
          ],

          if (verses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Relevant Verses',
              style: AppTextStyles.titleText.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFBEBEBE),
                    offset: Offset(20, 20),
                    blurRadius: 60,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(-20, -20),
                    blurRadius: 60,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: verses.map<Widget>((verse) {
                  // Extract verse reference from the format "text (reference)"
                  final regExp = RegExp(r'\((.*?)\)$');
                  final match = regExp.firstMatch(verse);
                  final verseKey = match?.group(1) ?? '';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Verse $verseKey',
                      style: AppTextStyles.englishText.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBox() {
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
        'Error: $_error',
        style: AppTextStyles.englishText.copyWith(color: const Color(0xFFC0392B)),
      ),
    );
  }
}

// This helps bridge between your existing code and the new implementation
class QuranSectionAdapter extends StatelessWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final dynamic openAiService; // Keep this to match existing parameter
  final FirestoreService? firestoreService;

  const QuranSectionAdapter({
    Key? key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.openAiService,
    this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create QuranRAGService instance
    final quranRAGService = QuranRAGService( // FIXED: Consistent capitalization
      apiKey: ConfigService.openAiApiKey,
    );
    
    // Create QuranService instance
    final quranService = QuranService();
    
    return QuranSection(
      query: query,
      answer: answer,
      verses: verses,
      quranRAGService: quranRAGService, // FIXED: Consistent capitalization
      quranService: quranService,
      firestoreService: firestoreService,
    );
  }
}