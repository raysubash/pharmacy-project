import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bill_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import 'package:intl/intl.dart';

class PurchaseBillScreen extends ConsumerWidget {
  const PurchaseBillScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Purchase Bills')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/bills/add');
        },
        child: const Icon(Icons.add),
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (bills) {
          if (bills.isEmpty) {
            return const Center(
              child: Text(
                'No purchase bills added yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final sortedBills = List.from(bills)
            ..sort((a, b) => b.billDate.compareTo(a.billDate));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedBills.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = sortedBills[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  title: Text(
                    bill.supplierName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Bill #${bill.billNumber} • ${DateFormat('yyyy-MM-dd').format(bill.billDate)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      Text(
                        '${bill.items.length} items',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Show bill details
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.6,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (context, scrollController) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Bill Details',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.headlineSmall,
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (ctx) => AlertDialog(
                                                      title: const Text(
                                                        'Confirm Delete',
                                                      ),
                                                      content: const Text(
                                                        'Are you sure you want to delete this bill?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    ctx,
                                                                  ),
                                                          child: const Text(
                                                            'Cancel',
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            ref
                                                                .read(
                                                                  billProvider
                                                                      .notifier,
                                                                )
                                                                .deleteBill(
                                                                  bill.id,
                                                                );
                                                            Navigator.pop(ctx);
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          },
                                                          child: const Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDetailRow(
                                    'Supplier',
                                    bill.supplierName,
                                  ),
                                  _buildDetailRow(
                                    'Bill Number',
                                    bill.billNumber,
                                  ),
                                  _buildDetailRow(
                                    'Date',
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(bill.billDate),
                                  ),
                                  const Divider(height: 32),
                                  Expanded(
                                    child: ListView.builder(
                                      controller: scrollController,
                                      itemCount: bill.items.length,
                                      itemBuilder: (context, index) {
                                        final item = bill.items[index];
                                        return ListTile(
                                          title: Text(
                                            item.medicineName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                'Batch: ${item.batchNumber}',
                                              ),
                                              Text('Qty: ${item.quantity}'),
                                            ],
                                          ),
                                          isThreeLine: true,
                                          trailing: Text(
                                            '₹${item.totalAmount}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '₹${bill.totalAmount}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
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
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
