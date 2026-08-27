import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../utils/theme.dart';

ImageProvider? getAvatarImageProvider(String? imagePath) {
  if (imagePath == null || imagePath.trim().isEmpty) return null;
  final path = imagePath.trim();
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  }
  try {
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return FileImage(file);
  } catch (e) {
    debugPrint('Error creating FileImage for path $path: $e');
    return null;
  }
}

class ProfileAvatarIcon extends ConsumerWidget {
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isClickable;

  const ProfileAvatarIcon({
    super.key,
    this.radius = 20, // Prominent size
    this.backgroundColor,
    this.iconColor,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final imagePath = profileAsync.value?.profileImagePath;
    final imageProvider = getAvatarImageProvider(imagePath);

    Widget avatar;
    if (imageProvider != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        backgroundImage: imageProvider,
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? AppTheme.primaryGreen.withValues(alpha: 0.15),
        child: Icon(
          Icons.person,
          size: radius * 1.25,
          color: iconColor ?? AppTheme.primaryGreen,
        ),
      );
    }

    if (!isClickable) return avatar;

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: avatar,
      ),
    );
  }
}
