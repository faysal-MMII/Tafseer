import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
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
import 'theme/text_styles.dart';
import '../models/hadith.dart';
import 'dart:io';
import 'widgets/faq_section.dart';
import 'screens/quran_screen.dart';
import 'screens/places_screen.dart';
import 'dart:async';
import 'screens/search_results_screen.dart';
import 'widgets/islamic_fun_fact.dart';
import 'services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'firebase_options.dart';
import 'screens/history_screen.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/hadith_screen.dart'; // Import HadithScreen

FirebaseAnalytics? analytics;

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

Future<AppData> initializeApp(dynamic _) async {
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
  if (isFirebaseSupported) {
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
      parameters: {'build_type': 'release'},
    ).then((_) {
      print('Successfully logged app_open event');
    }).catchError((error) {
      print('Failed to log app_open event: $error');
    });
    analyticsService = AnalyticsService();
  } else {
    print('Firebase Analytics not supported on this platform.');
  }
  return AppData(
    openAiService: openAiService,
    analyticsService: analyticsService,
    firestoreService: firestoreService,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("App starting - binding initialized");

  // Set up Flutter error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
    // Log to console at minimum
  };

  // Catch async errors with zone
  runZonedGuarded(() async {
    try {
      if (isFirebaseSupported) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        try {
          if (FirebaseCrashlytics.instance != null) {
            FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
          }
        } catch (e) {
          print("Could not set up Crashlytics: $e");
        }

        print("Firebase initialized");

        try {
          final auth = FirebaseAuth.instance;
          if (auth.currentUser == null) {
            print("No user logged in, signing in anonymously");
            await auth.signInAnonymously();
            print("Anonymous auth completed, user ID: ${auth.currentUser?.uid}");
          } else {
            print("User already logged in: ${auth.currentUser?.uid}");
          }
        } catch (e) {
          print("Authentication service error, but continuing: $e");
        }
      }
    } catch (e, stack) {
      print("Firebase initialization error: $e");
      print(stack);
      // Continue with fallback behavior
    }

    runApp(LoadingApp());
    print("Loading screen displayed");

    try {
      print("Starting to load environment files");
      await ConfigService.loadEnvFile();
      await dotenv.load(fileName: ".env");
      print("Environment files loaded");
      print("Initializing services");
      final quranService = QuranService();
      final hadithService = HadithService();
      print("Basic services initialized");
      print("Initializing RAG services");
      final quranRagService = QuranRAGService(apiKey: ConfigService.openAiApiKey);
      final hadithRagService = HadithRAGService(apiKey: ConfigService.openAiApiKey);
      print("RAG services initialized");
      print("Creating OpenAI service");
      final openAiService = OpenAiService(
        quranService: quranService,
        hadithService: hadithService,
        quranRagService: quranRagService,
        hadithRagService: hadithRagService,
      );
      print("OpenAI service created");
      FirestoreService? firestoreService;
      AnalyticsService? analyticsService;
      if (isFirebaseSupported) {
        print("Initializing Firestore");
        firestoreService = FirestoreService();
        print("Firestore initialized");
        await firestoreService.checkAndMigrateHistoryData();
        print("Firestore initialized and data migration checked");
        print("Setting up Analytics");
        analytics = FirebaseAnalytics.instance;
        await analytics!.setAnalyticsCollectionEnabled(true);
        final isSupported = await analytics!.isSupported();
        print('Firebase Analytics supported: $isSupported');
        await analytics!.logEvent(
          name: 'app_open',
          parameters: {'build_type': 'release'},
        );
        print("App open event logged");
        analyticsService = AnalyticsService();
        print("Analytics service created");
      } else {
        print('Firebase Analytics not supported on this platform.');
      }
      print("All services initialized, launching main app");
      runApp(MyApp(
        openAiService: openAiService,
        analyticsService: analyticsService,
        firestoreService: firestoreService,
      ));
      print("Main app launched");
    } catch (error, stackTrace) {
      print("Error during initialization: $error");
      print(stackTrace);
      runApp(MyApp(initializationError: 'Failed to initialize: $error'));
      if (isFirebaseSupported) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    }
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print(stackTrace);
    // Forward to Crashlytics if available
    try {
      if (isFirebaseSupported) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } catch (e) {
      print('Error reporting to Crashlytics: $e');
    }
  });
}

class LoadingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
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
    setState(() {
      _isLoading = true;
    });
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
      if (operationDuration < Duration(milliseconds: 500)) {
        await Future.delayed(Duration(milliseconds: 500) - operationDuration);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> logSearchCompletedEvent(String query, int versesFound) async {
    if (isFirebaseSupported && analytics != null) {
      await analytics!.logEvent(
        name: 'search_completed',
        parameters: {
          'query': query,
          'verses_found': versesFound,
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
    return LoadingOverlay(
      isLoading: _isLoading,
      loadingText: "Processing your question...",
      child: Scaffold(
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
      ),
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
    print('Building Quranic Evidence Section');
    print('Current Query: $currentQuery');
    print('AI Response: $_aiResponse');
    print('Quran Verses: $_quranVerses');
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

class AppData {
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;

  AppData({
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
  });
}