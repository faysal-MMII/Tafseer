import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hadith.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/openai_service.dart';
import '../widgets/hadith_section.dart';
import '../widgets/quran_section.dart';
import '../screens/quran_screen.dart';

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
  Map<String, dynamic>? _fullGeneratedResponse;

  bool _streamComplete = false;
  bool _generateComplete = false;

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
    print('[DEBUG] Starting _fetchResults');

    setState(() {
      _isLoading = true;
      _error = null;
      _aiResponse = '';
      _quranVerses = [];
      _hadiths = [];
      _fullGeneratedResponse = null;
      _streamComplete = false;
      _generateComplete = false;
    });

    try {
      print('[DEBUG] About to fetch Quran verses');
      final verses = await widget.openAiService.quranService.fetchQuranVerses(widget.query);
      print('[DEBUG] Verses fetched successfully: ${verses.length}');

      if (!mounted) {
        print('[DEBUG] Widget not mounted after verses fetch');
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
        return "$text ($reference)";
      }).toList();

      setState(() {
        _quranVerses = formattedVerses;
      });

      print('[DEBUG] About to create stream');
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
          print("[DEBUG] Stream onError called with: $error");
          print("[DEBUG] Error type: ${error.runtimeType}");
          setState(() {
            _isLoading = false;
            _isSearching = false;

            if (error is OpenAiServiceException) {
              print("[DEBUG] Caught OpenAiServiceException in stream: ${error.message}");
              _error = error.message;
            } else if (error is SocketException) {
              print("[DEBUG] Caught SocketException in stream");
              _error = 'No internet connection. Please check your network and try again.';
            } else {
              print("[DEBUG] Caught other error in stream: $error");
              _error = 'An unexpected error occurred while streaming.';
            }
          });
        },
        onDone: () {
          print("[DEBUG] Stream completed");
          _streamComplete = true;
          _attemptSave();
        }
      );

      print('[DEBUG] About to call generateResponse');
      widget.openAiService.generateResponse(widget.query).then((response) {
        print('[DEBUG] generateResponse completed successfully');

        if (!mounted) {
          print('[DEBUG] Widget not mounted after generateResponse');
          return;
        }

        _fullGeneratedResponse = response;
        _generateComplete = true;

        final hadithsCount = (response['hadith_results']['hadiths'] as List?)?.length ?? 0;
        print('[DEBUG] Hadiths received: $hadithsCount');

        setState(() {
          if (_aiResponse.length < 50) {
            _aiResponse = response['quran_results']['answer'] ?? '';
          }

          _hadiths = List<Hadith>.from(
            (response['hadith_results']['hadiths'] ?? []).map((h) {
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
          _isLoading = false;
        });

        _attemptSave();

      }).catchError((e) {
        print('[DEBUG] generateResponse catchError called with: $e');
        print('[DEBUG] Error type: ${e.runtimeType}');

        if (!mounted) return;
        setState(() {
          if (e is OpenAiServiceException) {
            print("[DEBUG] Caught OpenAiServiceException in generateResponse: ${e.message}");
            _error = e.message;
          } else if (e is SocketException) {
            print("[DEBUG] Caught SocketException in generateResponse");
            _error = 'No internet connection. Please check your network and try again.';
          } else {
            print("[DEBUG] Caught other error in generateResponse: $e");
            _error = 'An unexpected error occurred. Please try again later.';
          }
          _isLoading = false;
          _isSearching = false;
        });
      }).whenComplete(() {
        _isSearching = false;
        print('[DEBUG] generateResponse completed (finally block)');
      });

    } on OpenAiServiceException catch (e) {
      print('[DEBUG] Main try-catch caught OpenAiServiceException: ${e.message}');
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
        _isSearching = false;
      });
    } on SocketException catch (e) {
      print('[DEBUG] Main try-catch caught SocketException: $e');
      if (!mounted) return;
      setState(() {
        _error = 'No internet connection. Please check your network and try again.';
        _isLoading = false;
        _isSearching = false;
      });
    } catch (e) {
      print('[DEBUG] Main try-catch caught other error: $e');
      print('[DEBUG] Error type: ${e.runtimeType}');
      if (!mounted) return;
      setState(() {
        _error = 'An unexpected error occurred. Please try again later.';
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  void _attemptSave() {
    print("DEBUG: _attemptSave called. Stream complete: $_streamComplete, Generate complete: $_generateComplete");
    if (_streamComplete && _generateComplete && _fullGeneratedResponse != null) {
      print("DEBUG: Conditions met. Calling _saveToHistory.");
      _saveToHistory(_fullGeneratedResponse!);
    }
  }
  
  Future<void> _saveToHistory(Map<String, dynamic> response) async {
    if (widget.firestoreService == null) {
      print('DEBUG: FirestoreService is null, cannot save to history');
      return;
    }
    try {
      // Get the AI explanation about hadiths (this is what you want to see in history)
      final hadithExplanation = response['hadith_results']['answer'] ?? '';
      
      // Save the explanation as a hadith entry, not the raw irrelevant hadiths
      final hadithsToSave = hadithExplanation.isNotEmpty 
        ? [{'text': hadithExplanation}] 
        : <Map<String, dynamic>>[];
      await widget.firestoreService!.saveQA(
        question: widget.query,
        answer: _aiResponse,
        quranVerses: _quranVerses,
        hadiths: hadithsToSave, // Save the AI explanation, not raw hadiths
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Search Results',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: backgroundColor,
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
    final textTheme = Theme.of(context).textTheme;
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
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorContainer();
    }
    
    final mediaQuery = MediaQuery.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: mediaQuery.padding.bottom + 16,
      ),
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
    final textTheme = Theme.of(context).textTheme;
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
                  style: textTheme.titleMedium?.copyWith(
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
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                height: 1.4,
                color: Colors.black87,
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
    final textTheme = Theme.of(context).textTheme;
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
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.red[600],
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