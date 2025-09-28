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
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE reading_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Add a reading session
  Future<int> addReadingSession(ReadingHistory history) async {
    final db = await database;
    return await db.insert('reading_history', history.toMap());
  }

  // Get all reading sessions
  Future<List<ReadingHistory>> getAllReadingSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reading_history',
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => ReadingHistory.fromMap(maps[i]));
  }

  // Get favorite sessions only
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

  // Update a session (e.g., mark as favorite)
  Future<int> updateSession(ReadingHistory history) async {
    final db = await database;
    return await db.update(
      'reading_history',
      history.toMap(),
      where: 'id = ?',
      whereArgs: [history.id],
    );
  }

  // Delete a session
  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete('reading_history', where: 'id = ?', whereArgs: [id]);
  }

  // Check if URL already exists
  Future<ReadingHistory?> getSessionByUrl(String url) async {
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
