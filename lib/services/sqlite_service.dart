// lib/services/sqlite_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class SQLiteService {
  static final SQLiteService _instance = SQLiteService._internal();
  factory SQLiteService() => _instance;
  static Database? _database;

  SQLiteService._internal() {
    debugPrint('Initializing SQLiteService');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    debugPrint('Creating new database instance');
    _database = await _initDatabase();
    await _insertSampleData(_database!);
    return _database!;
  }

  Future<Database> _initDatabase() async {
    debugPrint('Initializing database');
    final dbPath = await databaseFactory.getDatabasesPath();
    final dbFile = path.join(dbPath, 'hadith.db');
    debugPrint('Database path: $dbFile');
    return await databaseFactory.openDatabase(
      dbFile,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('Creating database tables');
    // Create hadiths table first
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hadiths (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hadith_number TEXT,
        text TEXT NOT NULL,
        keywords TEXT
      )
    ''');
  }

  Future<void> _insertSampleData(Database db) async {
    debugPrint('Checking for existing data');
    final List<Map<String, dynamic>> hadiths = await db.query('hadiths');
    if (hadiths.isNotEmpty) {
      debugPrint('Sample data already exists');
      return;
    }

    debugPrint('Inserting sample data');
    final sampleHadiths = [
      {
        'hadith_number': 'Bukhari 1',
        'text': 'Actions are according to intentions, and everyone will get what was intended.',
        'keywords': 'intentions actions deeds niyyah'
      },
      {
        'hadith_number': 'Bukhari 2',
        'text': 'The best among you are those who learn the Quran and teach it.',
        'keywords': 'quran learning teaching education'
      }
    ];

    for (var hadith in sampleHadiths) {
      await db.insert('hadiths', hadith);
      debugPrint('Inserted hadith: ${hadith['hadith_number']}');
    }
  }

  Future<List<Map<String, dynamic>>> searchHadiths(String query) async {
    debugPrint('Searching for: $query');
    final db = await database;
    final results = await db.query(
      'hadiths',
      where: 'text LIKE ? OR keywords LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    debugPrint('Found ${results.length} results');
    return results;
  }
}