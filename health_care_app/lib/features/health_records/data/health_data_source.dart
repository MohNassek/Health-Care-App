import '../models/health_record.dart';

abstract class HealthDataSource {
  Future<HealthRecord> create(HealthRecord record);
  Future<List<HealthRecord>> readAll();
  Future<HealthRecord?> getRecordByDate(String date);
  Future<int> update(HealthRecord record);
  Future<int> delete(int id);
  Future<void> insertDummyDataIfEmpty();
  Future<List<HealthRecord>> readByDate(String date);
}
