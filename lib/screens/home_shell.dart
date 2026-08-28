import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/app_drawer.dart';

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final currentIndex = navigationShell.currentIndex;

    final navItems = [
      _NavItem(
        index: 0,
        label: 'Home',
        activeIcon: Icons.dashboard,
        inactiveIcon: Icons.dashboard_outlined,
      ),
      _NavItem(
        index: 1,
        label: 'Meds',
        activeIcon: Icons.inventory_2,
        inactiveIcon: Icons.inventory_2_outlined,
      ),
      _NavItem(
        index: 2,
        label: 'Sales',
        activeIcon: Icons.receipt_long,
        inactiveIcon: Icons.receipt_long_outlined,
      ),
      _NavItem(
        index: 3,
        label: 'Suppliers',
        activeIcon: Icons.local_shipping,
        inactiveIcon: Icons.local_shipping_outlined,
      ),
      _NavItem(
        index: 4,
        label: 'Profile',
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navigationShell.currentIndex != 0) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  const SizedBox(
                    width: 260,
                    child: AppDrawer(),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFE0E0E0),
                  ),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: isDesktop
            ? null
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 66,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: navItems.map((item) {
                        final isSelected = currentIndex == item.index;
                        return Expanded(
                          child: InkWell(
                            onTap: () => navigationShell.goBranch(item.index),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF003527).withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    isSelected
                                        ? item.activeIcon
                                        : item.inactiveIcon,
                                    size: 24,
                                    color: isSelected
                                        ? const Color(0xFF003527)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF003527)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  _NavItem({
    required this.index,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
