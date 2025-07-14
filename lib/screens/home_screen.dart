import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/openai_service.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/prayer_time_service.dart';
import '../services/qibla_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/islamic_fun_fact.dart';
import '../widgets/faq_section.dart';
import '../widgets/quran_section.dart';
import '../widgets/animations.dart';
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
  int _currentIndex = 2;
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
  late AnimationController _overlayAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _navOpacity;
  late Animation<double> _overlayAnimation;
  final ScrollController _scrollController = ScrollController();

  static const Color primaryBlue = Color(0xFF4A90E2);
  static const Color lightBlue = Color(0xFF81B3D2);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Color(0xFFF0F7FF);
  static const Color softAccent = Color(0xFFA4D4F5);

  @override
  void initState() {
    super.initState();
    _logScreenView();
    
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _scrollAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _overlayAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOutBack),
    );
    
    _navOpacity = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _scrollAnimationController, curve: Curves.easeInOut),
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _overlayAnimationController, curve: Curves.easeInOut),
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
    _overlayAnimationController.dispose();
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
        SlidePageRoute(
          child: SearchResultsScreen(
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
    });
  }

  void _toggleFAB() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _fabAnimationController.forward();
      _overlayAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
      _overlayAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          _buildMainContent(context),
          // Grey overlay when FAB is expanded
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              return _overlayAnimation.value > 0
                  ? GestureDetector(
                      onTap: _toggleFAB,
                      child: Container(
                        color: Colors.black.withOpacity(_overlayAnimation.value),
                        child: SizedBox.expand(),
                      ),
                    )
                  : SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredAnimationWrapper(
                delay: 100,
                child: _buildHeader(),
              ),
              
              SizedBox(height: 24),
              
              StaggeredAnimationWrapper(
                delay: 200,
                child: IslamicFunFact(),
              ),
              
              SizedBox(height: 24),
              
              StaggeredAnimationWrapper(
                delay: 300,
                child: _buildSearchSection(),
              ),
              
              SizedBox(height: 24),
              
              StaggeredAnimationWrapper(
                delay: 400,
                child: _buildFAQCard(),
              ),
              
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [primaryBlue, lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Tafseer',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Islamic Knowledge & Guidance',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            color: primaryBlue.withOpacity(0.15),
            offset: Offset(0, 10),
          ),
          BoxShadow(
            blurRadius: 15,
            color: Colors.white.withOpacity(0.2),
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, lightBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      color: primaryBlue.withOpacity(0.4),
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask Islamic Questions',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Get answers from Quran & Hadith',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: softAccent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.05),
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Salam alaykum...Seek answers to your questions here....',
                contentPadding: EdgeInsets.all(18),
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
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 8,
                        color: primaryBlue.withOpacity(0.3),
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
                fontWeight: FontWeight.w500,
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
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
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
    return SizedBox.shrink(); // Completely remove the bottom navigation bar
  }

  Widget _buildFloatingActionButton() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(bottom: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vertical stack of buttons (Samsung-style)
            if (_isExpanded)
              Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 3; i >= 0; i--) ...[
                      AnimatedBuilder(
                        animation: _fabAnimation,
                        builder: (context, child) {
                          final double opacity = (_fabAnimation.value).clamp(0.0, 1.0);
                          final double scale = (0.7 + 0.3 * _fabAnimation.value).clamp(0.0, 1.0);
                          
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: _buildGlassmorphicButton(
                                [FontAwesomeIcons.bookQuran, Icons.history, FontAwesomeIcons.bookOpen, Icons.explore][i],
                                ['QURAN', 'HISTORY', 'HADITH', 'TOOLS'][i],
                                i, // Pass index for different colors
                                [
                                  () {
                                    _toggleFAB();
                                    Navigator.push(context, SlidePageRoute(child: QuranScreen()));
                                  },
                                  () {
                                    _toggleFAB();
                                    Navigator.push(context, SlidePageRoute(
                                      child: HistoryScreen(firestoreService: widget.firestoreService),
                                      begin: Offset(-1.0, 0.0),
                                    ));
                                  },
                                  () {
                                    _toggleFAB();
                                    Navigator.push(context, ScalePageRoute(child: HadithScreen()));
                                  },
                                  () {
                                    _toggleFAB();
                                    Navigator.push(context, HeroPageRoute(
                                      child: IslamicToolsScreen(
                                        prayerTimeService: widget.prayerTimeService,
                                        qiblaService: widget.qiblaService,
                                        analyticsService: widget.analyticsService,
                                      ),
                                    ));
                                  },
                                ][i],
                              ),
                            ),
                          );
                        },
                      ),
                      if (i > 0) SizedBox(height: 12), // Increased spacing to accommodate text labels
                    ],
                  ],
                ),
              ),
            
            SizedBox(height: 20), // Increased spacing from Kaaba
            
            // Main Kaaba FAB
            ModernKaabaFAB(
              isExpanded: _isExpanded,
              onPressed: _toggleFAB,
              backgroundColor: primaryBlue,
              size: 56,
              child: Text('🕋', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassmorphicButton(IconData icon, String label, int index, VoidCallback onTap) {
    // Define bright, vibrant colors for the icons
    final List<Color> buttonColors = [
      Color(0xFF00E676), // Quran - Bright Green
      Color(0xFFFF9800), // History - Bright Orange
      Color(0xFF2196F3), // Hadith - Bright Blue
      Color(0xFFE91E63), // Tools - Bright Pink
    ];
    
    final Color buttonColor = buttonColors[index];
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, // Double the icon size (26 * 2)
            height: 52, // Double the icon size (26 * 2)
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                color: buttonColor,
                size: 26,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranicEvidenceSection() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
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