import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuranDatabase {
  static final QuranDatabase _instance = QuranDatabase._internal();
  factory QuranDatabase() => _instance;
  static Database? _database;

  QuranDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create verses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS verses (
        id INTEGER PRIMARY KEY,
        surah INTEGER NOT NULL,
        ayah INTEGER NOT NULL,
        verse_key TEXT NOT NULL,
        text_uthmani TEXT NOT NULL,
        translation TEXT,
        transliteration TEXT,
        UNIQUE(surah, ayah)
      )
    ''');

    // Create search index
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS verse_search 
      USING fts5(
        verse_id UNINDEXED,
        text,
        translation,
        content='verses',
        content_rowid='id'
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT v.*
      FROM verses v
      JOIN verse_search vs ON v.id = vs.verse_id
      WHERE vs.text MATCH ? OR vs.translation MATCH ?
      ORDER BY rank
      LIMIT 5
    ''', [query, query]);
  }
}
