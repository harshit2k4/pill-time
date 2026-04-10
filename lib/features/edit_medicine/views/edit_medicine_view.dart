import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/medicine_model.dart';
import '../controllers/edit_medicine_controller.dart';

class EditMedicineView extends StatelessWidget {
  final MedicineModel medicine;

  const EditMedicineView({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    // Inject the controller with the specific medicine we are editing
    final controller = Get.put(EditMedicineController(medicine: medicine));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: controller.nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: controller.selectedType.value,
                decoration: const InputDecoration(
                  labelText: 'Medicine Type',
                  border: OutlineInputBorder(),
                ),
                items: controller.medicineTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedType.value = val;
                    controller.updateUnits(val);
                  }
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: controller.amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Dose Amount',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Obx(
                      () => DropdownButtonFormField<String>(
                        value: controller.selectedUnit.value,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            (controller.selectedType.value == 'Liquid' ||
                                        controller.selectedType.value ==
                                            'Homeopathic'
                                    ? controller.liquidUnits
                                    : controller.pillUnits)
                                .map(
                                  (unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) controller.selectedUnit.value = val;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.stockController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Current Stock (Total)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: controller.instructionsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions (Optional)',
                  hintText: 'e.g., Take after meals',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Reminder Times',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...controller.selectedTimes.asMap().entries.map(
                      (entry) => InputChip(
                        label: Text(entry.value.format(context)),
                        onDeleted: () => controller.removeTime(entry.key),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Add Time'),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) controller.addTime(time);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: controller.updateMedicine,
                  icon: const Icon(Icons.save),
                  label: const Text('Update Medicine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
