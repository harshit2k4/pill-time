import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/models/medicine_model.dart';
import '../../../core/constants/app_strings.dart';

class HomeController extends GetxController {
  // This list will hold our medicines and update the UI automatically
  var medicines = <MedicineModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  // Load all medicines from the Hive box
  void loadMedicines() {
    final box = Hive.box<MedicineModel>(AppStrings.boxMedicines);
    // We convert the box values to a list
    medicines.assignAll(box.values.toList());
  }

  // A simple function to delete a medicine
  void deleteMedicine(int index) async {
    final box = Hive.box<MedicineModel>(AppStrings.boxMedicines);
    await box.deleteAt(index);
    loadMedicines(); // Refresh the list after deleting
  }
}
