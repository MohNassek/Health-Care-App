# health_care_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## HealthMate - Personal Health Tracker (Feature Summary)

This workspace contains a small feature-based implementation: `features/health_records` which provides:

- A local sqflite database storing `health_records` (id, date, steps, calories, water).
- Provider-based state management (`HealthProvider`) for managing records and CRUD actions.
- UI screens: Dashboard, Health Record List (with date search), Add/Edit Record (form with validation).

### Architecture (simple)

App
  └─ features/
	  └─ health_records/
		  ├─ health_record.dart      # data model
		  ├─ health_db.dart          # sqflite DB helper
		  ├─ health_provider.dart    # Provider for state & CRUD
		  └─ screens/
			  ├─ dashboard_screen.dart
			  ├─ list_screen.dart
			  └─ add_edit_screen.dart

Notes:
- The app uses Material 3 theming. Colors: water (blue), steps (green), calories (red).
- The app seeds two dummy records on first run for testing.

## How to run

From the project root run:

```powershell
flutter pub get
flutter run
```

## Next steps / Improvements

- Add unit/widget tests for provider and database.
- Add screenshots/wireframes to `docs/` and a PNG architecture diagram.
- Improve UX: charts, monthly summaries, export CSV.

