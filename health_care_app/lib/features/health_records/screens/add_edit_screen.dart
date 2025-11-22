import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../health_provider.dart';
import '../health_record.dart';
import '../../../utils/validators.dart';
import '../../../utils/colors.dart';
import '../../../utils/dimens.dart';
import '../../../utils/snackbar_helper.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';

class AddEditScreen extends StatefulWidget {
  final HealthRecord? record;
  const AddEditScreen({super.key, this.record});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _dateCtrl;
  late TextEditingController _stepsCtrl;
  late TextEditingController _calCtrl;
  late TextEditingController _waterCtrl;

  bool _isLoading = false;
  bool _dateExists = false;
  bool _checkingDate = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    // Always use today's date
    _dateCtrl = TextEditingController(text: _fmt(DateTime.now()));
    final r = widget.record;
    _stepsCtrl = TextEditingController(text: r?.steps.toString() ?? '0');
    _calCtrl = TextEditingController(text: r?.calories.toString() ?? '0');
    _waterCtrl = TextEditingController(text: r?.water.toString() ?? '0');

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    // Check date on init if adding new record
    if (widget.record == null) {
      _checkDateExists();
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _stepsCtrl.dispose();
    _calCtrl.dispose();
    _waterCtrl.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _fmt(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> _checkDateExists() async {
    if (widget.record != null) return; // Don't check for edit mode on init

    setState(() => _checkingDate = true);
    final prov = Provider.of<HealthProvider>(context, listen: false);
    final exists = await prov.checkDateExists(_dateCtrl.text);

    if (mounted) {
      setState(() {
        _dateExists = exists;
        _checkingDate = false;
      });
    }
  }


  bool _isFormValid() {
    if (!_formKey.currentState!.validate()) {
      _shakeController.forward(from: 0);
      return false;
    }

    // Additional checks - date is always today, so check if today's record exists (for add mode)
    if (widget.record == null && _dateExists) {
      _shakeController.forward(from: 0);
      return false;
    }

    return true;
  }

  Future<void> _save() async {
    if (!_isFormValid()) {
      SnackbarHelper.showError(context, 'Please fix the errors before saving.');
      return;
    }

    setState(() => _isLoading = true);

    final prov = Provider.of<HealthProvider>(context, listen: false);
    final r = HealthRecord(
      id: widget.record?.id,
      date: _dateCtrl.text,
      steps: int.parse(_stepsCtrl.text),
      calories: int.parse(_calCtrl.text),
      water: int.parse(_waterCtrl.text),
    );

    bool success;
    if (widget.record == null) {
      success = await prov.addRecord(r);
      if (success) {
        SnackbarHelper.showSuccess(context, 'Record added successfully!');
      } else {
        SnackbarHelper.showError(context, prov.error ?? 'Unable to save record.');
        setState(() => _isLoading = false);
        return;
      }
    } else {
      success = await prov.updateRecord(r);
      if (success) {
        SnackbarHelper.showSuccess(context, 'Record updated successfully!');
      } else {
        SnackbarHelper.showError(context, prov.error ?? 'Unable to update record.');
        setState(() => _isLoading = false);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.record != null;
    // For add mode, disable form if today's record already exists
    final formEnabled = !_dateExists || isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Record' : 'Add Record'),
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimens.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning banner for existing date (Add mode only)
                if (!isEditMode && _dateExists)
                  Container(
                    margin: const EdgeInsets.only(bottom: Dimens.spacingLarge),
                    padding: const EdgeInsets.all(Dimens.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Dimens.radiusMedium),
                      border: Border.all(color: AppColors.warning, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
                        const SizedBox(width: Dimens.spacingMedium),
                        Expanded(
                          child: Text(
                            'You already have a record for this day. You can only edit it, not add a new one.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Date field (always disabled, always today's date)
                CustomTextField(
                  controller: _dateCtrl,
                  label: 'Date',
                  prefixIcon: Icons.date_range,
                  validator: Validators.validateDate,
                  readOnly: true,
                  enabled: false, // Always disabled
                  helperText: 'Date is automatically set to today',
                ),
                const SizedBox(height: Dimens.spacingLarge),

                // Steps field
                CustomTextField(
                  controller: _stepsCtrl,
                  label: 'Steps',
                  prefixIcon: Icons.directions_walk,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateSteps,
                  enabled: formEnabled,
                  helperText: 'Enter steps (0-100,000)',
                ),
                const SizedBox(height: Dimens.spacingLarge),

                // Calories field
                CustomTextField(
                  controller: _calCtrl,
                  label: 'Calories (kcal)',
                  prefixIcon: Icons.local_fire_department,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateCalories,
                  enabled: formEnabled,
                  helperText: 'Enter calories (0-10,000)',
                ),
                const SizedBox(height: Dimens.spacingLarge),

                // Water field
                CustomTextField(
                  controller: _waterCtrl,
                  label: 'Water Intake (ml)',
                  prefixIcon: Icons.local_drink,
                  keyboardType: TextInputType.number,
                  validator: Validators.validateWater,
                  enabled: formEnabled,
                  helperText: 'Minimum 100ml',
                ),
                const SizedBox(height: Dimens.spacingXXLarge),

                // Save button
                PrimaryButton(
                  label: isEditMode ? 'Update Record' : 'Save Record',
                  icon: Icons.save,
                  onPressed: _save,
                  isLoading: _isLoading,
                  isEnabled: formEnabled && !_checkingDate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
