import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/medicine_model.dart';
import '../../models/sale_model.dart';
import '../../models/bill_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/profile_avatar_icon.dart';

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class _ChartPointData {
  final List<String> labels;
  final List<double> salesData;
  final List<double> purchaseData;
  final double maxY;

  _ChartPointData({
    required this.labels,
    required this.salesData,
    required this.purchaseData,
    required this.maxY,
  });
}

class _TopSellingData {
  final String name;
  final String subtitle;
  final int units;
  final double revenue;
  final Color themeColor;

  _TopSellingData({
    required this.name,
    required this.subtitle,
    required this.units,
    required this.revenue,
    required this.themeColor,
  });
}

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'Last 7 Days';
  final List<String> _periodOptions = ['Last 7 Days', 'Last 30 Days', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final billsAsync = ref.watch(billProvider);
    final salesAsync = ref.watch(saleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF191C1E)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1E)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00685F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_pharmacy_rounded,
                color: Color(0xFF00685F),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'AusadhiTrack',
              style: TextStyle(
                color: Color(0xFF00685F),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF3D4947)),
            onPressed: () {},
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Color(0xFF3D4947)),
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 4.0),
            child: ProfileAvatarIcon(
              radius: 18,
              iconColor: Color(0xFF00685F),
              backgroundColor: Color(0x1F00685F),
            ),
          ),
        ],
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00685F))),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (medicines) {
          return billsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00685F))),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (bills) {
              return salesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00685F))),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (sales) {
                  // --- Calculations ---
                  final totalStockValue = medicines.fold<double>(
                    0.0,
                    (sum, m) => sum + (m.currentStock * m.sellingPrice),
                  );
                  final totalPurchases = bills.fold<double>(
                    0.0,
                    (sum, b) => sum + b.totalAmount,
                  );
                  final totalSales = sales.fold<double>(
                    0.0,
                    (sum, s) => sum + s.grandTotal,
                  );
                  final netProfit = totalSales - totalPurchases;

                  // Growth vs last week
                  final now = DateTime.now();
                  final sevenDaysAgo = now.subtract(const Duration(days: 7));
                  final fourteenDaysAgo = now.subtract(const Duration(days: 14));

                  final currentWeekSales = sales
                      .where((s) => s.date.isAfter(sevenDaysAgo))
                      .fold(0.0, (sum, s) => sum + s.grandTotal);
                  final previousWeekSales = sales
                      .where((s) => s.date.isAfter(fourteenDaysAgo) && s.date.isBefore(sevenDaysAgo))
                      .fold(0.0, (sum, s) => sum + s.grandTotal);

                  double growthPercent = 0.0;
                  if (previousWeekSales > 0) {
                    growthPercent = ((currentWeekSales - previousWeekSales) / previousWeekSales) * 100;
                  } else if (currentWeekSales > 0) {
                    growthPercent = 100.0;
                  }

                  final chartData = _getChartData(_selectedPeriod, sales, bills);
                  final topSellingItems = _getTopSellingItems(sales, medicines);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Title
                        const Text(
                          'Reports',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF191C1E),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Analytics Cards Grid
                        _buildAnalyticsGrid(
                          totalSales: totalSales,
                          stockValue: totalStockValue,
                          netProfit: netProfit,
                          growthPercent: growthPercent,
                        ),
                        const SizedBox(height: 20),

                        // Performance Chart Card
                        _buildPerformanceChartCard(chartData),
                        const SizedBox(height: 20),

                        // Top Selling Items Mini Table
                        _buildTopSellingSection(topSellingItems),
                        const SizedBox(height: 24),

                        // Full PDF Export Button
                        _buildExportPdfButton(
                          medicinesCount: medicines.length,
                          stockValue: totalStockValue,
                          purchases: totalPurchases,
                          sales: totalSales,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsGrid({
    required double totalSales,
    required double stockValue,
    required double netProfit,
    required double growthPercent,
  }) {
    return Column(
      children: [
        // Total Revenue Card (Span 2 / Full width)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33BCC9C6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'TOTAL REVENUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF57657B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    Icons.trending_up,
                    color: Color(0xFF00685F),
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatCurrency(totalSales),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(0)}% vs last week',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00685F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grid of 2 Cards: Stock Value & Net Profit
        Row(
          children: [
            // Stock Value Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33BCC9C6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'STOCK VALUE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF57657B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF00628D),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatCurrency(stockValue),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Net Profit Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x33BCC9C6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'NET PROFIT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF57657B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFFF97316),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatCurrency(netProfit),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF191C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceChartCard(_ChartPointData chartData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33BCC9C6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title and Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sales vs Purchases',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF191C1E), size: 20),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF191C1E),
                    ),
                    onChanged: (newVal) {
                      if (newVal != null) {
                        setState(() {
                          _selectedPeriod = newVal;
                        });
                      }
                    },
                    items: _periodOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00685F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Sales',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF57657B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Purchases',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF57657B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0x20BCC9C6),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              chartData.labels[index],
                              style: const TextStyle(
                                color: Color(0xFF57657B),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Sales Line (Primary Green)
                  LineChartBarData(
                    spots: List.generate(
                      chartData.salesData.length,
                      (idx) => FlSpot(idx.toDouble(), chartData.salesData[idx]),
                    ),
                    isCurved: true,
                    color: const Color(0xFF00685F),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: const Color(0xFF00685F),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00685F).withValues(alpha: 0.1),
                    ),
                  ),
                  // Purchases Line (Orange Dashed)
                  LineChartBarData(
                    spots: List.generate(
                      chartData.purchaseData.length,
                      (idx) => FlSpot(idx.toDouble(), chartData.purchaseData[idx]),
                    ),
                    isCurved: true,
                    color: const Color(0xFFF97316),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    dashArray: [6, 4],
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isSale = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isSale ? "Sales" : "Purchases"}: Rs. ${spot.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: isSale ? const Color(0xFF00685F) : const Color(0xFFF97316),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: 0,
                maxY: chartData.maxY * 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingSection(List<_TopSellingData> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33BCC9C6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Selling',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C1E),
                ),
              ),
              TextButton(
                onPressed: () => _showAllTopSellingModal(context, items),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'VIEW ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00685F),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items List
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No sales recorded yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF57657B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ...items.take(4).map((item) => _buildTopSellingTile(item)),
        ],
      ),
    );
  }

  Widget _buildTopSellingTile(_TopSellingData item, {bool showBorder = true}) {
    final initialLetter = item.name.isNotEmpty ? item.name[0].toUpperCase() : 'M';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(
                bottom: BorderSide(color: Color(0x1ABCC9C6), width: 1),
              )
            : null,
      ),
      child: Row(
        children: [
          // Letter Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                initialLetter,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: item.themeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF191C1E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF57657B),
                  ),
                ),
              ],
            ),
          ),

          // Units & Revenue
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.units} units',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191C1E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rs. ${NumberFormat('#,##,000').format(item.revenue)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00685F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportPdfButton({
    required int medicinesCount,
    required double stockValue,
    required double purchases,
    required double sales,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _generateReport(
          ref,
          medicinesCount,
          stockValue,
          purchases,
          sales,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00685F),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFF00685F).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.picture_as_pdf, size: 22),
        label: const Text(
          'Download Full PDF Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _showAllTopSellingModal(BuildContext context, List<_TopSellingData> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'All Top Selling Medicines',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191C1E),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        return _buildTopSellingTile(items[index], showBorder: index < items.length - 1);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return 'Rs. ${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return 'Rs. ${NumberFormat('#,##,000').format(amount)}';
    } else {
      return 'Rs. ${amount.toStringAsFixed(0)}';
    }
  }

  _ChartPointData _getChartData(String period, List<Sale> sales, List<PurchaseBill> bills) {
    final now = DateTime.now();

    if (period == 'Last 30 Days') {
      List<String> labels = [];
      List<double> salesData = [];
      List<double> purchaseData = [];

      for (int i = 5; i >= 0; i--) {
        final endDate = now.subtract(Duration(days: i * 5));
        final startDate = endDate.subtract(const Duration(days: 5));
        labels.add(DateFormat('MMM d').format(endDate));

        final periodSales = sales
            .where((s) => s.date.isAfter(startDate) && s.date.isBefore(endDate.add(const Duration(days: 1))))
            .fold(0.0, (sum, s) => sum + s.grandTotal);
        final periodPurchases = bills
            .where((b) => b.entryDate.isAfter(startDate) && b.entryDate.isBefore(endDate.add(const Duration(days: 1))))
            .fold(0.0, (sum, b) => sum + b.totalAmount);

        salesData.add(periodSales);
        purchaseData.add(periodPurchases);
      }

      final maxY = [...salesData, ...purchaseData, 100.0].reduce((a, b) => a > b ? a : b);
      return _ChartPointData(labels: labels, salesData: salesData, purchaseData: purchaseData, maxY: maxY);
    } else if (period == 'This Year') {
      List<String> labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      List<double> salesData = List.filled(12, 0.0);
      List<double> purchaseData = List.filled(12, 0.0);

      for (final s in sales) {
        if (s.date.year == now.year) {
          salesData[s.date.month - 1] += s.grandTotal;
        }
      }
      for (final b in bills) {
        if (b.entryDate.year == now.year) {
          purchaseData[b.entryDate.month - 1] += b.totalAmount;
        }
      }

      final maxY = [...salesData, ...purchaseData, 100.0].reduce((a, b) => a > b ? a : b);
      return _ChartPointData(labels: labels, salesData: salesData, purchaseData: purchaseData, maxY: maxY);
    } else {
      // Last 7 Days
      final weekDays = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return DateTime(d.year, d.month, d.day);
      });

      final labels = weekDays.map((d) => DateFormat('E').format(d)).toList();

      final salesData = weekDays.map((day) {
        return sales.where((s) => _isSameDay(s.date, day)).fold(0.0, (sum, s) => sum + s.grandTotal);
      }).toList();

      final purchaseData = weekDays.map((day) {
        return bills.where((b) => _isSameDay(b.entryDate, day)).fold(0.0, (sum, b) => sum + b.totalAmount);
      }).toList();

      final maxY = [...salesData, ...purchaseData, 100.0].reduce((a, b) => a > b ? a : b);

      return _ChartPointData(labels: labels, salesData: salesData, purchaseData: purchaseData, maxY: maxY);
    }
  }

  List<_TopSellingData> _getTopSellingItems(List<Sale> sales, List<Medicine> medicines) {
    final Map<String, Map<String, dynamic>> itemMap = {};

    for (final sale in sales) {
      for (final item in sale.items) {
        final key = item.medicineName.trim();
        if (key.isEmpty) continue;
        if (!itemMap.containsKey(key)) {
          itemMap[key] = {'name': key, 'units': 0, 'revenue': 0.0};
        }
        itemMap[key]!['units'] = (itemMap[key]!['units'] as int) + item.quantity;
        itemMap[key]!['revenue'] = (itemMap[key]!['revenue'] as double) + item.total;
      }
    }

    final colors = [
      const Color(0xFF00685F),
      const Color(0xFF00628D),
      const Color(0xFFF97316),
      const Color(0xFF7B1FA2),
      const Color(0xFF008378),
    ];

    if (itemMap.isEmpty) {
      return [];
    }

    final sortedList = itemMap.values.toList()
      ..sort((a, b) => (b['units'] as int).compareTo(a['units'] as int));

    return sortedList.asMap().entries.map((entry) {
      final idx = entry.key;
      final val = entry.value;
      final name = val['name'] as String;

      final med = medicines.firstWhere(
        (m) => m.name.toLowerCase() == name.toLowerCase(),
        orElse: () => Medicine(
          id: '',
          name: name,
          category: 'General',
          unit: MeasureUnit.tablet,
          minStock: 0,
          sellingPrice: 0,
        ),
      );

      final unitStr = med.unit.name.capitalize();
      final brandStr = (med.brandName != null && med.brandName!.isNotEmpty)
          ? med.brandName!
          : med.category;
      final subtitle = '$unitStr • $brandStr';

      return _TopSellingData(
        name: name,
        subtitle: subtitle,
        units: val['units'] as int,
        revenue: val['revenue'] as double,
        themeColor: colors[idx % colors.length],
      );
    }).toList();
  }

  Future<void> _generateReport(
    WidgetRef ref,
    int totalMedicines,
    double stockValue,
    double purchases,
    double sales,
  ) async {
    final pdf = pw.Document();
    final profile = await ref.read(profileProvider.future);
    final user = ref.read(authProvider);
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      (profile?.name ?? 'PHARMACY NAME').toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('PAN: ${profile?.panNumber ?? ''}'),
                    pw.Text(profile?.location ?? ''),
                    pw.Text('Phone: ${profile?.phoneNumber ?? ''}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.Text(
                  'BUSINESS REPORT',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Center(
                child: pw.Text(
                  'Generated On: ${DateFormat('yyyy/MM/dd hh:mm a').format(now)}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'INVENTORY SUMMARY',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Description', 'Value'],
                data: [
                  ['Total Medicine Items', totalMedicines.toString()],
                  [
                    'Current Stock Valuation',
                    'Rs. ${stockValue.toStringAsFixed(2)}',
                  ],
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Text(
                'FINANCIAL SUMMARY',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headers: ['Description', 'Amount'],
                data: [
                  ['Total Purchases', 'Rs. ${purchases.toStringAsFixed(2)}'],
                  ['Total Sales', 'Rs. ${sales.toStringAsFixed(2)}'],
                  [
                    'Net Cash Flow',
                    'Rs. ${(sales - purchases).toStringAsFixed(2)}',
                  ],
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Note: Net Cash Flow = Sales - Purchases (Excludes inventory valuation)',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (user.userName != null) ...[
                        pw.Text(
                          user.userName!,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Authorized Signature',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Pharmacy_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }
}
