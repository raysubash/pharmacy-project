import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final userList = await ApiService.getAllUsers();
      setState(() {
        users = userList;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching users: $e")),
        );
      }
    }
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this user? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteUser(id);
        _fetchUsers(); // Refresh list
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("User deleted successfully")),
           );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete user: $e")),
          );
        }
      }
    }
  }

  void _viewPaymentProof(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("No proof attached")),
        );
        return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Container(
                 constraints: const BoxConstraints(maxHeight: 500),
                 child: Image.memory(
                   base64Decode(base64Image),
                   fit: BoxFit.contain,
                   errorBuilder: (ctx, err, stack) => const Center(
                     child: Text("Invalid Image Data", style: TextStyle(color: Colors.white)),
                   ),
                 ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
       context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.blueAccent,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Users",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${users.length}",
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: users.isEmpty 
                      ? const Center(child: Text("No users found"))
                      : ListView.builder(
                          itemCount: users.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                    final user = users[index];
                    final profile = user['profile'];
                    final subscription = profile?['subscription'];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(user['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(
                                    subscription != null && subscription['isActive'] == true ? "Active" : "Inactive",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: subscription != null && subscription['isActive'] == true ? Colors.green : Colors.grey,
                                )
                              ],
                            ),
                            Text("Email: ${user['email']}"),
                            const SizedBox(height: 8),
                            if (profile != null) ...[
                                Text("Pharmacy: ${profile['name']}"),
                                if (profile['location'] != null) Text("Location: ${profile['location']}"),
                                if (profile['phoneNumber'] != null) Text("Phone: ${profile['phoneNumber']}"),
                                if (profile['panNumber'] != null) Text("PAN/VAT: ${profile['panNumber']}"),
                                const Divider(),
                                Text("Plan: ${subscription?['plan'] ?? 'None'}"),
                                if (subscription?['expiryDate'] != null)
                                   Text("Expires: ${subscription['expiryDate'].toString().split('T')[0]}"),
                            ] else
                                const Text("No Profile Setup", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                            
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (subscription != null && subscription['paymentProofImage'] != null)
                                  TextButton.icon(
                                    icon: const Icon(Icons.image),
                                    label: const Text("View Proof"),
                                    onPressed: () => _viewPaymentProof(subscription['paymentProofImage']),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteUser(user['_id']),
                                  tooltip: "Delete User",
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
      ]
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add user screen or show dialog
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add User feature can be implemented here (e.g. signup flow)")));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
