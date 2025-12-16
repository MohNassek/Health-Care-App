import 'package:get_it/get_it.dart';

import '../../features/health_records/health_db.dart';
import '../../features/health_records/services/health_service.dart';
import '../../features/health_records/viewmodels/health_record_viewmodel.dart';

final GetIt getIt = GetIt.instance;

void setupLocator() {
  // Health service (data access)
  getIt.registerLazySingleton<HealthService>(() => HealthService(db: HealthDatabase.instance));

  // ViewModel - register factory so each provider gets its own instance
  getIt.registerFactory<HealthRecordViewModel>(() => HealthRecordViewModel(service: getIt<HealthService>()));
}
