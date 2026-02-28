import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sale_model.dart';
import '../services/api_service.dart';

final saleProvider = AsyncNotifierProvider<SaleNotifier, List<Sale>>(() {
  return SaleNotifier();
});

class SaleNotifier extends AsyncNotifier<List<Sale>> {
  @override
  Future<List<Sale>> build() async {
    return ApiService.getAllSales();
  }

  Future<void> addSale(Sale sale) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.addSale(sale);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
