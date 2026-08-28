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
    String medName = '';
    if (json['medicineName'] != null && json['medicineName'].toString().isNotEmpty) {
      medName = json['medicineName'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      medName = json['name'].toString();
    } else if (json['medicine'] != null) {
      if (json['medicine'] is Map && json['medicine']['name'] != null) {
        medName = json['medicine']['name'].toString();
      } else if (json['medicine'] is String) {
        medName = json['medicine'].toString();
      }
    }

    String medId = '';
    if (json['medicineId'] != null) {
      medId = json['medicineId'].toString();
    } else if (json['medicine'] != null && json['medicine'] is Map && json['medicine']['_id'] != null) {
      medId = json['medicine']['_id'].toString();
    } else if (json['id'] != null) {
      medId = json['id'].toString();
    }

    int qty = int.tryParse((json['quantity'] ?? json['qty'] ?? 1).toString()) ?? 1;
    double prc = double.tryParse((json['price'] ?? json['rate'] ?? json['sellingPrice'] ?? json['mrp'] ?? 0).toString()) ?? 0.0;
    double disc = double.tryParse((json['discount'] ?? 0).toString()) ?? 0.0;
    double tot = double.tryParse((json['total'] ?? json['amount'] ?? (qty * prc)).toString()) ?? (qty * prc);

    return SaleItem(
      medicineId: medId,
      medicineName: medName.isEmpty ? 'Medicine Item' : medName,
      quantity: qty,
      price: prc,
      discount: disc,
      total: tot,
      batchNumber: json['batchNumber'] ?? json['batch'] ?? json['batchNo'],
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.tryParse(json['expiryDate'].toString())
              : null,
      mrp: json['mrp'] != null ? double.tryParse(json['mrp'].toString()) : (prc > 0 ? prc : null),
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
    if (json.containsKey('sale') && json['sale'] is Map) {
      json = Map<String, dynamic>.from(json['sale'] as Map);
    }
    var rawItems = json['items'];
    List<SaleItem> items = [];
    if (rawItems is List) {
      items = rawItems.map((i) {
        if (i is Map<String, dynamic>) {
          return SaleItem.fromJson(i);
        } else if (i is Map) {
          return SaleItem.fromJson(Map<String, dynamic>.from(i));
        }
        return SaleItem(medicineId: '', medicineName: 'Item', quantity: 1, price: 0, total: 0);
      }).toList();
    }

    String getRawPayMode(Map<String, dynamic> map) {
      final keys = [
        'payMode',
        'paymentMode',
        'pay_mode',
        'payment_mode',
        'paymentMethod',
        'payMethod',
        'payment_method',
        'pay_method',
        'paymentType',
        'payment_type',
        'payType',
        'pay_type',
        'mode',
        'payment',
        'type',
        'method'
      ];
      for (final key in keys) {
        final val = map[key]?.toString().trim();
        if (val != null && val.isNotEmpty && val.toLowerCase() != 'null') {
          return val;
        }
      }
      return 'Cash';
    }

    final rawPayMode = getRawPayMode(json);
    String normalizedPayMode = 'Cash';
    if (rawPayMode.toLowerCase().contains('fone') ||
        rawPayMode.toLowerCase().contains('qr') ||
        rawPayMode.toLowerCase().contains('online') ||
        rawPayMode.toLowerCase().contains('digital')) {
      normalizedPayMode = 'Fonepay';
    } else if (rawPayMode.toLowerCase().contains('credit')) {
      normalizedPayMode = 'Credit';
    } else {
      normalizedPayMode = 'Cash';
    }

    return Sale(
      id: json['_id'] ?? json['id'],
      invoiceNumber: json['invoiceNumber'] ?? json['invoiceNo'] ?? '',
      customerName: json['customerName'] ?? json['customer']?['name'] ?? json['customer'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer']?['phone'],
      customerAddress: json['customerAddress'] ?? json['customer']?['address'],
      customerPan: json['customerPan'] ?? json['customer']?['pan'],
      payMode: normalizedPayMode,
      items: items,
      subTotal: double.tryParse((json['subTotal'] ?? json['subtotal'] ?? 0).toString()) ?? 0.0,
      discount: double.tryParse((json['discount'] ?? 0).toString()) ?? 0.0,
      tax: double.tryParse((json['tax'] ?? 0).toString()) ?? 0.0,
      grandTotal: double.tryParse((json['grandTotal'] ?? json['total'] ?? 0).toString()) ?? 0.0,
      date: json['date'] != null ? (DateTime.tryParse(json['date'].toString()) ?? DateTime.now()) : DateTime.now(),
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
      'paymentMode': payMode,
      'pay_mode': payMode,
      'payment_mode': payMode,
      'paymentMethod': payMode,
      'payMethod': payMode,
      'payment_method': payMode,
      'pay_method': payMode,
      'paymentType': payMode,
      'payment_type': payMode,
      'payType': payMode,
      'pay_type': payMode,
      'mode': payMode,
      'payment': payMode,
      'type': payMode,
      'method': payMode,
      'items': items.map((e) => e.toJson()).toList(),
      'subTotal': subTotal,
      'discount': discount,
      'tax': tax,
      'grandTotal': grandTotal,
      'date': date.toIso8601String(),
    };
  }
}
