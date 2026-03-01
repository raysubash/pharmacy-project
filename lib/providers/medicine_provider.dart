import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../services/local_storage_service.dart';

final medicineProvider =
    AsyncNotifierProvider<MedicineNotifier, List<Medicine>>(() {
      return MedicineNotifier();
    });

class MedicineNotifier extends AsyncNotifier<List<Medicine>> {
  @override
  Future<List<Medicine>> build() async {
    // Simulate async if needed, or just return list
    return LocalStorageService.getAllMedicines();
  }

  Future<void> addMedicine(Medicine medicine) async {
    final prev = state;
    state = const AsyncValue.loading();
    try {
      await LocalStorageService.addMedicine(medicine);
      // Refresh list from local storage
      state = AsyncValue.data(LocalStorageService.getAllMedicines());
    } catch (e) {
      state = prev; // Revert on error
      // TODO: Handle error
    }
  }

  Future<void> updateMedicine(String id, Medicine medicine) async {
    try {
      await LocalStorageService.updateMedicine(id, medicine);
      state = AsyncValue.data(LocalStorageService.getAllMedicines());
    } catch (e) {
      // TODO: Handle error
    }
  }

  Future<void> deleteMedicine(String id) async {
    try {
      await LocalStorageService.deleteMedicine(id);
      state = AsyncValue.data(LocalStorageService.getAllMedicines());
    } catch (e) {
      // TODO: Handle error
    }
  }
}
