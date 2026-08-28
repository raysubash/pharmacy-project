import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import '../../models/medicine_model.dart';
import '../../models/sale_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';

class CustomerBillScreen extends ConsumerStatefulWidget {
  const CustomerBillScreen({super.key});

  @override
  ConsumerState<CustomerBillScreen> createState() => _CustomerBillScreenState();
}

class _CustomerBillScreenState extends ConsumerState<CustomerBillScreen> {
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPanController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _discountController = TextEditingController(text: '0');

  String _paymentMode = 'Cash'; // Default: Cash or Fonepay

  // Search & Cart
  final _searchController = TextEditingController();
  List<Medicine> _searchResults = [];
  final List<SaleItem> _cartItems = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _invoiceNumberController.text =
        'INV-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _customerPanController.dispose();
    _invoiceNumberController.dispose();
    _searchController.dispose();
    _discountController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _searchMedicines(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final allMedicines = ref.read(medicineProvider).value ?? [];
    setState(() {
      _searchResults = allMedicines.where((med) {
        return med.name.toLowerCase().contains(query.toLowerCase()) ||
            (med.genericName?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  void _addToCart(Medicine medicine) {
    _showQuantityDialog(medicine);
  }

  Future<void> _showQuantityDialog(Medicine medicine) async {
    final quantityController = TextEditingController(text: '1');
    final discountController = TextEditingController(text: '0');
    final mrpController = TextEditingController(
      text: medicine.mrp?.toString() ?? medicine.sellingPrice.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add ${medicine.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available Stock: ${medicine.currentStock}',
                style: const TextStyle(color: Color(0xFF006B5F), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mrpController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rate / Unit (Rs)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Discount (%)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003527),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final qty = int.tryParse(quantityController.text);
                final disc = double.tryParse(discountController.text) ?? 0.0;
                final newPrice = double.tryParse(mrpController.text);

                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Quantity')),
                  );
                  return;
                }
                if (qty > medicine.currentStock) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Not enough stock')),
                  );
                  return;
                }
                if (newPrice == null || newPrice < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid Price')),
                  );
                  return;
                }

                _addConfirmedItemToCart(medicine, qty, disc, newPrice);
                Navigator.pop(context);
              },
              child: const Text('Add to Cart'),
            ),
          ],
        );
      },
    );
    _searchController.clear();
    setState(() => _searchResults = []);
  }

  void _addConfirmedItemToCart(
    Medicine medicine,
    int qty,
    double discountPercent,
    double finalPrice,
  ) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.medicineId == medicine.id,
    );

    final grossTotal = qty * finalPrice;
    final discountAmount = grossTotal * (discountPercent / 100);
    final netTotal = grossTotal - discountAmount;

    if (existingIndex != -1) {
      final currentQty = _cartItems[existingIndex].quantity;
      final newQty = currentQty + qty;

      if (newQty > medicine.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total quantity exceeds stock')),
        );
        return;
      }

      setState(() {
        _cartItems[existingIndex] = SaleItem(
          medicineId: medicine.id,
          medicineName: medicine.name,
          quantity: newQty,
          price: finalPrice,
          discount: discountPercent,
          total: (newQty * finalPrice) * (1 - (discountPercent / 100)),
          batchNumber: medicine.batchNumber,
          expiryDate: medicine.expiryDate,
          mrp: finalPrice,
        );
      });
    } else {
      setState(() {
        _cartItems.add(
          SaleItem(
            medicineId: medicine.id,
            medicineName: medicine.name,
            quantity: qty,
            price: finalPrice,
            discount: discountPercent,
            total: netTotal,
            batchNumber: medicine.batchNumber,
            expiryDate: medicine.expiryDate,
            mrp: finalPrice,
          ),
        );
      });
    }
  }

  void _updateItemQuantity(int index, int delta) {
    final item = _cartItems[index];
    final newQty = item.quantity + delta;

    if (newQty <= 0) {
      _removeFromCart(index);
      return;
    }

    final allMedicines = ref.read(medicineProvider).value ?? [];
    Medicine? medicine;
    try {
      medicine = allMedicines.firstWhere((m) => m.id == item.medicineId);
    } catch (_) {}

    if (medicine != null && newQty > medicine.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough stock')),
      );
      return;
    }

    setState(() {
      _cartItems[index] = SaleItem(
        medicineId: item.medicineId,
        medicineName: item.medicineName,
        quantity: newQty,
        price: item.price,
        discount: item.discount,
        total: (newQty * item.price) * (1 - (item.discount / 100)),
        batchNumber: item.batchNumber,
        expiryDate: item.expiryDate,
        mrp: item.mrp,
      );
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  double get _subTotalAmount =>
      _cartItems.fold(0, (sum, item) => sum + item.total);

  double get _discountAmount {
    return double.tryParse(_discountController.text) ?? 0.0;
  }

  double get _grandTotal => _subTotalAmount - _discountAmount;

  Future<void> _processSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item to current bill')),
      );
      return;
    }

    final customerName = _customerNameController.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerNameController.text.trim();

    final sale = Sale(
      invoiceNumber: _invoiceNumberController.text,
      customerName: customerName,
      customerPhone: _customerPhoneController.text,
      customerAddress: _customerAddressController.text,
      customerPan: _customerPanController.text,
      payMode: _paymentMode,
      items: _cartItems,
      subTotal: _subTotalAmount,
      discount: _discountAmount,
      grandTotal: _grandTotal,
      date: DateTime.now(),
    );

    try {
      await ref.read(saleProvider.notifier).addSale(sale);
      ref.invalidate(medicineProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale processed successfully!')),
        );
        await _printPdf(sale);
        setState(() {
          _cartItems.clear();
          _customerNameController.clear();
          _customerPhoneController.clear();
          _customerAddressController.clear();
          _customerPanController.clear();
          _discountController.text = '0';
          _invoiceNumberController.text =
              'INV-${DateTime.now().millisecondsSinceEpoch}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing sale: $e')),
        );
      }
    }
  }

  Future<void> _printPdf(Sale sale) async {
    final pdf = pw.Document();
    final profile = await ref.read(profileProvider.future);
    final user = ref.read(authProvider);
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('hh:mm:ss a');

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      (profile?.name ?? 'PHARMACY NAME').toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('PAN: ${profile?.panNumber ?? ''}'),
                    pw.Text(profile?.location ?? ''),
                    pw.Text('Phone: ${profile?.phoneNumber ?? ''}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('M/S: ${sale.customerName}'),
                        if (sale.customerAddress != null &&
                            sale.customerAddress!.isNotEmpty)
                          pw.Text('Address: ${sale.customerAddress}'),
                        if (sale.customerPhone != null &&
                            sale.customerPhone!.isNotEmpty)
                          pw.Text('Phone: ${sale.customerPhone}'),
                        if (sale.customerPan != null &&
                            sale.customerPan!.isNotEmpty)
                          pw.Text('PAN: ${sale.customerPan}'),
                        pw.Text('Pay Mode: ${sale.payMode}'),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Invoice No: ${sale.invoiceNumber}'),
                      pw.Text(
                        'Date: ${dateFormat.format(sale.date)}  ${timeFormat.format(sale.date)}',
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text('S.N.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text('ITEM DESCRIPTION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('RATE', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('AMOUNT', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ...sale.items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 1, child: pw.Text('$index', style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 4, child: pw.Text(item.medicineName, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(item.price.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text(item.total.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 250,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL:'),
                            pw.Text(sale.subTotal.toStringAsFixed(2)),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('NET TOTAL:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text(sale.grandTotal.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'In words: ${NumberToWordsEnglish.convert(sale.grandTotal.toInt()).toUpperCase()} ONLY',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (user.userName != null) ...[
                        pw.Text(user.userName!, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                      ],
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide())),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _showEditCustomerDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Customer Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003527),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerPanController,
                decoration: const InputDecoration(
                  labelText: 'PAN Number (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003527),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text('Save Customer Info'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddItemBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Medicine to Bill',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003527),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search medicine name or generic...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF003527)),
                      filled: true,
                      fillColor: const Color(0xFFF4F9F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (q) {
                      _searchMedicines(q);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Type medicine name to search stock...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _searchResults.length,
                            separatorBuilder: (c, i) => const Divider(),
                            itemBuilder: (context, index) {
                              final med = _searchResults[index];
                              return ListTile(
                                title: Text(
                                  med.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Stock: ${med.currentStock} | Price: Rs.${med.sellingPrice}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF62FAE3),
                                    foregroundColor: const Color(0xFF003527),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _addToCart(med);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDiscountDialog() {
    final controller = TextEditingController(text: _discountController.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Apply Global Discount'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Discount Amount (Rs)',
              border: OutlineInputBorder(),
              prefixText: 'Rs. ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003527),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _discountController.text = controller.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF003527), size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'New Sale Entry',
          style: TextStyle(
            color: Color(0xFF003527),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- 1. Customer Details Card ---
            _buildCustomerCard(),

            const SizedBox(height: 16),

            // --- 2. Current Bill Items Card ---
            _buildCurrentBillCard(),

            const SizedBox(height: 20),

            // --- 3. Payment Mode & Summary Card ---
            _buildPaymentSummaryCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Card 1: Customer Details
  Widget _buildCustomerCard() {
    final customerName = _customerNameController.text.trim().isEmpty
        ? 'Walk-in Customer'
        : _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim().isEmpty
        ? 'No phone provided'
        : _customerPhoneController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          top: BorderSide(color: Color(0xFF62FAE3), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.person_outline, size: 20, color: Color(0xFF003527)),
                  SizedBox(width: 8),
                  Text(
                    'CUSTOMER DETAILS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF003527),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showEditCustomerDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF3FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.edit, size: 14, color: Color(0xFF003527)),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003527),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1C30),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      customerPhone,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Current Bill Items
  Widget _buildCurrentBillCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFEEF2FF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 20, color: Color(0xFF003527)),
                    const SizedBox(width: 8),
                    Text(
                      'CURRENT BILL (${_cartItems.length} ITEMS)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Color(0xFF003527),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA7F3D0),
                    foregroundColor: const Color(0xFF00201D),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _showAddItemBottomSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add Item',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          if (_cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No items added yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap "+ Add Item" above to search & add medicines',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cartItems.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Item Details Left
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.medicineName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B1C30),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Batch: ${item.batchNumber ?? "N/A"} • Generic',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rs. ${item.price.toStringAsFixed(2)} / unit',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),

                      // Stepper & Item Total Right
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF3FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove, size: 16, color: Color(0xFF003527)),
                                  onPressed: () => _updateItemQuantity(index, -1),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003527),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _updateItemQuantity(index, 1),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF003527),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rs. ${item.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0B1C30),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Card 3: Payment Mode & Final Summary Card (Dark Navy Hero Card)
  Widget _buildPaymentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Navy
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label
          const Text(
            'PAYMENT MODE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 10),

          // Payment Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _paymentMode = 'Cash';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMode == 'Cash'
                            ? const Color(0xFF62FAE3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 18,
                            color: _paymentMode == 'Cash'
                                ? const Color(0xFF00201D)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cash',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _paymentMode == 'Cash'
                                  ? const Color(0xFF00201D)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _paymentMode = 'Fonepay';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _paymentMode == 'Fonepay'
                            ? const Color(0xFF62FAE3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 18,
                            color: _paymentMode == 'Fonepay'
                                ? const Color(0xFF00201D)
                                : Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fonepay',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _paymentMode == 'Fonepay'
                                  ? const Color(0xFF00201D)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),

          // Subtotal Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(fontSize: 15, color: Colors.white70),
              ),
              Text(
                'Rs. ${_subTotalAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Discount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Discount',
                    style: TextStyle(fontSize: 15, color: Colors.white70),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _showDiscountDialog,
                    child: const Icon(Icons.edit_note, size: 18, color: Color(0xFF62FAE3)),
                  ),
                ],
              ),
              Text(
                '- Rs. ${_discountAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grand Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Rs. ${_grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF62FAE3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Process Sale & Print Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF62FAE3),
                foregroundColor: const Color(0xFF00201D),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _processSale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.print_outlined, size: 22, color: Color(0xFF00201D)),
                  SizedBox(width: 8),
                  Text(
                    'Process Sale & Print',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00201D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
