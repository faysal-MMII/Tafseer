import 'package:flutter/material.dart';
import '../services/quran_service.dart';
import '../services/openai_service.dart';
import '../services/rag_services/quran_rag_service.dart';
import '../services/hadith_service.dart';
import '../services/rag_services/hadith_rag_service.dart';
import '../models/hadith.dart';
import '../services/firestore_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/text_styles.dart';
import 'dart:math';
import '../services/storage/offline_storage_service.dart';
import '../models/offline_response.dart';
import 'dart:convert';

String extractVerseNumbers(String text) {
  final RegExp versePattern = RegExp(r'\((\d+:\d+)\)');
  final matches = versePattern.allMatches(text);
  if (matches.isEmpty) {
    // Try alternate format (2:150)
    final RegExp altPattern = RegExp(r'(\d+:\d+)');
    final altMatches = altPattern.allMatches(text);
    if (altMatches.isEmpty) return '';
    return altMatches.first.group(1) ?? '';
  }
  return matches.first.group(1) ?? '';
}

String stripHtmlTags(String text) {
  // Remove HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Clean up extra whitespace
  text = text.replaceAll(RegExp(r'\s+'), ' ');

  // Decode HTML entities
  text = text.replaceAll('"', '"')
      .replaceAll('&', '&')
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll(' ', ' ');

  return text.trim();
}

RichText buildFormattedText(String text) {
  final RegExp exp = RegExp(r'<em>(.*?)</em>');
  List<TextSpan> spans = [];
  int lastIndex = 0;

  for (Match match in exp.allMatches(text)) {
    // Add text before the <em> tag
    if (match.start > lastIndex) {
      spans.add(TextSpan(
        text: text.substring(lastIndex, match.start),
        style: AppTextStyles.englishText,
      ));
    }

    spans.add(TextSpan(
      text: match.group(1),
      style: AppTextStyles.englishText.copyWith(
        fontStyle: FontStyle.italic,
      ),
    ));

    lastIndex = match.end;
  }

  if (lastIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastIndex),
      style: AppTextStyles.englishText,
    ));
  }

  return RichText(text: TextSpan(children: spans));
}

class QuranSection extends StatefulWidget {
  final String? query;
  final String answer;
  final List<String> verses;
  final OpenAiService openAiService;
  final FirestoreService? firestoreService;

  const QuranSection({
    super.key,
    this.query,
    this.answer = '',
    this.verses = const [],
    required this.openAiService,
    this.firestoreService,
  });

  @override
  State<QuranSection> createState() {
    print('QuranSection createState called');
    return _QuranSectionState();
  }
}

class _QuranSectionState extends State<QuranSection> {
  final QuranService _quranService = QuranService();
  final OfflineStorageService _offlineStorage = OfflineStorageService();
  late OpenAiService _openAiService;

  bool _isLoading = false;
  Map<String, dynamic>? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    print('QuranSection initState called');
    print('Initial Query: ${widget.query}');
    print('Initial Answer: ${widget.answer}');
    print('Initial Verses Length: ${widget.verses.length}');
    print('Initial Verses: ${widget.verses}');

    _openAiService = widget.openAiService;

    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchVerses(widget.query!);
    }
  }

  @override
  void didUpdateWidget(QuranSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != null && widget.query!.isNotEmpty) {
      _searchVerses(widget.query!);
    }
  }

  // In QuranSection, replace the automatic saving with:

  Future<void> _saveForOffline() async {
    if (_response == null && (widget.verses.isEmpty || widget.answer.isEmpty)) {
      return;
    }

    // No setState _isSaving = true; here

    try {
      // Get verses either from response or widget
      final List<Map<String, dynamic>> formattedVerses = [];

      if (_response != null && _response!['quran_results']?['verses'] != null) {
        // Handle verses from response
        for (var verse in _response!['quran_results']['verses']) {
          if (verse is Map<String, dynamic>) {
            formattedVerses.add({
              'verse_key': verse['verse_key'],
              'text': stripHtmlTags(verse['text'].toString()),
              'arabic_text': verse['arabic_text']
            });
          } else {
            formattedVerses.add({
              'verse_key': extractVerseNumbers(verse.toString()),
              'text': stripHtmlTags(verse.toString()),
            });
          }
        }
      } else if (widget.verses.isNotEmpty) {
        // Handle verses from widget
        for (var verse in widget.verses) {
          formattedVerses.add({
            'verse_key': extractVerseNumbers(verse),
            'text': stripHtmlTags(verse),
          });
        }
      }

      // Get the answer either from response or widget
      final String answer = stripHtmlTags(
          _response?['quran_results']?['answer']?.toString() ??
              widget.answer
      );

      // Create offline response
      final offlineResponse = OfflineResponse(
        query: widget.query ?? '',
        response: answer,
        type: 'quran',
        timestamp: DateTime.now(),
        references: formattedVerses,
      );

      await _offlineStorage.saveResponse(offlineResponse);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved for offline use')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: ${e.toString()}')),
        );
      }
    } finally {
      // No setState _isSaving = false; here
    }
  }


  // *** Integrated _searchVerses function with Type Casting and Null Checks ***
  Future<void> _searchVerses(String query) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null; // Clear any previous errors
      });

      Map<String, dynamic>? existingAnswer;
      if (widget.firestoreService != null) {
        existingAnswer = await widget.firestoreService?.findSimilarQuestion(query);
      }

      if (existingAnswer != null) {
        final answer = existingAnswer['answer'] as String?;
        final verses = existingAnswer['quranVerses'] as List<dynamic>?;

        if (answer != null && verses != null) {
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

      final response = await _openAiService.generateResponse(query);

      setState(() {
        _response = response;
        _isLoading = false;
      });

      if (widget.firestoreService != null) {
        await widget.firestoreService?.saveQA(
          question: query,
          answer: response['quran_results']?['answer'] ?? '',
          quranVerses: List<String>.from(response['quran_results']?['verses'] ?? []),
          hadiths: [],
        );
      }

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  // *** End of Integrated _searchVerses function with Type Casting and Null Checks ***


  void _debugPrintState() {
    print('\n=== QuranSection State Debug ===');
    print('_response: $_response');
    if (_response != null) {
      print('quran_results: ${_response!['quran_results']}');
      if (_response!['quran_results'] != null) {
        print('answer: ${_response!['quran_results']['answer']}');
        print('verses: ${_response!['quran_results']['verses']}');
      }
    }
    print('widget.verses length: ${widget.verses.length}');
    print('widget.answer length: ${widget.answer.length}');
    print('Current verses length: ${_response?['quran_results']?['verses']?.length ?? 0}');
    print('Current explanation length: ${_response?['quran_results']?['answer']?.length ?? 0}');
    print('Button visibility condition: ${_response != null || widget.verses.isNotEmpty || widget.answer.isNotEmpty}');
    print('=============================\n');
  }

  // Add this to track when response is updated
  void updateResponse(Map<String, dynamic> newResponse) {
    print('\n=== Updating Response ===');
    print('New response: $newResponse');
    setState(() {
      _response = newResponse;
    });
    _debugPrintState();
  }

  @override
  Widget build(BuildContext context) {
    print('QuranSection build method called');

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

    // Debugging print statements
    print('About to build Row - Condition check:');
    print('_response != null: ${_response != null}');
    print('verses.isNotEmpty: ${verses.isNotEmpty}');
    print('explanation.isNotEmpty: ${explanation.isNotEmpty}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE6E6E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD1D1D1),
            offset: const Offset(5, 5),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          print('Container constraints:');
          print('maxWidth: ${constraints.maxWidth}');
          print('maxHeight: ${constraints.maxHeight}');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quranic Evidence',
                    style: AppTextStyles.titleText.copyWith(fontSize: 24),
                  ),
                  // Removed IconButton here
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
                    style: AppTextStyles.englishText.copyWith(height: 1.6),
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
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0F0F0), Color(0xFFCACACA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFFBEBEBE),
                        offset: Offset(5, 5),
                        blurRadius: 10,
                        spreadRadius: -5,
                      ),
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-5, -5),
                        blurRadius: 10,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: verses.map<Widget>((verse) => Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: buildFormattedText(verse.toString()),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ],
          );
        },
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
        style: AppTextStyles.englishText.copyWith(color: Color(0xFFC0392B)),
      ),
    );
  }
}