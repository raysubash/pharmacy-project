import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../models/medicine_model.dart';
import '../../providers/medicine_provider.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? medicineToEdit;
  const AddMedicineScreen({super.key, this.medicineToEdit});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _minStockController = TextEditingController(); // Min Stock
  final _originalmrpController = TextEditingController(); // MRP
  final _sellingPriceController = TextEditingController();
  final _packagingController = TextEditingController();
  final _locationController = TextEditingController();
  final _initialStockController = TextEditingController();
  final _batchNumberController = TextEditingController(); // Batch
  final _expiryDateController = TextEditingController(); // Expiry

  // State Variables
  String? _selectedCategory;
  MeasureUnit? _selectedUnit;
  File? _selectedImage;
  DateTime? _selectedExpiryDate;

  // Default Categories
  final List<String> _categories = [
    'Antibiotic',
    'Painkiller',
    'Vitamin',
    'Syrup',
    'Ointment',
    'G.P + Gynae',
    'Add New Category...',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medicineToEdit != null) {
      final m = widget.medicineToEdit!;
      _nameController.text = m.name;
      _brandNameController.text = m.brandName ?? '';
      _genericNameController.text = m.genericName ?? '';
      _minStockController.text = m.minStock.toString();
      _originalmrpController.text = m.mrp?.toString() ?? '';
      _sellingPriceController.text = m.sellingPrice.toString();
      _packagingController.text = m.packaging ?? '';
      _locationController.text = m.storageLocation ?? '';
      _initialStockController.text = m.currentStock.toString();
      _batchNumberController.text = m.batchNumber ?? '';

      if (m.expiryDate != null) {
        _selectedExpiryDate = m.expiryDate;
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(
          m.expiryDate!,
        );
      }

      if (m.category.isNotEmpty && !_categories.contains(m.category)) {
        _categories.insert(0, m.category);
      }
      _selectedCategory = m.category;
      _selectedUnit = m.unit;

      if (m.imagePath != null &&
          m.imagePath!.isNotEmpty &&
          !m.imagePath!.startsWith('http')) {
        _selectedImage = File(m.imagePath!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandNameController.dispose();
    _genericNameController.dispose();
    _minStockController.dispose();
    _originalmrpController.dispose();
    _sellingPriceController.dispose();
    _packagingController.dispose();
    _locationController.dispose();
    _initialStockController.dispose();
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiryDate = picked;
        _expiryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addNewCategory() {
    showDialog(
      context: context,
      builder: (context) {
        String newCategory = '';
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Cardiological',
            ),
            onChanged: (value) {
              newCategory = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newCategory.isNotEmpty) {
                  setState(() {
                    _categories.insert(_categories.length - 1, newCategory);
                    _selectedCategory = newCategory;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newMedicine = Medicine(
          id: widget.medicineToEdit?.id ?? '', // Backend will generate ID if empty
          name: _nameController.text.trim(),
          brandName: _brandNameController.text.trim(),
          genericName: _genericNameController.text.trim(),
          category: _selectedCategory ?? 'Other',
          unit: _selectedUnit ?? MeasureUnit.tablet,
          minStock: int.tryParse(_minStockController.text) ?? 10,
          sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
          mrp: double.tryParse(_originalmrpController.text),
          packaging: _packagingController.text.trim(),
          storageLocation: _locationController.text.trim(),
          currentStock: int.tryParse(_initialStockController.text) ?? 0,
          imagePath: _selectedImage?.path ?? widget.medicineToEdit?.imagePath,
          batchNumber: _batchNumberController.text.trim(),
          expiryDate: _selectedExpiryDate,
        );

        if (widget.medicineToEdit != null) {
          await ref
              .read(medicineProvider.notifier)
              .updateMedicine(newMedicine.id, newMedicine);
        } else {
          await ref.read(medicineProvider.notifier).addMedicine(newMedicine);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.medicineToEdit != null
                    ? 'Medicine Updated Successfully'
                    : 'Medicine Saved Successfully',
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint(e.toString());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicineToEdit != null ? 'Edit Medicine' : 'Add New Medicine',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Medicine Image'),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      image:
                          _selectedImage != null
                              ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _selectedImage == null
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            )
                            : Stack(
                              children: [
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Details & Batch'),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name *'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Brand & Batch
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandNameController,
                      decoration: const InputDecoration(
                        labelText: 'Brand / Company *',
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _batchNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Batch Number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Expiry Date
              TextFormField(
                controller: _expiryDateController,
                readOnly: true,
                onTap: _pickExpiryDate,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 16),

              // Generic Name
              TextFormField(
                controller: _genericNameController,
                decoration: const InputDecoration(
                  labelText: 'Generic Name / Composition',
                ),
              ),
              const SizedBox(height: 16),

              // Category and Unit
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items:
                          _categories
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    style:
                                        e == 'Add New Category...'
                                            ? const TextStyle(
                                              color: AppTheme.primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            )
                                            : null,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v == 'Add New Category...') {
                          _addNewCategory();
                        } else {
                          setState(() {
                            _selectedCategory = v;
                          });
                        }
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<MeasureUnit>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit Type *',
                      ),
                      items:
                          MeasureUnit.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e.toString().split('.').last.toUpperCase(),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedUnit = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _packagingController,
                decoration: const InputDecoration(
                  labelText: 'Packing (e.g. 10 x 10 Blister)',
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Pricing & Stock'),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalmrpController,
                      decoration: const InputDecoration(labelText: 'MRP (₹)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price *',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _initialStockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Low Stock Alert',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Storage Location (Shelf/Rack)',
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveMedicine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.medicineToEdit == null
                        ? 'Save Medicine'
                        : 'Update Medicine',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }
}
