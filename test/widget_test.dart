// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:tafseer/main.dart';
import 'package:tafseer/services/analytics_service.dart';
import 'package:tafseer/services/firestore_service.dart';
import 'package:tafseer/services/openai_service.dart';
import 'package:tafseer/screens/search_results_screen.dart';
import 'widget_test.mocks.dart';

@GenerateMocks([OpenAiService, AnalyticsService, FirestoreService])
void main() {
  late MockOpenAiService mockOpenAiService;
  late MockAnalyticsService mockAnalyticsService;
  late MockFirestoreService mockFirestoreService;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockOpenAiService = MockOpenAiService();
    mockAnalyticsService = MockAnalyticsService();
    mockFirestoreService = MockFirestoreService();

    final Map<String, dynamic> mockResponse = {
      'quran_results': {
        'answer': 'Test Quran answer',
        'verses': ['Test verse 1 (1:1)', 'Test verse 2 (2:2)']
      },
      'hadith_results': {
        'hadiths': [
          {
            'text': 'Test hadith text',
            'arabic': 'Test arabic text',
            'grade': 'sahih',
            'narrator': 'Test narrator',
            'hadith_number': "1:234",
            'id': 1,
            'collection_id': 1,
            'chapter_id': 1
          }
        ]
      }
    };

    when(mockOpenAiService.generateResponse(any))
        .thenAnswer((_) async => mockResponse);

    // Default Firestore mock setup
    when(mockFirestoreService.findSimilarQuestion(any)).thenAnswer((_) async => null);
    when(mockFirestoreService.saveQA(
      question: anyNamed('question'),
      answer: anyNamed('answer'),
      quranVerses: anyNamed('quranVerses'),
      hadiths: anyNamed('hadiths'),
    )).thenAnswer((_) async => null);
  });

  group('Search Results Display Tests', () {
    setUp(() {
      when(mockOpenAiService.generateResponse(any)).thenAnswer((_) async => {
        'quran_results': {
          'answer': 'Test Quran answer',
          'verses': ['Test verse 1 (1:1)', 'Test verse 2 (2:2)']
        },
        'hadith_results': {
          'hadiths': [
            {
              'text': 'Test hadith text',
              'arabic': 'Test arabic text',
              'grade': 'sahih',
              'narrator': 'Test narrator',
              'hadith_number': "1:234"  // Use string format instead
            }
          ]
        }
      });
    });

    testWidgets('Shows basic search results correctly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      await _waitForContent(tester);

      // Check for RichText content instead of plain text
      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && 
            widget.text.toPlainText().contains('Test verse 1')
        ), 
        findsOneWidget,
        reason: 'Should find verse text in RichText widget'
      );
    });

    testWidgets('Shows loading state initially', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      
      // Check that loading appears
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Wait for a single frame pump
      await tester.pump(Duration(seconds: 1));
      
      // Check that search results screen exists
      expect(find.byType(SearchResultsScreen), findsOneWidget);
    });

    testWidgets('All section titles are visible', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      await _waitForContent(tester);

      expect(find.text('Quranic Evidence'), findsOneWidget);
      expect(find.text('Answer'), findsOneWidget);
      expect(find.text('Relevant Verses'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Shows network error properly', (WidgetTester tester) async {
      when(mockOpenAiService.generateResponse(any))
          .thenThrow(Exception('Network error'));

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      await tester.pump(Duration(seconds: 1));

      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('Shows timeout error properly', (WidgetTester tester) async {
      when(mockOpenAiService.generateResponse(any))
          .thenThrow(Exception('Request timeout'));

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      await tester.pump(Duration(seconds: 1));

      expect(find.textContaining('Request timeout'), findsOneWidget);
    });
  });

  group('Cached Results Tests', () {
    testWidgets('Uses cached results when available', (WidgetTester tester) async {
      // Setup cached response
      when(mockFirestoreService.findSimilarQuestion(any))
          .thenAnswer((_) async => {
            'answer': 'Cached answer',
            'quranVerses': ['Cached verse 1', 'Cached verse 2'],
            'hadiths': [
              {
                'text': 'Cached hadith',
                'hadith_number': {'book': 2, 'hadith': 345}  // Proper format here too
              }
            ]
          });

      // Mock OpenAI response (shouldn't be used)
      when(mockOpenAiService.generateResponse(any)).thenAnswer((_) async => {
        'quran_results': {
          'answer': 'Should not see this',
          'verses': []
        },
        'hadith_results': {
          'hadiths': []
        }
      });

      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await _pumpSearchScreen(
        tester, 
        'Test question',
        openAiService: mockOpenAiService,
        analyticsService: mockAnalyticsService,
        firestoreService: mockFirestoreService,
      );
      await _waitForContent(tester);

      expect(
        find.byWidgetPredicate(
          (widget) => widget is RichText && 
            widget.text.toPlainText().contains('Cached verse 1')
        ), 
        findsOneWidget,
        reason: 'Should find cached verse text in RichText widget'
      );
    });
  });
}

// Helper functions
Future<void> _pumpSearchScreen(
  WidgetTester tester, 
  String query, {
  required OpenAiService openAiService,
  required AnalyticsService? analyticsService,
  required FirestoreService? firestoreService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SearchResultsScreen(
          query: query,
          openAiService: openAiService,
          analyticsService: analyticsService,
          firestoreService: firestoreService,
        ),
      ),
    ),
  );
}

Future<void> _waitForContent(WidgetTester tester) async {
  int maxAttempts = 5;
  int currentAttempt = 0;
  while (currentAttempt < maxAttempts) {
    await tester.pump(Duration(milliseconds: 500));
    try {
      final richTextFinder = find.byWidgetPredicate(
        (widget) => widget is RichText && 
          (widget.text.toPlainText().contains('Test verse') ||
           widget.text.toPlainText().contains('Cached verse'))
      );
      if (richTextFinder.evaluate().isNotEmpty) {
        break;
      }
    } catch (_) {}
    currentAttempt++;
  }
  await tester.pump(Duration(milliseconds: 500));
}