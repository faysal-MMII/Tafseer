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
import '../widgets/formatted_text.dart'; 
import 'dart:math';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

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
  final QuranRAGService quranRAGService;
  final FirestoreService? firestoreService;
  final Function(String)? onVerseSelected;
  final bool isDarkMode;

  const QuranSection({
    super.key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.quranService,
    required this.quranRAGService,
    this.firestoreService,
    this.onVerseSelected,
    this.isDarkMode = false,
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
      final response = await widget.quranRAGService.generateResponse(query, verses);

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

  String _cleanContent(String text) {
    // Remove numbered list format (e.g., "1. ", "2. ")
    return text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final accentColor = isDark ? Color(0xFF1F9881) : Color(0xFF2D5F7C);
    final containerBackgroundColor = isDark ? Color(0xFF0E2552) : Colors.white;
    final contentBackgroundColor = isDark ? Color(0xFF0A1F4C) : Color(0xFFF8F9FA);
    final textColor = isDark ? Color(0xFFE0E0E0) : Color(0xFF424242);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorBox();
    }

    if (widget.answer.isEmpty && widget.verses.isEmpty && _response == null) {
      return Center(
        child: FormattedText(
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.symmetric(vertical: 20),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: containerBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.4) 
              : Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: isDark ? 8 : 10,
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
                'Quranic Evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (explanation.isNotEmpty) ...[
            Text(
              'Answer',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: contentBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _cleanContent(explanation),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ),
          ],

          if (verses.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Relevant Verses',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 15),
            // Using the original approach of rendering just verse references
            Column(
              children: List<Widget>.from(verses.map((verse) {
                // Extract verse reference
                final regExp = RegExp(r'\((.*?)\)$');
                final match = regExp.firstMatch(verse);
                final verseKey = match?.group(1) ?? '';
                
                if (verseKey.isEmpty) return Container();
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: contentBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Color(0xFF1A3366) : Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (widget.onVerseSelected != null) {
                        widget.onVerseSelected!(verseKey);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Verse $verseKey",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Icon(
                          Icons.navigate_next,
                          color: accentColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              })),
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
      child: FormattedText(
        'Error: $_error',
        style: AppTextStyles.englishText.copyWith(color: const Color(0xFFC0392B)),
      ),
    );
  }
}

class QuranSectionAdapter extends StatelessWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final dynamic openAiService;
  final FirestoreService? firestoreService;
  final Function(String)? onVerseSelected;
  final bool isDarkMode;

  const QuranSectionAdapter({
    Key? key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.openAiService,
    this.firestoreService,
    this.onVerseSelected,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final quranRAGService = QuranRAGService(
      apiKey: ConfigService.openAiApiKey,
    );
    
    final quranService = QuranService();
    
    return QuranSection(
      query: query,
      answer: answer,
      verses: verses,
      quranRAGService: quranRAGService,
      quranService: quranService,
      firestoreService: firestoreService,
      onVerseSelected: onVerseSelected,
      isDarkMode: isDarkMode,
    );
  }
}