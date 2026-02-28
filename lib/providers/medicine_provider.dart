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
    return ApiService.getAllMedicines();
  }

  Future<void> addMedicine(Medicine medicine) async {
    // Optimistic update or refresh
    final prev = state;
    state = const AsyncValue.loading();
    try {
      await ApiService.addMedicine(medicine);
      ref.invalidateSelf();
    } catch (e) {
      state = prev; // Revert on error
      // TODO: Handle error
    }
  }

  Future<void> updateMedicine(String id, Medicine medicine) async {
    try {
      await ApiService.updateMedicine(id, medicine);
      ref.invalidateSelf();
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await ApiService.deleteMedicine(id);
      ref.invalidateSelf();
    } catch (e) {
      // TODO: Handle error
    }
  }
}
