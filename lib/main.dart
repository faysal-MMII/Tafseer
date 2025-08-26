import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/config_service.dart';
import 'services/openai_service.dart';
import 'services/quran_service.dart';
import 'services/hadith_service.dart';
import 'services/rag_services/quran_rag_service.dart';
import 'services/rag_services/hadith_rag_service.dart';
import 'services/prayer_time_service.dart';
import 'services/qibla_service.dart';
import 'theme/text_styles.dart';
import 'theme/theme_provider.dart';
import '../models/hadith.dart';
import 'services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

/// A [RouteObserver] that unfocuses any primary focus when a new route is popped,
/// preventing the keyboard from automatically reappearing on TextFields.
class FocusAwareRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Ensure unfocus is called after the frame has been built to prevent layout issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  // didPush is also included to unfocus previous route's widgets
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    }
  }
}

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF001333),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables FIRST
  await dotenv.load(fileName: ".env");

  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
  };

  runApp(LoadingWidget());

  FirestoreService? firestoreService;
  AnalyticsService? analyticsService;
  FirebaseAnalytics? appAnalyticsInstance;

  bool firebaseSuccessfullyInitialized = false;

  try {
    // Firebase Initialization with offline handling
    if (isFirebaseSupported) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null) {
          await auth.signInAnonymously();
        }
        firebaseSuccessfullyInitialized = true;
      } catch (e) {
        print('Firebase initialization failed (offline?): $e');
        // firebaseSuccessfullyInitialized remains false
      }
    }

    // Initialize foreground task
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'prayer_service_channel',
        channelName: 'Prayer Service Active',
        channelDescription: 'Prayer notifications running in background',
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher_icon',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 30000,
        isOnceEvent: false,
        allowWakeLock: true,
      ),
    );

    // Initialize services that depend on environment variables
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

    final prayerTimeService = PrayerTimeService(
      onPrayerTime: (prayer) {
        if (navigatorKey.currentState != null && navigatorKey.currentState!.context != null) {
          ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
            SnackBar(
              content: Text('It\'s time for ${prayer.name} prayer'),
              duration: Duration(seconds: 10),
            ),
          );
        }
      }
    );
    final qiblaService = QiblaService();

    // Updated initialization call for prayerTimeService
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await prayerTimeService.initialize();
      await prayerTimeService.debugForegroundService();
    });


    if (firebaseSuccessfullyInitialized) {
      firestoreService = FirestoreService();
      appAnalyticsInstance = FirebaseAnalytics.instance;
      analyticsService = AnalyticsService();
      await analyticsService.initialize();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider<PrayerTimeService>.value(value: prayerTimeService),
        ],
        child: MyApp(
          openAiService: openAiService,
          analyticsService: analyticsService,
          firestoreService: firestoreService,
          prayerTimeService: prayerTimeService,
          qiblaService: qiblaService,
          appAnalytics: appAnalyticsInstance,
        ),
      ),
    );

  } catch (error, stackTrace) {
    print("Error during main initialization: $error");

    if (firebaseSuccessfullyInitialized && isFirebaseSupported) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }

    // Fallback in case of a general error
    final fallbackPrayerService = PrayerTimeService();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider<PrayerTimeService>.value(value: fallbackPrayerService),
        ],
        child: MyApp(
          openAiService: OpenAiService(
            quranService: QuranService(),
            hadithService: HadithService(),
            quranRagService: QuranRAGService(apiKey: ''), // Fallback with empty API key
            hadithRagService: HadithRAGService(apiKey: ''), // Fallback with empty API key
          ),
          prayerTimeService: fallbackPrayerService,
          qiblaService: QiblaService(),
          analyticsService: null, // No analytics if initialization failed
          firestoreService: null, // No firestore if initialization failed
          appAnalytics: null, // No analytics if initialization failed
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final OpenAiService openAiService;
  final AnalyticsService? analyticsService;
  final FirestoreService? firestoreService;
  final PrayerTimeService prayerTimeService;
  final QiblaService qiblaService;
  final String? initializationError;
  final FirebaseAnalytics? appAnalytics;

  MyApp({
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
    required this.prayerTimeService,
    required this.qiblaService,
    this.initializationError,
    this.appAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Tafseer',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      restorationScopeId: null,
      navigatorObservers: [
        FocusAwareRouteObserver(),
        if (appAnalytics != null) FirebaseAnalyticsObserver(analytics: appAnalytics!),
      ],
      theme: themeProvider.themeData.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          themeProvider.themeData.textTheme,
        ),
      ),
      home: HomeScreen(
        openAiService: openAiService,
        analyticsService: analyticsService,
        firestoreService: firestoreService,
        prayerTimeService: prayerTimeService,
        qiblaService: qiblaService,
      ),
    );
  }
}
