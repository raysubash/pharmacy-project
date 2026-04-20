import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/return_model.dart';
import '../models/bill_model.dart';
import '../models/medicine_model.dart';
import '../screens/home_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/medicine_inventory_screen.dart';
import '../screens/inventory/add_medicine_screen.dart';
import '../screens/bills/purchase_bill_screen.dart';
import '../screens/bills/add_bill_screen.dart';
import '../screens/returns/return_screen.dart';
import '../screens/returns/add_return_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/search/global_search_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/bills/customer_bill_screen.dart';
import '../screens/subscription/subscription_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';

MedicineFilter _medicineFilterFromQuery(String? filter) {
  switch (filter) {
    case 'lowStock':
      return MedicineFilter.lowStock;
    case 'expiring':
      return MedicineFilter.expiring;
    default:
      return MedicineFilter.all;
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder:
            (context, state) => ProfileScreen(
              isSetupMode: state.extra is bool ? state.extra as bool : false,
            ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: '/customer_bill',
        builder: (context, state) => const CustomerBillScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/medicines',
                builder:
                    (context, state) => MedicineInventoryScreen(
                      filter: _medicineFilterFromQuery(
                        state.uri.queryParameters['filter'],
                      ),
                    ),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddMedicineScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder:
                        (context, state) => AddMedicineScreen(
                          medicineToEdit: state.extra as Medicine?,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bills',
                builder: (context, state) => const PurchaseBillScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder:
                        (context, state) => AddPurchaseBillScreen(
                          billToEdit: state.extra as PurchaseBill?,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/returns',
                builder: (context, state) => const ReturnScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddReturnScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder:
                        (context, state) => AddReturnScreen(
                          itemToEdit: state.extra as ReturnItem?,
                        ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
