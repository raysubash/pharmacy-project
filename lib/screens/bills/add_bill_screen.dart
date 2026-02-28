import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../utils/theme.dart';

class AddPurchaseBillScreen extends ConsumerStatefulWidget {
  final PurchaseBill? billToEdit;
  const AddPurchaseBillScreen({super.key, this.billToEdit});

  @override
  ConsumerState<AddPurchaseBillScreen> createState() =>
      _AddPurchaseBillScreenState();
}

class _AddPurchaseBillScreenState extends ConsumerState<AddPurchaseBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemFormKey = GlobalKey<FormState>(); // Separate key for item addition

  // Header controllers
  final _billNumberController = TextEditingController();
  final _supplierNameController = TextEditingController();
  final _billDateController = TextEditingController();

  // Item controllers
  final _medicineNameController = TextEditingController();
  final _batchNumberController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _expDateController = TextEditingController();

  DateTime? _selectedBillDate;
  DateTime? _selectedMfgDate;
  DateTime? _selectedExpDate;

  List<BillItem> _billItems = [];

  bool get _isEditing => widget.billToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadBillData();
    } else {
      _selectedBillDate = DateTime.now();
      _billDateController.text = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedBillDate!);
    }
  }

  void _loadBillData() {
    final bill = widget.billToEdit!;
    _billNumberController.text = bill.billNumber;
    _supplierNameController.text = bill.supplierName;
    _selectedBillDate = bill.billDate;
    _billDateController.text = DateFormat('yyyy-MM-dd').format(bill.billDate);
    _billItems = List.from(bill.items);
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _supplierNameController.dispose();
    _billDateController.dispose();
    _medicineNameController.dispose();
    _batchNumberController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _mfgDateController.dispose();
    _expDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
    Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('yyyy-MM-dd').format(picked);
        onDateSelected(picked);
      });
    }
  }

  void _addBillItem() {
    if (_itemFormKey.currentState!.validate()) {
      if (_selectedMfgDate == null || _selectedExpDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select MFG and EXP dates')),
        );
        return;
      }

      final newItem = BillItem(
        medicineId:
            const Uuid().v4(), // Generate temporary ID or handle mapping
        medicineName: _medicineNameController.text.trim(),
        batchNumber: _batchNumberController.text.trim(),
        manufactureDate: _selectedMfgDate!,
        expiryDate: _selectedExpDate!,
        quantity: int.parse(_quantityController.text.trim()),
        purchasePrice: double.parse(_priceController.text.trim()),
      );

      setState(() {
        _billItems.add(newItem);
        // Clear item fields
        _medicineNameController.clear();
        _batchNumberController.clear();
        _quantityController.clear();
        _priceController.clear();
        _mfgDateController.clear();
        _expDateController.clear();
        _selectedMfgDate = null;
        _selectedExpDate = null;
      });
    }
  }

  void _removeBillItem(int index) {
    setState(() {
      _billItems.removeAt(index);
    });
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    final bill = PurchaseBill(
      id: widget.billToEdit?.id ?? '', // ID handled by backend for new bills
      billNumber: _billNumberController.text.trim(),
      supplierName: _supplierNameController.text.trim(),
      billDate: _selectedBillDate!,
      items: _billItems,
      totalAmount: _billItems.fold(0, (sum, item) => sum + item.totalAmount),
      entryDate: DateTime.now(),
    );

    try {
      if (_isEditing) {
        // Implement update logic if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing not fully supported yet')),
        );
      } else {
        await ref.read(billProvider.notifier).addBill(bill);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Purchase Bill Saved Successfully')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving bill: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Purchase Bill' : 'New Purchase Bill'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveBill),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Form
            Form(
              key: _formKey,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _billNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Number',
                          prefixIcon: Icon(Icons.receipt),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter bill number'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _supplierNameController,
                        decoration: const InputDecoration(
                          labelText: 'Supplier Name',
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? 'Please enter supplier name'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _billDateController,
                        decoration: const InputDecoration(
                          labelText: 'Bill Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap:
                            () => _selectDate(
                              context,
                              _billDateController,
                              (d) => _selectedBillDate = d,
                            ),
                        validator:
                            (value) =>
                                value!.isEmpty ? 'Please select date' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Add Item Section
            Text('Add Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _itemFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _medicineNameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _batchNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Batch No',
                              ),
                              validator:
                                  (val) => val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (val) => val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Price',
                              ),
                              keyboardType: TextInputType.number,
                              validator:
                                  (val) => val!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _mfgDateController,
                              decoration: const InputDecoration(
                                labelText: 'MFG Date',
                              ),
                              readOnly: true,
                              onTap:
                                  () => _selectDate(
                                    context,
                                    _mfgDateController,
                                    (d) => _selectedMfgDate = d,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _expDateController,
                              decoration: const InputDecoration(
                                labelText: 'EXP Date',
                              ),
                              readOnly: true,
                              onTap:
                                  () => _selectDate(
                                    context,
                                    _expDateController,
                                    (d) => _selectedExpDate = d,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addBillItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add to Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            // Items List
            if (_billItems.isNotEmpty) ...[
              Text(
                'Items in Bill (${_billItems.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _billItems.length,
                itemBuilder: (context, index) {
                  final item = _billItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item.medicineName),
                      subtitle: Text(
                        'Qty: ${item.quantity} | Batch: ${item.batchNumber}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${item.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeBillItem(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${_billItems.fold(0.0, (sum, item) => sum + item.totalAmount).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
