import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../data/models/dose_log_model.dart';
import '../../../core/constants/app_strings.dart';

class HistoryController extends GetxController {
  var logs = <DoseLogModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  void loadLogs() {
    final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);
    final allLogs = logBox.values.toList();
    // Sort so newest dates are at the top
    allLogs.sort((a, b) => b.logTime.compareTo(a.logTime));
    logs.assignAll(allLogs);
  }

  void clearHistory() {
    Get.defaultDialog(
      title: 'Clear History',
      middleText:
          'Are you sure you want to delete all dose logs? This cannot be undone.',
      textConfirm: 'Clear',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);
        await logBox.clear(); // This deletes everything in the box
        loadLogs(); // Refresh the empty list
        Get.back(); // Close the dialog
        Get.snackbar('History Cleared', 'All past logs have been removed.');
      },
    );
  }
}
