import 'dart:async';
import 'dart:math'; 
import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../theme/text_styles.dart';
import '../widgets/quran_section.dart';
import '../widgets/hadith_section.dart';
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/responsive_layout.dart'; 
import '../screens/quran_screen.dart';
import '../screens/quran_detail_screen.dart'; 
import '../data/surah_data.dart';
import '../widgets/formatted_text.dart';
import '../theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;

  SearchResultsScreen({
    required this.query,
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
  });

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  bool _isInitialized = false;
  String? _error;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  List<Hadith> _hadiths = [];
  bool _isSearching = false;
  StreamSubscription? _openAISubscription;

  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _isInitialized = true;
      Future.microtask(() => _fetchResults());
    }
  }

  Future<void> _fetchResults() async {
    if (_isSearching) {
      print('[DEBUG] Search already in progress, skipping');
      return;
    }

    _isSearching = true;
    print('[PERF] === Performance Tracking Started ===');
    final startTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _error = null;
      _aiResponse = '';
      _quranVerses = [];
      _hadiths = [];
    });

    try {
      print('[PERF] Starting data fetch: ${DateTime.now()}');
      final verses = await widget.openAiService.quranService.fetchQuranVerses(widget.query);
      print('[DEBUG] Verses count: ${verses.length}');

      if (!mounted) {
        print('[DEBUG] Widget not mounted after data fetch');
        return;
      }

      final formattedVerses = verses.map((v) {
        String text = '';
        if (v.containsKey('translations') && v['translations'] is List && v['translations'].isNotEmpty) {
          text = v['translations'][0]['text'] ?? '';
        } else {
          text = v['text'] ?? '';
        }
        String reference = v['verse_key'] ?? v['reference'] ?? '';
        print('[DEBUG] Formatted verse: $reference');
        return "$text ($reference)";
      }).toList();

      print('[DEBUG] Updating UI with ${formattedVerses.length} verses');
      setState(() {
        _quranVerses = formattedVerses;
        print('[DEBUG] _quranVerses length after update: ${_quranVerses.length}');
      });

      final stream = await widget.openAiService.streamQuranResponse(widget.query, verses);
      String accumulatedResponse = '';

      _openAISubscription = stream.listen(
        (chunk) {
          accumulatedResponse += chunk;
          setState(() {
            _aiResponse = accumulatedResponse;
            _isLoading = false;
          });
        },
        onError: (error) {
          print("[ERROR] OpenAI Stream error: $error");
        },
        onDone: () {
          print("[PERF] Streaming completed at: ${DateTime.now()}");
          print("[DEBUG] Final streaming response length: ${accumulatedResponse.length}");
        }
      );

      print('[PERF] Starting full generateResponse call: ${DateTime.now()}');
      widget.openAiService.generateResponse(widget.query).then((response) {
        print('[PERF] Full response completed: ${DateTime.now()}');

        if (!mounted) {
          print('[DEBUG] Widget not mounted after full response');
          return;
        }

        final hadithsCount = (response['hadith_results']['hadiths'] as List?)?.length ?? 0;
        print('[DEBUG] Hadiths received: $hadithsCount');

        setState(() {
          if (_aiResponse.length < 50) {
            print('[DEBUG] Using full response for _aiResponse as streaming response was insufficient');
            _aiResponse = response['quran_results']['answer'] ?? '';
          }

          _hadiths = List<Hadith>.from(
            (response['hadith_results']['hadiths'] ?? []).map((h) {
              print('[DEBUG] Processing hadith: ${h['text'].toString().substring(0, min(20, h['text'].toString().length))}...');
              return Hadith.fromMap({
                'id': 0,
                'collection_id': 0,
                'chapter_id': 0,
                'hadith_number': '',
                'text': h['text'] ?? '',
                'arabic_text': h['arabic'] ?? null,
                'grade': h['grade'] ?? null,
                'narrator': h['narrator'] ?? null,
                'keywords': null,
              });
            }),
          );
          print('[DEBUG] _hadiths length after update: ${_hadiths.length}');
          _isLoading = false;
        });

        _saveToHistory();

        print('[PERF] Total response time: ${DateTime.now().difference(startTime).inMilliseconds}ms');
      }).catchError((e) {
        print('[ERROR] Error in generateResponse: $e');
      }).whenComplete(() {
        _isSearching = false;
        print('[DEBUG] Search completed, _isSearching set to false');
      });

    } catch (e) {
      print('[ERROR] Error in _fetchResults: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _saveToHistory() async {
    if (widget.firestoreService == null) {
      print('DEBUG: FirestoreService is null, cannot save to history');
      return;
    }
    try {
      print('DEBUG: About to save QA - Question: ${widget.query}');
      print('DEBUG: Answer length: ${_aiResponse.length}');
      print('DEBUG: Verses count: ${_quranVerses.length}');
      print('DEBUG: Hadiths count: ${_hadiths.length}');
      final hadithsForSaving = _hadiths.map((hadith) => {
        'text': hadith.text,
        'arabic': hadith.arabicText,
        'grade': hadith.grade,
        'narrator': hadith.narrator,
      }).toList();
      await widget.firestoreService!.saveQA(
        question: widget.query,
        answer: _aiResponse,
        quranVerses: _quranVerses,
        hadiths: hadithsForSaving,
      );
      print('DEBUG: saveQA completed successfully');
    } catch (e, stackTrace) {
      print('ERROR saving QA to history: $e');
      print('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _openAISubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundColor,
        title: Text(
          'Search Results', 
          style: TextStyle(color: Colors.black87),
        ), 
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () => _fetchResults(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            ),
            SizedBox(height: 16),
            Text(
              'Searching for answers...',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorContainer();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildQueryContainer(),
          SizedBox(height: 16),
          _buildResultsContainer(),
        ],
      ),
    );
  }
  
  Widget _buildQueryContainer() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.15),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryBlue, lightBlue],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Your Question',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              widget.query,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranSectionAdapter(
          query: widget.query,
          answer: _aiResponse,
          verses: _quranVerses,
          openAiService: widget.openAiService,
          firestoreService: widget.firestoreService,
          onVerseSelected: _navigateToVerse,
        ),
        SizedBox(height: 16),
        HadithSection(
          query: widget.query,
          hadiths: _hadiths,
          openAiService: widget.openAiService,
          firestoreService: widget.firestoreService,
        ),
      ],
    );
  }
  
  Widget _buildErrorContainer() {
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[600],
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error Occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _navigateToVerse(String reference) {
    final regex = RegExp(r'(\d+):(\d+)');
    final match = regex.firstMatch(reference);

    if (match != null && match.groupCount >= 2) {
      final surahNumber = int.tryParse(match.group(1)!);
      final verseNumber = int.tryParse(match.group(2)!);

      if (surahNumber != null && verseNumber != null) {
        print('Navigating to Surah $surahNumber, Verse $verseNumber');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuranScreen(
              initialSurah: surahNumber,
              initialVerse: verseNumber,
            ),
          ),
        );
      }
    } else {
      print('Could not parse verse reference: $reference');
    }
  }
}