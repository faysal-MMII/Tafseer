import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../services/openai_service.dart';
import '../services/rag_services/quran_rag_service.dart';
import '../services/firestore_service.dart';
import '../services/config_service.dart';
import '../theme/text_styles.dart';
import '../widgets/formatted_text.dart'; 
import 'dart:math';
import '../theme/theme_provider.dart';

String stripHtmlTags(String text) {
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = text.replaceAll(RegExp(r'\s+'), ' ');
  return text.trim();
}

class QuranSection extends StatefulWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final QuranService quranService;
  final QuranRAGService quranRAGService;
  final FirestoreService? firestoreService;
  final Function(String)? onVerseSelected; // Add this parameter
  final bool isDarkMode; // Add this parameter

  const QuranSection({
    super.key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.quranService,
    required this.quranRAGService,
    this.firestoreService,
    this.onVerseSelected,
    this.isDarkMode = false, // Default to light mode
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

  String _cleanContent(String content) {
    return stripHtmlTags(content);
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

    // Get theme from provider
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;
    final accentColor = isDark ? Color(0xFF81B3D2) : Color(0xFF2D5F7C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories,
                  color: accentColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                  ? Color(0xFF252525) 
                  : Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _cleanContent(explanation),
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Color(0xFFE0E0E0) : Color(0xFF424242),
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
            const SizedBox(height: 12),
            ...verses.map((verse) => _buildVerseItem(context, verse, accentColor)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseItem(BuildContext context, String verse, Color accentColor) {
    final isDark = widget.isDarkMode;
    
    // Extract verse reference
    final regExp = RegExp(r'\((.*?)\)$');
    final match = regExp.firstMatch(verse);
    final verseKey = match?.group(1) ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF252525) : Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
            ? Color(0xFF353535) 
            : Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (widget.onVerseSelected != null && verseKey.isNotEmpty) {
            widget.onVerseSelected!(verseKey);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              verse,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Color(0xFFE0E0E0) : Color(0xFF424242),
              ),
            ),
            if (verseKey.isNotEmpty && widget.onVerseSelected != null) ...[
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'View in Quran',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentColor,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.navigate_next,
                    color: accentColor,
                    size: 14,
                  ),
                ],
              ),
            ],
          ],
        ),
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

// This helps bridge between your existing code and the new implementation
class QuranSectionAdapter extends StatelessWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final dynamic openAiService; // Keep this to match existing parameter
  final FirestoreService? firestoreService;
  final Function(String)? onVerseSelected; // Add this parameter
  final bool isDarkMode; // Add this parameter

  const QuranSectionAdapter({
    Key? key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.openAiService,
    this.firestoreService,
    this.onVerseSelected,
    this.isDarkMode = false, // Default to light mode
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Create QuranRAGService instance
    final quranRAGService = QuranRAGService(
      apiKey: ConfigService.openAiApiKey,
    );
    
    // Create QuranService instance
    final quranService = QuranService();
    
    return QuranSection(
      query: query,
      answer: answer,
      verses: verses,
      quranRAGService: quranRAGService,
      quranService: quranService,
      firestoreService: firestoreService,
      onVerseSelected: onVerseSelected,
      isDarkMode: isDarkMode, // Pass the dark mode parameter
    );
  }
}