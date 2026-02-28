import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/return_model.dart';
import '../../models/medicine_model.dart';
import '../../providers/return_provider.dart';
import '../../providers/medicine_provider.dart';
import '../../utils/theme.dart';

class AddReturnScreen extends ConsumerStatefulWidget {
  const AddReturnScreen({super.key});

  @override
  ConsumerState<AddReturnScreen> createState() => _AddReturnScreenState();
}

class _AddReturnScreenState extends ConsumerState<AddReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _medicineController = TextEditingController();
  final _batchController = TextEditingController();
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController(); // Or dropdown
  final _dateController = TextEditingController();

  String _status = 'Pending';
  final List<String> _statuses = [
    'Pending',
    'Approved',
    'Returned',
    'Rejected',
    'Reminder',
  ];
  final List<String> _reasons = ['Expired', 'Damaged', 'Wrong Item', 'Other'];
  String? _selectedReason;
  DateTime _selectedDate = DateTime.now();

  bool _isReminder = false;
  Medicine? _selectedMedicine;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _batchController.dispose();
    _qtyController.dispose();
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveReturn() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedReason == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a reason')));
      return;
    }

    final returnItem = ReturnItem(
      id: const Uuid().v4(),
      medicineName: _medicineController.text.trim(),
      batchNumber: _batchController.text.trim(),
      quantity: int.parse(_qtyController.text.trim()),
      reason: _selectedReason!,
      returnDate: _selectedDate,
      status: _isReminder ? 'Reminder' : _status,
    );

    try {
      await ref.read(returnProvider.notifier).addReturn(returnItem);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return added successfully')),
        );
        // Navigate back to history list
        // Assuming /returns is the history page
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding return: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Return Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Switch for Reminder
              SwitchListTile(
                title: const Text('Set as Reminder'),
                subtitle: const Text(
                  'Only schedule a return task, do not process immediately.',
                ),
                value: _isReminder,
                onChanged: (val) {
                  setState(() {
                    _isReminder = val;
                    if (_isReminder) {
                      _status = 'Reminder';
                    } else {
                      _status = 'Pending';
                    }
                  });
                },
              ),
              const Divider(),
              // Medicine Search & Auto-fill
              Consumer(
                builder: (context, ref, child) {
                  final medicinesAsync = ref.watch(medicineProvider);
                  return medicinesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error loading medicines: $e'),
                    data: (medicines) {
                      return Autocomplete<Medicine>(
                        displayStringForOption:
                            (Medicine option) => option.name,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<Medicine>.empty();
                          }
                          return medicines.where((Medicine option) {
                            return option.name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (Medicine selection) {
                          setState(() {
                            _selectedMedicine = selection;
                            _medicineController.text = selection.name;
                            _batchController.text = selection.batchNumber ?? '';
                            // You could also set expiry, etc. if your return model supports it
                          });
                        },
                        fieldViewBuilder: (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          // Sync initial text if user manually typed before selecting
                          if (_medicineController.text.isNotEmpty &&
                              textEditingController.text.isEmpty) {
                            textEditingController.text =
                                _medicineController.text;
                          }
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Search Medicine Name',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.search),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              return null;
                            },
                            onChanged: (val) {
                              _medicineController.text = val;
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                items:
                    _reasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                onChanged: (val) => setState(() => _selectedReason = val),
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Return/Reminder Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              if (!_isReminder) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value:
                      _status == 'Reminder'
                          ? null
                          : _status, // Don't show Reminder in status dropdown if not reminder mode?
                  items:
                      _statuses
                          .where((s) => s != 'Reminder')
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveReturn,
                  child: const Text('SAVE RETURN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
