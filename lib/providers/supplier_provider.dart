import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/supplier_model.dart';

final supplierProvider =
    StateNotifierProvider<SupplierNotifier, List<Supplier>>((ref) {
  return SupplierNotifier();
});

class SupplierNotifier extends StateNotifier<List<Supplier>> {
  SupplierNotifier() : super([]) {
    _loadSuppliers();
  }

  static const String _storageKey = 'pharmacy_suppliers_list';

  Future<void> _loadSuppliers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);
      if (rawList != null && rawList.isNotEmpty) {
        state = rawList
            .map((item) => Supplier.fromJson(jsonDecode(item)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveSuppliers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = state.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_storageKey, rawList);
    } catch (_) {}
  }

  void addSupplier(Supplier supplier) {
    final newSupplier = Supplier(
      id: supplier.id.isEmpty ? const Uuid().v4() : supplier.id,
      name: supplier.name,
      contactPerson: supplier.contactPerson,
      phone: supplier.phone,
      email: supplier.email,
      status: supplier.status,
      categories: supplier.categories,
      iconType: supplier.iconType,
      billImagePath: supplier.billImagePath,
      billNumber: supplier.billNumber,
      billAmount: supplier.billAmount,
    );
    state = [...state, newSupplier];
    _saveSuppliers();
  }

  void deleteSupplier(String id) {
    state = state.where((s) => s.id != id).toList();
    _saveSuppliers();
  }
}
