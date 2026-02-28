import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<Medicine> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() => _query = query);
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final allMedicines = ref.read(medicineProvider).value ?? [];
    setState(() {
      _results =
          allMedicines.where((m) {
            final nameMatch = m.name.toLowerCase().contains(
              query.toLowerCase(),
            );
            final genericMatch =
                m.genericName?.toLowerCase().contains(query.toLowerCase()) ??
                false;
            final batchMatch = (m.batchNumber ?? '').toLowerCase().contains(
              query.toLowerCase(),
            );
            return nameMatch || genericMatch || batchMatch;
          }).toList();
    });
  }

  Widget _buildDetailRow(
    String label,
    String? value, {
    bool isStock = false,
    int? minStock,
    bool isPrice = false,
  }) {
    if (value == null || value.isEmpty) return const SizedBox();
    Color? valueColor;
    if (isStock && minStock != null) {
      final stock = int.tryParse(value) ?? 0;
      valueColor = stock <= minStock ? Colors.red : Colors.green;
    }
    if (isPrice) {
      valueColor = Colors.blue[800];
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            medicine.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Generic Name', medicine.genericName),
                _buildDetailRow('Batch Number', medicine.batchNumber),
                _buildDetailRow('Brand Name', medicine.brandName),
                _buildDetailRow('Category', medicine.category),
                const Divider(),
                _buildDetailRow('Packaging', medicine.packaging),
                _buildDetailRow('Storage Location', medicine.storageLocation),
                _buildDetailRow(
                  'Unit',
                  medicine.unit.toString().split('.').last,
                ),
                const Divider(),
                _buildDetailRow(
                  'Current Stock',
                  '${medicine.currentStock}',
                  isStock: true,
                  minStock: medicine.minStock,
                ),
                _buildDetailRow(
                  'Expiry Date',
                  medicine.expiryDate?.toString().substring(0, 10),
                ),
                const Divider(),
                if (medicine.mrp != null)
                  _buildDetailRow(
                    'MRP',
                    'Rs. ${medicine.mrp!.toStringAsFixed(2)}',
                  ),
                _buildDetailRow(
                  'Selling Price',
                  'Rs. ${medicine.sellingPrice.toStringAsFixed(2)}',
                  isPrice: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/medicines/edit', extra: medicine);
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search medicines, generics, batch...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onChanged: _performSearch,
        ),
      ),
      body:
          _query.isEmpty
              ? const Center(
                child: Text(
                  'Type to search',
                  style: TextStyle(color: Colors.grey),
                ),
              )
              : _results.isEmpty
              ? const Center(child: Text('No results found'))
              : ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final medicine = _results[index];
                  return ListTile(
                    title: Text(medicine.name),
                    subtitle: Text(
                      '${medicine.genericName ?? ''} • Batch: ${medicine.batchNumber}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Stock: ${medicine.currentStock}',
                          style: TextStyle(
                            color:
                                medicine.currentStock <= medicine.minStock
                                    ? Colors.red
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('₹${medicine.sellingPrice}'),
                      ],
                    ),
                    onTap: () {
                      _showMedicineDetails(medicine);
                    },
                  );
                },
              ),
    );
  }
}
