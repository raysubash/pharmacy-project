import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/return_model.dart';
import '../services/local_storage_service.dart';

final returnProvider = AsyncNotifierProvider<ReturnNotifier, List<ReturnItem>>(
  () {
    return ReturnNotifier();
  },
);

class ReturnNotifier extends AsyncNotifier<List<ReturnItem>> {
  @override
  Future<List<ReturnItem>> build() async {
    return LocalStorageService.getAllReturns();
  }

  Future<void> addReturn(ReturnItem returnItem) async {
    // state = const AsyncValue.loading(); // Don't wipe the list immediately
    try {
      await LocalStorageService.addReturn(returnItem);
      // ref.invalidateSelf(); // This triggers a full refresh
      // Optimized: Just refresh without clearing if possible, or let the UI handle the 'refreshing' state
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st); // Set error state if adding fails
      rethrow; // Re-throw so the UI knows it failed!
    }
  }

  Future<void> updateReturn(String id, ReturnItem returnItem) async {
    try {
      await LocalStorageService.updateReturn(id, returnItem);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> deleteReturn(String id) async {
    try {
      await LocalStorageService.deleteReturn(id);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }
}
