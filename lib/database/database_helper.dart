import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class DatabaseHelper {
  static Future<Database> initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'data', 'hadith.db');

    await Directory(p.dirname(path)).create(recursive: true);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create hadiths table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS hadiths (
            id INTEGER PRIMARY KEY,
            collection_id INTEGER,
            chapter_id INTEGER,
            hadith_number TEXT,
            text TEXT,
            arabic_text TEXT,
            grade TEXT,
            narrator TEXT,
            keywords TEXT
          )
        ''');

        // Create bookmarks table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            content_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(user_id, content_type, content_id)
          )
        ''');

        // Create reading history table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reading_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            content_type TEXT NOT NULL,
            content_id TEXT NOT NULL,
            read_count INTEGER DEFAULT 1,
            last_read TEXT NOT NULL,
            UNIQUE(user_id, content_type, content_id)
          )
        ''');
      },
    );
  }
}
