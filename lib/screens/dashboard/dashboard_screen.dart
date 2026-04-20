import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

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
    // Bills provider not strictly needed for summary unless we count bills

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      drawer: const AppDrawer(),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (medicines) {
          return salesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (sales) {
              // --- Data Processing ---
              final totalMedicines = medicines.length;
              final lowStock =
                  medicines.where((m) => m.currentStock <= m.minStock).toList();
              final expired =
                  medicines
                      .where(
                        (m) =>
                            m.expiryDate != null &&
                            m.expiryDate!.isBefore(DateTime.now()),
                      )
                      .toList();

              // Expiring Soon: 3 months from now
              final threeMonthsFromNow = DateTime.now().add(Duration(days: 90));
              final expiringsoon =
                  medicines
                      .where(
                        (m) =>
                            m.expiryDate != null &&
                            m.expiryDate!.isAfter(DateTime.now()) &&
                            m.expiryDate!.isBefore(threeMonthsFromNow),
                      )
                      .toList();

              // Over Stock: unused for 2 months (createdDate + 60 days)
              final twoMonthsAgo = DateTime.now().subtract(Duration(days: 60));
              final overStock =
                  medicines
                      .where(
                        (m) =>
                            m.createdDate.isBefore(twoMonthsAgo) &&
                            m.currentStock == medicines
                                .where((med) => med.id == m.id)
                                .first
                                .currentStock,
                      )
                      .toList();

              // Calculate Today's Sales
              final now = DateTime.now();
              final todaySalesList =
                  sales.where((s) => isSameDay(s.date, now)).toList();

              final todaySalesTotal = todaySalesList.fold(
                0.0,
                (sum, s) => sum + s.grandTotal,
              );

              // Calculate Weekly Sales for Sparkline
              final weeklySales = List.generate(7, (index) {
                final day = now.subtract(Duration(days: 6 - index));
                final dailyTotal = sales
                    .where((s) => isSameDay(s.date, day))
                    .fold(0.0, (sum, s) => sum + s.grandTotal);
                return FlSpot(index.toDouble(), dailyTotal);
              });

              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSalesCard(
                            context,
                            todaySalesTotal,
                            weeklySales,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Overview",
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStatGrid(
                            totalMedicines,
                            lowStock.length,
                            expired.length,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "Quick Actions",
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActions(context),
                          if (lowStock.isNotEmpty ||
                              expired.isNotEmpty ||
                              expiringsoon.isNotEmpty ||
                              overStock.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              "Attention Needed",
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildAlerts(
                              context,
                              lowStock,
                              expired,
                              expiringsoon,
                              overStock,
                            ),
                          ],
                          const SizedBox(height: 80), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.0, // Increased height
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4CAF50), // Green 500
                Color(0xFF009688), // Teal 500
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMM').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Welcome Back, Pharmacist!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar Mockup
                    GestureDetector(
                      onTap: () => context.push('/search'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Search medicines, bills...',
                                style: TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildSalesCard(
    BuildContext context,
    double todayTotal,
    List<FlSpot> spots,
  ) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Graph
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  minY: 0,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Today's Sales",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${todayTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 32,
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.trending_up,
                            size: 14,
                            color: AppTheme.primaryGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "+12% vs yesterday", // Mock data or could be calculated
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    'Rs',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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

  Widget _buildStatGrid(int totalMedicines, int lowStock, int expired) {
    return SizedBox(
      height: 120, // Height for the row of cards
      child: Row(
        children: [
          Expanded(
            child: _buildInfoCard(
              "Medicines",
              "$totalMedicines",
              Icons.medication_outlined,
              Colors.blue,
              Colors.blue.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              "Low Stock",
              "$lowStock",
              Icons.warning_amber_rounded,
              Colors.orange,
              Colors.orange.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoCard(
              "Expired",
              "$expired",
              Icons.event_busy,
              Colors.red,
              Colors.red.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context,
          'New Sale',
          Icons.shopping_cart_checkout,
          const Color(0xFF4CAF50), // Green
          () => context.push('/customer_bill'),
        ),
        _buildActionButton(
          context,
          'Add Item',
          Icons.add_circle_outline,
          const Color(0xFF2196F3), // Blue
          () => context.push('/medicines/add'),
        ),
        _buildActionButton(
          context,
          'Add Bill',
          Icons.receipt_long,
          const Color(0xFFFF9800), // Orange
          () => context.push('/bills/add'),
        ),
        _buildActionButton(
          context,
          'Returns',
          Icons.assignment_return,
          const Color(0xFF9C27B0), // Purple
          () => context.push('/returns'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlerts(
    BuildContext context,
    List<Medicine> lowStockMedicines,
    List<Medicine> expiredMedicines,
    List<Medicine> expiringSoonMedicines,
    List<Medicine> overStockMedicines,
  ) {
    List<Widget> alerts = [];

    if (lowStockMedicines.isNotEmpty) {
      alerts.add(
        _buildAlertTile(
          "${lowStockMedicines.length} items are low in stock",
          Icons.warning,
          Colors.orange,
          () {
            context.go('/medicines?filter=lowStock');
          },
        ),
      );

      for (final medicine in lowStockMedicines.take(3)) {
        alerts.add(const SizedBox(height: 8));
        alerts.add(
          _buildAlertTile(
            '${medicine.name} (${medicine.currentStock} left)',
            Icons.medication,
            Colors.orange,
            () {
              context.go('/medicines?filter=lowStock');
            },
          ),
        );
      }

      if (lowStockMedicines.length > 3) {
        alerts.add(const SizedBox(height: 8));
        alerts.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+${lowStockMedicines.length - 3} more low stock medicines',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        );
      }
    }

    if (expiredMedicines.isNotEmpty) {
      alerts.add(const SizedBox(height: 8));
      alerts.add(
        _buildAlertTile(
          "${expiredMedicines.length} items have expired",
          Icons.error,
          Colors.red,
          () {
            context.go('/medicines?filter=expiring');
          },
        ),
      );
    }

    if (expiringSoonMedicines.isNotEmpty) {
      alerts.add(const SizedBox(height: 8));
      alerts.add(
        _buildAlertTile(
          "${expiringSoonMedicines.length} items expiring in 3 months",
          Icons.schedule,
          Colors.amber,
          () {
            context.go('/medicines?filter=expiring');
          },
        ),
      );
    }

    if (overStockMedicines.isNotEmpty) {
      alerts.add(const SizedBox(height: 8));
      alerts.add(
        _buildAlertTile(
          "${overStockMedicines.length} items overstock (unused 2+ months)",
          Icons.inventory_2,
          Colors.purple,
          () {
            context.go('/medicines?filter=overStock');
          },
        ),
      );
    }

    return Column(children: alerts);
  }

  Widget _buildAlertTile(
    String message,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: color.withValues(alpha: 0.7),
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
