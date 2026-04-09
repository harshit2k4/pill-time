import 'package:hive/hive.dart';

part 'dose_log_model.g.dart';

@HiveType(typeId: 1)
class DoseLogModel extends HiveObject {
  @HiveField(0)
  String medicineId;

  @HiveField(1)
  DateTime logTime;

  @HiveField(2)
  String status; // taken, skipped, missed

  DoseLogModel({
    required this.medicineId,
    required this.logTime,
    required this.status,
  });
}
