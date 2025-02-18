import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class UserInteractionService {
  final Database database;
  static const String DEFAULT_USER_ID = 'default_user';
  static UserInteractionService? _instance;
  bool _isInitialized = false;

  // Private constructor
  UserInteractionService._({required this.database});

  // Factory constructor for singleton pattern
  factory UserInteractionService({required Database database}) {
    _instance ??= UserInteractionService._(database: database);
    return _instance!;
  }

  // Original method - keep this named exactly as initializeTable
  Future<void> initializeTable() async {
    if (_isInitialized) {
      print('UserInteractionService already initialized');
      return;
    }

    print('Starting UserInteractionService initialization...');
    await _createTables();
    _isInitialized = true;
    print('UserInteractionService initialization completed');
  }

  Future<void> _createTables() async {
    // Create tables in a transaction to ensure atomicity
    await database.transaction((txn) async {
      // Create user_history table first
      print('Creating user_history table...');
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS user_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          content_type TEXT NOT NULL,
          content_id TEXT NOT NULL,
          is_bookmarked INTEGER DEFAULT 0,
          last_read INTEGER NOT NULL,
          read_count INTEGER DEFAULT 1
        )
      ''');
      print('user_history table created successfully');

      // Create bookmarks table
      print('Creating bookmarks table...');
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS bookmarks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL DEFAULT 1,
          content_type TEXT NOT NULL,
          content_id TEXT NOT NULL,
          created_at TIMESTAMP NOT NULL DEFAULT (datetime('now')),
          UNIQUE(user_id, content_type, content_id)
        )
      ''');
      print('bookmarks table created successfully');

      // Create indices
      print('Creating index on user_history...');
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_user_content ON user_history(user_id, content_type, content_id)'
      );
      print('Index created successfully');
    });
  }

  // Bookmark-related methods
  Future<void> addBookmark({
    required String contentType,
    required String contentId,
    int userId = 1,
  }) async {
    try {
      await database.insert(
        'bookmarks',
        {
          'user_id': userId,
          'content_type': contentType,
          'content_id': contentId,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error adding bookmark: $e');
      rethrow;
    }
  }

  Future<void> removeBookmark({
    required String contentType,
    required String contentId,
    int userId = 1,
  }) async {
    try {
      await database.delete(
        'bookmarks',
        where: 'content_type = ? AND content_id = ? AND user_id = ?',
        whereArgs: [contentType, contentId, userId],
      );
    } catch (e) {
      print('Error removing bookmark: $e');
      rethrow;
    }
  }

  Future<bool> isBookmarked({
    required String contentType,
    required String contentId,
    int userId = 1,
  }) async {
    try {
      print('DEBUG: Checking bookmark status for $contentType - $contentId');
      final result = await database.query(
        'bookmarks',
        where: 'content_type = ? AND content_id = ? AND user_id = ?',
        whereArgs: [contentType, contentId, userId],
        limit: 1,
      );
      print('DEBUG: Bookmark check completed. Result: ${result.isNotEmpty}');
      return result.isNotEmpty;
    } catch (e) {
      print('ERROR: Failed to check bookmark status: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBookmarks({
    required String contentType,
    int userId = 1,
  }) async {
    try {
      print('DEBUG: Fetching bookmarks for $contentType');
      final bookmarks = await database.query(
        'bookmarks',
        where: 'content_type = ? AND user_id = ?',
        whereArgs: [contentType, userId],
        orderBy: 'created_at DESC',
      );
      print('DEBUG: Retrieved ${bookmarks.length} bookmarks');
      return bookmarks;
    } catch (e) {
      print('ERROR: Failed to fetch bookmarks: $e');
      return [];
    }
  }

  // Method to check bookmark status with error handling
  Future<bool> checkBookmarkStatus({
    required String contentType,
    required String contentId,
    int userId = 1,
  }) async {
    print('DEBUG: Checking bookmark status for $contentType - $contentId');
    if (database == null) {
      print('ERROR: Database is not initialized');
      return false;
    }

    try {
      final result = await database.query(
        'bookmarks',
        where: 'content_type = ? AND content_id = ? AND user_id = ?',
        whereArgs: [contentType, contentId, userId],
        limit: 1,
      );
      print('DEBUG: Bookmark check completed. Result: ${result.isNotEmpty}');
      return result.isNotEmpty;
    } catch (e) {
      print('ERROR: Failed to check bookmark status: $e');
      return false;
    }
  }
}