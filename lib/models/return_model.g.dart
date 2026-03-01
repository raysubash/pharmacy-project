// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'return_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReturnItemAdapter extends TypeAdapter<ReturnItem> {
  @override
  final int typeId = 6;

  @override
  ReturnItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReturnItem(
      id: fields[0] as String,
      medicineName: fields[1] as String,
      batchNumber: fields[2] as String,
      quantity: fields[3] as int,
      reason: fields[4] as String,
      returnDate: fields[5] as DateTime,
      refundAmount: fields[6] as double?,
      status: fields[7] as String,
      originalBillNo: fields[8] as String?,
      expiryDate: fields[9] as DateTime?,
      supplierName: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReturnItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineName)
      ..writeByte(2)
      ..write(obj.batchNumber)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.reason)
      ..writeByte(5)
      ..write(obj.returnDate)
      ..writeByte(6)
      ..write(obj.refundAmount)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.originalBillNo)
      ..writeByte(9)
      ..write(obj.expiryDate)
      ..writeByte(10)
      ..write(obj.supplierName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
