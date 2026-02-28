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
    return ApiService.getProfile();
  }

  Future<void> saveProfile(PharmacyProfile profile) async {
    state = const AsyncValue.loading();
    try {
      await ApiService.saveProfile(profile);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> fetchProfile() async {
    ref.invalidateSelf();
  }
}
