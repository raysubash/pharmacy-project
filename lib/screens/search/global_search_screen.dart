import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';
import '../../widgets/medicine_details_dialog.dart';

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



  void _showMedicineDetails(Medicine medicine) {
    showMedicineDetailsModal(context, medicine);
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
                        Text('Rs ${medicine.sellingPrice}'),
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
