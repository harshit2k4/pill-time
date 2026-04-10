import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_medicine_controller.dart';

class AddMedicineView extends StatelessWidget {
  const AddMedicineView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddMedicineController());

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
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

              // Type Selector
              DropdownButtonFormField<String>(
                value: controller.selectedType.value,
                decoration: const InputDecoration(
                  labelText: 'Medicine Type',
                  border: OutlineInputBorder(),
                ),
                items: controller.medicineTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (val) {
                  controller.selectedType.value = val!;
                  controller.updateUnits(val);
                },
              ),
              const SizedBox(height: 16),

              // Responsive Dose Row
              LayoutBuilder(
                builder: (context, constraints) {
                  // If the screen is very narrow, stack these vertically
                  bool isNarrow = constraints.maxWidth < 300;
                  return Flex(
                    direction: isNarrow ? Axis.vertical : Axis.horizontal,
                    children: [
                      Flexible(
                        flex: isNarrow ? 0 : 2,
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
                      SizedBox(
                        width: isNarrow ? 0 : 12,
                        height: isNarrow ? 12 : 0,
                      ),
                      Flexible(
                        flex: isNarrow ? 0 : 1,
                        child: Obx(() {
                          // Determine which list to use
                          List<String> currentUnits =
                              (controller.selectedType.value == 'Liquid' ||
                                  controller.selectedType.value ==
                                      'Homeopathic')
                              ? controller.liquidUnits
                              : controller.pillUnits;

                          // Do a Safety Check: If the current value isn't in the new list,
                          // reset it to the first item of that list to prevent the crash.
                          if (!currentUnits.contains(
                            controller.selectedUnit.value,
                          )) {
                            // Use a microtask to avoid "setState() during build" errors
                            Future.microtask(
                              () => controller.selectedUnit.value =
                                  currentUnits.first,
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value:
                                currentUnits.contains(
                                  controller.selectedUnit.value,
                                )
                                ? controller.selectedUnit.value
                                : currentUnits.first,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: currentUnits
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                controller.selectedUnit.value = val!,
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Stock Field
              // TextFormField(
              //   controller: controller.stockController,
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //     labelText: 'Total Inventory / Stock',
              //     hintText: 'e.g. 30 (pills or ml)',
              //     border: OutlineInputBorder(),
              //   ),
              //   validator: (val) => val!.isEmpty ? 'Required' : null,
              // ),
              Obx(
                () => TextFormField(
                  controller: controller.stockController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Current Total Stock',
                    // NEW: Helper text explains the unit to the user
                    helperText:
                        (controller.selectedUnit.value == 'ml' ||
                            controller.selectedUnit.value == 'drops')
                        ? 'Enter total ML available in the bottle'
                        : 'Enter total number of pills available',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.inventory_2),
                  ),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Instructions
              TextFormField(
                controller: controller.instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  hintText: 'e.g. After lunch',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Reminder Times Section
              const Text(
                'Reminder Schedule',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                  onPressed: controller.saveMedicine,
                  icon: const Icon(Icons.save),
                  label: const Text('Save and Set Reminders'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
