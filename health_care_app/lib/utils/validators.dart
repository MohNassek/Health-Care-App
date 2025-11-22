class Validators {
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a valid date.';
    }

    // Check if date is valid format (yyyy-MM-dd)
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please select a valid date.';
    }

    // Parse the date
    final parts = value.split('-');
    if (parts.length != 3) {
      return 'Please select a valid date.';
    }

    try {
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final date = DateTime(year, month, day);

      // Check if date is in the future
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDate = DateTime(date.year, date.month, date.day);

      if (selectedDate.isAfter(today)) {
        return 'Future dates are not allowed.';
      }

      return null;
    } catch (e) {
      return 'Please select a valid date.';
    }
  }

  static String? validateSteps(String? value) {
    if (value == null || value.isEmpty) {
      return 'Steps are required.';
    }

    final steps = int.tryParse(value);
    if (steps == null) {
      return 'Steps must be a number.';
    }

    if (steps < 0) {
      return 'Steps cannot be negative.';
    }

    if (steps > 100000) {
      return 'Steps cannot exceed 100,000.';
    }

    return null;
  }

  static String? validateCalories(String? value) {
    if (value == null || value.isEmpty) {
      return 'Calories are required.';
    }

    final calories = int.tryParse(value);
    if (calories == null) {
      return 'Calories must be a number.';
    }

    if (calories < 0) {
      return 'Calories cannot be negative.';
    }

    if (calories > 10000) {
      return 'Calories cannot exceed 10,000.';
    }

    return null;
  }

  static String? validateWater(String? value) {
    if (value == null || value.isEmpty) {
      return 'Water intake is required.';
    }

    final water = int.tryParse(value);
    if (water == null) {
      return 'Water must be a valid number.';
    }

    if (water < 100) {
      return 'Minimum intake is 100ml.';
    }

    return null;
  }
}

