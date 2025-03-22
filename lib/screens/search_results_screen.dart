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
      print('Search already in progress, skipping');
      return;
    }

    _isSearching = true;

    print('=== Performance Tracking ===');
    final startTime = DateTime.now();

    setState(() {
      _isLoading = true;
      _error = null;
      _aiResponse = '';
      _quranVerses = [];
      _hadiths = [];
    });

    try {
      print('Starting API request: ${DateTime.now()}');
      final response = await widget.openAiService.generateResponse(widget.query);
      print('API request completed: ${DateTime.now()}');

      if (!mounted) return;

      setState(() {
        _aiResponse = response['quran_results']['answer'] ?? '';
        _quranVerses = List<String>.from(response['quran_results']['verses'] ?? []);
        _hadiths = List<Hadith>.from(
          (response['hadith_results']['hadiths'] ?? []).map((h) => Hadith.fromMap({
            'id': 0,
            'collection_id': 0,
            'chapter_id': 0,
            'hadith_number': '',
            'text': h['text'] ?? '',
            'arabic_text': h['arabic'] ?? null,
            'grade': h['grade'] ?? null,
            'narrator': h['narrator'] ?? null,
            'keywords': null,
          })),
        );
        _isLoading = false;
      });

      widget.firestoreService?.saveQA(
        question: widget.query,
        answer: response['quran_results']['answer'] ?? '',
        quranVerses: List<String>.from(response['quran_results']['verses'] ?? []),
        hadiths: (response['hadith_results']['hadiths'] as List? ?? []).map((h) => h['text'] as String).toList(),
      ).catchError((e) => print('Firestore save error: $e'));

    } catch (e) {
      print('Error in _fetchResults: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } finally {
      _isSearching = false;
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Search Results', 
          style: theme.appBarTheme.titleTextStyle,
        ), 
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.iconTheme.color,
          ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: () => _fetchResults(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorContainer();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return SingleChildScrollView(
      child: ResponsiveLayout(
        child: Column(
          children: [
            _buildQueryContainer(),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildResultsContainer(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQueryContainer() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDarkMode 
              ? Colors.black26 
              : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode 
                  ? [Color(0xFF1E3A38), Color(0xFF102423)] 
                  : [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'Your Question',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
          ),
          // Question text
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              widget.query,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContainer() {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
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
          isDarkMode: isDarkMode,
        ),
        SizedBox(height: 16),
        HadithSection(
          query: widget.query,
          hadiths: _hadiths,
          openAiService: widget.openAiService,
          firestoreService: widget.firestoreService,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }
  
  Widget _buildErrorContainer() {
    final theme = Theme.of(context);
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Center(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Color(0xFF331111) : Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black26 
                : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isDarkMode ? Colors.redAccent.shade700 : Colors.redAccent.shade100,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: isDarkMode ? Colors.redAccent.shade200 : Colors.redAccent,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Error Occurred',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isDarkMode ? Colors.redAccent.shade200 : Colors.redAccent,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? theme.textTheme.bodyMedium?.color : Colors.red.shade900,
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