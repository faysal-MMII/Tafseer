import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import '../services/firestore_service.dart'; // Import FirestoreService

class QuranService {
  static Map<String, dynamic>? _quranData;
  final FirestoreService? _firestoreService; // FirestoreService is now an optional dependency

  QuranService([this._firestoreService]); // Constructor accepts optional FirestoreService

  Future<void> _loadQuranData() async {
    if (_quranData != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/translation.json');
      _quranData = json.decode(jsonString);
    } catch (e) {
      print('Error loading Quran data: $e');
      throw Exception('Failed to load Quran data');
    }
  }

  Future<List<Map<String, dynamic>>> fetchQuranVerses(String query) async {
    // Check Firestore cache if available
    if (_firestoreService != null) {
      final cachedResponse = await _firestoreService!.getCachedVerse('search:$query'); // Check Firestore cache
      if (cachedResponse != null) {
        print('Quran search results for query "$query" retrieved from Firestore cache.');
        return List<Map<String, dynamic>>.from(cachedResponse['results']);
      }
    }

    final quranApiUrl = ConfigService.quranApiUrl;
    final quranApiLanguage = ConfigService.quranApiLanguage;

    try {
      final response = await http.get(
        Uri.parse('$quranApiUrl/search?q=$query&language=$quranApiLanguage&size=5'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final verses = data['search']['results'];

        final results = List<Map<String, dynamic>>.from(verses.map((verse) => {
          'reference': verse['verse_key'],
          'text': verse['translations'][0]['text'],
          'arabic_text': verse['text'],
          'verse_key': verse['verse_key'],
        }));

        // Cache in Firestore if available
        if (_firestoreService != null && results.isNotEmpty) {
          await _firestoreService!.cacheVerse('search:$query', {
            'results': results,
            'query': query,
            'timestamp': DateTime.now().toIso8601String(),
          });
          print('Quran search results for query "$query" cached in Firestore.');
        }

        return results;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchVerseDetails(String verseKey) async {
    // Check Firestore cache first if available
    if (_firestoreService != null) {
      final cachedVerse = await _firestoreService!.getCachedVerse('verse:$verseKey'); // Check Firestore cache
      if (cachedVerse != null) {
        print('Verse details for "$verseKey" retrieved from Firestore cache.');
        return cachedVerse;
      }
    }

    final quranApiUrl = ConfigService.quranApiUrl;
    final quranApiLanguage = ConfigService.quranApiLanguage;

    try {
      final response = await http.get(
        Uri.parse('$quranApiUrl/verses/by_key/$verseKey?language=$quranApiLanguage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final verseData = data['verse'];

        // Cache in Firestore if available
        if (_firestoreService != null) {
          await _firestoreService!.cacheVerse('verse:$verseKey', verseData); // Cache verse details in Firestore
          print('Verse details for "$verseKey" cached in Firestore.');
        }

        return verseData;
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchSurahVerses(int surahNumber) async {
    // Try fetching from local JSON first
    await _loadQuranData();

    try {
      final chapters = _quranData!['quran']['chapters'] as List;
      final chapter = chapters.firstWhere(
        (ch) => ch['chapter'] == surahNumber,
        orElse: () => throw Exception('Surah not found'),
      );

      return List<Map<String, dynamic>>.from(
        chapter['verses'].map((verse) => {
          'verse_key': '$surahNumber:${verse['verse']}',
          'text': verse['text'],
          // 'arabic_text': verse['arabic'] ?? '', // Add if available in JSON
        }),
      );
    } catch (e) {
      print('Error fetching surah $surahNumber from local JSON: $e');
      // Fallback to API if local JSON fails
      return _fetchSurahVersesFromApi(surahNumber);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSurahVersesFromApi(int surahNumber) async {
    final quranApiUrl = ConfigService.quranApiUrl;
    final quranApiLanguage = ConfigService.quranApiLanguage;

    try {
      final response = await http.get(
        Uri.parse('$quranApiUrl/verses/by_chapter/$surahNumber?language=$quranApiLanguage'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final verses = data['verses'];

        return List<Map<String, dynamic>>.from(verses.map((verse) => {
          'reference': verse['verse_key'],
          'text': verse['translations'][0]['text'],
          'arabic_text': verse['text'],
          'verse_key': verse['verse_key'],
        }));
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching surah $surahNumber from API: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchQuran(String query) async {
    // Try searching in local JSON first
    await _loadQuranData();

    try {
      List<Map<String, dynamic>> results = [];
      final chapters = _quranData!['quran']['chapters'] as List;

      for (var chapter in chapters) {
        final chapterNum = chapter['chapter'];
        final verses = chapter['verses'] as List;

        for (var verse in verses) {
          if (verse['text'].toLowerCase().contains(query.toLowerCase())) {
            results.add({
              'verse_key': '$chapterNum:${verse['verse']}',
              'text': verse['text'],
              // 'arabic_text': verse['arabic'] ?? '', // Add if available in JSON
            });
          }
        }
      }

      return results;
    } catch (e) {
      print('Error searching Quran in local JSON: $e');
      // Fallback to API if local JSON fails
      return fetchQuranVerses(query);
    }
  }
}