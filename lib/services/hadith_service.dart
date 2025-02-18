import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/hadith.dart';
import 'user_interaction_service.dart';

class HadithService {
  static final HadithService _instance = HadithService._internal();
  static Database? _database;
  static bool _initialized = false;
  late UserInteractionService userInteractionService;

  // New: Static map to hold Hadith data from JSON
  static Map<String, dynamic>? _hadithData;

  factory HadithService([Database? existingDb]) {
    if (existingDb != null) {
      _database = existingDb;
      _initialized = true;
    }
    return _instance;
  }

  HadithService._internal();

  // New: Load Hadith data from JSON file
  Future<void> loadHadithData() async {
    if (_hadithData != null) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/nawawi.json');
      _hadithData = json.decode(jsonString);
    } catch (e) {
      print('Error loading Hadith data: $e');
      throw Exception('Failed to load Hadith data');
    }
  }

  // New: Fetch a specific Hadith by number
  Future<Hadith> fetchHadith(int number) async {
    await loadHadithData();  // Changed from _loadHadithData

    try {
      final hadithList = _hadithData!['hadiths']['hadiths'] as List;
      final hadithData = hadithList.firstWhere(
        (h) => h['hadith'] == number,
        orElse: () => throw Exception('Hadith not found'),
      );

      return Hadith.fromMap({
        'id': hadithData['hadith'],
        'collection_id': 1, // Nawawi collection
        'chapter_id': 1,    // Default chapter
        'hadith_number': hadithData['hadith'].toString(),
        'text': hadithData['text'],
        'arabic_text': null,
        'grade': null,
        'narrator': null,
        'keywords': null,
      });
    } catch (e) {
      print('Error fetching hadith $number: $e');
      throw Exception('Failed to fetch hadith');
    }
  }

  // New: Search Hadiths by query
  Future<List<Hadith>> searchHadith(String query) async {
    await loadHadithData();  // Changed from _loadHadithData

    try {
      final hadithList = _hadithData!['hadiths']['hadiths'] as List;
      return hadithList
          .where((h) => h['text'].toLowerCase().contains(query.toLowerCase()))
          .map((h) => Hadith.fromMap({
                'id': h['hadith'],
                'collection_id': 1,
                'chapter_id': 1,
                'hadith_number': h['hadith'].toString(),
                'text': h['text'],
                'arabic_text': null,
                'grade': null,
                'narrator': null,
                'keywords': null,
              }))
          .toList();
    } catch (e) {
      print('Error searching hadiths: $e');
      return [];
    }
  }

  // New: Get collection name
  String getCollectionName() {
    return _hadithData?['hadiths']['collection'] ?? 'Forty Hadith of Imam Nawawi';
  }

  // Existing methods for database operations
  void initializeUserInteraction(Database db) {
    userInteractionService = UserInteractionService(database: db);
  }

  Database? get databaseInstance => _database;

  Future<void> _ensureTableExists(Database db) async {
    print('Checking for hadiths table...');
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

    await db.execute(''' 
      CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
        text,
        content='hadiths',
        content_rowid='id'
      )
    ''');

    final ftsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM hadiths_fts')
    ) ?? 0;

    final mainCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM hadiths')
    ) ?? 0;

    if (ftsCount == 0 && mainCount > 0) {
      print('Populating FTS table...');
      await db.execute(''' 
        INSERT INTO hadiths_fts(rowid, text)
        SELECT id, text FROM hadiths
      ''');
    }

    print('Tables initialized. Main table count: $mainCount, FTS table count: $ftsCount');
  }

  Future<void> _populateFTSTable(Database db) async {
    try {
      final ftsExists = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hadiths_fts'"
      );

      if (ftsExists.isEmpty) {
        print('Creating FTS table...');
        await db.execute(''' 
          CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
            text,
            content='hadiths',
            content_rowid='id'
          );
        ''');
      }

      final ftsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hadiths_fts')
      ) ?? 0;
      
      final mainCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hadiths')
      ) ?? 0;

      print('FTS count: $ftsCount, Main table count: $mainCount');

      if (ftsCount != mainCount) {
        print('Rebuilding FTS table...');
        await db.transaction((txn) async {
          await txn.execute('DELETE FROM hadiths_fts');
          await txn.execute(''' 
            INSERT INTO hadiths_fts(rowid, text)
            SELECT id, text FROM hadiths
          ''');
        });
        
        final newCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM hadiths_fts')
        ) ?? 0;
        print('FTS table rebuilt. New count: $newCount');
      }
    } catch (e) {
      print('Error in _populateFTSTable: $e');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (!_initialized && (Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }

    final dbPath = join(Directory.current.path, 'data', 'hadith.db');
    print('📂 Database path: $dbPath');

    try {
      final exists = await databaseExists(dbPath);
      print('Database exists: $exists');

      if (!exists || await File(dbPath).length() == 0) {
        print('Database missing or empty, recreating...');
        await recreateDatabase(dbPath);
      }

      _database = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          print('Creating database for first time...');
          await _ensureTableExists(db);
          initializeUserInteraction(db);
          await userInteractionService.initializeTable();
        },
        onOpen: (Database db) async {
          print('Database opened, checking structure...');
          await _ensureTableExists(db);
          initializeUserInteraction(db);
          await userInteractionService.initializeTable();

          final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM hadiths')
          );
          print('Hadiths count: $count');
        },
      );

      print('✅ Database opened successfully');
      return _database!;
    } catch (e) {
      print('❌ Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> recreateDatabase(String path) async {
    try {
      print('📁 Starting database recreation at path: $path');

      if (await File(path).exists()) {
        await File(path).delete();
        print('🗑️ Deleted existing database file');
      }

      final directory = Directory(dirname(path));
      await directory.create(recursive: true);
      print('📂 Created directory: ${directory.path}');

      final assetPath = join("assets", "data", "hadith.db");
      print('📂 Loading asset from: $assetPath');

      try {
        final ByteData data = await rootBundle.load(assetPath);
        print('✅ Loaded asset, size: ${data.lengthInBytes} bytes');

        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);

        final newFile = File(path);
        print('✅ New database file created, size: ${await newFile.length()} bytes');
      } catch (e) {
        print('❌ Error loading asset: $e');
        rethrow;
      }
    } catch (e) {
      print('❌ Error recreating database: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<List<Hadith>> searchHadiths(String query) async {
    if (query.isEmpty) return [];

    final db = await database;
    print('🔍 Starting search for query: $query');

    try {
      List<Map<String, dynamic>> results = await db.rawQuery(''' 
        SELECT h.*, json_extract(h.hadith_number, '\$') as hadith_number
        FROM hadiths h
        JOIN hadiths_fts f ON h.id = f.rowid
        WHERE hadiths_fts MATCH ?
        ORDER BY rank
        LIMIT 10
      ''', ['"$query"']);
      
      print("First result raw: ${results.firstOrNull}");
      print("hadith_number type: ${results.firstOrNull?['hadith_number']?.runtimeType}");
      print("===========================\n");

      return _convertToHadiths(results);
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  List<Hadith> _convertToHadiths(List<Map<String, dynamic>> maps) {
    maps.forEach((map) {
      print('\n--- DEBUG MAP ---');
      print('Raw map: $map');
      print('hadith_number type: ${map['hadith_number'].runtimeType}');
      print('hadith_number value: ${map['hadith_number']}');
      print('----------------\n');
    });

    return maps.map((map) {
      try {
        return Hadith(
          id: map['id'] ?? 0,
          collectionId: map['collection_id'] ?? 0,
          chapterId: map['chapter_id'] ?? 0,
          hadithNumber: HadithNumber.fromDynamic(map['hadith_number']),
          text: map['text']?.toString() ?? '',
          arabicText: map['arabic_text']?.toString(),
          grade: map['grade']?.toString(),
          narrator: map['narrator']?.toString(),
          keywords: map['keywords']?.toString(),
        );
      } catch (e) {
        print('Error converting map to Hadith: $e');
        print('Problematic map: $map');
        return Hadith(
          id: map['id'] ?? 0,
          collectionId: map['collection_id'] ?? 0,
          chapterId: map['chapter_id'] ?? 0,
          hadithNumber: HadithNumber(book: 0, hadith: 0),
          text: map['text']?.toString() ?? '',
        );
      }
    }).toList();
  }

  Future<void> validateDatabaseState() async {
    final db = await database;
    try {
      var tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hadiths'"
      );
      
      if (tables.isEmpty) {
        print('Table not found, creating it...');
        await _ensureTableExists(db);
      }

      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hadiths')
      );
      print('Current hadith count: $count');

      if (count == 0) {
        print('No data found, inserting sample data...');
        await _ensureTableExists(db);
      }

      var hasFTS = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='hadiths_fts'"
      );
      
      if (hasFTS.isEmpty) {
        print('FTS table missing, recreating...');
        await db.execute(''' 
          CREATE VIRTUAL TABLE IF NOT EXISTS hadiths_fts USING fts5(
            text,
            content='hadiths',
            content_rowid='id'
          )
        ''');
      }
      
      await _populateFTSTable(db);
      
    } catch (e) {
      print('Database validation error: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> debugDatabase() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hadiths'));
    print('Total hadiths in database: $count');

    final ftsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM hadiths_fts'));
    print('Total hadiths in FTS index: $ftsCount');
  }
}