class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String status; // 'Active Vendor', 'Primary Partner', 'Expediting'
  final List<String> categories;
  final String iconType; // 'truck', 'surgical', 'pill', 'biotech'
  final String? billImagePath;
  final String? billNumber;
  final double? billAmount;

  Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    this.status = 'Active Vendor',
    required this.categories,
    this.iconType = 'truck',
    this.billImagePath,
    this.billNumber,
    this.billAmount,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'Active Vendor',
      categories: List<String>.from(json['categories'] ?? []),
      iconType: json['iconType'] ?? 'truck',
      billImagePath: json['billImagePath'],
      billNumber: json['billNumber'],
      billAmount: json['billAmount'] != null
          ? double.tryParse(json['billAmount'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactPerson': contactPerson,
      'phone': phone,
      'email': email,
      'status': status,
      'categories': categories,
      'iconType': iconType,
      'billImagePath': billImagePath,
      'billNumber': billNumber,
      'billAmount': billAmount,
    };
  }
}
