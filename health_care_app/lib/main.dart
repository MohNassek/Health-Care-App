import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/di/injection.dart';
import 'core/theme.dart';
import 'features/health_records/viewmodels/health_record_viewmodel.dart';
import 'features/health_records/views/dashboard_view.dart';
import 'features/health_records/views/list_view.dart';
import 'features/health_records/views/add_record_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HealthRecordViewModel>(
      create: (_) {
        final vm = getIt<HealthRecordViewModel>();
        vm.init();
        return vm;
      },
      child: MaterialApp(
        title: 'HealthMate',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routes: {
          '/': (_) => const DashboardView(),
          '/add': (_) => const AddRecordView(),
          '/list': (_) => const ListViewPage(),
        },
      ),
    );
  }
}
