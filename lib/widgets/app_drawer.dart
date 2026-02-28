import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';
import '../providers/profile_provider.dart';

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
                final name = profile?.name ?? 'Ausadhi Track';
                final location =
                    profile?.location ?? 'Pharmacy Management System';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.local_pharmacy, // Changed to pharmacy icon
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
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
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication),
            title: const Text('Medicines'),
            onTap: () {
              context.go('/medicines');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Bills'),
            onTap: () {
              context.go('/bills');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_return),
            title: const Text('Returns'),
            onTap: () {
              context.go('/returns');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reports'),
            onTap: () {
              context.go('/reports');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Customer Bill'),
            onTap: () {
              context.push('/customer_bill');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Subscription'),
            onTap: () {
              context.push('/subscription');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
