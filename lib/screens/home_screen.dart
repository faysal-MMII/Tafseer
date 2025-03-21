import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/islamic_fun_fact.dart';
import '../widgets/faq_section.dart';
import '../widgets/quran_section.dart';
import '../theme/text_styles.dart';
import 'search_results_screen.dart';
import 'places_screen.dart';
import 'quran_screen.dart';
import 'hadith_screen.dart';
import 'history_screen.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../widgets/shimmer_loading_effect.dart';

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

class HomeScreen extends StatefulWidget {
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;

  HomeScreen({
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _controller = TextEditingController();
  String? currentQuery;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  bool _showResults = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    widget.analyticsService?.logScreenView(
      screenName: 'Home Screen',
      screenClass: 'HomeScreen',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askQuestion(String query) async {
    if (query.isEmpty) return;
    
    // Log the question being asked
    widget.analyticsService?.logQuestionAsked('Home Screen Question');
    widget.analyticsService?.logEvent(
      name: 'search_initiated',
      parameters: {
        'query_length': query.length,
        'query_first_word': query.split(' ').first,
      },
    );
    
    final loadingStartTime = DateTime.now();
    Future.delayed(Duration.zero, () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query,
            openAiService: widget.openAiService,
            analyticsService: widget.analyticsService,
            firestoreService: widget.firestoreService,
          ),
        ),
      );
      final operationDuration = DateTime.now().difference(loadingStartTime);
      
      // Log completion of the search
      widget.analyticsService?.logEvent(
        name: 'search_completed',
        parameters: {
          'query_length': query.length,
          'duration_ms': operationDuration.inMilliseconds,
        },
      );
      
      if (operationDuration < Duration(milliseconds: 500)) {
        await Future.delayed(Duration(milliseconds: 500) - operationDuration);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = widget.firestoreService;
    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0),
      appBar: AppBar(
        toolbarHeight: 70,
        title: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _currentIndex = 0),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, color: Colors.blueGrey[800], size: 20),
                      Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 11,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.analyticsService?.logFeatureUsed('places_screen');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlacesScreen()));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mosque, color: Colors.blueGrey[800], size: 20),
                      Text(
                        'Explore',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 11,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.analyticsService?.logFeatureUsed('quran_screen');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QuranScreen()));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.bookQuran, color: Colors.blueGrey[800], size: 20),
                      Text(
                        'Quran',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 11,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.analyticsService?.logFeatureUsed('hadith_screen');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HadithScreen()));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FontAwesomeIcons.bookOpen, color: Colors.blueGrey[800], size: 20),
                      Text(
                        'Hadith',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 11,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    widget.analyticsService?.logFeatureUsed('history_screen');
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(firestoreService: firestoreService)));
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, color: Colors.blueGrey[800], size: 20),
                      Text(
                        'History',
                        style: TextStyle(
                          color: Colors.blueGrey[800],
                          fontSize: 11,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return ResponsiveLayout(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tafseer',
              style: AppTextStyles.titleText.copyWith(fontSize: 44),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            IslamicFunFact(),
            SizedBox(height: 20),
            _buildQuestionInput(),
            FAQSection(),
            SizedBox(height: 20),
            if (_error != null) ...[
              _buildErrorBox(),
            ] else if (_showResults) ...[
              _buildQuranicEvidenceSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF0F0F0)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD1D1D1),
              offset: Offset(3, 3),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-3, -3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Salam alaykum...Seek answers to your questions here....',
                  contentPadding: EdgeInsets.fromLTRB(16, 16, 8, 8),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.blueGrey.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                style: AppTextStyles.englishText.copyWith(
                  color: Color(0xFF333333),
                  fontSize: 14,
                ),
                minLines: 1,
                maxLines: 6, // Limit to 6 lines to prevent excessive expansion
                textAlignVertical: TextAlignVertical.center,
              ),
            ),
            // Send button centered vertically
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    // Clear text after sending to mimic WhatsApp behavior
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _askQuestion(text);
                      _controller.clear();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      FontAwesomeIcons.magnifyingGlass,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuranicEvidenceSection() {
    return QuranSectionAdapter(
      query: currentQuery,
      answer: _aiResponse,
      verses: _quranVerses,
      openAiService: widget.openAiService,
      firestoreService: widget.firestoreService,
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
