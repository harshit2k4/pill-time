import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/medicine_model.dart';
import '../../../core/services/notification_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../home/controllers/dose_controller.dart';

class EditMedicineController extends GetxController {
  final MedicineModel medicine;
  final formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController nameController;
  late TextEditingController amountController;
  late TextEditingController stockController;
  late TextEditingController instructionsController;

  // Observables
  var selectedType = 'Tablet'.obs;
  var selectedUnit = 'pills'.obs;
  var selectedTimes = <TimeOfDay>[].obs;

  final List<String> medicineTypes = [
    'Tablet',
    'Capsule',
    'Liquid',
    'Homeopathic',
    'Other',
  ];
  final List<String> pillUnits = ['pills', 'mg', 'mcg'];
  final List<String> liquidUnits = ['ml', 'drops'];

  EditMedicineController({required this.medicine});

  @override
  void onInit() {
    super.onInit();
    // Pre-fill the form with the existing medicine data
    nameController = TextEditingController(text: medicine.name);
    amountController = TextEditingController(
      text: medicine.doseAmount.toString(),
    );
    stockController = TextEditingController(
      text: medicine.stockQuantity.toString(),
    );
    instructionsController = TextEditingController(text: medicine.instructions);

    selectedType.value = medicine.type;
    selectedUnit.value = medicine.doseUnit;

    // Convert saved string times (HH:mm) back to TimeOfDay objects
    selectedTimes.value = medicine.scheduleTimes.map((timeStr) {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  void updateUnits(String? type) {
    if (type == 'Liquid' || type == 'Homeopathic') {
      selectedUnit.value = 'ml';
    } else {
      selectedUnit.value = 'pills';
    }
  }

  void addTime(TimeOfDay time) {
    if (!selectedTimes.contains(time)) {
      selectedTimes.add(time);
    }
  }

  void removeTime(int index) {
    selectedTimes.removeAt(index);
  }

  Future<void> updateMedicine() async {
    if (formKey.currentState!.validate()) {
      if (selectedTimes.isEmpty) {
        Get.snackbar(
          'Reminder Required',
          'Please add at least one time',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Cancel old alarms
      await NotificationService.cancelMedicineAlarms(medicine);

      // Update the medicine object with new values
      medicine.name = nameController.text.trim();
      medicine.type = selectedType.value;
      medicine.doseAmount = double.tryParse(amountController.text) ?? 0.0;
      medicine.doseUnit = selectedUnit.value;
      medicine.instructions = instructionsController.text.trim();
      medicine.stockQuantity = double.tryParse(stockController.text) ?? 0.0;

      // Convert TimeOfDay back to HH:mm strings
      medicine.scheduleTimes = selectedTimes
          .map(
            (t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          )
          .toList();

      // Save to Hive
      await medicine.save();

      // Schedule new alarms
      await NotificationService.scheduleMedicineAlarm(medicine);

      // Refresh UI and close
      Get.find<HomeController>().loadMedicines();
      Get.find<DoseController>().refreshPendingDoses();
      Get.back();
      Get.snackbar(
        'Success',
        '${medicine.name} updated',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    amountController.dispose();
    stockController.dispose();
    instructionsController.dispose();
    super.onClose();
  }
}
