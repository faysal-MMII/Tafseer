import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
  int _currentIndex = 0;
  final TextEditingController _controller = TextEditingController();
  String? currentQuery;
  String _aiResponse = '';
  List<String> _quranVerses = [];
  bool _showResults = false;
  bool _isLoading = false;
  String? _error;
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _logScreenView();
    _floatingController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
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
    _floatingController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final firestoreService = widget.firestoreService;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f4c75),
                  Color(0xFF3282b8),
                ]
              : [
                  Color(0xFFe3f2fd),
                  Color(0xFFbbdefb),
                  Color(0xFF90caf9),
                  Color(0xFF64b5f6),
                ],
          ),
        ),
        child: Stack(
          children: [
            // Floating background elements
            _buildFloatingElements(),
            
            // Main content with glass app bar
            Column(
              children: [
                _buildGlassAppBar(isDarkMode),
                Expanded(
                  child: _buildMainContent(context, themeProvider),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        // Animated floating circles
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
              top: 100 + (_floatingController.value * 20),
              left: 50 + (_floatingController.value * 10),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.blue.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
              top: 300 - (_floatingController.value * 30),
              right: 40 + (_floatingController.value * 15),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyan.withOpacity(0.4),
                      Colors.teal.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _floatingController,
          builder: (context, child) {
            return Positioned(
              bottom: 200 + (_floatingController.value * 25),
              left: 200 - (_floatingController.value * 20),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.orange.withOpacity(0.3),
                      Colors.pink.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          top: 250,
          left: 100,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.green.withOpacity(0.4),
                  Colors.lightGreen.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassAppBar(bool isDarkMode) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: isDarkMode 
              ? Colors.white.withOpacity(0.1)
              : Colors.white.withOpacity(0.2),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGlassNavButton(
                    icon: Icons.home,
                    label: 'Home',
                    isActive: _currentIndex == 0,
                    onTap: () => setState(() => _currentIndex = 0),
                  ),
                  _buildGlassNavButton(
                    widget: SvgPicture.asset(
                      'assets/icon/compass_needle.svg',
                      width: 20,
                      height: 20,
                      color: _currentIndex == 1 ? Colors.white : Colors.white70,
                    ),
                    label: 'Tools',
                    isActive: _currentIndex == 1,
                    onTap: () {
                      widget.analyticsService?.logFeatureUsed('islamic_tools_screen');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => IslamicToolsScreen(
                            prayerTimeService: widget.prayerTimeService,
                            qiblaService: widget.qiblaService,
                            analyticsService: widget.analyticsService,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildGlassNavButton(
                    icon: FontAwesomeIcons.bookQuran,
                    label: 'Quran',
                    isActive: _currentIndex == 2,
                    onTap: () {
                      widget.analyticsService?.logFeatureUsed('quran_screen');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => QuranScreen()));
                    },
                  ),
                  _buildGlassNavButton(
                    icon: FontAwesomeIcons.bookOpen,
                    label: 'Hadith',
                    isActive: _currentIndex == 3,
                    onTap: () {
                      widget.analyticsService?.logFeatureUsed('hadith_screen');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HadithScreen()));
                    },
                  ),
                  _buildGlassNavButton(
                    icon: Icons.history,
                    label: 'History',
                    isActive: _currentIndex == 4,
                    onTap: () {
                      widget.analyticsService?.logFeatureUsed('history_screen');
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen(firestoreService: widget.firestoreService)));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavButton({
    IconData? icon,
    Widget? widget,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isActive 
            ? Colors.white.withOpacity(0.2)
            : Colors.transparent,
          border: Border.all(
            color: isActive 
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget ?? Icon(
              icon,
              color: isActive ? Colors.white : Colors.white70,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeProvider themeProvider) {
    return ResponsiveLayout(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            
            // Title Section with Glass Effect
            _buildGlassContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tafseer',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Islamic Knowledge & Guidance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return _buildGlassButton(
                        onTap: () => themeProvider.toggleTheme(),
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: Icon(
                            key: ValueKey<bool>(themeProvider.isDarkMode),
                            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Fun Fact Card with Glass Effect
            _buildGlassContainer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IslamicFunFact(),
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Search Box with Glass Effect
            _buildGlassSearchBox(),
            
            SizedBox(height: 24),
            
            // FAQ Section with Glass Effect
            _buildGlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frequently Asked Questions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FAQSection(),
                  ),
                ],
              ),
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
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassSearchBox() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Salam alaykum...Seek answers to your questions here....',
                    hintStyle: TextStyle(
                      color: Colors.white60,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              SizedBox(width: 12),
              _buildGlassButton(
                onTap: () {
                  final text = _controller.text.trim();
                  if (text.isNotEmpty) {
                    _askQuestion(text);
                    _controller.clear();
                  }
                },
                child: Icon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildQuranicEvidenceSection() {
    return _buildGlassContainer(
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
    return _buildGlassContainer(
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Text(
          'Error: $_error',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}