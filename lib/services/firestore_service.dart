import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/deviceid_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _classifyFirestoreError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('timeout') || errorString.contains('connection')) {
      return 'network_connection';
    } else if (errorString.contains('permission') || errorString.contains('denied')) {
      return 'permission_denied';
    } else if (errorString.contains('quota') || errorString.contains('exceeded')) {
      return 'quota_exceeded';
    } else if (errorString.contains('unavailable') || errorString.contains('service')) {
      return 'service_unavailable';
    } else if (errorString.contains('cancelled')) {
      return 'request_cancelled';
    } else {
      return 'unknown_error';
    }
  }

  List<String> _generateSearchableTerms(String text) {
    final words = text.toLowerCase().split(' ');
    final searchableTerms = <String>{};

    for (int i = 0; i < words.length; i++) {
      for (int j = i; j < words.length; j++) {
        searchableTerms.add(words.sublist(i, j + 1).join(' '));
      }
    }

    return searchableTerms.take(10).toList();
  }

  List<String> _cleanQuranVerses(List<String> verses) {
    return verses.where((verse) =>
      verse.isNotEmpty &&
      !verse.contains('null') &&
      verse != 'null'
    ).map((verse) {
      final regex = RegExp(r'\(([^)]+)\)$');
      final match = regex.firstMatch(verse);
      if (match != null && match.group(1) != null && match.group(1) != 'null') {
        return match.group(1)!;
      }
      return verse;
    }).toList();
  }

  List<Map<String, dynamic>> _cleanHadiths(List<dynamic> hadiths) {
    return hadiths.where((hadith) => hadith != null).map((hadith) {
      if (hadith is Map<String, dynamic>) {
        final cleanHadith = <String, dynamic>{};
        hadith.forEach((key, value) {
          if (value != null && value.toString() != 'null' && value.toString().isNotEmpty) {
            cleanHadith[key] = value;
          }
        });
        return cleanHadith;
      } else if (hadith is String && hadith.isNotEmpty && hadith != 'null') {
        return {'text': hadith};
      }
      return null;
    }).where((hadith) => hadith != null && hadith!.isNotEmpty)
      .cast<Map<String, dynamic>>().toList();
  }

  Future<void> saveQA({
    required String question,
    required String answer,
    required List<String> quranVerses,
    required List<dynamic> hadiths,
  }) async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();
      print('DEBUG: Saving QA for device: $deviceId');
      print('DEBUG: Question: $question');

      final existingQuestions = await _db.collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .where('question', isEqualTo: question)
          .get();

      print('DEBUG: Found ${existingQuestions.docs.length} existing questions');

      final cleanVerses = _cleanQuranVerses(quranVerses);
      final cleanHadiths = _cleanHadiths(hadiths);

      if (existingQuestions.docs.isNotEmpty) {
        print('DEBUG: Updating existing entry');
        await _db.collection('qa_history')
            .doc(existingQuestions.docs.first.id)
            .update({
          'answer': answer,
          'quranVerses': cleanVerses,
          'hadiths': cleanHadiths,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('Updated existing QA entry');
      } else {
        print('DEBUG: Creating new entry');
        final searchableTerms = _generateSearchableTerms(question);
        print('DEBUG: Generated ${searchableTerms.length} searchable terms');

        final docRef = await _db.collection('qa_history').add({
          'deviceId': deviceId,
          'question': question,
          'answer': answer,
          'quranVerses': cleanVerses,
          'hadiths': cleanHadiths,
          'searchableTerms': searchableTerms,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('QA saved successfully with ID: ${docRef.id}');
        print('Saved ${cleanVerses.length} verses and ${cleanHadiths.length} hadiths');
      }
    } catch (e, stackTrace) {
      final errorType = _classifyFirestoreError(e);
      print('ERROR saving QA: $e. Classified as: $errorType');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> testSaveMultipleQuestions() async {
    print('Testing multiple question saves...');

    await saveQA(
      question: "Test question 1",
      answer: "Test answer 1",
      quranVerses: [],
      hadiths: [],
    );

    await saveQA(
      question: "Test question 2",
      answer: "Test answer 2",
      quranVerses: [],
      hadiths: [],
    );

    print('Test saves completed');
  }

  Future<Map<String, dynamic>?> findSimilarQuestion(String question) async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();
      final searchTerms = _generateSearchableTerms(question);

      for (final term in searchTerms) {
        final snapshot = await _db.collection('qa_history')
            .where('deviceId', isEqualTo: deviceId)
            .where('searchableTerms', arrayContains: term)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.data();
        }
      }
      return null;
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error checking Firestore: $e. Classified as: $errorType');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCachedVerse(String verseKey) async {
    try {
      final doc = await _db.collection('quran_cache')
          .doc(verseKey)
          .get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error getting cached verse: $e. Classified as: $errorType');
      return null;
    }
  }

  Future<void> cacheVerse(String verseKey, Map<String, dynamic> verseData) async {
    try {
      await _db.collection('quran_cache')
          .doc(verseKey)
          .set({
        ...verseData,
        'cachedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error caching verse: $e. Classified as: $errorType');
    }
  }

  Future<void> cacheBulkVerses(Map<String, Map<String, dynamic>> verses) async {
    try {
      final batch = _db.batch();

      verses.forEach((verseKey, verseData) {
        final docRef = _db.collection('quran_cache').doc(verseKey);
        batch.set(docRef, {
          ...verseData,
          'cachedAt': FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error in bulk caching: $e. Classified as: $errorType');
    }
  }

  Future<void> clearOldCache() async {
    try {
      final cutoff = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7))
      );

      final oldCacheDocs = await _db.collection('quran_cache')
          .where('cachedAt', isLessThan: cutoff)
          .get();

      final batch = _db.batch();
      for (var doc in oldCacheDocs.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error clearing old cache: $e. Classified as: $errorType');
    }
  }

  Future<void> checkAndMigrateHistoryData() async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();

      final snapshot = await _db.collection('qa_history')
          .limit(100)
          .get();

      print('Found ${snapshot.docs.length} history records to check');

      int migratedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('deviceId')) {
          await _db.collection('qa_history')
              .doc(doc.id)
              .update({'deviceId': deviceId});
          migratedCount++;
        }
      }

      print('Migrated $migratedCount records to include deviceId');

      final deviceSnapshot = await _db.collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .limit(5)
          .get();

      print('After migration, found ${deviceSnapshot.docs.length} records for current device');
    } catch (e) {
      final errorType = _classifyFirestoreError(e);
      print('Error checking/migrating history data: $e. Classified as: $errorType');
    }
  }
}