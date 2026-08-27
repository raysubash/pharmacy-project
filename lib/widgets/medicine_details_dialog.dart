import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/medicine_model.dart';
import '../utils/theme.dart';

void showMedicineDetailsModal(BuildContext context, Medicine medicine) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MedicineDetailsBottomSheet(medicine: medicine),
  );
}

class MedicineDetailsBottomSheet extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailsBottomSheet({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    final activeStatuses = medicine.activeStatuses;
    final String formattedExpiry = medicine.expiryDate != null
        ? DateFormat('dd MMM yyyy').format(medicine.expiryDate!)
        : 'N/A';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or Icon Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    ),
                  ),
                  child: medicine.imagePath != null &&
                          medicine.imagePath!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: medicine.imagePath!.startsWith('http')
                              ? Image.network(medicine.imagePath!, fit: BoxFit.cover)
                              : Image.file(File(medicine.imagePath!), fit: BoxFit.cover),
                        )
                      : Icon(
                          Icons.medication_liquid_rounded,
                          size: 32,
                          color: AppTheme.primaryGreen,
                        ),
                ),
                const SizedBox(width: 14),

                // Name & Generic
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      if (medicine.genericName != null &&
                          medicine.genericName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          medicine.genericName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Status Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: activeStatuses.map((status) {
                          String text = status.label;
                          if (status == MedicineStatus.expired &&
                              medicine.daysUntilExpiry != null) {
                            text = 'Expired (${medicine.daysUntilExpiry!.abs()}d ago)';
                          } else if (status == MedicineStatus.expiringSoon &&
                              medicine.daysUntilExpiry != null) {
                            text = 'Expires in ${medicine.daysUntilExpiry}d';
                          } else if (status == MedicineStatus.lowStock) {
                            text = 'Low Stock (${medicine.currentStock}/${medicine.minStock})';
                          } else if (status == MedicineStatus.overStock &&
                              medicine.maxStock != null) {
                            text = 'Over Stock (${medicine.currentStock}/${medicine.maxStock})';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: status.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: status.color.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(status.icon, size: 12, color: status.color),
                                const SizedBox(width: 4),
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: status.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Close X Button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Cards Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Current Stock',
                          value: '${medicine.currentStock}',
                          subtitle: 'Min: ${medicine.minStock}${medicine.maxStock != null ? ' | Max: ${medicine.maxStock}' : ''}',
                          icon: Icons.inventory_2_outlined,
                          color: medicine.currentStock <= medicine.minStock
                              ? Colors.orange[700]!
                              : AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Selling Price',
                          value: 'Rs. ${medicine.sellingPrice.toStringAsFixed(2)}',
                          subtitle: medicine.mrp != null
                              ? 'MRP: Rs. ${medicine.mrp!.toStringAsFixed(2)}'
                              : 'Standard Rate',
                          icon: Icons.payments_outlined,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Detail Section: General Info
                  _buildSectionHeader('General Information', Icons.info_outline),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem('Brand Name', medicine.brandName ?? 'N/A'),
                        _buildDivider(),
                        _buildInfoItem('Generic Name', medicine.genericName ?? 'N/A'),
                        _buildDivider(),
                        _buildInfoItem('Category', medicine.category.isNotEmpty ? medicine.category : 'General'),
                        _buildDivider(),
                        _buildInfoItem('Packaging', medicine.packaging ?? 'N/A'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detail Section: Stock & Location
                  _buildSectionHeader('Stock & Storage Details', Icons.warehouse_outlined),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem('Batch Number', medicine.batchNumber ?? 'N/A'),
                        _buildDivider(),
                        _buildInfoItem('Expiry Date', formattedExpiry),
                        _buildDivider(),
                        _buildInfoItem('Measure Unit', medicine.unit.toString().split('.').last.toUpperCase()),
                        _buildDivider(),
                        _buildInfoItem('Storage Location', medicine.storageLocation ?? 'Not Specified'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Detail Section: Pricing & Margin
                  _buildSectionHeader('Pricing Overview', Icons.sell_outlined),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoItem(
                          'Maximum Retail Price (MRP)',
                          medicine.mrp != null
                              ? 'Rs. ${medicine.mrp!.toStringAsFixed(2)}'
                              : 'N/A',
                        ),
                        _buildDivider(),
                        _buildInfoItem(
                          'Selling Price',
                          'Rs. ${medicine.sellingPrice.toStringAsFixed(2)}',
                          valueColor: AppTheme.primaryGreen,
                          isBold: true,
                        ),
                        if (medicine.mrp != null && medicine.mrp! > medicine.sellingPrice) ...[
                          _buildDivider(),
                          _buildInfoItem(
                            'Customer Discount',
                            'Rs. ${(medicine.mrp! - medicine.sellingPrice).toStringAsFixed(2)} (${(((medicine.mrp! - medicine.sellingPrice) / medicine.mrp!) * 100).toStringAsFixed(1)}% OFF)',
                            valueColor: Colors.deepOrange,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Bottom Action Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/medicines/edit', extra: medicine);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Medicine',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3436),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? const Color(0xFF2D3436),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
