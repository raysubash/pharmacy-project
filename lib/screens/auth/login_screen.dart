import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/return_provider.dart';
import '../../providers/sale_provider.dart';
import '../../utils/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDemoLogin() async {
    _emailController.text = 'adminsubash@gmail.com';
    _passwordController.text = 'adminsubash';
    await _handleLogin();
  }

  Future<void> _handleDemoPharmacistLogin() async {
    _emailController.text = 'demo@pharmacy.com';
    _passwordController.text = 'demo123';
    await _handleLogin();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text.trim());

      final authState = ref.read(authProvider);

      if (mounted) {
        if (authState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${authState.error}'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (authState.token != null) {
          // Reset provider cache so previous account's data is not reused.
          ref.invalidate(medicineProvider);
          ref.invalidate(saleProvider);
          ref.invalidate(billProvider);
          ref.invalidate(returnProvider);
          ref.invalidate(profileProvider);

          // Check role first
          if (authState.role == 'admin') {
            context.go('/admin-dashboard');
            return;
          }

          // Login successful
          // Check if profile is set up
          try {
            // Refresh to get latest data from server
            ref.invalidate(profileProvider);
            final profile = await ref.read(profileProvider.future);

            if (mounted) {
              if (profile == null || profile.name.isEmpty) {
                // No profile set up -> Go to Profile Setup
                context.go('/profile', extra: true);
              } else if (profile.subscription?.isActive != true &&
                  (profile.subscription?.paymentProofImage == null ||
                      profile.subscription!.paymentProofImage!.isEmpty)) {
                // No active subscription and no pending proof -> Go to Subscription
                context.go('/subscription');
              } else {
                // Profile exists -> Go to Dashboard
                context.go('/dashboard');
              }
            }
          } catch (e) {
            // If error fetching profile (e.g. network issue), go to dashboard or handle
            // Assuming if 404/null it returns null above, but if exception:
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Could not verify profile. Going to dashboard.',
                  ),
                ),
              );
              context.go('/dashboard');
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_pharmacy,
                        size: 64,
                        color: AppTheme.primaryGreen,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pharmacy Login',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                !v!.contains('@')
                                    ? 'Please enter a valid email'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: isLoading ? null : _handleLogin,
                          child:
                              isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('LOGIN'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text('Create New Account'),
                      ),
                      const SizedBox(height: 24),
                      // ── Demo Login (REMOVE before deployment) ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade300,
                            width: 1.5,
                            // ignore: deprecated_member_use
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.science,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Testing Only',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isLoading ? null : _handleDemoLogin,
                                icon: const Icon(Icons.rocket_launch, size: 18),
                                label: const Text(
                                  'Demo Login (Admin)',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isLoading ? null : _handleDemoPharmacistLogin,
                                icon: const Icon(Icons.local_pharmacy, size: 18),
                                label: const Text(
                                  'Demo Login (Pharmacist)',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
