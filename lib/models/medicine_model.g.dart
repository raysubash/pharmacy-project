// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicineAdapter extends TypeAdapter<Medicine> {
  @override
  final int typeId = 1;

  @override
  Medicine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medicine(
      id: fields[0] as String,
      name: fields[1] as String,
      genericName: fields[2] as String?,
      category: fields[3] as String,
      unit: fields[4] as MeasureUnit,
      minStock: fields[5] as int,
      sellingPrice: fields[6] as double,
      storageLocation: fields[7] as String?,
      currentStock: fields[8] as int,
      brandName: fields[9] as String?,
      packaging: fields[10] as String?,
      mrp: fields[11] as double?,
      imagePath: fields[12] as String?,
      batchNumber: fields[13] as String?,
      expiryDate: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Medicine obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.genericName)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.minStock)
      ..writeByte(6)
      ..write(obj.sellingPrice)
      ..writeByte(7)
      ..write(obj.storageLocation)
      ..writeByte(8)
      ..write(obj.currentStock)
      ..writeByte(9)
      ..write(obj.brandName)
      ..writeByte(10)
      ..write(obj.packaging)
      ..writeByte(11)
      ..write(obj.mrp)
      ..writeByte(12)
      ..write(obj.imagePath)
      ..writeByte(13)
      ..write(obj.batchNumber)
      ..writeByte(14)
      ..write(obj.expiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasureUnitAdapter extends TypeAdapter<MeasureUnit> {
  @override
  final int typeId = 0;

  @override
  MeasureUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MeasureUnit.tablet;
      case 1:
        return MeasureUnit.syrup;
      case 2:
        return MeasureUnit.capsule;
      case 3:
        return MeasureUnit.injection;
      case 4:
        return MeasureUnit.other;
      default:
        return MeasureUnit.tablet;
    }
  }

  @override
  void write(BinaryWriter writer, MeasureUnit obj) {
    switch (obj) {
      case MeasureUnit.tablet:
        writer.writeByte(0);
        break;
      case MeasureUnit.syrup:
        writer.writeByte(1);
        break;
      case MeasureUnit.capsule:
        writer.writeByte(2);
        break;
      case MeasureUnit.injection:
        writer.writeByte(3);
        break;
      case MeasureUnit.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasureUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
