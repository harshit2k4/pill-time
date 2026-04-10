import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/history_controller.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  // Simple helper function to check if two dates are the exact same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HistoryController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dose History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear History',
            onPressed: controller.clearHistory,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.logs.isEmpty) {
          return const Center(child: Text('No history available yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.logs.length,
          itemBuilder: (context, index) {
            final log = controller.logs[index];

            // Logic for the day divider
            // Show divider if it is the very first item OR if the day changed
            bool showDivider =
                index == 0 ||
                !isSameDay(log.logTime, controller.logs[index - 1].logTime);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showDivider)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 4.0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(log.logTime),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    title: Text(
                      log.medicineName, // Using the preserved name from the model
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Taken at ${DateFormat('hh:mm a').format(log.logTime)}',
                    ),
                    trailing: Text(
                      log.status.toUpperCase(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}
