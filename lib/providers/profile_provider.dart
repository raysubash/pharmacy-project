import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pharmacy_profile_model.dart';
import '../services/api_service.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, PharmacyProfile?>(() {
      return ProfileNotifier();
    });

class ProfileNotifier extends AsyncNotifier<PharmacyProfile?> {
  @override
  Future<PharmacyProfile?> build() async {
    // Real-time polling: auto-refresh every 12 seconds
    final timer = Timer.periodic(const Duration(seconds: 12), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());

    return ApiService.getProfile();
  }

  Future<void> saveProfile(PharmacyProfile profile) async {
    state = AsyncValue.data(profile);
    try {
      final updated = await ApiService.saveProfile(profile);
      if (updated != null) {
        state = AsyncValue.data(updated);
      }
    } catch (e) {
      // Keep local optimistic state on error
      state = AsyncValue.data(profile);
    }
  }

  Future<void> fetchProfile() async {
    ref.invalidateSelf();
  }
}
