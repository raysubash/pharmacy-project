import 'package:hive/hive.dart';

part 'bill_model.g.dart';

@HiveType(typeId: 4)
class BillItem {
  @HiveField(0)
  final String medicineId;
  @HiveField(1)
  final String medicineName;
  @HiveField(2)
  final String batchNumber;
  @HiveField(3)
  final DateTime manufactureDate;
  @HiveField(4)
  final DateTime expiryDate;
  @HiveField(5)
  final int quantity;
  @HiveField(6)
  final double purchasePrice;
  @HiveField(7)
  final double totalAmount;

  BillItem({
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    required this.purchasePrice,
  }) : totalAmount = quantity * purchasePrice;

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      medicineId: json['medicineId'],
      medicineName: json['medicineName'],
      batchNumber: json['batchNumber'],
      manufactureDate: DateTime.parse(json['manufactureDate']),
      expiryDate: DateTime.parse(json['expiryDate']),
      quantity: int.parse(json['quantity'].toString()),
      purchasePrice: double.parse(json['purchasePrice'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'batchNumber': batchNumber,
      'manufactureDate': manufactureDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'quantity': quantity,
      'purchasePrice': purchasePrice,
      'totalAmount': totalAmount,
    };
  }
}

@HiveType(typeId: 5)
class PurchaseBill {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String billNumber;
  @HiveField(2)
  final String supplierName;
  @HiveField(3)
  final DateTime billDate;
  @HiveField(4)
  final List<BillItem> items;
  @HiveField(5)
  final double totalAmount;
  @HiveField(6)
  final DateTime entryDate;

  PurchaseBill({
    required this.id,
    required this.billNumber,
    required this.supplierName,
    required this.billDate,
    required this.items,
    required this.totalAmount,
    required this.entryDate,
  });

  factory PurchaseBill.fromJson(Map<String, dynamic> json) {
    return PurchaseBill(
      id: json['_id'] ?? json['id'] ?? '',
      billNumber: json['billNumber'],
      supplierName: json['supplierName'],
      billDate: DateTime.parse(json['billDate']),
      items:
          (json['items'] as List)
              .map((item) => BillItem.fromJson(item))
              .toList(),
      totalAmount: double.parse(json['totalAmount'].toString()),
      entryDate: DateTime.parse(json['entryDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'billNumber': billNumber,
      'supplierName': supplierName,
      'billDate': billDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'entryDate': entryDate.toIso8601String(),
    };
  }
}
