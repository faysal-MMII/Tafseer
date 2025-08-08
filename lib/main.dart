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
import 'dart:io';
import 'dart:async';
import 'services/analytics_service.dart';
import '../services/firestore_service.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseAnalytics? analytics;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

bool get isFirebaseSupported => kIsWeb || Platform.isIOS || Platform.isAndroid;

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
  
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter error: ${details.exception}');
  };
  
  runApp(LoadingWidget());
  
  try {
    // Initialize foreground task for background operations
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

    if (isFirebaseSupported) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }
    }
    
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
    
    // Updated Timer call with debugForegroundService()
    Timer(Duration.zero, () async {
      await prayerTimeService.initialize();
      await prayerTimeService.debugForegroundService(); // ADDED LINE
    });
    
    FirestoreService? firestoreService;
    AnalyticsService? analyticsService;
    
    if (isFirebaseSupported) {
      firestoreService = FirestoreService();
      analytics = FirebaseAnalytics.instance;
      analyticsService = AnalyticsService();
      await analyticsService.initialize();
    }
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: MyApp(
          openAiService: openAiService,
          analyticsService: analyticsService,
          firestoreService: firestoreService,
          prayerTimeService: prayerTimeService,
          qiblaService: qiblaService,
        ),
      ),
    );
    
  } catch (error, stackTrace) {
    print("Error during initialization: $error");
    
    if (isFirebaseSupported) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace);
    }
    
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: MyApp(
          openAiService: OpenAiService(
            quranService: QuranService(),
            hadithService: HadithService(),
            quranRagService: QuranRAGService(apiKey: ''),
            hadithRagService: HadithRAGService(apiKey: ''),
          ),
          prayerTimeService: PrayerTimeService(),
          qiblaService: QiblaService(),
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

  MyApp({
    required this.openAiService,
    this.analyticsService,
    this.firestoreService,
    required this.prayerTimeService,
    required this.qiblaService,
    this.initializationError,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Tafseer',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        if (analytics != null) FirebaseAnalyticsObserver(analytics: analytics!),
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