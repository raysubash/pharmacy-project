import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pharmacy_profile_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, PharmacyProfile?>(() {
      return ProfileNotifier();
    });

class ProfileNotifier extends AsyncNotifier<PharmacyProfile?> {
  @override
  Future<PharmacyProfile?> build() async {
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
      await LocalStorageService.saveProfile(profile);
      state = AsyncValue.data(profile);
    }
  }

  Future<void> fetchProfile() async {
    ref.invalidateSelf();
  }
}
