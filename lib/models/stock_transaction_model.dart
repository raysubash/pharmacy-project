class StockTransaction {
  final String? id;
  final String medicineId;
  final String type;
  final int quantity;
  final int signedQuantity;
  final int resultingQuantity;
  final String? referenceId;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  StockTransaction({
    this.id,
    required this.medicineId,
    required this.type,
    required this.quantity,
    required this.signedQuantity,
    required this.resultingQuantity,
    this.referenceId,
    this.reason = '',
    this.createdBy = 'system',
    required this.createdAt,
  });

  /// Human-readable label for the transaction type
  String get typeLabel {
    switch (type) {
      case 'PURCHASE':
        return 'Purchase';
      case 'SALE':
        return 'Sale';
      case 'RETURN_IN':
        return 'Return (In)';
      case 'RETURN_OUT':
        return 'Return (Out)';
      case 'ADJUSTMENT':
        return 'Adjustment';
      case 'DAMAGE':
        return 'Damage';
      case 'INITIAL':
        return 'Initial Stock';
      default:
        return type;
    }
  }

  /// Whether this transaction increased stock
  bool get isStockIn => signedQuantity > 0;

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    return StockTransaction(
      id: json['_id'] ?? json['id'],
      medicineId: json['medicineId'] ?? '',
      type: json['type'] ?? 'ADJUSTMENT',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      signedQuantity: (json['signedQuantity'] as num?)?.toInt() ?? 0,
      resultingQuantity: (json['resultingQuantity'] as num?)?.toInt() ?? 0,
      referenceId: json['referenceId'],
      reason: json['reason'] ?? '',
      createdBy: json['createdBy'] ?? 'system',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'medicineId': medicineId,
      'type': type,
      'quantity': quantity,
      'signedQuantity': signedQuantity,
      'resultingQuantity': resultingQuantity,
      'referenceId': referenceId,
      'reason': reason,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
