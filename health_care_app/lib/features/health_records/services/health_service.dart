import '../models/health_record.dart';
import '../health_db.dart';

class HealthService {
  final HealthDatabase _db;
  HealthService({HealthDatabase? db}) : _db = db ?? HealthDatabase.instance;

  Future<List<HealthRecord>> getAll() => _db.readAll();
  Future<HealthRecord?> getByDate(String date) => _db.getRecordByDate(date);
  Future<HealthRecord> create(HealthRecord record) => _db.create(record);
  Future<int> update(HealthRecord record) => _db.update(record);
  Future<int> delete(int id) => _db.delete(id);
  Future<void> insertDummyDataIfEmpty() => _db.insertDummyDataIfEmpty();
  Future<List<HealthRecord>> readByDate(String date) => _db.readByDate(date);
}
