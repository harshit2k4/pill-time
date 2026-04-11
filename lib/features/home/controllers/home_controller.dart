import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/medicine_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/notification_service.dart';
import 'dose_controller.dart';

class HomeController extends GetxController {
  var medicines = <MedicineModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  void loadMedicines() {
    final box = Hive.box<MedicineModel>(AppStrings.boxMedicines);
    medicines.assignAll(box.values.toList());
  }

  // NEW: Delete with Undo Logic
  void deleteMedicineWithUndo(int index, MedicineModel medicineToDelete) async {
    final box = Hive.box<MedicineModel>(AppStrings.boxMedicines);

    // 1. Cancel Alarms immediately
    await NotificationService.cancelMedicineAlarms(medicineToDelete);

    // 2. Delete from database
    await box.deleteAt(index);
    loadMedicines();
    Get.find<DoseController>().refreshPendingDoses();

    // 3. Show Glassmorphic Bottom Snackbar
    Get.snackbar(
      'Medicine Deleted',
      '${medicineToDelete.name} was removed.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.black87.withOpacity(0.7),
      colorText: Colors.white,
      mainButton: TextButton(
        onPressed: () async {
          // UNDO ACTION: Re-add the exact same medicine back to Hive
          final restoredMed = MedicineModel(
            id: medicineToDelete.id,
            name: medicineToDelete.name,
            type: medicineToDelete.type,
            doseAmount: medicineToDelete.doseAmount,
            doseUnit: medicineToDelete.doseUnit,
            instructions: medicineToDelete.instructions,
            scheduleTimes: medicineToDelete.scheduleTimes,
            stockQuantity: medicineToDelete.stockQuantity,
            startDate: medicineToDelete.startDate,
            dropsPerMl: medicineToDelete.dropsPerMl,
          );

          await box.add(restoredMed);
          await NotificationService.scheduleMedicineAlarm(restoredMed);
          loadMedicines();
          Get.find<DoseController>().refreshPendingDoses();

          Get.back(); // Close snackbar
          Get.snackbar('Restored', '${medicineToDelete.name} is back.');
        },
        child: const Text(
          'UNDO',
          style: TextStyle(
            color: Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Refill Dialog
  // BETTER UI: Refill Dialog
  void showRefillDialog(MedicineModel medicine) {
    final textController = TextEditingController();

    String refillUnit =
        (medicine.type == 'Liquid' || medicine.type == 'Homeopathic')
        ? 'ml'
        : medicine.doseUnit;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_shopping_cart,
                size: 48,
                color: Theme.of(Get.context!).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Refill ${medicine.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount added in $refillUnit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
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
                    onPressed: () async {
                      double addedAmount =
                          double.tryParse(textController.text) ?? 0.0;
                      if (addedAmount > 0) {
                        medicine.stockQuantity += addedAmount;
                        await medicine.save();
                        loadMedicines();
                        Get.back();
                      }
                    },
                    child: const Text('Refill'),
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
