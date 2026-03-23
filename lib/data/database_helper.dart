import 'package:btl_nhom_15/model/lunar_event.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lunar_event.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE lunar_events(
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT    NOT NULL,
        description TEXT    DEFAULT '',
        date        TEXT    NOT NULL,
        isLunar     INTEGER NOT NULL DEFAULT 0,
        isYearly    INTEGER NOT NULL DEFAULT 0,
        startTime   TEXT    DEFAULT '',
        endTime     TEXT    DEFAULT '',
        location    TEXT    DEFAULT '',
        color       TEXT    DEFAULT '#1A3A4A',
        repeatType  TEXT    DEFAULT 'none',
        reminders   TEXT    DEFAULT '[1440]'
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE lunar_events ADD COLUMN isYearly INTEGER NOT NULL DEFAULT 0",
      );
    }
    if (oldVersion < 3) {
      for (final sql in [
        "ALTER TABLE lunar_events ADD COLUMN startTime TEXT DEFAULT ''",
        "ALTER TABLE lunar_events ADD COLUMN endTime TEXT DEFAULT ''",
        "ALTER TABLE lunar_events ADD COLUMN location TEXT DEFAULT ''",
        "ALTER TABLE lunar_events ADD COLUMN color TEXT DEFAULT '#1A3A4A'",
        "ALTER TABLE lunar_events ADD COLUMN repeatType TEXT DEFAULT 'none'",
        "ALTER TABLE lunar_events ADD COLUMN reminders TEXT DEFAULT '[1440]'",
      ]) {
        try {
          await db.execute(sql);
        } catch (_) {}
      }
    }
  }

  Future<int> insertEvent(LunarEvent event) async {
    final db = await instance.database;
    return await db.insert('lunar_events', event.toMap());
  }

  Future<List<LunarEvent>> getAllEvents() async {
    final db = await instance.database;
    final result = await db.query(
      'lunar_events',
      orderBy: 'date ASC, startTime ASC',
    );
    return result.map((m) => LunarEvent.fromMap(m)).toList();
  }

  Future<int> updateEvent(LunarEvent event) async {
    final db = await instance.database;
    return await db.update(
      'lunar_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await instance.database;
    return await db.delete('lunar_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<LunarEvent>> searchEvents(String query) async {
    final db = await instance.database;
    final result = await db.query(
      'lunar_events',
      where: 'title LIKE ? OR description LIKE ? OR location LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'date ASC',
    );
    return result.map((m) => LunarEvent.fromMap(m)).toList();
  }

  Future<Map<String, int>> getMonthStats(int year, int month) async {
    final db = await instance.database;
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery('''
      SELECT isLunar, COUNT(*) as count FROM lunar_events
      WHERE date LIKE '$monthStr%' GROUP BY isLunar
    ''');
    int lunarCount = 0, solarCount = 0;
    for (final row in result) {
      if (row['isLunar'] == 1)
        lunarCount = row['count'] as int;
      else
        solarCount = row['count'] as int;
    }
    return {'lunar': lunarCount, 'solar': solarCount};
  }
}
