import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../widgets/profile_avatar_icon.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final salesAsync = ref.watch(saleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F7), // Soft clean background
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 2,
        titleSpacing: 16,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFF003527),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF404944)),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF404944)),
            onPressed: () => context.push('/notifications'),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 4.0),
            child: ProfileAvatarIcon(
              radius: 16,
              iconColor: Color(0xFF003527),
              backgroundColor: Color(0xFFE5EEFF),
            ),
          ),
        ],
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => _buildErrorCard(context, ref, 'Failed to fetch inventory data. Please check your internet connection.'),
        data: (medicines) {
          return salesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => _buildErrorCard(context, ref, 'Failed to fetch sales data. Please check your internet connection.'),
            data: (sales) {
              // --- Data Calculations ---
              final totalMedicines = medicines.length;
              final lowStock = medicines
                  .where((m) => m.activeStatuses.contains(MedicineStatus.lowStock))
                  .toList();
              final expired = medicines
                  .where((m) => m.activeStatuses.contains(MedicineStatus.expired))
                  .toList();
              final expiringSoon = medicines
                  .where((m) => m.activeStatuses.contains(MedicineStatus.expiringSoon))
                  .toList();

              // Calculate Today's Sales
              final now = DateTime.now();
              final todaySalesList =
                  sales.where((s) => isSameDay(s.date, now)).toList();

              final todaySalesTotal = todaySalesList.fold(
                0.0,
                (sum, s) => sum + s.grandTotal,
              );

              // Calculate 7-day sales spots for sparkline
              final weeklySales = List.generate(7, (index) {
                final day = now.subtract(Duration(days: 6 - index));
                final dailyTotal = sales
                    .where((s) => isSameDay(s.date, day))
                    .fold(0.0, (sum, s) => sum + s.grandTotal);
                return FlSpot(index.toDouble(), dailyTotal);
              });

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Today's Sales Hero Card
                    _buildSalesHeroCard(todaySalesTotal, weeklySales, todaySalesList.length),

                    const SizedBox(height: 20),

                    // Section 2: Quick Stats Grid (Medicines, Low Stock, Expired)
                    _buildStatsGrid(totalMedicines, lowStock.length, expired.length),

                    const SizedBox(height: 20),

                    // Section 3: Quick Actions (2x2 Grid)
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 24),

                    // Section 4: Attention Needed List
                    _buildAttentionNeededSection(
                      context,
                      lowStock,
                      expired,
                      expiringSoon,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- 1. Today's Sales Hero Card ---
  Widget _buildSalesHeroCard(
    double todayTotal,
    List<FlSpot> weeklySales,
    int todayCount,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // Dark Emerald
            Color(0xFF043D2E),
            Color(0xFF022C22),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Glow Effect
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF006B5F).withValues(alpha: 0.4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Today's Sales",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${todayTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Color(0xFF62FAE3),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '+15%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Sparkline Representation using LineChart
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: weeklySales,
                          isCurved: true,
                          color: const Color(0xFF3CDDC7),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF3CDDC7).withValues(alpha: 0.35),
                                const Color(0xFF3CDDC7).withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Quick Stats Grid ---
  Widget _buildStatsGrid(int totalMeds, int lowStockCount, int expiredCount) {
    return Row(
      children: [
        // Card 1: Medicines
        Expanded(
          child: _buildStatCard(
            title: 'Medicines',
            value: '$totalMeds',
            icon: Icons.medication,
            iconColor: const Color(0xFF00628D),
            iconBg: const Color(0xFFE0F2FE),
            bgGradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFEDF7F4)],
            ),
            borderColor: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 12),

        // Card 2: Low Stock
        Expanded(
          child: _buildStatCard(
            title: 'Low Stock',
            value: '$lowStockCount',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            bgGradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF8ED)],
            ),
            borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 12),

        // Card 3: Expired
        Expanded(
          child: _buildStatCard(
            title: 'Expired',
            value: '$expiredCount',
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBg: const Color(0xFFFEE2E2),
            bgGradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFFF0F0)],
            ),
            borderColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required LinearGradient bgGradient,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF404944),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Quick Actions (2x2 Grid) ---
  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        // Action 1: New Sale
        _buildGradientActionButton(
          label: 'New Sale',
          icon: Icons.add_shopping_cart,
          gradient: const LinearGradient(
            colors: [Color(0xFF003527), Color(0xFF064E3B)],
          ),
          textColor: Colors.white,
          onTap: () => context.push('/customer_bill'),
        ),

        // Action 2: Add Item
        _buildGradientActionButton(
          label: 'Add Item',
          icon: Icons.add_box_outlined,
          gradient: const LinearGradient(
            colors: [Color(0xFF006B5F), Color(0xFF004F46)],
          ),
          textColor: Colors.white,
          onTap: () => context.push('/medicines/add'),
        ),

        // Action 3: Sales History
        _buildOutlineActionButton(
          label: 'Sales History',
          icon: Icons.history,
          onTap: () => context.go('/bills'),
        ),

        // Action 4: Suppliers
        _buildOutlineActionButton(
          label: 'Suppliers',
          icon: Icons.local_shipping_outlined,
          onTap: () => context.go('/suppliers'),
        ),
      ],
    );
  }

  Widget _buildGradientActionButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003527).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlineActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF4F9F7)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF003527), size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF003527),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Color(0xFFD97706),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connection Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1C30),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003527),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.invalidate(medicineProvider);
                  ref.invalidate(saleProvider);
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. Attention Needed List Section ---
  Widget _buildAttentionNeededSection(
    BuildContext context,
    List<Medicine> lowStock,
    List<Medicine> expired,
    List<Medicine> expiringSoon,
  ) {
    final hasAlerts = lowStock.isNotEmpty || expired.isNotEmpty || expiringSoon.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Attention Needed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1C30),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/notifications'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF006B5F),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFEDF7F4)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF064E3B).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              if (!hasAlerts)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'All caught up! No inventory items need immediate attention.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                // Low Stock Alerts
                for (final m in lowStock.take(2))
                  _buildAttentionItemTile(
                    title: m.name,
                    subtitle: 'Low Stock: ${m.currentStock} left',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                    isWarning: true,
                    onTap: () => context.go('/medicines?filter=lowStock'),
                  ),

                // Expired Alerts
                for (final m in expired.take(2))
                  _buildAttentionItemTile(
                    title: m.name,
                    subtitle: 'Expired Items: ${m.currentStock}',
                    icon: Icons.event_busy,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                    isWarning: false,
                    onTap: () => context.go('/medicines?filter=expiring'),
                  ),

                // Expiring Soon Alerts
                for (final m in expiringSoon.take(2))
                  _buildAttentionItemTile(
                    title: m.name,
                    subtitle: 'Expiring in ${m.daysUntilExpiry ?? 30} days',
                    icon: Icons.schedule,
                    iconColor: const Color(0xFF9333EA),
                    iconBg: const Color(0xFFF3E8FF),
                    isWarning: true,
                    onTap: () => context.go('/medicines?filter=expiringSoon'),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionItemTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required bool isWarning,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x0F000000), width: 1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B1C30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
                        size: 14,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isWarning ? Icons.add : Icons.chevron_right,
                color: const Color(0xFF006B5F),
              ),
              onPressed: onTap,
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}
