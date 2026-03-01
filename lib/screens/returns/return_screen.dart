import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/return_provider.dart';
import '../../models/return_model.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReturnDetails(ReturnItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            item.medicineName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Status', item.status, isStatus: true),
                const Divider(),
                _buildDetailRow('Batch Number', item.batchNumber),
                _buildDetailRow('Quantity', '${item.quantity}'),
                _buildDetailRow('Reason', item.reason),
                _buildDetailRow(
                  'Return Date',
                  DateFormat('yyyy-MM-dd').format(item.returnDate),
                ),
                if (item.supplierName != null)
                  _buildDetailRow('Supplier', item.supplierName),
                if (item.refundAmount != null)
                  _buildDetailRow('Refund Amount', 'Rs. ${item.refundAmount}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value, {bool isStatus = false}) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (isStatus)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(value).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: _getStatusColor(value),
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Optimistic / Data handling
    // We use .when but we can also use .valueOrNull if we want to show stale data while loading
    // But since the user complained about loading stick, let's keep it clean
    final returnsAsync = ref.watch(returnProvider);
    final previousReturns =
        returnsAsync
            .valueOrNull; // Use this for "loading" state display if exists

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          elevation: 0,
          title: const Text('Returns Management'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'Return Requests'), Tab(text: 'Reminders')],
          ),
        ),
        body: Column(
          children: [
            // Styled Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.primaryGreen,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search returns, batch, reason...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),
            // Content
            Expanded(
              child: Builder(
                builder: (context) {
                  return returnsAsync.when(
                    data: (data) => _buildFilteredTabs(context, data),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    loading:
                        () =>
                            returnsAsync.value != null
                                ? _buildFilteredTabs(
                                  context,
                                  returnsAsync.value!,
                                )
                                : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
            context.push('/returns/add');
          },
        ),
      ),
    );
  }

  Widget _buildFilteredTabs(BuildContext context, List<ReturnItem> allReturns) {
    // Search Filtering
    final filtered =
        allReturns.where((r) {
          final q = _searchQuery.toLowerCase();
          return r.medicineName.toLowerCase().contains(q) ||
              r.batchNumber.toLowerCase().contains(q) ||
              r.reason.toLowerCase().contains(q);
        }).toList();

    final requests = filtered.where((r) => r.status != 'Reminder').toList();
    final reminders = filtered.where((r) => r.status == 'Reminder').toList();

    requests.sort((a, b) => b.returnDate.compareTo(a.returnDate));
    reminders.sort((a, b) => a.returnDate.compareTo(b.returnDate));

    return TabBarView(
      children: [
        _buildReturnList(context, requests, false),
        _buildReturnList(context, reminders, true),
      ],
    );
  }

  Future<void> _deleteReturn(ReturnItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Delete return for ${item.medicineName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      if (mounted) {
        try {
          // Use ref.read outside build
          await ref.read(returnProvider.notifier).deleteReturn(item.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Return deleted')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      }
    }
  }

  Widget _buildReturnList(
    BuildContext context,
    List<ReturnItem> items,
    bool isReminder,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isReminder ? 'No reminders set.' : 'No return requests found.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(item.status).withOpacity(0.1),
              child: Icon(
                isReminder ? Icons.alarm : Icons.assignment_return,
                color: _getStatusColor(item.status),
              ),
            ),
            title: Text(
              item.medicineName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${item.quantity} • ${item.reason}'),
                Text(
                  isReminder
                      ? 'Due: ${DateFormat('yyyy-MM-dd').format(item.returnDate)}'
                      : 'Date: ${DateFormat('yyyy-MM-dd').format(item.returnDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  context.push('/returns/edit', extra: item);
                } else if (value == 'delete') {
                  _deleteReturn(item);
                }
              },
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ];
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.status,
                      style: TextStyle(
                        color: _getStatusColor(item.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.more_vert,
                      size: 16,
                      color: _getStatusColor(item.status),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () {
              _showReturnDetails(item);
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(
          0xFF4CAF50,
        ); // AppTheme.primaryGreen might not be static
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      case 'Returned':
        return Colors.blue;
      case 'Reminder': // Fix: handle 'Reminder' case if it comes here
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
