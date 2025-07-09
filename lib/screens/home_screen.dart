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
  int _currentIndex = 2; // Center Ka'aba button
  final TextEditingController _controller = TextEditingController();
  String? currentQuery;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  bool _showResults = false;
  bool _isLoading = false;
  String? _error;
  bool _isExpanded = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _logScreenView();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _fabAnimationController.dispose();
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
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Color(0xFF001333) : Color(0xFFE8F5E8), // Reference background
      extendBody: true,
      body: _buildMainContent(context),
      bottomNavigationBar: _buildBottomNavigation(isDarkMode),
      floatingActionButton: _buildFloatingActionButton(isDarkMode),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
              ? [Color(0xFF001333), Color(0xFF0E2552)]
              : [Color(0xFFE8F5E8), Color(0xFFF0F8F0)], // Reference gradient
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for nav
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and theme toggle
              _buildHeader(themeProvider),
              
              SizedBox(height: 24),
              
              // Islamic Fun Fact Card (Reference Style)
              _buildFunFactCard(isDarkMode),
              
              SizedBox(height: 24),
              
              // Search Box (Reference Style)
              _buildSearchCard(isDarkMode),
              
              SizedBox(height: 24),
              
              // FAQ Section (Reference Style)
              _buildFAQCard(isDarkMode),
              
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

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tafseer',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF28C76F), // Reference green
                ),
              ),
              Text(
                'Islamic Knowledge & Guidance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Color(0xFF28C76F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: Icon(
                      key: ValueKey<bool>(themeProvider.isDarkMode),
                      themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Color(0xFF28C76F),
                    ),
                  ),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFunFactCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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

  Widget _buildSearchCard(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: Color(0xFF28C76F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  color: Color(0xFF28C76F),
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
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
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
                    color: Color(0xFF28C76F),
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

  Widget _buildFAQCard(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: Color(0xFF28C76F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.help_outline,
                  color: Color(0xFF28C76F),
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

  Widget _buildBottomNavigation(bool isDarkMode) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.history, 'History', 0),
          _buildNavItem(FontAwesomeIcons.bookQuran, 'Quran', 1),
          SizedBox(width: 60), // Space for FAB
          _buildNavItem(FontAwesomeIcons.bookOpen, 'Hadith', 3),
          _buildNavItem(Icons.explore, 'Tools', 4),
        ],
      ),
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
              color: isActive ? Color(0xFF28C76F) : Colors.grey[400],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Color(0xFF28C76F) : Colors.grey[400],
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDarkMode) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Orbit buttons
        if (_isExpanded) ...[
          AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Stack(
                children: [
                  // Search button (top)
                  Transform.translate(
                    offset: Offset(0, -80 * _fabAnimation.value),
                    child: _buildOrbitButton(
                      Icons.search,
                      'Search',
                      () {
                        _toggleFAB();
                        // Quick search overlay
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(height: 200, child: Center(child: Text('Quick Search'))),
                        );
                      },
                    ),
                  ),
                  // Dhikr button (bottom left)
                  Transform.translate(
                    offset: Offset(-60 * _fabAnimation.value, 40 * _fabAnimation.value),
                    child: _buildOrbitButton(
                      Icons.favorite,
                      'Dhikr',
                      () {
                        _toggleFAB();
                        // Quick dhikr counter
                      },
                    ),
                  ),
                  // Qibla button (bottom right)
                  Transform.translate(
                    offset: Offset(60 * _fabAnimation.value, 40 * _fabAnimation.value),
                    child: _buildOrbitButton(
                      Icons.explore,
                      'Qibla',
                      () {
                        _toggleFAB();
                        // Quick qibla
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        // Main FAB (Ka'aba)
        FloatingActionButton(
          onPressed: _toggleFAB,
          backgroundColor: Color(0xFF28C76F),
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: Duration(milliseconds: 300),
            child: Text(
              '🕋', // Ka'aba emoji or use custom icon
              style: TextStyle(fontSize: 24),
            ),
          ),
          elevation: 6,
        ),
      ],
    );
  }

  Widget _buildOrbitButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      width: 45,
      height: 45,
      child: FloatingActionButton(
        mini: true,
        onPressed: onTap,
        backgroundColor: Colors.white,
        child: Icon(icon, color: Color(0xFF28C76F), size: 20),
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
        color: Colors.white,
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