import 'package:hive/hive.dart';

part 'return_model.g.dart';

@HiveType(typeId: 6)
class ReturnItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String medicineName;
  @HiveField(2)
  final String batchNumber;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final String reason;
  @HiveField(5)
  final DateTime returnDate;
  @HiveField(6)
  final double? refundAmount;
  @HiveField(7)
  String status; // 'Pending', 'Approved', 'Rejected'
  @HiveField(8)
  final String? originalBillNo;
  @HiveField(9)
  final DateTime? expiryDate;
  @HiveField(10)
  final String? supplierName;

  ReturnItem({
    required this.id,
    required this.medicineName,
    required this.batchNumber,
    required this.quantity,
    required this.reason,
    required this.returnDate,
    this.refundAmount,
    this.status = 'Pending',
    this.originalBillNo,
    this.expiryDate,
    this.supplierName,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    return ReturnItem(
      id: json['_id'] ?? json['id'] ?? '',
      medicineName: json['medicineName'],
      batchNumber: json['batchNumber'],
      quantity: int.parse(json['quantity'].toString()),
      reason: json['reason'],
      returnDate: DateTime.parse(json['returnDate']),
      refundAmount:
          json['refundAmount'] != null
              ? double.parse(json['refundAmount'].toString())
              : null,
      status: json['status'] ?? 'Pending',
      originalBillNo: json['originalBillNo'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
      supplierName: json['supplierName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'medicineName': medicineName,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'reason': reason,
      'returnDate': returnDate.toIso8601String(),
      'refundAmount': refundAmount,
      'status': status,
      'originalBillNo': originalBillNo,
      'expiryDate': expiryDate?.toIso8601String(),
      'supplierName': supplierName,
    };
  }
}
