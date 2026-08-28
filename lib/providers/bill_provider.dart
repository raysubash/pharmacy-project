import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../services/api_service.dart';
import 'medicine_provider.dart';

final billProvider = AsyncNotifierProvider<BillNotifier, List<PurchaseBill>>(
  () {
    return BillNotifier();
  },
);

class BillNotifier extends AsyncNotifier<List<PurchaseBill>> {
  @override
  Future<List<PurchaseBill>> build() async {
    // Real-time polling: auto-refresh every 8 seconds
    final timer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    return await ApiService.getAllBills();
  }

  Future<void> addBill(PurchaseBill bill) async {
    try {
      await ApiService.addPurchaseBill(bill);
      ref.invalidate(medicineProvider);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await ApiService.deleteBill(id);
      ref.invalidate(medicineProvider);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
