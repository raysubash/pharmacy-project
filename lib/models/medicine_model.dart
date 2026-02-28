enum MeasureUnit { tablet, syrup, capsule, injection, other }

class Medicine {
  final String id;
  final String name;
  final String? genericName;
  final String category;
  final MeasureUnit unit;
  final int minStock;
  final double sellingPrice;
  final String? storageLocation;
  int currentStock;
  final String? brandName;
  final String? packaging;
  final double? mrp;
  final String? imagePath;
  final String? batchNumber;
  final DateTime? expiryDate;

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
  });

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
    };
  }

  static MeasureUnit _parseUnit(String unitString) {
    return MeasureUnit.values.firstWhere(
      (e) => e.toString().split('.').last == unitString,
      orElse: () => MeasureUnit.other,
    );
  }
}
