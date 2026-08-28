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

          // Login successful: Sequence: login -> subscription -> profile setup -> dashboard
          try {
            // Refresh to get latest data from server
            ref.invalidate(profileProvider);
            final profile = await ref.read(profileProvider.future);

            if (mounted) {
              final isActiveSub = profile?.subscription?.isActive == true ||
                  (profile?.subscription?.paymentProofImage != null &&
                      profile!.subscription!.paymentProofImage!.isNotEmpty);

              final isProfileSetup = profile != null &&
                  profile.name.trim().isNotEmpty &&
                  profile.name != 'Pharmacist Admin' &&
                  profile.phoneNumber.trim().isNotEmpty;

              if (!isActiveSub) {
                // Step 2: Subscription Screen
                context.go('/subscription');
              } else if (!isProfileSetup) {
                // Step 3: Profile Setup Screen
                context.go('/profile', extra: true);
              } else {
                // Step 4: Dashboard Screen
                context.go('/dashboard');
              }
            }
          } catch (e) {
            // If error fetching profile, send to subscription to be safe
            if (mounted) {
              context.go('/subscription');
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'AusadhiTrack Login',
                        style: TextStyle(
                          fontSize: 22,
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
