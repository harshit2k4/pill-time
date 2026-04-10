import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pill_time/features/add_medicine/views/add_medicine_view.dart';
import 'package:pill_time/features/home/controllers/dose_controller.dart';
import '../../edit_medicine/views/edit_medicine_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../med_history/views/history_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController());
    final doseController = Get.put(DoseController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pill Time'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const HistoryView()),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Horizontal Loading Bar
            Obx(
              () => doseController.isLoading.value
                  ? const LinearProgressIndicator(minHeight: 2)
                  : const SizedBox(height: 2),
            ),
            // Due Doses Section
            Obx(() {
              if (doseController.pendingDoses.isEmpty)
                return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Due Doses (${doseController.pendingDoses.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...doseController.pendingDoses.map((dose) {
                      final timeString = DateFormat.jm().format(
                        dose.scheduledTime,
                      );
                      return Obx(
                        () => Opacity(
                          // Make UI look inactive when loading
                          opacity: doseController.isLoading.value ? 0.5 : 1.0,
                          child: AbsorbPointer(
                            // Block clicks when loading
                            absorbing: doseController.isLoading.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                borderColor: Colors.redAccent.withOpacity(0.3),
                                child: Row(
                                  children: [
                                    const Icon(Icons.alarm, size: 30),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${dose.medicine.name} at $timeString',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${dose.medicine.doseAmount} ${dose.medicine.doseUnit}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          doseController.markAsTaken(dose),
                                      child: const Text('Take'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                "My Medicines",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            // Medicines List
            Expanded(
              child: Obx(() {
                return ListView.builder(
                  itemCount: controller.medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = controller.medicines[index];

                    // Calculate daily usage based on schedule and units
                    double dailyUsage =
                        medicine.doseAmount * medicine.scheduleTimes.length;
                    if (medicine.doseUnit == 'drops') {
                      dailyUsage = dailyUsage / (medicine.dropsPerMl ?? 20);
                    }

                    // Alert if less than 3 days of stock is left
                    bool isLowStock =
                        medicine.stockQuantity <= (dailyUsage * 3);

                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                      child: Dismissible(
                        key: Key(medicine.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400, // Softer red
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Match card radius
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        onDismissed: (direction) {
                          // Pass the medicine object to handle undo safely
                          controller.deleteMedicineWithUndo(index, medicine);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            borderColor: isLowStock
                                ? Colors.redAccent.withOpacity(0.5)
                                : null,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Get.to(
                                  () => EditMedicineView(medicine: medicine),
                                );
                              },
                              child: ListTile(
                                title: Text(
                                  medicine.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${medicine.doseAmount} ${medicine.doseUnit} • ${medicine.type}',
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          isLowStock
                                              ? Icons.warning_amber_rounded
                                              : Icons.inventory_2_outlined,
                                          size: 14,
                                          color: isLowStock
                                              ? Colors.redAccent
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Stock: ${medicine.stockQuantity.toStringAsFixed(1)}',
                                          style: TextStyle(
                                            color: isLowStock
                                                ? Colors.redAccent
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart),
                                  onPressed: () =>
                                      controller.showRefillDialog(medicine),
                                ),
                              ),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const AddMedicineView()),
        label: const Text('Add Medicine'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
