import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/medicine_model.dart';
import '../../models/return_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/return_provider.dart';

enum NotificationType {
  expired,
  expiringSoon,
  lowStock,
  returnReminder,
}

class NotificationData {
  final String id;
  final NotificationType type;
  final String title;
  final String medicineName;
  final String? batchNumber;
  final String description;
  final DateTime date;
  final int? quantity;
  final Medicine? medicine;
  final ReturnItem? returnItem;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.medicineName,
    this.batchNumber,
    required this.description,
    required this.date,
    this.quantity,
    this.medicine,
    this.returnItem,
  });
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _showAll = false;
  final Set<String> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    final medicinesAsync = ref.watch(medicineProvider);
    final returnsAsync = ref.watch(returnProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF191C1E)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF191C1E),
          ),
        ),
      ),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00685F))),
        error: (e, st) => Center(child: Text('Error loading notifications: $e')),
        data: (medicines) {
          return returnsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00685F))),
            error: (e, st) => Center(child: Text('Error loading returns: $e')),
            data: (returns) {
              final rawNotifications = _buildNotificationList(medicines, returns);
              final activeNotifications = rawNotifications
                  .where((n) => !_dismissedIds.contains(n.id))
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header: Recent Alerts + Mark all read
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF191C1E),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _dismissedIds.addAll(activeNotifications.map((n) => n.id));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All notifications marked as read'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Row(
                              children: const [
                                Icon(Icons.done_all, size: 16, color: Color(0xFF00685F)),
                                SizedBox(width: 4),
                                Text(
                                  'Mark all read',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF00685F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (activeNotifications.isEmpty) ...[
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00685F).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_off_outlined,
                                size: 48,
                                color: Color(0xFF00685F),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'All caught up!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191C1E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'No pending alerts for low stock or expiry.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF57657B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Notifications Cards List
                      ...(_showAll
                              ? activeNotifications
                              : activeNotifications.take(6))
                          .map((notif) => _buildNotificationCard(notif)),

                      if (activeNotifications.length > 6 && !_showAll) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAll = true;
                              });
                            },
                            icon: const Text(
                              'Load More',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF57657B),
                              ),
                            ),
                            label: const Icon(
                              Icons.expand_more,
                              size: 18,
                              color: Color(0xFF57657B),
                            ),
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notif) {
    Color accentColor;
    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    switch (notif.type) {
      case NotificationType.expired:
        accentColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFFFDAD6);
        iconColor = const Color(0xFF93000A);
        iconData = Icons.error_rounded;
        break;
      case NotificationType.expiringSoon:
        accentColor = const Color(0xFFF59E0B);
        iconBgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        iconColor = const Color(0xFFD97706);
        iconData = Icons.warning_rounded;
        break;
      case NotificationType.lowStock:
        accentColor = const Color(0xFFF97316);
        iconBgColor = const Color(0xFFF97316).withValues(alpha: 0.12);
        iconColor = const Color(0xFFEA580C);
        iconData = Icons.inventory_2_rounded;
        break;
      case NotificationType.returnReminder:
        accentColor = const Color(0xFF00628D);
        iconBgColor = const Color(0xFFC9E6FF);
        iconColor = const Color(0xFF004C6E);
        iconData = Icons.assignment_return_rounded;
        break;
    }

    final timeAgoStr = _formatTimeAgo(notif.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left Accent Bar (4px)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: accentColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Circle Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Time Ago
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notif.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191C1E),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgoStr,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF57657B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Description
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF3D4947),
                              height: 1.35,
                            ),
                            children: [
                              TextSpan(text: notif.description),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Action Buttons
                        _buildActionButtons(notif),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(NotificationData notif) {
    switch (notif.type) {
      case NotificationType.expired:
        return Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                if (notif.medicine != null) {
                  _showDiscardDialog(context, notif.medicine!);
                } else {
                  setState(() {
                    _dismissedIds.add(notif.id);
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.delete_outline, size: 14),
              label: const Text(
                'Discard',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                context.go('/medicines?filter=expiring');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF57657B),
                side: const BorderSide(color: Color(0x33BCC9C6)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );

      case NotificationType.expiringSoon:
        return ElevatedButton.icon(
          onPressed: () {
            context.go('/medicines?filter=expiringSoon');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            foregroundColor: const Color(0xFFD97706),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.local_offer_outlined, size: 14),
          label: const Text(
            'Discount',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );

      case NotificationType.lowStock:
        return ElevatedButton.icon(
          onPressed: () {
            context.go('/medicines?filter=lowStock');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00685F),
            foregroundColor: Colors.white,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.shopping_cart_outlined, size: 14),
          label: const Text(
            'Reorder',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );

      case NotificationType.returnReminder:
        return OutlinedButton(
          onPressed: () {
            context.go('/returns');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF00628D),
            side: const BorderSide(color: Color(0xFF00628D)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Process Return',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
    }
  }

  void _showDiscardDialog(BuildContext context, Medicine medicine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Discard ${medicine.name}?'),
        content: Text(
          'This will remove ${medicine.currentStock} units of expired stock from active inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(medicineProvider.notifier).deleteMedicine(medicine.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${medicine.name} removed from inventory')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Discard'),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes.abs();
      return '${mins == 0 ? 1 : mins}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours.abs()}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  List<NotificationData> _buildNotificationList(
    List<Medicine> medicines,
    List<ReturnItem> returns,
  ) {
    final List<NotificationData> list = [];
    final now = DateTime.now();

    // 1. Expired Medicines (Real-Time Data)
    final expiredMeds = medicines.where((m) {
      if (m.expiryDate != null && m.expiryDate!.isBefore(now)) return true;
      return m.activeStatuses.contains(MedicineStatus.expired);
    }).toList();

    for (var m in expiredMeds) {
      final batchStr = (m.batchNumber != null && m.batchNumber!.isNotEmpty)
          ? 'Batch #${m.batchNumber}'
          : 'Current batch';
      list.add(
        NotificationData(
          id: 'exp_${m.id}',
          type: NotificationType.expired,
          title: 'Expired Medication',
          medicineName: m.name,
          batchNumber: m.batchNumber,
          description:
              '$batchStr of ${m.name} has passed its expiration date. Remove from active inventory immediately.',
          date: m.expiryDate ?? now,
          quantity: m.currentStock,
          medicine: m,
        ),
      );
    }

    // 2. Expiring Soon Medicines (Real-Time Data)
    final expiringSoonMeds = medicines.where((m) {
      if (expiredMeds.contains(m)) return false;
      if (m.daysUntilExpiry != null && m.daysUntilExpiry! <= 30 && m.daysUntilExpiry! >= 0) return true;
      return m.activeStatuses.contains(MedicineStatus.expiringSoon);
    }).toList();

    for (var m in expiringSoonMeds) {
      final days = m.daysUntilExpiry ?? 30;
      list.add(
        NotificationData(
          id: 'expsoon_${m.id}',
          type: NotificationType.expiringSoon,
          title: 'Expiring Soon',
          medicineName: m.name,
          batchNumber: m.batchNumber,
          description:
              '${m.currentStock} units of ${m.name} will expire in $days days. Consider moving to clearance or returning to supplier.',
          date: m.expiryDate ?? now,
          quantity: m.currentStock,
          medicine: m,
        ),
      );
    }

    // 3. Low Stock Alerts (Real-Time Data)
    final lowStockMeds = medicines.where((m) {
      if (m.currentStock <= m.minStock) return true;
      return m.activeStatuses.contains(MedicineStatus.lowStock);
    }).toList();

    for (var m in lowStockMeds) {
      list.add(
        NotificationData(
          id: 'lowstock_${m.id}',
          type: NotificationType.lowStock,
          title: 'Low Stock Alert',
          medicineName: m.name,
          batchNumber: m.batchNumber,
          description:
              '${m.name} is below minimum stock level of ${m.minStock} units (Current stock: ${m.currentStock}). Reorder to avoid stockouts.',
          date: now,
          quantity: m.currentStock,
          medicine: m,
        ),
      );
    }

    // 4. Return Reminders (Real-Time Data)
    for (var r in returns) {
      if (r.status == 'Reminder' ||
          r.status == 'Pending' ||
          r.returnDate.isBefore(now.add(const Duration(days: 3)))) {
        list.add(
          NotificationData(
            id: 'ret_${r.id}',
            type: NotificationType.returnReminder,
            title: 'Return Reminder',
            medicineName: r.medicineName,
            description:
                'Supplier return window for ${r.medicineName} (${r.reason}) is active.',
            date: r.returnDate,
            returnItem: r,
          ),
        );
      }
    }

    // Sort by type urgency (Expired -> ExpiringSoon -> LowStock -> ReturnReminder)
    list.sort((a, b) => a.type.index.compareTo(b.type.index));
    return list;
  }
}
