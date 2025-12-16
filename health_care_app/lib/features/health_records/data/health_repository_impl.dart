import 'health_repository.dart';

import '../models/health_record.dart';
import 'health_data_source.dart';

class HealthRepositoryImpl implements HealthRepository {
  final HealthDataSource _dataSource;
  HealthRepositoryImpl({HealthDataSource? dataSource}) : _dataSource = dataSource ?? (throw ArgumentError('dataSource is required'));

  @override
  Future<HealthRecord> createRecord(HealthRecord record) async {
    return await _dataSource.create(record);
  }

  @override
  Future<int> deleteRecord(int id) async {
    return await _dataSource.delete(id);
  }

  @override
  Future<List<HealthRecord>> getAllHealthRecords() async {
    return await _dataSource.readAll();
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    return await _dataSource.getRecordByDate(date);
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    return await _dataSource.update(record);
  }

  @override
  Future<void> insertDummyDataIfEmpty() async {
    await _dataSource.insertDummyDataIfEmpty();
  }

  Future<List<HealthRecord>> readByDate(String date) async {
    return await _dataSource.readByDate(date);
  }
}
