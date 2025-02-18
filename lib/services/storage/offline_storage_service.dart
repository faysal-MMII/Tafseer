import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/offline_response.dart';

class OfflineStorageService {
  static Database? _database;
  static const String tableName = 'offline_responses';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'offline_responses.db');
    print('Offline database path: $path'); // Debug print for database path
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            query TEXT NOT NULL,
            response TEXT NOT NULL,
            type TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            ref_content TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> saveResponse(OfflineResponse response) async {
    final db = await database;
    final map = response.toMap();

    // Debug prints for saving response
    print('Saving offline response:');
    print('Query: ${map['query']}');
    print('Response: ${map['response']}');
    print('Type: ${map['type']}');
    print('References: ${map['ref_content']}');

    await db.insert(
      tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OfflineResponse>> searchResponses(String query, String type) async {
    final db = await database;

    // Debug prints for searching responses
    print('Searching for offline responses:');
    print('Query: $query');
    print('Type: $type');

    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'query LIKE ? AND type = ?',
      whereArgs: ['%$query%', type],
      orderBy: 'timestamp DESC',
    );

    // Debug prints for search results
    print('Found ${maps.length} responses');
    if (maps.isNotEmpty) {
      print('First response: ${maps.first}');
    }

    return List.generate(maps.length, (i) {
      try {
        return OfflineResponse.fromMap(maps[i]);
      } catch (e) {
        print('Error parsing response ${i + 1}: $e'); // Debug print for parsing errors
        rethrow;
      }
    });
  }

  Future<List<OfflineResponse>> getAllResponses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      orderBy: 'timestamp DESC',
    );

    // Debug prints for all responses
    print('Retrieved ${maps.length} responses from the database');

    return List.generate(maps.length, (i) {
      try {
        return OfflineResponse.fromMap(maps[i]);
      } catch (e) {
        print('Error parsing response ${i + 1}: $e'); // Debug print for parsing errors
        rethrow;
      }
    });
  }

  Future<void> deleteResponse(String query, String type) async {
    final db = await database;

    // Debug prints for deleting response
    print('Deleting offline response:');
    print('Query: $query');
    print('Type: $type');

    await db.delete(
      tableName,
      where: 'query = ? AND type = ?',
      whereArgs: [query, type],
    );

    // Debug print for confirmation
    print('Response deleted successfully');
  }
}