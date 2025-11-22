import 'package:flutter/material.dart';
import 'health_db.dart';
import 'health_record.dart';

class HealthProvider with ChangeNotifier {
  final HealthDatabase _db = HealthDatabase.instance;
  List<HealthRecord> _records = [];
  List<HealthRecord> get records => _records;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // Cache for today's summary
  Map<String, int>? _todaySummaryCache;
  DateTime? _cacheDate;

  Future<void> init() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _db.insertDummyDataIfEmpty();
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
      _records = await _db.readAll();
      _invalidateCache();
      notifyListeners();
    } catch (e) {
      _error = 'Unable to load records.';
      notifyListeners();
    }
  }

  Future<bool> checkDateExists(String date) async {
    try {
      final record = await _db.getRecordByDate(date);
      return record != null;
    } catch (e) {
      return false;
    }
  }

  Future<HealthRecord?> getRecordByDate(String date) async {
    try {
      return await _db.getRecordByDate(date);
    } catch (e) {
      return null;
    }
  }

  Future<bool> addRecord(HealthRecord r) async {
    try {
      _error = null;
      // Check if date already exists
      final exists = await checkDateExists(r.date);
      if (exists) {
        _error = 'A record for this date already exists. You can only add one entry per day.';
        notifyListeners();
        return false;
      }

      final created = await _db.create(r);
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
      // Check if date is being changed to an existing date
      final existing = await getRecordByDate(r.date);
      if (existing != null && existing.id != r.id) {
        _error = 'A record already exists for this day. Please select another date.';
        notifyListeners();
        return false;
      }

      await _db.update(r);
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
      await _db.delete(id);
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

  Future<List<HealthRecord>> searchByDate(String date) async {
    try {
      return await _db.readByDate(date);
    } catch (e) {
      return [];
    }
  }

  Map<String, int> getTodaySummary() {
    final today = DateTime.now();
    final todayStr = _formatDate(today);

    // Check cache
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
