import 'package:flutter/material.dart';

enum MeasureUnit {
  tablet,
  syrup,
  capsule,
  injection,
  other,
}

enum MedicineStatus {
  expired,
  expiringSoon,
  lowStock,
  overStock,
  inStock,
}

extension MedicineStatusX on MedicineStatus {
  String get label {
    switch (this) {
      case MedicineStatus.expired:
        return 'Expired';
      case MedicineStatus.expiringSoon:
        return 'Expiring Soon';
      case MedicineStatus.lowStock:
        return 'Low Stock';
      case MedicineStatus.overStock:
        return 'Over Stock';
      case MedicineStatus.inStock:
        return 'In Stock';
    }
  }

  Color get color {
    switch (this) {
      case MedicineStatus.expired:
        return const Color(0xFFD32F2F);
      case MedicineStatus.expiringSoon:
        return const Color(0xFFE65100);
      case MedicineStatus.lowStock:
        return const Color(0xFFF57C00);
      case MedicineStatus.overStock:
        return const Color(0xFF7B1FA2);
      case MedicineStatus.inStock:
        return const Color(0xFF2E7D32);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case MedicineStatus.expired:
        return const Color(0xFFFFEBEE);
      case MedicineStatus.expiringSoon:
        return const Color(0xFFFFF3E0);
      case MedicineStatus.lowStock:
        return const Color(0xFFFFF8E1);
      case MedicineStatus.overStock:
        return const Color(0xFFF3E5F5);
      case MedicineStatus.inStock:
        return const Color(0xE8E8F5E9);
    }
  }

  IconData get icon {
    switch (this) {
      case MedicineStatus.expired:
        return Icons.error_outline;
      case MedicineStatus.expiringSoon:
        return Icons.access_time_outlined;
      case MedicineStatus.lowStock:
        return Icons.warning_amber_rounded;
      case MedicineStatus.overStock:
        return Icons.inventory_2_outlined;
      case MedicineStatus.inStock:
        return Icons.check_circle_outline;
    }
  }
}

class Medicine {
  final String id;
  final String name;
  final String? genericName;
  final String category;
  final MeasureUnit unit;
  final int minStock;
  final double sellingPrice;
  final String? storageLocation;
  final int currentStock;
  final String? brandName;
  final String? packaging;
  final double? mrp;
  final String? imagePath;
  final String? batchNumber;
  final String? barcode;
  final DateTime? expiryDate;
  final DateTime createdDate;
  final int? maxStock;

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
    this.barcode,
    this.expiryDate,
    this.maxStock,
    DateTime? createdDate,
  }) : createdDate = createdDate ?? DateTime.now();

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  MedicineStatus get primaryStatus {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (expiryDate != null) {
      final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
      if (expiry.isBefore(today)) {
        return MedicineStatus.expired;
      }
      final days = expiry.difference(today).inDays;
      if (days <= 30) {
        return MedicineStatus.expiringSoon;
      }
    }

    if (currentStock <= minStock) {
      return MedicineStatus.lowStock;
    }

    if (maxStock != null && maxStock! > 0 && currentStock > maxStock!) {
      return MedicineStatus.overStock;
    }

    return MedicineStatus.inStock;
  }

  List<MedicineStatus> get activeStatuses {
    final List<MedicineStatus> statuses = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (expiryDate != null) {
      final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
      if (expiry.isBefore(today)) {
        statuses.add(MedicineStatus.expired);
      } else {
        final days = expiry.difference(today).inDays;
        if (days <= 30) {
          statuses.add(MedicineStatus.expiringSoon);
        }
      }
    }

    if (currentStock <= minStock) {
      statuses.add(MedicineStatus.lowStock);
    }

    if (maxStock != null && maxStock! > 0 && currentStock > maxStock!) {
      statuses.add(MedicineStatus.overStock);
    }

    if (statuses.isEmpty) {
      statuses.add(MedicineStatus.inStock);
    }

    return statuses;
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      genericName: json['genericName'],
      category: json['category'],
      unit: _parseUnit(json['unit']),
      minStock: json['minStock'] ?? 0,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      storageLocation: json['storageLocation'],
      currentStock: json['currentStock'] ?? 0,
      brandName: json['brandName'],
      packaging: json['packaging'],
      mrp: (json['mrp'] as num?)?.toDouble(),
      imagePath: json['imagePath'],
      batchNumber: json['batchNumber'],
      barcode: json['barcode'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
      maxStock: json['maxStock'] as int?,
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
      'barcode': barcode,
      'expiryDate': expiryDate?.toIso8601String(),
      'maxStock': maxStock,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  /// For update operations — excludes currentStock since it's managed by stock transactions
  Map<String, dynamic> toJsonForUpdate() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'genericName': genericName,
      'category': category,
      'unit': unit.toString().split('.').last,
      'minStock': minStock,
      'sellingPrice': sellingPrice,
      'storageLocation': storageLocation,
      'brandName': brandName,
      'packaging': packaging,
      'mrp': mrp,
      'imagePath': imagePath,
      'batchNumber': batchNumber,
      'barcode': barcode,
      'expiryDate': expiryDate?.toIso8601String(),
      'maxStock': maxStock,
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
