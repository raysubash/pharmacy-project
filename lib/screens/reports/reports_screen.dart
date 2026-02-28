import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/sale_provider.dart'; // Added for Sales Reports
import '../../providers/profile_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final billsAsync = ref.watch(billProvider);
    final salesAsync = ref.watch(saleProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: const AppDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        title: const Text(
          'Analytics Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (medicines) {
          return billsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
            data: (bills) {
              return salesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
                data: (sales) {
                  // --- Data Processing for Charts ---
                  final now = DateTime.now();
                  final weekDays = List.generate(7, (i) {
                    final d = now.subtract(Duration(days: 6 - i));
                    return DateTime(d.year, d.month, d.day);
                  });

                  final salesData =
                      weekDays.map((day) {
                        return sales
                            .where((s) => isSameDay(s.date, day))
                            .fold(0.0, (sum, s) => sum + s.grandTotal);
                      }).toList();

                  final purchaseData =
                      weekDays.map((day) {
                        return bills
                            .where((b) => isSameDay(b.entryDate, day))
                            .fold(0.0, (sum, b) => sum + b.totalAmount);
                      }).toList();

                  final maxY = [
                    ...salesData,
                    ...purchaseData,
                    100.0, // Minimum height
                  ].reduce((curr, next) => curr > next ? curr : next);

                  // --- Summary Stats ---
                  final totalMedicines = medicines.length;
                  final totalStockValue = medicines.fold<double>(
                    0.0,
                    (sum, m) => sum + (m.currentStock * m.sellingPrice),
                  );
                  final totalPurchases = bills.fold(
                    0.0,
                    (sum, b) => sum + b.totalAmount,
                  );
                  final totalSales = sales.fold(
                    0.0,
                    (sum, s) => sum + s.grandTotal,
                  );

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- Header Chart Section ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(30),
                              bottomRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Weekly Performance",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Sales vs Purchases (Last 7 Days)",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AspectRatio(
                                aspectRatio: 1.5,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index < weekDays.length) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  DateFormat(
                                                    'E',
                                                  ).format(weekDays[index]),
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              );
                                            }
                                            return const Text('');
                                          },
                                          interval: 1,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      // Sales Line
                                      LineChartBarData(
                                        spots: List.generate(7, (index) {
                                          return FlSpot(
                                            index.toDouble(),
                                            salesData[index],
                                          );
                                        }),
                                        isCurved: true,
                                        color: Colors.white,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                      ),
                                      // Purchases Line
                                      LineChartBarData(
                                        spots: List.generate(7, (index) {
                                          return FlSpot(
                                            index.toDouble(),
                                            purchaseData[index],
                                          );
                                        }),
                                        isCurved: true,
                                        color: Colors.orangeAccent,
                                        barWidth: 2,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: false),
                                        dashArray: [5, 5],
                                      ),
                                    ],
                                    lineTouchData: LineTouchData(
                                      touchTooltipData: LineTouchTooltipData(
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((spot) {
                                            final isSale = spot.barIndex == 0;
                                            return LineTooltipItem(
                                              '${isSale ? "Sale" : "Buy"}: ${spot.y.toStringAsFixed(0)}',
                                              TextStyle(
                                                color:
                                                    isSale
                                                        ? AppTheme.primaryGreen
                                                        : Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                    minY: 0,
                                    maxY: maxY * 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- Summary Grid ---
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Report Overview",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 15,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.3,
                                children: [
                                  _buildStatCard(
                                    "Stock Value",
                                    "₹${totalStockValue.toStringAsFixed(0)}",
                                    Icons.inventory_2,
                                    Colors.blue,
                                  ),
                                  _buildStatCard(
                                    "Total Sales",
                                    "₹${totalSales.toStringAsFixed(0)}",
                                    Icons.trending_up,
                                    Colors.green,
                                  ),
                                  _buildStatCard(
                                    "Purchases",
                                    "₹${totalPurchases.toStringAsFixed(0)}",
                                    Icons.shopping_bag,
                                    Colors.orange,
                                  ),
                                  _buildStatCard(
                                    "Medicines",
                                    "$totalMedicines",
                                    Icons.medical_services,
                                    Colors.purple,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 30),

                              // --- PDF Button ---
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _generateReport(
                                        ref,
                                        medicines.length,
                                        totalStockValue,
                                        totalPurchases,
                                        totalSales,
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                  ),
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text(
                                    "Download Full Report",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
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

  bool isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _generateReport(
    WidgetRef ref,
    int totalMedicines,
    double stockValue,
    double purchases,
    double sales,
  ) async {
    final pdf = pw.Document();
    // Use ref from state if needed, but here it is passed as argument which is fine.
    // However, since we are now in a ConsumerState, we might want to use 'ref' property instead of argument to avoid shadowing.
    // Or just rename argument. But existing code uses 'ref'.
    // Let's keep it as is, it's a valid method in the class.

    final profile = await ref.read(profileProvider.future);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (profile?.name ?? 'PHARMACY REPORT').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (profile != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('PAN: ${profile.panNumber}'),
                      pw.Text(profile.location),
                      pw.Text('Phone: ${profile.phoneNumber}'),
                    ],
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Full Business Report',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Generated on: ${DateTime.now().toString()}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Inventory Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Bullet(text: 'Total Medicines Count: $totalMedicines'),
              pw.Bullet(
                text:
                    'Current Stock Valuation: ${stockValue.toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Financial Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Bullet(
                text: 'Total Purchases: ${purchases.toStringAsFixed(2)}',
              ),
              pw.Bullet(text: 'Total Sales: ${sales.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Net Approximate Profit (Sales - Purchases): ${(sales - purchases).toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.Paragraph(
                text:
                    'Note: This represents raw cash flow difference, not actual profit as inventory valuation is excluded.',
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
