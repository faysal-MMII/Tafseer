import 'package:flutter/material.dart';
import '../models/hadith.dart';
import '../theme/text_styles.dart';
import '../widgets/quran_section.dart';
import '../widgets/hadith_section.dart';
import '../services/openai_service.dart';
import 'package:sqflite/sqflite.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;
  final OpenAiService openAiService;
  final Database db;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService; // Keep firestoreService nullable

  SearchResultsScreen({
    required this.query,
    required this.openAiService,
    required this.db,
    this.analyticsService,
    this.firestoreService, // Keep firestoreService nullable in constructor
  });

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _isLoading = true;
  String? _error;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  List<Hadith> _hadiths = [];

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    await widget.analyticsService?.logQuestionAsked(widget.query);
    final startTime = DateTime.now().millisecondsSinceEpoch;

    try {
      // First, check if we have a similar question in Firestore
      final existingQA = await widget.firestoreService?.findSimilarQuestion(widget.query);

      if (existingQA != null) {
        // Use existing answer if found
        setState(() {
          _aiResponse = existingQA['answer'] ?? '';  // Add null check
          _quranVerses = List<String>.from(existingQA['quranVerses'] ?? []); // Add null check
          _hadiths = List<Hadith>.from(
            (existingQA['hadiths'] as List? ?? []).map((h) => Hadith.fromMap({  // Add null check
              'id': 0,
              'collection_id': 0,
              'chapter_id': 0,
              'hadith_number': '',
              'text': h,
              'arabic_text': null,
              'grade': null,
              'narrator': null,
              'keywords': null,
            })),
          );
          _isLoading = false;
        });
      } else {
        // Rest of your code remains the same
        final response = await widget.openAiService.generateResponse(widget.query);

        await widget.firestoreService?.saveQA(
          question: widget.query,
          answer: response['quran_results']['answer'] ?? 'No answer found.',
          quranVerses: List<String>.from(response['quran_results']['verses'] ?? []),
          hadiths: List<String>.from(response['hadith_results']['hadiths'] ?? []),
        );

        setState(() {
          _aiResponse = response['quran_results']['answer'] ?? 'No answer found.';
          _quranVerses = List<String>.from(response['quran_results']['verses'] ?? []);
          _hadiths = List<Hadith>.from(
            (response['hadith_results']['hadiths'] ?? []).map((h) => Hadith.fromMap({
              'id': 0,
              'collection_id': 0,
              'chapter_id': 0,
              'hadith_number': '',
              'text': h,
              'arabic_text': null,
              'grade': null,
              'narrator': null,
              'keywords': null,
            })),
          );
          _isLoading = false;
        });
      }

      await widget.analyticsService?.logAnswerGenerated(
        widget.query,
        DateTime.now().millisecondsSinceEpoch - startTime,
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorContainer();
    }

    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 800,
          margin: EdgeInsets.all(40),
          child: Column(
            children: [
              _buildQueryContainer(),
              SizedBox(height: 20),
              _buildResultsContainer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueryContainer() {
    return Container(
      padding: EdgeInsets.all(20),
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
            style: AppTextStyles.titleText.copyWith(fontSize: 18),
          ),
          SizedBox(height: 10),
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
          db: widget.db,
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