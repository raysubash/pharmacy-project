class PharmacyProfile {
  String id;
  String name;
  String location;
  String panNumber;
  String phoneNumber;
  SubscriptionInfo? subscription;

  PharmacyProfile({
    required this.id,
    required this.name,
    required this.location,
    required this.panNumber,
    required this.phoneNumber,
    this.subscription,
  });

  factory PharmacyProfile.fromJson(Map<String, dynamic> json) {
    return PharmacyProfile(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'],
      location: json['location'],
      panNumber: json['panNumber'],
      phoneNumber: json['phoneNumber'],
      subscription:
          json['subscription'] != null
              ? SubscriptionInfo.fromJson(json['subscription'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) '_id': id,
      'name': name,
      'location': location,
      'panNumber': panNumber,
      'phoneNumber': phoneNumber,
    };
  }
}

class SubscriptionInfo {
  String plan;
  DateTime? startDate;
  DateTime? expiryDate;
  bool isActive;
  String? paymentProofImage;

  SubscriptionInfo({
    required this.plan,
    this.startDate,
    this.expiryDate,
    required this.isActive,
    this.paymentProofImage,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] ?? 'none',
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      expiryDate:
          json['expiryDate'] != null
              ? DateTime.parse(json['expiryDate'])
              : null,
      isActive: json['isActive'] ?? false,
      paymentProofImage: json['paymentProofImage'],
    );
  }
}
