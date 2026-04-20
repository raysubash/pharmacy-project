import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:number_to_words_english/number_to_words_english.dart';
import '../../models/medicine_model.dart';
import '../../models/sale_model.dart';
//import '../../models/pharmacy_profile_model.dart';
import '../../providers/medicine_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class CustomerBillScreen extends ConsumerStatefulWidget {
  const CustomerBillScreen({super.key});

  @override
  ConsumerState<CustomerBillScreen> createState() => _CustomerBillScreenState();
}

class _CustomerBillScreenState extends ConsumerState<CustomerBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _customerPanController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _discountController = TextEditingController(
    text: '0',
  ); // Global Discount Amount

  String _paymentMode = 'Cash'; // Default

  // Search
  final _searchController = TextEditingController();
  List<Medicine> _searchResults = [];

  // Cart
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
      _searchResults =
          allMedicines.where((med) {
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
    ); // Allow editing MRP

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${medicine.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Stock: ${medicine.currentStock}'),
              const SizedBox(height: 10),
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
                controller: mrpController, // Allow edit MRP
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Rate / MRP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
              onPressed: () {
                final qty = int.tryParse(quantityController.text);
                final disc = double.tryParse(discountController.text) ?? 0.0;
                final newPrice = double.tryParse(
                  mrpController.text,
                ); // User edited price

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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    // Clear search and refocus for next entry
    _searchController.clear();
    setState(() => _searchResults = []);
    _searchFocusNode.requestFocus();
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

    // Calculate total: (Price * Qty) - Discount
    final grossTotal = qty * finalPrice;
    final discountAmount = grossTotal * (discountPercent / 100);
    final netTotal = grossTotal - discountAmount;

    if (existingIndex != -1) {
      // Check if new total quantity exceeds stock
      final currentQty = _cartItems[existingIndex].quantity;
      final newQty = currentQty + qty;

      if (newQty > medicine.currentStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Total quantity exceeds stock')),
        );
        return;
      }

      setState(() {
        // Update existing item.
        // Note: We overwrite price/discount with the NEW values for simplicity.
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

//  void _updateQuantity(int index, int newQty) {
//    if (newQty <= 0) {
//      _removeFromCart(index);
//      return;
//    }
//
//    final item = _cartItems[index];
//    final allMedicines = ref.read(medicineProvider).value ?? [];
//
//    Medicine? medicine;
//    try {
//      medicine = allMedicines.firstWhere((m) => m.id == item.medicineId);
//    } catch (_) {}
//
//    if (medicine != null && newQty > medicine.currentStock) {
//      ScaffoldMessenger.of(
//        context,
//      ).showSnackBar(const SnackBar(content: Text('Not enough stock')));
//      return;
//    }
//
//    setState(() {
//      _cartItems[index] = SaleItem(
//        medicineId: item.medicineId,
//        medicineName: item.medicineName,
//        quantity: newQty,
//        price: item.price,
//        discount: item.discount, // Use existing item discount
//        total: (newQty * item.price) * (1 - (item.discount / 100)),
//        batchNumber: item.batchNumber,
//        expiryDate: item.expiryDate,
//        mrp: item.mrp,
//      );
//    });
//  }

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
    if (!_formKey.currentState!.validate()) return;
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    final sale = Sale(
      invoiceNumber: _invoiceNumberController.text,
      customerName: _customerNameController.text,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _printPdf(Sale sale) async {
    final pdf = pw.Document();
    // Ensure we have the latest profile data
    final profile = await ref.read(profileProvider.future);
    final user = ref.read(authProvider);
    final dateFormat = DateFormat('yyyy/MM/dd');
    final timeFormat = DateFormat('hh:mm:ss a');

    // Font setup can be added here if needed for Nepali support later

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              // Centered Pharmacy Name
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

              // Invoice Details Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Side: Customer Info
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
                  // Right Side: Invoice Info
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

              // --- Items Table Header ---
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'S.N.',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      'ITEM DESCRIPTION',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'BATCH',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'EXP.DATE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'MRP',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'DIS %',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      'QTY',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'RATE',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      'AMOUNT',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // --- Items Rows ---
              ...sale.items.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '$index',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 4,
                        child: pw.Text(
                          item.medicineName,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.batchNumber ?? '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.expiryDate != null
                              ? DateFormat('yyyy/MM').format(item.expiryDate!)
                              : '',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.mrp?.toStringAsFixed(2) ?? '',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          item.discount.toStringAsFixed(1),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(
                          '${item.quantity}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.price.toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.total.toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // --- Totals ---
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
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
                            pw.Text(
                              'NET TOTAL:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              sale.grandTotal.toStringAsFixed(2),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
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

              // --- Footer ---
              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (user.userName != null) ...[
                        pw.Text(
                          user.userName!,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      pw.Container(
                        width: 150,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide()),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Authorized Signature',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Bill'),
        backgroundColor: AppTheme.primaryGreen,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Customer Details Card
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerAddressController,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _customerPanController,
                              decoration: const InputDecoration(
                                labelText: 'PAN (Optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMode,
                              decoration: const InputDecoration(
                                labelText: 'Payment Mode',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  ['Cash', 'Credit', 'Fonepay']
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _paymentMode = v!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Global Discount (Rs)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged:
                                  (val) => setState(
                                    () {},
                                  ), // rebuild to show total change
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Section with "Add Another" flow implicitly supported
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                labelText: 'Search Medicine (Type to search & add)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                helperText:
                    'Tap + to add item. Search clears automatically for next item.',
              ),
              onChanged: _searchMedicines,
            ),
            if (_searchResults.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Card(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final med = _searchResults[index];
                      return ListTile(
                        title: Text(med.name),
                        subtitle: Text(
                          'Stock: ${med.currentStock} | Price: Rs.${med.sellingPrice}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppTheme.primaryGreen,
                          ),
                          onPressed: () => _addToCart(med),
                        ),
                      );
                    },
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Cart Items List (Full Width)
            Expanded(
              child: Card(
                elevation: 2,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppTheme.primaryGreen,
                      width: double.infinity,
                      child: const Text(
                        'Bill Items',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _cartItems.isEmpty
                              ? const Center(child: Text('No items added'))
                              : ListView.separated(
                                itemCount: _cartItems.length,
                                separatorBuilder: (c, i) => const Divider(),
                                itemBuilder: (context, index) {
                                  final item = _cartItems[index];
                                  return ListTile(
                                    title: Text(
                                      item.medicineName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Batch: ${item.batchNumber ?? "N/A"} | Price: ${item.price} | Disc: ${item.discount}%',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${item.quantity} x ${item.price} = ',
                                        ),
                                        Text(
                                          'Rs.${item.total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _removeFromCart(index),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Optional: Edit on tap?
                                      // For now, removing is safer or just implement full edit dialog
                                    },
                                  );
                                },
                              ),
                    ),
                    // Totals Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Sub Total:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Rs.${_subTotalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Global Discount:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(
                                '- Rs.${_discountAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs.${_grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: _processSale,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 10),
                    Text('GENERATE & PRINT BILL'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
