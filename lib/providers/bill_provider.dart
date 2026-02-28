import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../services/api_service.dart';

final billProvider = AsyncNotifierProvider<BillNotifier, List<PurchaseBill>>(
  () {
    return BillNotifier();
  },
);

class BillNotifier extends AsyncNotifier<List<PurchaseBill>> {
  @override
  Future<List<PurchaseBill>> build() async {
    return ApiService.getAllBills();
  }

  Future<void> addBill(PurchaseBill bill) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.addPurchaseBill(bill);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await ApiService.deleteBill(id);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }
}
