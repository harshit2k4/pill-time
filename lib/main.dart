import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pill_time/core/services/notification_service.dart';
import 'package:pill_time/features/home/views/home_view.dart';

import 'core/theme/app_theme.dart';
import 'data/models/medicine_model.dart';
import 'data/models/dose_log_model.dart';

void main() async {
  // Ensure Flutter is initialized before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final directory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(directory.path);

  // Register Adapters
  Hive.registerAdapter(MedicineModelAdapter());
  Hive.registerAdapter(DoseLogModelAdapter());

  // Open Boxes
  await Hive.openBox<MedicineModel>('medicines');
  await Hive.openBox<DoseLogModel>('dose_logs');

  // WAKE UP THE NOTIFICATION SERVICE
  await NotificationService.init();

  runApp(const MedicineApp());
}

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Medicine Reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: HomeView(),
    );
  }
}
