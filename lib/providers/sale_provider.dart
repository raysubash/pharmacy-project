import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import '../services/api_service.dart';
import 'medicine_provider.dart';

final saleProvider = AsyncNotifierProvider<SaleNotifier, List<Sale>>(() {
  return SaleNotifier();
});

class SaleNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    // Real-time polling: auto-refresh every 8 seconds
    final timer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    return await ApiService.getAllSales();
  }

  Future<void> addSale(Sale sale) async {
    final currentList = state.value ?? [];
    // Optimistically update local state so sales history shows the new sale immediately
    state = AsyncValue.data([sale, ...currentList.where((s) => s.invoiceNumber != sale.invoiceNumber)]);

    try {
      final createdSale = await ApiService.addSale(sale);
      if (createdSale != null) {
        final updatedList = state.value ?? [];
        state = AsyncValue.data([
          createdSale,
          ...updatedList.where((s) => s.invoiceNumber != createdSale.invoiceNumber && s.invoiceNumber != sale.invoiceNumber)
        ]);
      }
      ref.invalidate(medicineProvider);
    } catch (_) {
      // Even if network fails, keep the optimistic sale in state
    }
  }

  Future<void> clearAllSales() async {
    state = const AsyncValue.data([]);
    try {
      await ApiService.deleteAllSales();
      ref.invalidateSelf();
    } catch (_) {
      // Keep optimistic empty state
    }
  }
}
