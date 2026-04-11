import 'dart:async'; // Required for Timer
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/dose_log_model.dart';
import '../../../core/constants/app_strings.dart';
import 'dart:math' as math;

import 'home_controller.dart';

class DueDose {
  final MedicineModel medicine;
  final DateTime scheduledTime;
  DueDose({required this.medicine, required this.scheduledTime});
}

class DoseController extends GetxController {
  var pendingDoses = <DueDose>[].obs;
  var isLoading = false.obs;
  DateTime? _lastClickTime;
  Timer? _refreshTimer; // Timer to update the list as time passes

  @override
  void onInit() {
    super.onInit();
    refreshPendingDoses();
    // Refresh the list every minute to catch new due doses
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => refreshPendingDoses(),
    );
  }

  @override
  void onClose() {
    _refreshTimer?.cancel(); // Always cancel timers
    super.onClose();
  }

  void refreshPendingDoses() {
    final medBox = Hive.box<MedicineModel>(AppStrings.boxMedicines);
    final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);

    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);
    List<DueDose> dueItems = [];

    for (var medicine in medBox.values) {
      for (var timeStr in medicine.scheduleTimes) {
        final parts = timeStr.split(':');
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        // Check if time passed AND not already taken today
        if (scheduledTime.isBefore(now)) {
          bool alreadyTaken = logBox.values.any(
            (log) =>
                log.medicineId == medicine.id &&
                DateFormat('yyyy-MM-dd').format(log.logTime) == todayDate &&
                log.logTime.hour == scheduledTime.hour &&
                log.logTime.minute == scheduledTime.minute,
          );

          if (!alreadyTaken) {
            dueItems.add(
              DueDose(medicine: medicine, scheduledTime: scheduledTime),
            );
          }
        }
      }
    }
    // Sort by time so the most urgent is at the top
    dueItems.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    pendingDoses.assignAll(dueItems);
  }

  Future<void> markAsTaken(DueDose dose) async {
    // Prevent action if already loading
    if (isLoading.value) return;

    DateTime now = DateTime.now();

    // Safety check for rapid clicking
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!).inSeconds < 5) {
      Get.snackbar(
        AppStrings.safetyWarningTitle,
        AppStrings.safetyWarningBody,
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true; // Start loading state
    _lastClickTime = now;

    try {
      // Artificial delay to show the loading bar and prevent spam
      await Future.delayed(const Duration(milliseconds: 800));

      final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);

      final newLog = DoseLogModel(
        medicineId: dose.medicine.id,
        logTime: dose.scheduledTime,
        status: 'taken',
        medicineName: dose.medicine.name, // NEW: Save the name here
      );
      await logBox.add(newLog);

      // Stock Calculation Logic
      // If the unit is 'drops', we convert it to ML before subtracting from stock
      // This assumes the total stock is stored in ML for liquids
      double reduction = dose.medicine.doseAmount;
      if (dose.medicine.doseUnit == 'drops') {
        reduction = dose.medicine.doseAmount / (dose.medicine.dropsPerMl ?? 20);
      }

      dose.medicine.stockQuantity = math.max(
        0.0,
        dose.medicine.stockQuantity - reduction,
      );
      await dose.medicine.save();

      refreshPendingDoses();
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().loadMedicines();
      }
    } finally {
      isLoading.value = false; // Stop loading state
    }
  }
}
