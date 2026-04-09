import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pill_time/features/add_medicine/views/add_medicine_view.dart';
import 'package:pill_time/features/home/controllers/dose_controller.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize our controller
    final controller = Get.put(HomeController());
    final doseController = Get.put(DoseController());
    return Scaffold(
      appBar: AppBar(title: const Text('My Medicines')),
      body: Column(
        children: [
          // This Obx handles the new Dose Due Now card
          Obx(() {
            if (doseController.pendingDoses.isEmpty) {
              return const SizedBox.shrink();
            }

            final medicine = doseController.pendingDoses.first;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm_on, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dose Due Now',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${medicine.name} - ${medicine.doseAmount} ${medicine.doseUnit}',
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => doseController.markAsTaken(medicine),
                          child: const Text('Take Now'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // This Expanded contains the existing medicines list
          Expanded(
            child: Obx(() {
              if (controller.medicines.isEmpty) {
                return const Center(child: Text('No medicines added yet.'));
              }

              // We removed the Expanded widget from here because it is now wrapping the Obx above
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.medicines.length,
                itemBuilder: (context, index) {
                  final medicine = controller.medicines[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              medicine.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${medicine.doseAmount} ${medicine.doseUnit} • ${medicine.type}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.to(() => const AddMedicineView());
        },
        label: const Text('Add Medicine'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
