// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pharmacy_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PharmacyProfileAdapter extends TypeAdapter<PharmacyProfile> {
  @override
  final int typeId = 8;

  @override
  PharmacyProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PharmacyProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      location: fields[2] as String,
      panNumber: fields[3] as String,
      phoneNumber: fields[4] as String,
      subscription: fields[5] as SubscriptionInfo?,
    );
  }

  @override
  void write(BinaryWriter writer, PharmacyProfile obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.location)
      ..writeByte(3)
      ..write(obj.panNumber)
      ..writeByte(4)
      ..write(obj.phoneNumber)
      ..writeByte(5)
      ..write(obj.subscription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PharmacyProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SubscriptionInfoAdapter extends TypeAdapter<SubscriptionInfo> {
  @override
  final int typeId = 7;

  @override
  SubscriptionInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscriptionInfo(
      plan: fields[0] as String,
      startDate: fields[1] as DateTime?,
      expiryDate: fields[2] as DateTime?,
      isActive: fields[3] as bool,
      paymentProofImage: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SubscriptionInfo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.plan)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.expiryDate)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.paymentProofImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
