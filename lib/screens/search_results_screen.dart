import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../theme/text_styles.dart';
import '../widgets/quran_section.dart';
import '../widgets/hadith_section.dart';
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/responsive_layout.dart'; // Ensure ResponsiveLayout is imported

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
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0),
      appBar: AppBar(
        title: Text('Search Results', style: AppTextStyles.titleText),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchResults(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
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
            SizedBox(height: isSmallScreen ? 12 : 20),
            _buildResultsContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryContainer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0F0F0)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD1D1D1),
            offset: Offset(5, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Question:',
            style: AppTextStyles.titleText.copyWith(
              fontSize: isSmallScreen ? 16 : 18
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 10),
          Text(
            widget.query,
            style: AppTextStyles.englishText,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuranSection(
          query: widget.query,
          answer: _aiResponse,
          verses: _quranVerses,
          openAiService: widget.openAiService,
          firestoreService: widget.firestoreService,
        ),
        SizedBox(height: 20),
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
          color: Color(0xFFFADBD8),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: Color(0xFFE74C3C),
              width: 4,
            ),
          ),
        ),
        child: Text(
          'Error: $_error',
          style: AppTextStyles.englishText.copyWith(
            color: Color(0xFFC0392B),
          ),
        ),
      ),
    );
  }
}