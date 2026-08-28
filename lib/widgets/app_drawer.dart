import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/medicine_provider.dart';
import '../utils/theme.dart';
import '../providers/profile_provider.dart';
import '../providers/return_provider.dart';
import '../providers/sale_provider.dart';
import 'profile_avatar_icon.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryGreen),
            child: profileAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              error:
                  (err, stack) => const Text(
                    'Error loading profile',
                    style: TextStyle(color: Colors.white),
                  ),
              data: (profile) {
                final name = profile?.name ?? 'AusadhiTrack';
                final location =
                    profile?.location ?? 'AusadhiTrack Pharmacy System';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 44,
                            width: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const ProfileAvatarIcon(
                          radius: 22,
                          isClickable: false,
                          iconColor: AppTheme.primaryGreen,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Medicines'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/medicines');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Sales History'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/bills');
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Suppliers Directory'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/suppliers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Customer Bill'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.push('/customer_bill');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Subscription'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.push('/subscription');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              ref.invalidate(medicineProvider);
              ref.invalidate(saleProvider);
              ref.invalidate(billProvider);
              ref.invalidate(returnProvider);
              ref.invalidate(profileProvider);

              if (!context.mounted) return;
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
