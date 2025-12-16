import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/health_record.dart';
import 'data/health_data_source.dart';

class HealthDatabase implements HealthDataSource {
  static final HealthDatabase instance = HealthDatabase._init();
  static Database? _database;

  HealthDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_records.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add UNIQUE constraint by recreating table
      await db.execute('''
        CREATE TABLE health_records_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          steps INTEGER NOT NULL,
          calories INTEGER NOT NULL,
          water INTEGER NOT NULL
        )
      ''');
      
      // Copy data, handling duplicates by keeping the first one
      await db.execute('''
        INSERT INTO health_records_new (id, date, steps, calories, water)
        SELECT id, date, steps, calories, water
        FROM health_records
        WHERE id IN (
          SELECT MIN(id) FROM health_records GROUP BY date
        )
      ''');
      
      await db.execute('DROP TABLE health_records');
      await db.execute('ALTER TABLE health_records_new RENAME TO health_records');
    }
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    final db = await instance.database;
    final res = await db.query(
      'health_records',
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );
    if (res.isEmpty) return null;
    return HealthRecord.fromMap(res.first);
  }

  @override
  Future<HealthRecord> create(HealthRecord record) async {
    final db = await instance.database;
    try {
      final id = await db.insert('health_records', record.toMap());
      return record.copyWith(id: id);
    } on DatabaseException catch (e) {
      // Check for UNIQUE constraint violation (SQLite error code 2067)
      if (e.toString().contains('UNIQUE constraint') || 
          e.toString().contains('2067') ||
          e.toString().contains('unique')) {
        throw Exception('A record for this date already exists.');
      }
      rethrow;
    }
  }

  @override
  Future<List<HealthRecord>> readAll() async {
    final db = await instance.database;
    final res = await db.query('health_records', orderBy: 'date DESC');
    return res.map((e) => HealthRecord.fromMap(e)).toList();
  }

  @override
  Future<List<HealthRecord>> readByDate(String date) async {
    final db = await instance.database;
    final res = await db.query('health_records', where: 'date = ?', whereArgs: [date]);
    return res.map((e) => HealthRecord.fromMap(e)).toList();
  }

  @override
  Future<int> update(HealthRecord record) async {
    final db = await instance.database;
    try {
      // Check if date is being changed and if new date already exists
      final existing = await getRecordByDate(record.date);
      if (existing != null && existing.id != record.id) {
        throw Exception('A record already exists for this day.');
      }
      
      return await db.update(
        'health_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
    } on DatabaseException catch (e) {
      // Check for UNIQUE constraint violation
      if (e.toString().contains('UNIQUE constraint') || 
          e.toString().contains('2067') ||
          e.toString().contains('unique')) {
        throw Exception('A record already exists for this day.');
      }
      rethrow;
    }
  }

  @override
  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> insertDummyDataIfEmpty() async {
    final list = await readAll();
    if (list.isNotEmpty) return;
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    await create(HealthRecord(date: _fmt(today), steps: 5400, calories: 320, water: 1200));
    await create(HealthRecord(date: _fmt(yesterday), steps: 7800, calories: 480, water: 1500));
  }

  String _fmt(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
