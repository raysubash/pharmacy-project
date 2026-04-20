import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/return_provider.dart';
import '../../models/medicine_model.dart';
import '../../models/return_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineProvider);
    final returnsAsync = ref.watch(returnProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: medicinesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (medicines) {
          return returnsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (e, st) => const Center(child: Text('Error loading returns')),
            data: (returns) {
              final notifications = _generateNotifications(medicines, returns);

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No new notifications',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.color.withValues(alpha: 0.1),
                        child: Icon(notif.icon, color: notif.color),
                      ),
                      title: Text(
                        notif.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(notif.message),
                      trailing: Text(
                        notif.date != null
                            ? DateFormat('MM/dd').format(notif.date!)
                            : 'Now',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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

  List<_NotificationItem> _generateNotifications(
    List<Medicine> medicines,
    List<ReturnItem> returns,
  ) {
    final List<_NotificationItem> list = [];
    final now = DateTime.now();
    final thirtyDays = now.add(const Duration(days: 30));

    // 1. Low Stock
    for (var m in medicines) {
      if (m.currentStock <= m.minStock) {
        list.add(
          _NotificationItem(
            title: 'Low Stock Alert',
            message: '${m.name} is running low (${m.currentStock} left).',
            icon: Icons.inventory,
            color: Colors.orange,
            date: now,
          ),
        );
      }

      // 2. Expiry Check (on medicine batch if available, currently Medicine model has expiryDate)
      if (m.expiryDate != null) {
        if (m.expiryDate!.isBefore(now)) {
          list.add(
            _NotificationItem(
              title: 'Medicine Expired',
              message: '${m.name} (Batch: ${m.batchNumber}) has expired!',
              icon: Icons.warning,
              color: Colors.red,
              date: m.expiryDate,
            ),
          );
        } else if (m.expiryDate!.isBefore(thirtyDays)) {
          list.add(
            _NotificationItem(
              title: 'Expiring Soon',
              message:
                  '${m.name} expires on ${DateFormat('yyyy-MM-dd').format(m.expiryDate!)}',
              icon: Icons.access_time,
              color: Colors.amber,
              date: m.expiryDate,
            ),
          );
        }
      }
    }

    // 3. Return Reminders
    for (var r in returns) {
      if (r.status == 'Reminder' &&
          r.returnDate.isBefore(now.add(const Duration(days: 1)))) {
        list.add(
          _NotificationItem(
            title: 'Return Reminder',
            message: 'Process return for ${r.medicineName} (${r.reason})',
            icon: Icons.assignment_return,
            color: Colors.blue,
            date: r.returnDate,
          ),
        );
      }
    }

    // Sort by Date (urgent/recent first)
    // Actually we want urgency. Expired > Low Stock > Reminders
    // But list sort is stable if we just append.
    // Let's just shuffle or keep as is.
    return list;
  }
}

class _NotificationItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final DateTime? date;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    this.date,
  });
}
