import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import '../models/reading_history.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static sql.Database? _database;

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    final dbPath = await sql.getDatabasesPath();
    final databasePath = path.join(dbPath, 'reading_history.db');

    return await sql.openDatabase(
      databasePath,
      version: 2, // Increment version to update schema
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase, // Add this for migration
    );
  }

  Future<void> _createTables(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE reading_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        userEmail TEXT NOT NULL
      )
    ''');
  }

  // Upgrade database to add userEmail column
  Future<void> _upgradeDatabase(
    sql.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE reading_history ADD COLUMN userEmail TEXT NOT NULL DEFAULT 'default@user.com'
      ''');
    }
  }

  // Add a reading session with user email
  Future<int> addReadingSession(ReadingHistory history) async {
    final db = await database;
    return await db.insert('reading_history', history.toMap());
  }

  // Get all reading sessions for a specific user
  Future<List<ReadingHistory>> getSessionsByUser(String userEmail) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      where: 'userEmail = ?',
      whereArgs: [userEmail],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Get favorite sessions only for a specific user
  Future<List<ReadingHistory>> getFavoriteSessionsByUser(
    String userEmail,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      where: 'isFavorite = ? AND userEmail = ?',
      whereArgs: [1, userEmail],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Update a session (e.g., mark as favorite)
  Future<int> updateSession(ReadingHistory history) async {
    final db = await database;
    return await db.update(
      'reading_history',
      history.toMap(),
      where: 'id = ? AND userEmail = ?',
      whereArgs: [history.id, history.userEmail],
    );
  }

  // Delete a session for specific user
  Future<int> deleteSession(int id, String userEmail) async {
    final db = await database;
    return await db.delete(
      'reading_history',
      where: 'id = ? AND userEmail = ?',
      whereArgs: [id, userEmail],
    );
  }

  // Check if URL already exists for specific user
  Future<ReadingHistory?> getSessionByUrl(String url, String userEmail) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      where: 'url = ? AND userEmail = ?',
      whereArgs: [url, userEmail],
    );
    if (maps.isNotEmpty) {
      return ReadingHistory.fromMap(maps.first);
    }
    return null;
  }

  // Keep these for backward compatibility or remove them
  // Get all reading sessions (all users - for backward compatibility)
  Future<List<ReadingHistory>> getAllReadingSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Get favorite sessions only (all users - for backward compatibility)
  Future<List<ReadingHistory>> getFavoriteSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      where: 'isFavorite = ?',
      whereArgs: [1],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Delete a session (old method - for backward compatibility)
  Future<int> deleteSessionOld(int id) async {
    final db = await database;
    return await db.delete('reading_history', where: 'id = ?', whereArgs: [id]);
  }

  // Check if URL already exists (old method - for backward compatibility)
  Future<ReadingHistory?> getSessionByUrlOld(String url) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      where: 'url = ?',
      whereArgs: [url],
    );
    if (maps.isNotEmpty) {
      return ReadingHistory.fromMap(maps.first);
    }
    return null;
  }
}
