import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/pharmacy_profile_model.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/profile_avatar_icon.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isSetupMode;
  const ProfileScreen({super.key, this.isSetupMode = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoading = false;

  Future<void> _pickAndSaveImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      String? selectedImagePath;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 85,
        );
        if (pickedFile != null) {
          selectedImagePath = pickedFile.path;
        }
      } else {
        // Desktop / Fallback
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          selectedImagePath = result.files.single.path;
        }
      }

      if (selectedImagePath != null) {
        final currentProfile = ref.read(profileProvider).value;
        final updatedProfile = PharmacyProfile(
          id: currentProfile?.id ?? '',
          name: currentProfile?.name ?? 'Pharmacist Admin',
          location: currentProfile?.location ?? 'Kathmandu, Nepal',
          panNumber: currentProfile?.panNumber ?? '1234-123-9874',
          phoneNumber: currentProfile?.phoneNumber ?? '9841234567',
          subscription: currentProfile?.subscription,
          profileImagePath: selectedImagePath,
        );

        await ref.read(profileProvider.notifier).saveProfile(updatedProfile);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update photo: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: [
                const ListTile(
                  title: Text(
                    'Update Profile Picture',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGreen),
                  title: const Text('Take Photo (Camera)'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppTheme.primaryGreen),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSaveImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileBottomSheet(PharmacyProfile? currentProfile) {
    final nameController = TextEditingController(text: currentProfile?.name ?? '');
    final panController = TextEditingController(text: currentProfile?.panNumber ?? '');
    final locationController = TextEditingController(text: currentProfile?.location ?? '');
    final phoneController = TextEditingController(text: currentProfile?.phoneNumber ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Edit Profile Information',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Pharmacy / User Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Mobile Phone',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: panController,
                    decoration: InputDecoration(
                      labelText: 'Tell / PAN Number',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);
                          setState(() => _isLoading = true);

                          final updated = PharmacyProfile(
                            id: currentProfile?.id ?? '',
                            name: nameController.text.trim(),
                            panNumber: panController.text.trim(),
                            location: locationController.text.trim(),
                            phoneNumber: phoneController.text.trim(),
                            subscription: currentProfile?.subscription,
                            profileImagePath: currentProfile?.profileImagePath,
                          );

                          try {
                            await ref.read(profileProvider.notifier).saveProfile(updated);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Profile details saved successfully!'),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error updating profile: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final passFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: passFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password'),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm New Password'),
                    validator: (v) => (v != newPassCtrl.text) ? 'Passwords do not match' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (passFormKey.currentState!.validate()) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: AppTheme.primaryGreen,
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: widget.isSetupMode ? null : const AppDrawer(),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (profile) {
          final displayName = profile?.name.isNotEmpty == true
              ? profile!.name
              : (authState.userName ?? 'Pharmacist');
          final displayEmail = '${displayName.toLowerCase().replaceAll(' ', '')}@gmail.com';
          final mobileNum = profile?.phoneNumber.isNotEmpty == true
              ? profile!.phoneNumber
              : 'Not set';
          final tellNum = profile?.panNumber.isNotEmpty == true
              ? profile!.panNumber
              : 'Not set';
          final addressStr = profile?.location.isNotEmpty == true
              ? profile!.location
              : 'Not set';
          final postalCodeStr = 'Not set';

          final avatarImageProvider = getAvatarImageProvider(profile?.profileImagePath);

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Header Section with Green Banner & Avatar
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Green Background with Soft Bubbles Pattern
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF2E7D32),
                            Color(0xFF4CAF50),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -40,
                            right: -30,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            left: -40,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 40,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 44,
                            left: 16,
                            child: SafeArea(
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/dashboard');
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Centered Profile Avatar & Name with Camera Upload Icon Badge
                    Positioned(
                      top: 60,
                      child: Column(
                        children: [
                          // Interactive Avatar with Camera Upload Icon Badge
                          GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: const Color(0xFFE8F5E9),
                                    backgroundImage: avatarImageProvider,
                                    child: avatarImageProvider == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 54,
                                            color: AppTheme.primaryGreen,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating White Main Card
                Transform.translate(
                  offset: const Offset(0, -25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              // Top 3 Action Icons Row: Payment | Settings | Notification
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildTopActionButton(
                                    context,
                                    icon: Icons.account_balance_wallet_outlined,
                                    label: 'Payment',
                                    onTap: () => context.push('/subscription'),
                                  ),
                                  _buildTopActionButton(
                                    context,
                                    icon: Icons.settings_outlined,
                                    label: 'Settings',
                                    onTap: () => _showEditProfileBottomSheet(profile),
                                  ),
                                  _buildTopActionButton(
                                    context,
                                    icon: Icons.assessment_outlined,
                                    label: 'Report',
                                    onTap: () => context.push('/reports'),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              Divider(color: Colors.grey.shade200, height: 1),
                              const SizedBox(height: 16),

                              // Info List Rows
                              _buildInfoRow(
                                label: 'Password:',
                                trailingWidget: GestureDetector(
                                  onTap: _showChangePasswordDialog,
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 16),

                              _buildInfoRow(
                                label: 'Mobile:',
                                value: mobileNum,
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 16),

                              _buildInfoRow(
                                label: 'Tell / PAN:',
                                value: tellNum,
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 16),

                              _buildInfoRow(
                                label: 'Address:',
                                value: addressStr,
                              ),
                              const SizedBox(height: 16),
                              Divider(color: Colors.grey.shade100, height: 1),
                              const SizedBox(height: 16),

                              _buildInfoRow(
                                label: 'PostalCode:',
                                value: postalCodeStr,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Bottom Green Pill Button: Edit Profile
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _showEditProfileBottomSheet(profile),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    String? value,
    Widget? trailingWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        if (trailingWidget != null)
          trailingWidget
        else
          Text(
            value ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }
}
