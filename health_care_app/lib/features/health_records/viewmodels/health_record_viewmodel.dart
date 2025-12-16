import 'package:flutter/material.dart';
import '../models/health_record.dart';
import '../services/health_service.dart';

class HealthRecordViewModel with ChangeNotifier {
  final HealthService _service;
  HealthRecordViewModel({required HealthService service}) : _service = service;

  List<HealthRecord> _records = [];
  List<HealthRecord> get records => _records;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Map<String, int>? _todaySummaryCache;
  DateTime? _cacheDate;

  Future<void> init() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _service.insertDummyDataIfEmpty();
      await loadAll();
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      _error = 'Database error occurred.';
      notifyListeners();
    }
  }

  Future<void> loadAll() async {
    try {
      _error = null;
      _records = await _service.getAll();
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      _error = 'Unable to load records.';
      notifyListeners();
    }
  }

  Future<bool> checkDateExists(String date) async {
    try {
      final record = await _service.getByDate(date);
      return record != null;
    } catch (e) {
      return false;
    }
  }

  Future<HealthRecord?> getRecordByDate(String date) async {
    try {
      return await _service.getByDate(date);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addRecord(HealthRecord r) async {
    try {
      _error = null;
      final exists = await checkDateExists(r.date);
      if (exists) {
        _error = 'A record for this date already exists. You can only add one entry per day.';
        notifyListeners();
        return false;
      }

      final created = await _service.create(r);
      _records.insert(0, created);
      _invalidateCache();
      notifyListeners();
      return true;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        _error = 'A record for this date already exists. You can only add one entry per day.';
      } else {
        _error = 'Unable to save record.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(HealthRecord r) async {
    try {
      _error = null;
      // Only today's record may be edited
      if (!_isTodayDate(r.date)) {
        _error = 'Only today\'s record can be edited.';
        notifyListeners();
        return false;
      }
      final existing = await getRecordByDate(r.date);
      if (existing != null && existing.id != r.id) {
        _error = 'A record already exists for this day. Please select another date.';
        notifyListeners();
        return false;
      }

      await _service.update(r);
      final idx = _records.indexWhere((e) => e.id == r.id);
      if (idx != -1) {
        _records[idx] = r;
        _invalidateCache();
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (e.toString().contains('already exists')) {
        _error = 'A record already exists for this day. Please select another date.';
      } else {
        _error = 'Record cannot be updated.';
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(int id) async {
    try {
      _error = null;
      // Allow deletion only for today's record
      final rec = _records.firstWhere((e) => e.id == id, orElse: () => HealthRecord(date: '', steps: 0, calories: 0, water: 0));
      if (rec.id == null || !_isTodayDate(rec.date)) {
        _error = 'Only today\'s record can be deleted.';
        notifyListeners();
        return false;
      }
      await _service.delete(id);
      _records.removeWhere((e) => e.id == id);
      _invalidateCache();
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Unable to delete record.';
      notifyListeners();
      return false;
    }
  }

  bool _isTodayDate(String dateStr) {
    try {
      final today = DateTime.now();
      final todayStr = _formatDate(today);
      return dateStr == todayStr;
    } catch (e) {
      return false;
    }
  }

  Future<List<HealthRecord>> searchByDate(String date) async {
    try {
      return await _service.readByDate(date);
    } catch (e) {
      return [];
    }
  }

  Map<String, int> getTodaySummary() {
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    if (_todaySummaryCache != null &&
        _cacheDate != null &&
        _cacheDate!.year == today.year &&
        _cacheDate!.month == today.month &&
        _cacheDate!.day == today.day) {
      return _todaySummaryCache!;
    }

    final todays = _records.where((r) => r.date == todayStr).toList();
    final summary = {
      'water': todays.fold<int>(0, (p, e) => p + e.water),
      'steps': todays.fold<int>(0, (p, e) => p + e.steps),
      'calories': todays.fold<int>(0, (p, e) => p + e.calories),
    };

    _todaySummaryCache = summary;
    _cacheDate = today;
    return summary;
  }

  void _invalidateCache() {
    _todaySummaryCache = null;
    _cacheDate = null;
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
