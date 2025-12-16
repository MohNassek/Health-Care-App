import '../models/health_record.dart';

abstract class HealthRepository {
  Future<List<HealthRecord>> getAllHealthRecords();
  Future<HealthRecord?> getRecordByDate(String date);
  Future<HealthRecord> createRecord(HealthRecord record);
  Future<int> updateRecord(HealthRecord record);
  Future<int> deleteRecord(int id);
  Future<void> insertDummyDataIfEmpty();
}
