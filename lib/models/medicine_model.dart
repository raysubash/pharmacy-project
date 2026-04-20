import 'package:hive/hive.dart';

part 'medicine_model.g.dart';

@HiveType(typeId: 0)
enum MeasureUnit {
  @HiveField(0)
  tablet,
  @HiveField(1)
  syrup,
  @HiveField(2)
  capsule,
  @HiveField(3)
  injection,
  @HiveField(4)
  other,
}

@HiveType(typeId: 1)
class Medicine {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String? genericName;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final MeasureUnit unit;
  @HiveField(5)
  final int minStock;
  @HiveField(6)
  final double sellingPrice;
  @HiveField(7)
  final String? storageLocation;
  @HiveField(8)
  int currentStock;
  @HiveField(9)
  final String? brandName;
  @HiveField(10)
  final String? packaging;
  @HiveField(11)
  final double? mrp;
  @HiveField(12)
  final String? imagePath;
  @HiveField(13)
  final String? batchNumber;
  @HiveField(14)
  final DateTime? expiryDate;
  @HiveField(15)
  final DateTime createdDate;

  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    required this.category,
    required this.unit,
    required this.minStock,
    required this.sellingPrice,
    this.storageLocation,
    this.currentStock = 0,
    this.brandName,
    this.packaging,
    this.mrp,
    this.imagePath,
    this.batchNumber,
    this.expiryDate,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      genericName: json['genericName'],
      category: json['category'],
      unit: _parseUnit(json['unit']),
      minStock: json['minStock'],
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      storageLocation: json['storageLocation'],
      currentStock: json['currentStock'] ?? 0,
      brandName: json['brandName'],
      packaging: json['packaging'],
      mrp: (json['mrp'] as num?)?.toDouble(),
      imagePath: json['imagePath'],
      batchNumber: json['batchNumber'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
      createdDate:
          json['createdDate'] != null
              ? DateTime.parse(json['createdDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'genericName': genericName,
      'category': category,
      'unit': unit.toString().split('.').last,
      'minStock': minStock,
      'sellingPrice': sellingPrice,
      'storageLocation': storageLocation,
      'currentStock': currentStock,
      'brandName': brandName,
      'packaging': packaging,
      'mrp': mrp,
      'imagePath': imagePath,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
    };
  }

  static MeasureUnit _parseUnit(String unitString) {
    return MeasureUnit.values.firstWhere(
      (e) => e.toString().split('.').last == unitString,
      orElse: () => MeasureUnit.other,
    );
  }
}
