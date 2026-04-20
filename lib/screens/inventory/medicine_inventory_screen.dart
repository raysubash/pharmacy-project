import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/app_drawer.dart';

enum MedicineFilter { all, lowStock, expiring, expiringSoon, overStock }

class MedicineInventoryScreen extends ConsumerStatefulWidget {
  final MedicineFilter filter;
  const MedicineInventoryScreen({super.key, this.filter = MedicineFilter.all});

  @override
  ConsumerState<MedicineInventoryScreen> createState() =>
      _MedicineInventoryScreenState();
}

class _MedicineInventoryScreenState
    extends ConsumerState<MedicineInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateStock(Medicine medicine, int change) async {
    final newStock = medicine.currentStock + change;
    if (newStock >= 0) {
      final updatedMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        genericName: medicine.genericName,
        category: medicine.category,
        unit: medicine.unit,
        minStock: medicine.minStock,
        sellingPrice: medicine.sellingPrice,
        storageLocation: medicine.storageLocation,
        currentStock: newStock,
        brandName: medicine.brandName,
        packaging: medicine.packaging,
        mrp: medicine.mrp,
        imagePath: medicine.imagePath,
        batchNumber: medicine.batchNumber,
        expiryDate: medicine.expiryDate,
        createdDate: medicine.createdDate,
      );

      await ref
          .read(medicineProvider.notifier)
          .updateMedicine(medicine.id, updatedMedicine);
    }
  }

  void _confirmDelete(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete ${medicine.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(medicineProvider.notifier).deleteMedicine(medicine.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsyncValue = ref.watch(medicineProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text(
          'Medicine Inventory',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicine, batch, or company',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: medicinesAsyncValue.when(
              data: (allMedicines) {
                if (allMedicines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.medication_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No medicines added yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final medicines =
                    allMedicines.where((m) {
                      final name = m.name.toLowerCase();
                      final brand = (m.brandName ?? '').toLowerCase();
                      final batch = (m.batchNumber ?? '').toLowerCase();

                      final matchesSearch =
                          name.contains(_searchQuery) ||
                          brand.contains(_searchQuery) ||
                          batch.contains(_searchQuery);

                      bool passesFilter = true;
                      if (widget.filter == MedicineFilter.lowStock) {
                        passesFilter = m.currentStock <= m.minStock;
                      } else if (widget.filter == MedicineFilter.expiring) {
                        passesFilter =
                            m.expiryDate != null &&
                            m.expiryDate!.isBefore(DateTime.now());
                      } else if (widget.filter == MedicineFilter.expiringSoon) {
                        final threeMonthsFromNow =
                            DateTime.now().add(Duration(days: 90));
                        passesFilter =
                            m.expiryDate != null &&
                            m.expiryDate!.isAfter(DateTime.now()) &&
                            m.expiryDate!.isBefore(threeMonthsFromNow);
                      } else if (widget.filter == MedicineFilter.overStock) {
                        final twoMonthsAgo =
                            DateTime.now().subtract(Duration(days: 60));
                        passesFilter =
                            m.createdDate.isBefore(twoMonthsAgo) &&
                            m.currentStock == m.currentStock;
                      }

                      return matchesSearch && passesFilter;
                    }).toList();

                if (medicines.isEmpty) {
                  return const Center(child: Text('No medicines found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image with rounded corners
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey[100],
                                  ),
                                  child:
                                      medicine.imagePath != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child:
                                                medicine.imagePath!.startsWith(
                                                      'http',
                                                    )
                                                    ? Image.network(
                                                      medicine.imagePath!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.broken_image,
                                                            size: 30,
                                                            color: Colors.grey,
                                                          ),
                                                    )
                                                    : Image.file(
                                                      File(medicine.imagePath!),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return const Icon(
                                                          Icons.broken_image,
                                                          size: 30,
                                                          color: Colors.grey,
                                                        );
                                                      },
                                                    ),
                                          )
                                          : const Icon(
                                            Icons.medication,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                ),
                                const SizedBox(width: 16),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              medicine.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2D3436),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          // Expiry Badge removed? Or kept?
                                          // User didn't explicitly ask to remove the expiry badge from item, just "expiring soon... navbar".
                                          // "navbar" implies filters.
                                          // I will keep item badge as it's useful context.
                                          if (medicine.expiryDate != null &&
                                              medicine.expiryDate!
                                                      .difference(
                                                        DateTime.now(),
                                                      )
                                                      .inDays <
                                                  30)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.red[50],
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Expiring',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      if (medicine.genericName?.isNotEmpty ??
                                          false)
                                        Text(
                                          medicine.genericName!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),

                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Packing',
                                        medicine.packaging ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        'MRP',
                                        '₹${medicine.mrp ?? 0.0}/-',
                                      ),
                                      _buildInfoRow(
                                        'Company',
                                        medicine.brandName ?? 'N/A',
                                      ),
                                      if (medicine.batchNumber?.isNotEmpty ??
                                          false)
                                        _buildInfoRow(
                                          'Batch',
                                          medicine.batchNumber!,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xFFF1F2F6)),
                            const SizedBox(height: 12),
                            // Actions Row
                            Row(
                              children: [
                                // Edit Button
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    context.push('/medicines/edit', extra: medicine);
                                  },
                                  tooltip: 'Edit Medicine',
                                ),
                                // Delete Button
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(medicine),
                                  tooltip: 'Delete Medicine',
                                ),
                                const Spacer(),
                                _buildQuantityButton(
                                  icon: Icons.remove,
                                  color: const Color(0xFFEFF3F6),
                                  iconColor: Colors.black,
                                  onTap: () => _updateStock(medicine, -1),
                                ),
                                Container(
                                  width: 40,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${medicine.currentStock}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _buildQuantityButton(
                                  icon: Icons.add,
                                  color: AppTheme.primaryGreen,
                                  iconColor: Colors.white,
                                  onTap: () => _updateStock(medicine, 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/medicines/add');
        },
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF455A64),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}
