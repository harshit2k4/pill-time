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
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Clear History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to delete all dose logs? This cannot be undone.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);
                      await logBox.clear();
                      loadLogs();
                      Get.back();
                      Get.snackbar(
                        'History Cleared',
                        'All past logs have been removed.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
