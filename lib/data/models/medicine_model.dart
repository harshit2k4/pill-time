import 'package:hive/hive.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 0)
class MedicineModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String type; // Tablet, Liquid, etc.

  @HiveField(3)
  double doseAmount; // Changed to double for 0.5 doses

  @HiveField(4)
  String doseUnit; // mg, ml, drops, pills

  @HiveField(5)
  String instructions;
  @HiveField(6)
  List<String> scheduleTimes;

  @HiveField(7)
  double stockQuantity; // Total quantity left

  @HiveField(8)
  DateTime startDate;

  @HiveField(9)
  int? dropsPerMl; // Optional conversion for liquids

  MedicineModel({
    required this.id,
    required this.name,
    required this.type,
    required this.doseAmount,
    required this.doseUnit,
    required this.instructions,
    required this.scheduleTimes,
    required this.stockQuantity,
    required this.startDate,
    this.dropsPerMl = 20,
  });
}
