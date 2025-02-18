import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;

class QuranLoader {
  static Future<void> loadQuranData() async {
    try {
      // Get database path
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'quran.db');

      // Check if database already exists
      if (await File(path).exists()) {
        print('Quran database already exists');
        return;
      }

      print('Downloading Quran data...');
      
      // Create database
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          // Create tables
          await db.execute('''
            CREATE TABLE verses (
              id INTEGER PRIMARY KEY,
              surah INTEGER NOT NULL,
              ayah INTEGER NOT NULL,
              verse_key TEXT NOT NULL,
              text_uthmani TEXT NOT NULL,
              translation TEXT,
              UNIQUE(surah, ayah)
            )
          ''');

          await db.execute('''
            CREATE VIRTUAL TABLE verse_search 
            USING fts5(
              verse_id UNINDEXED,
              text,
              translation,
              content='verses',
              content_rowid='id'
            )
          ''');
        },
      );

      // Load data from bundled JSON file
      final String jsonData = await rootBundle.loadString('assets/data/quran.json');
      final quranData = json.decode(jsonData);

      // Begin transaction for faster insertion
      await db.transaction((txn) async {
        int verseId = 1;
        
        // For each surah
        for (var surah = 1; surah <= 114; surah++) {
          final surahData = quranData[surah.toString()];
          final verses = surahData['verses'];
          
          // For each verse in surah
          for (var ayah = 1; ayah <= verses.length; ayah++) {
            final verse = verses[ayah.toString()];
            final verseKey = '$surah:$ayah';
            
            // Insert verse data
            await txn.insert('verses', {
              'id': verseId,
              'surah': surah,
              'ayah': ayah,
              'verse_key': verseKey,
              'text_uthmani': verse['arabic'],
              'translation': verse['translation'],
            });

            // Insert search data
            await txn.insert('verse_search', {
              'verse_id': verseId,
              'text': verse['arabic'],
              'translation': verse['translation'],
            });

            verseId++;
          }
          
          // Progress update
          print('Loaded Surah $surah');
        }
      });

      print('Quran data loaded successfully');

    } catch (e) {
      print('Error loading Quran data: $e');
      rethrow;
    }
  }

  // Helper method to download and save Quran text file
  static Future<void> _downloadFile(String url, String savePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await File(savePath).writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      print('Error downloading file: $e');
      rethrow;
    }
  }

  // Helper method to check if database needs update
  static Future<bool> needsUpdate() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran.db');
    return !await File(path).exists();
  }
}
