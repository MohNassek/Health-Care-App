import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../health_provider.dart';
import '../health_record.dart';
import 'list_screen.dart';
import 'add_edit_screen.dart';
import '../../../utils/colors.dart';
import '../../../utils/dimens.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/primary_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<HealthProvider>(context);
    final summary = prov.getTodaySummary();
    final today = DateTime.now();
    final todayStr = _formatDate(today);
    final todayRecord = prov.records.firstWhere(
      (r) => r.date == todayStr,
      orElse: () => HealthRecord(date: '', steps: 0, calories: 0, water: 0),
    );
    final hasTodayRecord = todayRecord.id != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthMate Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListScreen()),
            ),
            tooltip: 'View All Records',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await prov.loadAll();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Dimens.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Today\'s Summary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: Dimens.spacingSmall),
              Text(
                todayStr,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: Dimens.spacingXXLarge),

              // Metrics Cards
              if (hasTodayRecord) ...[
                _buildMetricCard(
                  icon: Icons.directions_walk,
                  title: 'Steps',
                  value: summary['steps'] ?? 0,
                  color: AppColors.stepsColor,
                  bgColor: AppColors.stepsBg,
                  unit: 'steps',
                ),
                const SizedBox(height: Dimens.spacingLarge),
                _buildMetricCard(
                  icon: Icons.local_fire_department,
                  title: 'Calories',
                  value: summary['calories'] ?? 0,
                  color: AppColors.caloriesColor,
                  bgColor: AppColors.caloriesBg,
                  unit: 'kcal',
                ),
                const SizedBox(height: Dimens.spacingLarge),
                _buildMetricCard(
                  icon: Icons.local_drink,
                  title: 'Water Intake',
                  value: summary['water'] ?? 0,
                  color: AppColors.waterColor,
                  bgColor: AppColors.waterBg,
                  unit: 'ml',
                ),
              ] else
                _buildEmptyState(),

              const SizedBox(height: Dimens.spacingXXLarge),

              // Action Buttons
              if (hasTodayRecord) ...[
                // Update Button
                PrimaryButton(
                  label: 'Update Today\'s Record',
                  icon: Icons.edit,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditScreen(record: todayRecord),
                      ),
                    );
                    await prov.loadAll();
                  },
                ),
                const SizedBox(height: Dimens.spacingMedium),
                // Delete Button
                SizedBox(
                  height: Dimens.buttonHeight,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteTodayRecord(context, prov, todayRecord),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text(
                      'Delete Today\'s Record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ] else
                // Add Button (only shown when no record exists)
                PrimaryButton(
                  label: 'Add Today\'s Record',
                  icon: Icons.add,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditScreen(record: null),
                      ),
                    );
                    await prov.loadAll();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required int value,
    required Color color,
    required Color bgColor,
    required String unit,
  }) {
    return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimens.radiusLarge),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(Dimens.radiusLarge),
            ),
            padding: const EdgeInsets.all(Dimens.paddingLarge),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimens.paddingMedium),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                  ),
                  child: Icon(icon, color: color, size: Dimens.iconLarge),
                ),
                const SizedBox(width: Dimens.spacingLarge),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: value),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedValue, child) {
                          return Text(
                            '$animatedValue $unit',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radiusLarge),
      ),
      child: Container(
        padding: const EdgeInsets.all(Dimens.paddingXLarge),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: Dimens.spacingLarge),
            Text(
              'No records for today.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: Dimens.spacingSmall),
            Text(
              'Add your first record to start tracking your health!',
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

  Future<void> _deleteTodayRecord(
    BuildContext context,
    HealthProvider prov,
    HealthRecord record,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Today\'s Record'),
        content: const Text(
          'Are you sure you want to delete today\'s health record? This action cannot be undone.',
        ),
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

    if (confirm == true && mounted) {
      final success = await prov.deleteRecord(record.id!);
      if (success) {
        SnackbarHelper.showSuccess(context, 'Today\'s record deleted successfully');
      } else {
        SnackbarHelper.showError(context, prov.error ?? 'Unable to delete record');
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
