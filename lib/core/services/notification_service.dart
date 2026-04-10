import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pill_time/features/home/controllers/dose_controller.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../../data/models/medicine_model.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // init Timezones
    tz.initializeTimeZones();

    try {
      // In some versions, this returns a String. In others, a TimezoneInfo object.
      // Cast it to dynamic first to avoid compiler errors, then convert to string.
      dynamic tzResult = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = tzResult.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to UTC if local timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // init Notification Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    // await _notificationsPlugin.initialize(settings);
    // // ONLY check permissions if we are on Android or iOS
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      await _checkExactAlarmPermission();
    }

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // This runs when the user taps the notification
        // It ensures the app opens to the home screen and refreshes doses
        Get.offAllNamed('/');
        if (Get.isRegistered<DoseController>()) {
          Get.find<DoseController>().refreshPendingDoses();
        }
      },
    );
  }

  static Future<void> _checkExactAlarmPermission() async {
    // Exact alarms are required for medicine reminders to be precise.
    if (await Permission.scheduleExactAlarm.isDenied) {
      _showPermissionDialog();
    }
  }

  static void _showPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Precise Reminders Needed'),
        content: const Text(
          'To ensure your medicine reminders ring exactly on time, '
          'this app needs the "Exact Alarm" permission. '
          '\n\nPlease allow this in the next screen.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Later')),
          FilledButton(
            onPressed: () async {
              Get.back();
              // Open the specific system settings page for Exact Alarms
              await openAppSettings();
            },
            child: const Text('Allow in Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleMedicineAlarm(MedicineModel medicine) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Alarms for scheduled medicines',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    for (String timeString in medicine.scheduleTimes) {
      final parts = timeString.split(':');
      final int notificationId = (medicine.id + timeString).hashCode;

      if (GetPlatform.isAndroid || GetPlatform.isIOS) {
        await _notificationsPlugin.zonedSchedule(
          notificationId,
          'Time for ${medicine.name}',
          'Dose: ${medicine.doseAmount} ${medicine.doseUnit}',
          _nextInstanceOfTime(int.parse(parts[0]), int.parse(parts[1])),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: medicine.id,
        );
      } else {
        debugPrint('Skipped alarm scheduling on Linux for: ${medicine.name}');
      }
    }
  }

  static Future<void> cancelMedicineAlarms(MedicineModel medicine) async {
    for (String timeString in medicine.scheduleTimes) {
      // Recreate the exact same ID we used to schedule it
      final int notificationId = (medicine.id + timeString).hashCode;

      await _notificationsPlugin.cancel(notificationId);
    }
  }
}
