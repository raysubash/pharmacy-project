import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/profile_avatar_icon.dart';
import '../../widgets/medicine_details_dialog.dart';

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
  late MedicineFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filter;
  }

  @override
  void didUpdateWidget(MedicineInventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      setState(() {
        _activeFilter = widget.filter;
      });
    }
  }

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

  Widget _buildFilterChipsBar(List<Medicine> allMedicines) {
    final lowStockCount = allMedicines
        .where((m) => m.activeStatuses.contains(MedicineStatus.lowStock))
        .length;
    final expiringSoonCount = allMedicines
        .where((m) => m.activeStatuses.contains(MedicineStatus.expiringSoon))
        .length;
    final expiredCount = allMedicines
        .where((m) => m.activeStatuses.contains(MedicineStatus.expired))
        .length;
    final overStockCount = allMedicines
        .where((m) => m.activeStatuses.contains(MedicineStatus.overStock))
        .length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          _buildChip(
            'All (${allMedicines.length})',
            MedicineFilter.all,
            AppTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Low Stock ($lowStockCount)',
            MedicineFilter.lowStock,
            Colors.orange[700]!,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Expiring Soon ($expiringSoonCount)',
            MedicineFilter.expiringSoon,
            Colors.amber[800]!,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Expired ($expiredCount)',
            MedicineFilter.expiring,
            Colors.red[700]!,
          ),
          const SizedBox(width: 8),
          _buildChip(
            'Over Stock ($overStockCount)',
            MedicineFilter.overStock,
            Colors.purple[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, MedicineFilter filterType, Color activeColor) {
    final isSelected = _activeFilter == filterType;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Colors.grey[100],
      elevation: isSelected ? 2 : 0,
      pressElevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : Colors.grey.shade300,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _activeFilter = filterType;
          });
        }
      },
    );
  }

  Widget _buildStatusBadges(Medicine medicine) {
    final active = medicine.activeStatuses;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: active.map((status) {
        String badgeText = status.label;
        if (status == MedicineStatus.expired) {
          final days = medicine.daysUntilExpiry;
          if (days != null) {
            badgeText = 'Expired (${days.abs()}d ago)';
          }
        } else if (status == MedicineStatus.expiringSoon) {
          final days = medicine.daysUntilExpiry;
          if (days != null) {
            badgeText = 'Expires in ${days}d';
          }
        } else if (status == MedicineStatus.lowStock) {
          badgeText = 'Low Stock (${medicine.currentStock}/${medicine.minStock})';
        } else if (status == MedicineStatus.overStock) {
          badgeText = 'Over Stock (${medicine.currentStock}/${medicine.maxStock ?? 0})';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: status.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: status.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 12, color: status.color),
              const SizedBox(width: 4),
              Text(
                badgeText,
                style: TextStyle(
                  color: status.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
        actions: const [
          ProfileAvatarIcon(
            radius: 20,
            iconColor: Colors.white,
            backgroundColor: Color(0x33FFFFFF),
          ),
        ],
      ),
      body: medicinesAsyncValue.when(
        data: (allMedicines) {
          final medicines = allMedicines.where((m) {
            final name = m.name.toLowerCase();
            final brand = (m.brandName ?? '').toLowerCase();
            final batch = (m.batchNumber ?? '').toLowerCase();

            final matchesSearch =
                name.contains(_searchQuery) ||
                brand.contains(_searchQuery) ||
                batch.contains(_searchQuery);

            bool passesFilter = true;
            if (_activeFilter == MedicineFilter.lowStock) {
              passesFilter = m.activeStatuses.contains(MedicineStatus.lowStock);
            } else if (_activeFilter == MedicineFilter.expiring) {
              passesFilter = m.activeStatuses.contains(MedicineStatus.expired);
            } else if (_activeFilter == MedicineFilter.expiringSoon) {
              passesFilter = m.activeStatuses.contains(MedicineStatus.expiringSoon);
            } else if (_activeFilter == MedicineFilter.overStock) {
              passesFilter = m.activeStatuses.contains(MedicineStatus.overStock);
            }

            return matchesSearch && passesFilter;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // Filter Chips Bar
              _buildFilterChipsBar(allMedicines),
              const SizedBox(height: 8),

              Expanded(
                child: allMedicines.isEmpty
                    ? Center(
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
                      )
                    : medicines.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inventory_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _activeFilter == MedicineFilter.lowStock
                                      ? 'No low stock medicines found.'
                                      : 'No medicines match the selected filter.',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                if (_activeFilter != MedicineFilter.all) ...[
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => setState(
                                      () => _activeFilter = MedicineFilter.all,
                                    ),
                                    icon: const Icon(Icons.clear_all, size: 18),
                                    label: const Text('Show All Medicines'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : ListView.builder(
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => showMedicineDetailsModal(context, medicine),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  medicine.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF2D3436),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (medicine.genericName?.isNotEmpty ?? false) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    medicine.genericName!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadges(medicine),
                                        ],
                                      ),

                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Packing',
                                        medicine.packaging ?? 'N/A',
                                      ),
                                      _buildInfoRow(
                                        'MRP',
                                        'Rs ${medicine.mrp ?? 0.0}/-',
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
                    ),
                  );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'medicine_inventory_fab',
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
