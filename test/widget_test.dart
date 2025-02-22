// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'package:tafseer/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tafseer/services/analytics_service.dart';
import 'package:tafseer/services/firestore_service.dart';
import 'package:tafseer/services/openai_service.dart';
import 'package:tafseer/services/quran_service.dart';
import 'package:tafseer/services/hadith_service.dart';
import 'widget_test.mocks.dart';

@GenerateMocks([
  OpenAiService, 
  AnalyticsService, 
  FirestoreService,
  QuranService,
  HadithService,
  SharedPreferences
])
void main() {
  late MockOpenAiService mockOpenAiService;
  late MockAnalyticsService mockAnalyticsService;
  late MockFirestoreService mockFirestoreService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockOpenAiService = MockOpenAiService();
    mockAnalyticsService = MockAnalyticsService();
    mockFirestoreService = MockFirestoreService();
    mockSharedPreferences = MockSharedPreferences();
  });

  group('State Persistence Tests', () {
    testWidgets('App preserves question input during background', (WidgetTester tester) async {
      final testQuestion = 'What is the importance of Salah?';
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            openAiService: mockOpenAiService,
            analyticsService: mockAnalyticsService,
            firestoreService: mockFirestoreService,
          ),
        ),
      );

      // Enter text
      await tester.enterText(
        find.byType(TextField), 
        testQuestion
      );
      await tester.pump();

      // Simulate app going to background
      await tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Simulate app coming back to foreground
      await tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      // Verify text is still there
      expect(find.text(testQuestion), findsOneWidget);
    });

    testWidgets('App restores last screen after restart', (WidgetTester tester) async {
      // Mock SharedPreferences to return last screen
      when(mockSharedPreferences.getString('last_screen')).thenReturn('quran');
      
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            openAiService: mockOpenAiService,
            analyticsService: mockAnalyticsService,
            firestoreService: mockFirestoreService,
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify we're on the right screen
      expect(find.text('Quran'), findsOneWidget);
    });
  });
}