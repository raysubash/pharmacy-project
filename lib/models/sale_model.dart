class SaleItem {
  final String medicineId;
  final String medicineName;
  final int quantity;
  final double price; // Selling Price or CC/RATE
  final double discount;
  final double total;
  final String? batchNumber;
  final DateTime? expiryDate;
  final double? mrp;

  SaleItem({
    required this.medicineId,
    required this.medicineName,
    required this.quantity,
    required this.price,
    this.discount = 0.0,
    required this.total,
    this.batchNumber,
    this.expiryDate,
    this.mrp,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      medicineId: json['medicineId'],
      medicineName: json['medicineName'],
      quantity: int.parse(json['quantity'].toString()),
      price: double.parse(json['price'].toString()),
      discount: double.parse((json['discount'] ?? 0).toString()),
      total: double.parse(json['total'].toString()),
      batchNumber: json['batchNumber'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
      mrp: json['mrp'] != null ? double.parse(json['mrp'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'mrp': mrp,
    };
  }
}

class Sale {
  final String? id;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String? customerPan;
  final String payMode;
  final List<SaleItem> items;
  final double subTotal;
  final double discount;
  final double tax;
  final double grandTotal;
  final DateTime date;

  Sale({
    this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    this.customerPan,
    this.payMode = 'Cash',
    required this.items,
    this.subTotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.grandTotal,
    required this.date,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List;
    List<SaleItem> items = itemsList.map((i) => SaleItem.fromJson(i)).toList();

    return Sale(
      id: json['_id'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'],
      customerAddress: json['customerAddress'],
      customerPan: json['customerPan'],
      payMode: json['payMode'] ?? 'Cash',
      items: items,
      subTotal: double.parse((json['subTotal'] ?? 0).toString()),
      discount: double.parse((json['discount'] ?? 0).toString()),
      tax: double.parse((json['tax'] ?? 0).toString()),
      grandTotal: double.parse((json['grandTotal'] ?? 0).toString()),
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'customerPan': customerPan,
      'payMode': payMode,
      'items': items.map((e) => e.toJson()).toList(),
      'subTotal': subTotal,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'date': date.toIso8601String(),
    };
  }
}
