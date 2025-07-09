import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/prayer_time_service.dart';
import '../services/qibla_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/islamic_fun_fact.dart';
import '../widgets/faq_section.dart';
import '../widgets/quran_section.dart';
import '../theme/text_styles.dart';
import '../theme/theme_provider.dart';
import 'search_results_screen.dart';
import 'quran_screen.dart';
import 'hadith_screen.dart';
import 'history_screen.dart';
import 'islamic_tools_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

class HomeScreen extends StatefulWidget {
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;
  final PrayerTimeService prayerTimeService;
  final QiblaService qiblaService;

  HomeScreen({
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
    required this.prayerTimeService,
    required this.qiblaService,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 2; // Center Ka'aba is active by default
  final TextEditingController _controller = TextEditingController();
  String? currentQuery;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  bool _showResults = false;
  bool _isLoading = false;
  String? _error;
  bool _isExpanded = false;
  bool _isScrolling = false;
  late AnimationController _fabAnimationController;
  late AnimationController _scrollAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _navOpacity;
  final ScrollController _scrollController = ScrollController();

  // Modern blue theme colors - Enhanced for better contrast
  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF); // Better contrast - soothing bluish tint

  @override
  void initState() {
    super.initState();
    _logScreenView();
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    
    _navOpacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _scrollAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 50 && !_isScrolling) {
      setState(() => _isScrolling = true);
      _scrollAnimationController.forward();
    } else if (_scrollController.offset <= 50 && _isScrolling) {
      setState(() => _isScrolling = false);
      _scrollAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabAnimationController.dispose();
    _scrollAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logScreenView() async {
    widget.analyticsService?.logScreenView(
      screenName: 'Home Screen',
      screenClass: 'HomeScreen',
    );
  }

  Future<void> _askQuestion(String query) async {
    if (query.isEmpty) return;

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

  void _toggleFAB() {
    print("FAB toggle called! Current expanded: $_isExpanded"); // Debug
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
    print("New expanded state: $_isExpanded"); // Debug
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: _buildMainContent(context),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [backgroundColor, Color(0xFFEEF7FF)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and theme toggle
              _buildHeader(),
              
              SizedBox(height: 24),
              
              // Islamic Fun Fact Card
              _buildFunFactCard(),
              
              SizedBox(height: 24),
              
              // Search Box
              _buildSearchCard(),
              
              SizedBox(height: 24),
              
              // FAQ Section
              _buildFAQCard(),
              
              SizedBox(height: 20),
              
              if (_error != null) ...[
                _buildErrorBox(),
              ] else if (_showResults) ...[
                _buildQuranicEvidenceSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tafseer',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
              letterSpacing: -1.0,
            ),
          ),
          Text(
            'Islamic Knowledge & Guidance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunFactCard() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 1), // Added border for contrast
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IslamicFunFact(),
      ),
    );
  }

  Widget _buildSearchCard() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Ask Islamic Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFEAF3FB), // Better contrast
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryBlue.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Salam alaykum...Seek answers to your questions here....',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                suffixIcon: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _askQuestion(text);
                        _controller.clear();
                      }
                    },
                  ),
                ),
              ),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  color: primaryBlue,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          FAQSection(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AnimatedBuilder(
      animation: _navOpacity,
      builder: (context, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(_navOpacity.value), // Light blue nav bar
            border: Border(
              top: BorderSide(color: Colors.grey[300]!, width: 1), // Added top border
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(width: 60), // Just space for the FAB - no other icons
          ),
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        _navigateToScreen(index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? primaryBlue : Colors.grey[400],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryBlue : Colors.grey[400],
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return SizedBox(
      width: 240, // Even larger for perfect spacing
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Navigation icons AROUND the Ka'aba button when expanded
          if (_isExpanded) ...[
            // Quran button (top) - Perfectly centered above Ka'aba
            Positioned(
              top: 20,
              left: 90, // (240-60)/2 = 90 for perfect center
              child: Container(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  mini: false,
                  heroTag: "quran_fab",
                  backgroundColor: lightBlue,
                  elevation: 8,
                  onPressed: () {
                    print("Quran button tapped!");
                    _toggleFAB();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => QuranScreen()));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.bookQuran, color: Colors.white, size: 18),
                      SizedBox(height: 2),
                      Text('QURAN', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            // History button (left) - Perfectly aligned left of Ka'aba
            Positioned(
              top: 90, // (240-60)/2 = 90 for perfect vertical center
              left: 20,
              child: Container(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  mini: false,
                  heroTag: "history_fab",
                  backgroundColor: lightBlue,
                  elevation: 8,
                  onPressed: () {
                    print("History button tapped!");
                    _toggleFAB();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(firestoreService: widget.firestoreService)));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: Colors.white, size: 18),
                      SizedBox(height: 2),
                      Text('HISTORY', style: TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            // Hadith button (right) - Perfectly aligned right of Ka'aba
            Positioned(
              top: 90, // Same vertical position as History
              left: 160, // 240-60-20 = 160 for right alignment
              child: Container(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  mini: false,
                  heroTag: "hadith_fab",
                  backgroundColor: lightBlue,
                  elevation: 8,
                  onPressed: () {
                    print("Hadith button tapped!");
                    _toggleFAB();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HadithScreen()));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FontAwesomeIcons.bookOpen, color: Colors.white, size: 18),
                      SizedBox(height: 2),
                      Text('HADITH', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            // Tools button (bottom) - Perfectly centered below Ka'aba
            Positioned(
              top: 160, // 240-60-20 = 160 for bottom alignment
              left: 90, // Same horizontal position as Quran
              child: Container(
                width: 60,
                height: 60,
                child: FloatingActionButton(
                  mini: false,
                  heroTag: "tools_fab",
                  backgroundColor: lightBlue,
                  elevation: 8,
                  onPressed: () {
                    print("Tools button tapped!");
                    _toggleFAB();
                    Navigator.push(context, MaterialPageRoute(builder: (context) => IslamicToolsScreen(
                      prayerTimeService: widget.prayerTimeService,
                      qiblaService: widget.qiblaService,
                      analyticsService: widget.analyticsService,
                    )));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, color: Colors.white, size: 18),
                      SizedBox(height: 2),
                      Text('TOOLS', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Main FAB (Ka'aba) - Dead center of 240x240 container
          Positioned(
            top: 90, // (240-60)/2 = 90
            left: 90, // (240-60)/2 = 90
            child: FloatingActionButton(
              heroTag: "main_fab",
              onPressed: _toggleFAB,
              backgroundColor: primaryBlue,
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0,
                duration: Duration(milliseconds: 300),
                child: Text(
                  '🕋',
                  style: TextStyle(fontSize: 24),
                ),
              ),
              elevation: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitButton(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Container(
      width: 45,
      height: 45,
      child: FloatingActionButton(
        mini: true,
        onPressed: onTap,
        backgroundColor: cardColor,
        child: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        elevation: 4,
      ),
    );
  }

  void _navigateToScreen(int index) {
    switch (index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(firestoreService: widget.firestoreService)));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => QuranScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => HadithScreen()));
        break;
      case 4:
        Navigator.push(context, MaterialPageRoute(builder: (context) => IslamicToolsScreen(
          prayerTimeService: widget.prayerTimeService,
          qiblaService: widget.qiblaService,
          analyticsService: widget.analyticsService,
        )));
        break;
    }
  }

  Widget _buildQuranicEvidenceSection() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: QuranSectionAdapter(
        query: currentQuery,
        answer: _aiResponse,
        verses: _quranVerses,
        openAiService: widget.openAiService,
        firestoreService: widget.firestoreService,
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error: $_error',
              style: TextStyle(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }
}