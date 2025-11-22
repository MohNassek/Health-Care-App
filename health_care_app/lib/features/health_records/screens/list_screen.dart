import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../health_provider.dart';
import '../health_record.dart';
import 'add_edit_screen.dart';
import '../../../utils/colors.dart';
import '../../../utils/dimens.dart';
import '../../../utils/snackbar_helper.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  String? _filterDate;
  Timer? _debounceTimer;
  bool _isFiltered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final dt = await showDatePicker(
      context: context,
      initialDate: _filterDate != null
          ? DateTime.parse(_filterDate!)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (dt != null) {
      _debounceSearch(_fmt(dt));
    }
  }

  void _debounceSearch(String date) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _filterDate = date;
        _isFiltered = true;
      });
    });
  }

  void _clearFilter() {
    setState(() {
      _filterDate = null;
      _isFiltered = false;
    });
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Are you sure you want to delete the record for ${record.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final prov = Provider.of<HealthProvider>(context, listen: false);
      final success = await prov.deleteRecord(record.id!);
      if (success) {
        SnackbarHelper.showSuccess(context, 'Record deleted successfully');
      } else {
        SnackbarHelper.showError(context, prov.error ?? 'Unable to delete record');
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool _isTodayRecord(HealthRecord record) {
    final today = DateTime.now();
    final todayStr = _formatDate(today);
    return record.date == todayStr;
  }

  Future<void> _editRecord(HealthRecord record) async {
    // Only allow editing today's record
    if (!_isTodayRecord(record)) {
      SnackbarHelper.showWarning(
        context,
        'You can only edit today\'s record. Past records cannot be modified.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(record: record)),
    );
    final prov = Provider.of<HealthProvider>(context, listen: false);
    await prov.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<HealthProvider>(context);
    final allRecords = prov.records;
    final displayRecords = _isFiltered && _filterDate != null
        ? allRecords.where((r) => r.date == _filterDate).toList()
        : allRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Records'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.search),
            tooltip: 'Search by date',
          ),
          if (_isFiltered)
            IconButton(
              onPressed: _clearFilter,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear filter',
            ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : displayRecords.isEmpty
              ? _buildEmptyState(_isFiltered)
              : ListView.builder(
                  padding: const EdgeInsets.all(Dimens.paddingMedium),
                  itemCount: displayRecords.length,
                  itemBuilder: (context, idx) {
                    final r = displayRecords[idx];
                    return _buildRecordCard(r, idx);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add');
          await prov.loadAll();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _buildEmptyState(bool isFiltered) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimens.paddingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: Dimens.spacingLarge),
            Text(
              isFiltered ? 'No matches for this day.' : 'No Records Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: Dimens.spacingSmall),
            Text(
              isFiltered
                  ? 'Try selecting a different date.'
                  : 'Start by adding your first health record.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(HealthRecord record, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: Dimens.spacingMedium),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimens.radiusLarge),
        ),
        child: Dismissible(
          key: Key('record_${record.id}'),
          direction: _isTodayRecord(record)
              ? DismissDirection.horizontal
              : DismissDirection.endToStart, // Only allow delete swipe for non-today records
          background: _isTodayRecord(record)
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(Dimens.radiusLarge),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: Dimens.paddingLarge),
                  child: const Icon(Icons.edit, color: Colors.white, size: 28),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(Dimens.radiusLarge),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: Dimens.paddingLarge),
                  child: const Icon(Icons.lock_outline, color: Colors.white, size: 28),
                ),
          secondaryBackground: Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(Dimens.radiusLarge),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: Dimens.paddingLarge),
            child: const Icon(Icons.delete, color: Colors.white, size: 28),
          ),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd && _isTodayRecord(record)) {
              _editRecord(record);
            } else if (direction == DismissDirection.endToStart) {
              _deleteRecord(record);
            }
          },
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              // Only allow edit swipe for today's record
              if (!_isTodayRecord(record)) {
                SnackbarHelper.showWarning(
                  context,
                  'You can only edit today\'s record.',
                );
                return false;
              }
              return true;
            } else if (direction == DismissDirection.endToStart) {
              return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Record'),
                      content: Text('Delete record for ${record.date}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            }
            return false;
          },
          child: InkWell(
            onTap: () => _editRecord(record),
            borderRadius: BorderRadius.circular(Dimens.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.all(Dimens.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: _isTodayRecord(record)
                                ? AppColors.primary
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            record.date,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isTodayRecord(record)) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Editable',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_isFiltered && _filterDate == record.date)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Match',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Dimens.spacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          Icons.directions_walk,
                          '${record.steps}',
                          'Steps',
                          AppColors.stepsColor,
                        ),
                      ),
                      const SizedBox(width: Dimens.spacingSmall),
                      Expanded(
                        child: _buildMetricItem(
                          Icons.local_fire_department,
                          '${record.calories}',
                          'Calories',
                          AppColors.caloriesColor,
                        ),
                      ),
                      const SizedBox(width: Dimens.spacingSmall),
                      Expanded(
                        child: _buildMetricItem(
                          Icons.local_drink,
                          '${record.water}',
                          'ml',
                          AppColors.waterColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimens.paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimens.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
