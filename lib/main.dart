import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 
import 'services/config_service.dart';
import 'services/openai_service.dart';
import 'services/quran_service.dart';
import 'services/hadith_service.dart';
import 'services/rag_services/quran_rag_service.dart';
import 'services/rag_services/hadith_rag_service.dart';
import 'widgets/quran_section.dart';
import 'widgets/hadith_section.dart';
import 'theme/text_styles.dart';
import '../models/hadith.dart';
import 'dart:io';
import 'widgets/faq_section.dart';
import 'screens/quran_screen.dart';
import 'screens/hadith_screen.dart';
import 'screens/places_screen.dart';
import 'dart:async';
import 'screens/search_results_screen.dart';
import 'widgets/islamic_fun_fact.dart';
import 'services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'firebase_options.dart';
import 'screens/history_screen.dart';
import 'widgets/responsive_layout.dart';

FirebaseAnalytics? analytics;
bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // Log uncaught errors
  runZonedGuarded(() async {
    await ConfigService.loadEnvFile();
    await dotenv.load(fileName: ".env");

    final quranService = QuranService();
    final hadithService = HadithService();

    final quranRagService = QuranRAGService(apiKey: ConfigService.openAiApiKey);
    final hadithRagService = HadithRAGService(apiKey: ConfigService.openAiApiKey);

    final openAiService = OpenAiService(
      quranService: quranService,
      hadithService: hadithService,
      quranRagService: quranRagService,
      hadithRagService: hadithRagService,
    );

    FirestoreService? firestoreService;
    if (Platform.isAndroid || Platform.isIOS) {
      firestoreService = FirestoreService();
    }

    AnalyticsService? analyticsService;

    if (isFirebaseSupported) {
      analytics = FirebaseAnalytics.instance;
      await analytics!.setAnalyticsCollectionEnabled(true);
      final isSupported = await analytics!.isSupported();
      print('Firebase Analytics supported: $isSupported');
      await analytics!.logEvent(
        name: 'app_open',
        parameters: {'build_type': 'release'}
      ).then((_) {
        print('Successfully logged app_open event');
      }).catchError((error) {
        print('Failed to log app_open event: $error');
      });
      analyticsService = AnalyticsService();
    } else {
      print('Firebase Analytics not supported on this platform.');
    }

    runApp(MyApp(
      openAiService: openAiService,
      analyticsService: analyticsService,
      firestoreService: firestoreService,
    ));
  }, (error, stackTrace) {
    // Log errors to Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
    runApp(MyApp(initializationError: 'Failed to initialize app: $error'));
  });
}

class MyApp extends StatelessWidget {
  final OpenAiService? openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;
  final String? initializationError;

  MyApp({
    this.openAiService,
    this.analyticsService,
    this.firestoreService,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tafseer',
      navigatorObservers: [
        if (analytics != null) FirebaseAnalyticsObserver(analytics: analytics!),
      ],
      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: AppTextStyles.englishText,
          titleLarge: AppTextStyles.titleText,
        ),
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
      ),
      home: initializationError != null
          ? ErrorScreen(message: initializationError!)
          : HomeScreen(
              openAiService: openAiService!,
              analyticsService: analyticsService,
              firestoreService: firestoreService,
            ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            message,
            style: AppTextStyles.englishText.copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

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
  List<Hadith> _hadiths = [];
  bool _showResults = false;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    if (isFirebaseSupported && analytics != null) {
      await analytics!.logScreenView(
        screenName: 'Home Screen',
        screenClass: 'HomeScreen',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askQuestion(String query) async {
    if (query.isEmpty) return;

    widget.analyticsService?.logQuestionAsked('Home Screen Question');

    Navigator.push(
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
  }

  Future<void> logSearchCompletedEvent(
      String query, int versesFound, int hadithsFound) async {
    if (isFirebaseSupported && analytics != null) {
      await analytics!.logEvent(
        name: 'search_completed',
        parameters: {
          'query': query,
          'verses_found': versesFound,
          'hadiths_found': hadithsFound,
        },
      ).then((_) {
        print('search_completed event logged successfully');
      }).catchError((error) {
        print('Failed to log search_completed event: $error');
      });
    }
  }

  void _showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Search Error', style: AppTextStyles.titleText),
        content: Text(error, style: AppTextStyles.englishText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: AppTextStyles.englishText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = widget.firestoreService;

    return Scaffold(
      backgroundColor: Color(0xFFF0F0F0),
      appBar: AppBar(
        toolbarHeight: 70,  // Increased height for buttons
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
            if (_isLoading) ...[
              Center(child: CircularProgressIndicator()),
            ] else if (_error != null) ...[
              _buildErrorBox(),
            ] else if (_showResults) ...[
              _buildQuranicEvidenceSection(),
              SizedBox(height: 20),
              _buildHadithGuidanceSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0F0F0)],
        ),
        borderRadius: BorderRadius.circular(6),
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
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Salam alaykum...seek answers to your questions here....',
              contentPadding: EdgeInsets.all(20),
              border: InputBorder.none,
            ),
            style: AppTextStyles.englishText.copyWith(color: Color(0xFF333333)),
            minLines: 4,
            maxLines: 4,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              onPressed: () => _askQuestion(_controller.text.trim()),
              child: Text('Ask a Question', style: AppTextStyles.englishText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranicEvidenceSection() {
    print('Building Quranic Evidence Section');
    print('Current Query: $currentQuery');
    print('AI Response: $_aiResponse');
    print('Quran Verses: $_quranVerses');

    return QuranSection(
      query: currentQuery,
      answer: _aiResponse,
      verses: _quranVerses,
      openAiService: widget.openAiService,
      firestoreService: widget.firestoreService,
    );
  }

  Widget _buildHadithGuidanceSection() {
    print('=== HomeScreen Debug ===');
    print('OpenAiService exists: ${widget.openAiService != null}');
    print('=====================');

    return _buildResultSection(
      title: 'Hadith Guidance',
      children: [
        HadithSection(
          query: currentQuery,
          hadiths: _hadiths,
          openAiService: widget.openAiService,
          firestoreService: widget.firestoreService,
        ),
      ],
    );
  }

  Widget _buildResultSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFE6E6E6)],
        ),
        borderRadius: BorderRadius.circular(8),
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
            title,
            style: AppTextStyles.titleText.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
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