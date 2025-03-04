import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    return searchableTerms.take(10).toList(); // Limit to avoid too many terms
  }

  Future<void> saveQA({
    required String question,
    required String answer,
    required List<String> quranVerses,
    required List<dynamic> hadiths,
  }) async {
    try {
      // Get current user ID
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      // If not logged in, don't save history (or handle accordingly)
      if (userId == null) {
        print('User not logged in, history not saved');
        return;
      }

      final searchableTerms = _generateSearchableTerms(question);

      await _db.collection('qa_history').add({
        'userId': userId,  // Store the user ID
        'question': question,
        'answer': answer,
        'quranVerses': quranVerses,
        'hadiths': hadiths,
        'searchableTerms': searchableTerms,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
  }

  Future<Map<String, dynamic>?> findSimilarQuestion(String question) async {
    try {
      // Get current user ID
      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      // If not logged in, can't find user-specific questions
      if (userId == null) {
        return null;
      }

      final searchTerms = _generateSearchableTerms(question);

      for (final term in searchTerms) {
        final snapshot = await _db.collection('qa_history')
            .where('userId', isEqualTo: userId)  // Filter by user ID
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

  // New Quran caching methods - INTEGRATED HERE
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

  // New method to check and migrate history data
  Future<void> checkAndMigrateHistoryData() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('No user logged in, cannot check history data');
        return;
      }
      
      // First, check if there are any documents without userId
      final snapshot = await _db.collection('qa_history')
          .limit(100) // Limit to prevent too many reads
          .get();
      
      print('Found ${snapshot.docs.length} history records to check');
      
      int migratedCount = 0;
      
      // Check if any documents don't have userId field
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('userId')) {
          // Update the document to include the current user's ID
          await _db.collection('qa_history')
              .doc(doc.id)
              .update({'userId': userId});
          migratedCount++;
        }
      }
      
      print('Migrated $migratedCount records to include userId');
      
      final userSnapshot = await _db.collection('qa_history')
          .where('userId', isEqualTo: userId)
          .limit(5)
          .get();
      
      print('After migration, found ${userSnapshot.docs.length} records for current user');
      
    } catch (e) {
      print('Error checking/migrating history data: $e');
    }
  }
}