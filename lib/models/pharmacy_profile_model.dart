import 'package:hive/hive.dart';

part 'pharmacy_profile_model.g.dart';

@HiveType(typeId: 8)
class PharmacyProfile {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String location;
  @HiveField(3)
  String panNumber;
  @HiveField(4)
  String phoneNumber;
  @HiveField(5)
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

@HiveType(typeId: 7)
class SubscriptionInfo {
  @HiveField(0)
  String plan;
  @HiveField(1)
  DateTime? startDate;
  @HiveField(2)
  DateTime? expiryDate;
  @HiveField(3)
  bool isActive;
  @HiveField(4)
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
