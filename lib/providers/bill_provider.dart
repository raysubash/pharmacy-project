import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../services/local_storage_service.dart';

final billProvider = AsyncNotifierProvider<BillNotifier, List<PurchaseBill>>(
  () {
    return BillNotifier();
  },
);

class BillNotifier extends AsyncNotifier<List<PurchaseBill>> {
  @override
  Future<List<PurchaseBill>> build() async {
    return LocalStorageService.getAllBills();
  }

  Future<void> addBill(PurchaseBill bill) async {
    state = const AsyncValue.loading();
    try {
      await LocalStorageService.addBill(bill);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await LocalStorageService.deleteBill(id);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }
}
