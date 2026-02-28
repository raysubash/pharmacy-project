import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';
import 'package:pharmacyproject/providers/profile_provider.dart';
import 'package:pharmacyproject/services/api_service.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  // Test Public Key
  // Note: This is a Test Key. Replace with your Live Public Key for production.
  final String _publicKey = "test_public_key_dc74e0fd57cb46cd93832aee0a390234";

  Future<void> _uploadStatement({
    required String planName,
    required String amount,
    required File image,
  }) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    try {
      // Convert image to base64
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Call backend endpoint "upload-statement"
      await ApiService.uploadStatement(
        pharmacyId: profile.id,
        plan: planName,
        amount: amount,
        paymentProofImage: base64Image,
      );

      // Refresh profile so the "View Payment Proof" button appears
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Statement Uploaded! Pending Verification."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close dialog
        context.go('/dashboard');
      }
    } catch (e) {
      log("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload statement: $e")),
        );
      }
    }
  }

  // Placeholder - currently unused as we show instructions first
  // ignore: unused_element
  Future<void> _processPayment(String planName, String amount) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile not loaded. Please try again."),
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Initiating Khalti Payment...")),
        );
      }

      // 1. Initiate Payment on Backend to get PIDX
      final pidxData = await ApiService.initiateKhaltiPayment(
        amount: amount,
        purchaseOrderId:
            "SUB-${profile.id}-${DateTime.now().millisecondsSinceEpoch}",
        purchaseOrderName: "Pharmacy Subscription - $planName",
        customerInfo: {
          "name": profile.name,
          "email": "pharmacy@example.com", // Add actual email if available
          "phone": profile.phoneNumber,
        },
      );

      final String pidx = pidxData['pidx'];
      if (pidx.isEmpty) {
        throw Exception("Failed to get PIDX from backend");
      }

      log("Received PIDX: $pidx");

      if (!mounted) return;

      // 2. Initialize Khalti SDK with PIDX
      final config = KhaltiPayConfig(
        publicKey: _publicKey,
        pidx: pidx,
        environment: Environment.test,
      );

      final khalti = await Khalti.init(
        enableDebugging: true,
        payConfig: config,
        onPaymentResult: (paymentResult, khalti) {
          log("Payment Result Callback: ${paymentResult.payload?.status}");
          _handlePaymentResult(paymentResult, planName, amount);
          khalti.close(context);
        },
        onMessage: (
          khalti, {
          description,
          statusCode,
          event,
          needsPaymentConfirmation,
        }) async {
          log("Khalti Message: $description, Status: $statusCode");
          khalti.close(context);
        },
        onReturn: () {
          log("Khalti Return callback");
        },
      );

      // 3. Open Khalti Checkout
      if (mounted) {
        khalti.open(context);
      }
    } catch (e) {
      log("Khalti Error: $e");
      String message = "Error initiating payment: $e";
      if (e.toString().contains("DioException")) {
        message =
            "Server Error: Failed to initiate payment. Please check your internet connection and verify backend URL.";
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _handlePaymentResult(
    PaymentResult result,
    String planName,
    String price,
  ) async {
    log("Handling Result: ${result.payload}");
    final status = result.payload?.status;

    if (status == 'Completed' || status == 'Pending') {
      try {
        final profile = ref.read(profileProvider).value;
        if (profile != null) {
          // Call backend to update subscription
          await ApiService.updateSubscription(
            profile.id,
            planName,
            price,
            result.payload?.pidx ?? "unknown_pidx",
          );

          // Refresh Profile
          await ref.read(profileProvider.notifier).fetchProfile();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Subscription Updated Successfully!"),
                backgroundColor: Colors.green,
              ),
            );
            // Go to dashboard immediately
            context.go('/dashboard');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Payment successful but subscription update failed: $e",
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Failed: $status"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Khalti Subscription"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (profile) {
          final currentPlan = profile?.subscription?.plan ?? 'None';
          final isActive = profile?.subscription?.isActive ?? false;
          final expiry = profile?.subscription?.expiryDate;
          // final paymentProofImage = profile?.subscription?.paymentProofImage;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isActive)
                  Card(
                    color: Colors.green.shade50,
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Current Plan: $currentPlan",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (expiry != null)
                            Text(
                              "Valid until: ${expiry.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                        ],
                      ),
                    ),
                  ),
                const Text(
                  "Choose a Plan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildPlanCard("1 Month", "3000", Colors.purple),
                const SizedBox(height: 16),
                _buildPlanCard("3 Months", "5000", Colors.deepPurple),
                const SizedBox(height: 16),
                _buildPlanCard("6 Months", "8000", Colors.indigo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _showPaymentInstructions(
    BuildContext context,
    String plan,
    String amount,
  ) {
    File? selectedImage;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text("Payment Instructions"),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "FIRST PAY\nADD STATEMENT",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "My Esewa ID is 9746814074\nMy Khalti ID is 9746814074",
                      ),
                      const SizedBox(height: 20),
                      if (selectedImage != null)
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text("Cancel"),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setState(() {
                              selectedImage = File(image.path);
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo, size: 20),
                        label: const Text("Add Statement"),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ElevatedButton(
                          onPressed:
                              selectedImage == null
                                  ? null // Disabled if no image
                                  : () {
                                    _uploadStatement(
                                      planName: plan,
                                      amount: amount,
                                      image: selectedImage!,
                                    );
                                  },
                          child: const Text("OK"),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildPlanCard(String title, String price, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      "Rs. $price",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.account_balance_wallet, size: 40, color: color),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaymentButton(
              "Pay with Khalti",
              const Color(0xFF5C2D91), // Khalti Purple
              Icons.account_balance_wallet,
              () => _showPaymentInstructions(context, title, price),
            ),
            const SizedBox(height: 10),
            _buildPaymentButton(
              "Pay with Esewa",
              const Color(0xFF60BB46), // Esewa Green
              Icons.account_balance_wallet,
              () => _showPaymentInstructions(context, title, price),
            ),

            // Original integration commented out for now as per instruction to show popup first
            /*
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text("Pay with Khalti"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _processPayment(title, price),
              ),
            ),
            */
          ],
        ),
      ),
    );
  }
}
