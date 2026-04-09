import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:pill_time/core/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/medicine_model.dart';
import '../../../core/constants/app_strings.dart';
import '../../home/controllers/home_controller.dart';

class AddMedicineController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // Controllers
  final nameController = TextEditingController();
  final amountController = TextEditingController(); // Numeric dose
  final stockController = TextEditingController(); // Total stock
  final instructionsController = TextEditingController();

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

  // Units change based on type
  final List<String> pillUnits = ['pills', 'mg', 'mcg'];
  final List<String> liquidUnits = ['ml', 'drops'];

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

  Future<void> saveMedicine() async {
    if (formKey.currentState!.validate()) {
      if (selectedTimes.isEmpty) {
        Get.snackbar('Reminder Required', 'Please add at least one time');
        return;
      }

      final newMedicine = MedicineModel(
        id: const Uuid().v4(),
        name: nameController.text.trim(),
        type: selectedType.value,
        doseAmount: double.tryParse(amountController.text) ?? 0.0,
        doseUnit: selectedUnit.value,
        instructions: instructionsController.text.trim(),
        scheduleTimes: selectedTimes
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
            )
            .toList(),
        stockQuantity: double.tryParse(stockController.text) ?? 0.0,
        startDate: DateTime.now(),
        dropsPerMl: 20, // Default medical standard
      );

      final box = Hive.box<MedicineModel>(AppStrings.boxMedicines);
      await box.add(newMedicine);
      await NotificationService.scheduleMedicineAlarm(newMedicine);

      Get.find<HomeController>().loadMedicines();
      Get.back();
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
