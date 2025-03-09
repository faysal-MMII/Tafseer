import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/config_service.dart';
import 'services/openai_service.dart';
import 'services/quran_service.dart';
import 'services/hadith_service.dart';
import 'services/rag_services/quran_rag_service.dart';
import 'services/rag_services/hadith_rag_service.dart';
import 'theme/text_styles.dart';
import '../models/hadith.dart';
import 'dart:io';
import 'dart:async';
import 'services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAnalytics? analytics;

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

Future<AppData> initializeApp() async {
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
    await analytics!.logEvent(
      name: 'app_open',
      parameters: {'build_type': 'release'},
    );
    analyticsService = AnalyticsService();
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
  };

  // Catch async errors with zone
  runZonedGuarded(() async {
    try {
      if (isFirebaseSupported) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
        print("Flutter error handler registered with Crashlytics");

        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          print("No user logged in, signing in anonymously");
          await auth.signInAnonymously();
          print("Anonymous auth completed, user ID: ${auth.currentUser?.uid}");
        } else {
          print("User already logged in: ${auth.currentUser?.uid}");
        }
      }
    } catch (e, stack) {
      print("Firebase initialization error: $e");
    }

    runApp(LoadingApp());
    print("Loading screen displayed");

    try {
      final appData = await initializeApp();
      FirestoreService? firestoreService = appData.firestoreService;
      AnalyticsService? analyticsService = appData.analyticsService;

      if (isFirebaseSupported) {
        await analyticsService?.initialize();
        await analyticsService?.logEvent(
          name: 'first_open',
          parameters: {'build_type': 'release'},
        );

        // Schedule periodic heartbeat
        Timer.periodic(Duration(minutes: 30), (_) {
          analyticsService?.logHeartbeat();
        });
      }

      print("All services initialized, launching main app");
      runApp(MyApp(
        openAiService: appData.openAiService,
        analyticsService: analyticsService,
        firestoreService: firestoreService,
      ));
    } catch (error, stackTrace) {
      print("Error during initialization: $error");
      print(stackTrace);
      runApp(MyApp(
        openAiService: OpenAiService(
          quranService: QuranService(),
          hadithService: HadithService(),
          quranRagService: QuranRAGService(apiKey: ''),
          hadithRagService: HadithRAGService(apiKey: ''),
        ),
        initializationError: 'Failed to initialize: $error',
      ));
      if (isFirebaseSupported) {
        FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    }
  }, (error, stackTrace) {
    print('Uncaught error: $error');
    print(stackTrace);
    if (isFirebaseSupported) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
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
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;
  final String? initializationError;

  MyApp({
    required this.openAiService,
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
              openAiService: openAiService,
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