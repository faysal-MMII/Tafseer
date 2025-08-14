import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/deviceid_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // FIXED: Clean the verse data before saving
  List<String> _cleanQuranVerses(List<String> verses) {
    return verses.where((verse) => 
      verse.isNotEmpty && 
      !verse.contains('null') && 
      verse != 'null'
    ).map((verse) {
      // Extract just the reference if it's in format "text (reference)"
      final regex = RegExp(r'\(([^)]+)\)$');
      final match = regex.firstMatch(verse);
      if (match != null && match.group(1) != null && match.group(1) != 'null') {
        return match.group(1)!; // Return just "2:255"
      }
      return verse;
    }).toList();
  }

  // FIXED: Clean hadith data before saving
  List<Map<String, dynamic>> _cleanHadiths(List<dynamic> hadiths) {
    return hadiths.where((hadith) => hadith != null).map((hadith) {
      if (hadith is Map<String, dynamic>) {
        // Clean the hadith map
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

      // Check if a similar question already exists
      final existingQuestions = await _db.collection('qa_history')
          .where('deviceId', isEqualTo: deviceId)
          .where('question', isEqualTo: question)
          .get();

      // FIXED: Clean the data before saving
      final cleanVerses = _cleanQuranVerses(quranVerses);
      final cleanHadiths = _cleanHadiths(hadiths);

      if (existingQuestions.docs.isNotEmpty) {
        // Update existing entry
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
        // Create searchable terms from the question
        final searchableTerms = _generateSearchableTerms(question);

        // Save new entry
        await _db.collection('qa_history').add({
          'deviceId': deviceId,
          'question': question,
          'answer': answer,
          'quranVerses': cleanVerses,
          'hadiths': cleanHadiths,
          'searchableTerms': searchableTerms,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print('QA saved successfully with device ID: $deviceId');
        print('Saved ${cleanVerses.length} verses and ${cleanHadiths.length} hadiths');
      }
    } catch (e) {
      print('Error saving QA: $e');
    }
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
      print('Error checking Firestore: $e');
      return null;
    }
  }

  // Quran caching methods
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
      print('Error getting cached verse: $e');
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
      print('Error caching verse: $e');
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
      print('Error in bulk caching: $e');
    }
  }

  Future<void> clearOldCache() async {
    try {
      // Clear cache older than 7 days
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
      print('Error clearing old cache: $e');
    }
  }

  // Method to check and migrate history data
  Future<void> checkAndMigrateHistoryData() async {
    try {
      final String deviceId = await DeviceIDService.getDeviceID();

      // First, check if there are any documents without deviceId
      final snapshot = await _db.collection('qa_history')
          .limit(100)
          .get();

      print('Found ${snapshot.docs.length} history records to check');

      int migratedCount = 0;

      // Check if any documents don't have deviceId field
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('deviceId')) {
          // Update the document to include the device ID
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
      print('Error checking/migrating history data: $e');
    }
  }
}