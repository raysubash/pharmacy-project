import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/return_model.dart';
import '../services/api_service.dart';

final returnProvider = AsyncNotifierProvider<ReturnNotifier, List<ReturnItem>>(
  () {
    return ReturnNotifier();
  },
);

class ReturnNotifier extends AsyncNotifier<List<ReturnItem>> {
  @override
  Future<List<ReturnItem>> build() async {
    // Real-time polling: auto-refresh every 8 seconds
    final timer = Timer.periodic(const Duration(seconds: 8), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    return await ApiService.getAllReturns();
  }

  Future<void> addReturn(ReturnItem returnItem) async {
    try {
      await ApiService.addReturn(returnItem);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateReturn(String id, ReturnItem returnItem) async {
    try {
      // TODO: Add ApiService.updateReturn when backend supports it
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReturn(String id) async {
    try {
      await ApiService.deleteReturn(id);
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
