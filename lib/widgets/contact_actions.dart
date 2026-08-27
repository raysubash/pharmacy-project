import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/theme.dart';

/// Service providing reusable launcher functions for Phone Dialer and WhatsApp
class ContactService {
  /// Opens native Phone Dialer pad with pre-filled number
  static Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
    final String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final String targetNumber = cleanPhone.isNotEmpty ? cleanPhone : phoneNumber;

    if (targetNumber.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid phone number available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: targetNumber,
    );

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch phone dialer for $targetNumber'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Opens direct WhatsApp chat with international number formatting (Default: 977 for Nepal)
  static Future<void> openWhatsApp(BuildContext context, String phoneNumber) async {
    String number = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (number.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid phone number available for WhatsApp.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (number.startsWith('0')) {
      number = number.substring(1);
    }

    if (!number.startsWith('977')) {
      number = '977$number';
    }

    final Uri uri = Uri.parse('https://wa.me/$number');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening WhatsApp for $number...'),
          backgroundColor: const Color(0xFF25D366),
        ),
      );
    }
  }
}

/// Production-ready reusable UI widget presenting [ 📞 Call ] and [ 💬 WhatsApp ] buttons
class ContactActionButtons extends StatelessWidget {
  final String phoneNumber;
  final String? supplierName;

  const ContactActionButtons({
    super.key,
    required this.phoneNumber,
    this.supplierName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 📞 Call Button
        Expanded(
          child: SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => ContactService.makePhoneCall(context, phoneNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.call, size: 18),
              label: const Text(
                'Call',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // 💬 WhatsApp Button
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => ContactService.openWhatsApp(context, phoneNumber),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFF25D366)),
              label: const Text(
                'WhatsApp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF25D366),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
