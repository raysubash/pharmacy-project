import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../services/api_service.dart';

final medicineProvider =
    AsyncNotifierProvider<MedicineNotifier, List<Medicine>>(() {
      return MedicineNotifier();
    });

class MedicineNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    // Real-time polling: auto-refresh every 8 seconds
    final timer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    return await ApiService.getAllMedicines();
  }

  Future<void> addMedicine(Medicine medicine) async {
    try {
      await ApiService.addMedicine(medicine);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateMedicine(String id, Medicine medicine) async {
    try {
      await ApiService.updateMedicine(id, medicine);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await ApiService.deleteMedicine(id);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
