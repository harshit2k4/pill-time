import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/dose_log_model.dart';
import '../../../core/constants/app_strings.dart';

class DoseController extends GetxController {
  var pendingDoses = <MedicineModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    refreshPendingDoses();
  }

  void refreshPendingDoses() {
    final medBox = Hive.box<MedicineModel>(AppStrings.boxMedicines);
    final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);

    DateTime now = DateTime.now();
    String todayDate = DateFormat('yyyy-MM-dd').format(now);

    List<MedicineModel> dueItems = [];

    for (var medicine in medBox.values) {
      for (var timeStr in medicine.scheduleTimes) {
        // Convert "HH:mm" to a DateTime object for today
        final parts = timeStr.split(':');
        final scheduledTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        // If the time has passed AND it's not logged today
        if (scheduledTime.isBefore(now)) {
          bool alreadyTaken = logBox.values.any(
            (log) =>
                log.medicineId == medicine.id &&
                DateFormat('yyyy-MM-dd').format(log.logTime) == todayDate &&
                log.logTime.hour == scheduledTime.hour &&
                log.logTime.minute == scheduledTime.minute,
          );

          if (!alreadyTaken) {
            dueItems.add(medicine);
          }
        }
      }
    }
    pendingDoses.assignAll(dueItems);
  }

  Future<void> markAsTaken(MedicineModel medicine) async {
    final logBox = Hive.box<DoseLogModel>(AppStrings.boxLogs);

    // Create the log
    final newLog = DoseLogModel(
      medicineId: medicine.id,
      logTime: DateTime.now(),
      status: 'taken',
    );
    await logBox.add(newLog);

    // Reduce Stock
    double reduction = medicine.doseAmount;
    if (medicine.doseUnit == 'drops') {
      reduction = medicine.doseAmount / (medicine.dropsPerMl ?? 20);
    }

    medicine.stockQuantity -= reduction;
    await medicine.save(); // Hive built-in save for objects

    refreshPendingDoses();
    Get.snackbar('Success', '${medicine.name} marked as taken');
  }
}
