import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import 'package:go_router/go_router.dart';
import '../../models/sale_model.dart';
import '../../providers/sale_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/profile_avatar_icon.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Today, Cash, Fonepay, Credit
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmClearAllSales(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'Clear Sales History',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all sales history from database? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      await ref.read(saleProvider.notifier).clearAllSales();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All sales history deleted successfully!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(saleProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
        title: const Text(
          'Sales History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Clear All Sales History',
            onPressed: () => _confirmClearAllSales(context),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12.0, left: 4.0),
            child: ProfileAvatarIcon(
              radius: 18,
              iconColor: Colors.white,
              backgroundColor: Color(0x33FFFFFF),
            ),
          ),
        ],
      ),
      body: salesAsync.when(
        data: (sales) {
          final sortedSales = List<Sale>.from(sales)
            ..sort((a, b) => b.date.compareTo(a.date));

          // Filter logic
          final filteredSales = sortedSales.where((sale) {
            final matchesQuery = _searchQuery.isEmpty ||
                sale.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                sale.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (sale.customerPhone != null && sale.customerPhone!.contains(_searchQuery)) ||
                sale.items.any((item) => item.medicineName.toLowerCase().contains(_searchQuery.toLowerCase()));

            if (!matchesQuery) return false;

            if (_selectedFilter == 'Today') {
              final now = DateTime.now();
              return sale.date.year == now.year &&
                  sale.date.month == now.month &&
                  sale.date.day == now.day;
            } else if (_selectedFilter == 'Cash') {
              return sale.payMode.toLowerCase().contains('cash');
            } else if (_selectedFilter == 'Fonepay') {
              return sale.payMode.toLowerCase().contains('fone') ||
                  sale.payMode.toLowerCase().contains('qr') ||
                  sale.payMode.toLowerCase().contains('online');
            } else if (_selectedFilter == 'Credit') {
              return sale.payMode.toLowerCase().contains('credit');
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Search and Filter Bar
              _buildSearchAndFilter(),

              // Sales List
              Expanded(
                child: filteredSales.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          return _buildSaleCard(sale);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
        error: (err, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText('Error loading sales history: $err'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'sales_history_fab',
        onPressed: () => context.push('/customer_bill'),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Sale',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search by Invoice, Customer, Phone, Medicine...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Today', 'Cash', 'Fonepay', 'Credit'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryGreen,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[200],
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = filter);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    final dateFormat = DateFormat('yyyy-MM-dd • hh:mm a');
    final modeLower = sale.payMode.toLowerCase();
    final isCash = modeLower.contains('cash');
    final isFonepay = modeLower.contains('fone') || modeLower.contains('qr') || modeLower.contains('online');
    final isCredit = modeLower.contains('credit');

    final displayPayMode = isFonepay
        ? 'Fonepay'
        : isCash
            ? 'Cash'
            : isCredit
                ? 'Credit'
                : sale.payMode;

    final payModeColor = isFonepay
        ? Colors.blue
        : isCash
            ? Colors.green
            : isCredit
                ? Colors.orange
                : Colors.grey;

    final payModeIcon = isFonepay
        ? Icons.qr_code_scanner
        : isCash
            ? Icons.payments_outlined
            : Icons.credit_card;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showSaleDetails(sale),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Invoice # & PayMode Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sale.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: payModeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: payModeColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          payModeIcon,
                          size: 14,
                          color: payModeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          displayPayMode,
                          style: TextStyle(
                            color: payModeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer Info & Date
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customerName.isEmpty ? 'Walk-in Customer' : sale.customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                          Text(
                            sale.customerPhone!,
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        Text(
                          dateFormat.format(sale.date),
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs ${sale.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        '${sale.items.length} ${sale.items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _printPdf(sale),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Print Receipt'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showSaleDetails(sale),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Sales History Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sales processed through Customer Bill will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/customer_bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create New Sale'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaleDetails(Sale sale) {
    final dateFormat = DateFormat('yyyy-MM-dd • hh:mm a');
    final profile = ref.read(profileProvider).value;
    final pharmacyName = (profile?.name.isNotEmpty == true) ? profile!.name : 'MEDICINE & PHARMACY CARE';
    final pharmacyAddress = (profile?.location.isNotEmpty == true) ? profile!.location : 'Kathmandu, Nepal';
    final pharmacyPhone = (profile?.phoneNumber.isNotEmpty == true) ? profile!.phoneNumber : '9841234567';
    final pharmacyPan = (profile?.panNumber.isNotEmpty == true) ? profile!.panNumber : '1234-123-9874';

    final modeLower = sale.payMode.toLowerCase();
    final isFonepay = modeLower.contains('fone') || modeLower.contains('qr') || modeLower.contains('online');
    final isCredit = modeLower.contains('credit');
    final modalPayMode = isFonepay ? 'FONEPAY' : (isCredit ? 'CREDIT' : 'CASH');
    final modalPayColor = isFonepay ? Colors.blue : (isCredit ? Colors.orange : AppTheme.primaryGreen);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6F8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Top Action & Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'Tax Invoice Preview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Realistic Thermal Receipt Paper Container
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Pharmacy Header
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  pharmacyName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pharmacyAddress,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                Text(
                                  'Phone: $pharmacyPhone | PAN: $pharmacyPan',
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TAX INVOICE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Divider(thickness: 1.5, color: Colors.black26),
                          const SizedBox(height: 10),

                          // 2. Invoice & Customer Info Grid
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Invoice Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Invoice No:',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      sale.invoiceNumber,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Date & Time:',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      dateFormat.format(sale.date),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              // Right: Customer Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Customer:',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                    Text(
                                      sale.customerName.isEmpty ? "Walk-in Customer" : sale.customerName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                                      Text(
                                        'Ph: ${sale.customerPhone}',
                                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: modalPayColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Pay: $modalPayMode',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: modalPayColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(thickness: 1.5, color: Colors.black26),
                          const SizedBox(height: 10),

                          // 3. Itemized Table Headers
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: const [
                                SizedBox(
                                  width: 24,
                                  child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text('ITEM NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 65,
                                  child: Text('RATE', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                SizedBox(
                                  width: 75,
                                  child: Text('AMOUNT', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Items List Rows
                          if (sale.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: Text(
                                  'No item breakdown available for this invoice.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sale.items.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, index) {
                                final item = sale.items[index];
                                final hasBatchOrExp = (item.batchNumber != null && item.batchNumber!.isNotEmpty) ||
                                    item.expiryDate != null ||
                                    item.discount > 0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.medicineName,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                            ),
                                            if (hasBatchOrExp) ...[
                                              const SizedBox(height: 2),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 2,
                                                children: [
                                                  if (item.batchNumber != null && item.batchNumber!.isNotEmpty)
                                                    Text(
                                                      'Batch: ${item.batchNumber}',
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                                    ),
                                                  if (item.expiryDate != null)
                                                    Text(
                                                      'Exp: ${DateFormat('yyyy/MM').format(item.expiryDate!)}',
                                                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                                                    ),
                                                  if (item.discount > 0)
                                                    Text(
                                                      'Disc: ${item.discount.toStringAsFixed(0)}%',
                                                      style: const TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.w600),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '${item.quantity}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 65,
                                        child: Text(
                                          item.price.toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 75,
                                        child: Text(
                                          'Rs ${item.total.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 12),
                          const Divider(thickness: 1.5, color: Colors.black26),
                          const SizedBox(height: 8),

                          // 4. Totals Summary Box
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                  Text('Rs ${sale.subTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              if (sale.discount > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Discount:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                                    Text('- Rs ${sale.discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'GRAND TOTAL:',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    Text(
                                      'Rs ${sale.grandTotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 5. Footer Terms & Thank You Message
                          Center(
                            child: Column(
                              children: const [
                                Text(
                                  'Thank you for your purchase! Wish you good health! 💊',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black54,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '* Computer Generated Invoice. Goods once sold will not be taken back without bill.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 9, color: Colors.grey),
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

              const SizedBox(height: 16),

              // 6. Action Button (PRINT RECEIPT)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _printPdf(sale);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.print_rounded),
                  label: const Text(
                    'PRINT TAX INVOICE (PDF)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printPdf(Sale sale) async {
    final pdf = pw.Document();
    final profile = await ref.read(profileProvider.future);
    final user = ref.read(authProvider);
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('hh:mm:ss a');

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
                    if (profile?.panNumber != null) pw.Text('PAN: ${profile?.panNumber}'),
                    if (profile?.location != null) pw.Text(profile!.location),
                    if (profile?.phoneNumber != null) pw.Text('Phone: ${profile?.phoneNumber}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('M/S: ${sale.customerName.isEmpty ? "Walk-in Customer" : sale.customerName}'),
                        if (sale.customerAddress != null && sale.customerAddress!.isNotEmpty)
                          pw.Text('Address: ${sale.customerAddress}'),
                        if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                          pw.Text('Phone: ${sale.customerPhone}'),
                        if (sale.customerPan != null && sale.customerPan!.isNotEmpty)
                          pw.Text('PAN: ${sale.customerPan}'),
                        pw.Text('Pay Mode: ${sale.payMode}'),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice No: ${sale.invoiceNumber}'),
                      pw.Text(
                        'Date: ${dateFormat.format(sale.date)}  ${timeFormat.format(sale.date)}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('S.N.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('BATCH', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('EXP.DATE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('MRP', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('DIS %', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('QTY', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              ...sale.items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 1, child: pw.Text('$index', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 4, child: pw.Text(item.medicineName, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(item.batchNumber ?? '', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.expiryDate != null ? DateFormat('yyyy/MM').format(item.expiryDate!) : '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(flex: 2, child: pw.Text(item.mrp?.toStringAsFixed(2) ?? '', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text(item.discount.toStringAsFixed(1), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(item.total.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL:'),
                            pw.Text(sale.subTotal.toStringAsFixed(2)),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('NET TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text(sale.grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'In words: ${NumberToWordsEnglish.convert(sale.grandTotal.toInt()).toUpperCase()} ONLY',
                style: const pw.TextStyle(fontSize: 10),
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
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
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
    );
  }
}
