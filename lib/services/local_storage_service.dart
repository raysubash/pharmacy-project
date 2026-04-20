import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine_model.dart';
import '../models/sale_model.dart';
import '../models/bill_model.dart';
import '../models/return_model.dart';
import '../models/pharmacy_profile_model.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static const String configBoxName = 'app_config';
  static const String medicineBoxName = 'medicines';
  static const String saleBoxName = 'sales';
  static const String billBoxName = 'bills';
  static const String returnBoxName = 'returns';
  static const String profileBoxName = 'profile';
  static const String _activeUserKeyField = 'active_user_key';
  static const String _fallbackUserKey = 'guest_user';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(PharmacyProfileAdapter());
    Hive.registerAdapter(SubscriptionInfoAdapter());
    Hive.registerAdapter(MedicineAdapter());
    Hive.registerAdapter(MeasureUnitAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(SaleItemAdapter());
    Hive.registerAdapter(PurchaseBillAdapter());
    Hive.registerAdapter(BillItemAdapter());
    Hive.registerAdapter(ReturnItemAdapter());

    // Open Boxes
    await Hive.openBox(configBoxName);
    await Hive.openBox<Medicine>(medicineBoxName);
    await Hive.openBox<Sale>(saleBoxName);
    await Hive.openBox<PurchaseBill>(billBoxName);
    await Hive.openBox<ReturnItem>(returnBoxName);
    await Hive.openBox<PharmacyProfile>(profileBoxName);
  }

  static Future<void> setActiveUserKey(String? userKey) async {
    final box = Hive.box(configBoxName);
    final sanitized = userKey?.trim();
    if (sanitized == null || sanitized.isEmpty) {
      await box.delete(_activeUserKeyField);
    } else {
      await box.put(_activeUserKeyField, sanitized);
    }
  }

  static String _currentUserKey() {
    final box = Hive.box(configBoxName);
    final userKey = box.get(_activeUserKeyField);
    if (userKey is String && userKey.trim().isNotEmpty) {
      return userKey;
    }
    return _fallbackUserKey;
  }

  static String _userScopedKey(String id) {
    return '${_currentUserKey()}::$id';
  }

  static bool _belongsToCurrentUser(dynamic key) {
    return key is String && key.startsWith('${_currentUserKey()}::');
  }

  // --- Medicine Operations ---
  static List<Medicine> getAllMedicines() {
    final box = Hive.box<Medicine>(medicineBoxName);
    return box
        .toMap()
        .entries
        .where((entry) => _belongsToCurrentUser(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  static Future<void> addMedicine(Medicine medicine) async {
    final box = Hive.box<Medicine>(medicineBoxName);
    // Ensure ID is set
    String id = medicine.id.isEmpty ? const Uuid().v4() : medicine.id;
    final newMedicine = Medicine(
      id: id,
      name: medicine.name,
      genericName: medicine.genericName,
      category: medicine.category,
      unit: medicine.unit,
      minStock: medicine.minStock,
      sellingPrice: medicine.sellingPrice,
      storageLocation: medicine.storageLocation,
      currentStock: medicine.currentStock,
      brandName: medicine.brandName,
      packaging: medicine.packaging,
      mrp: medicine.mrp,
      imagePath: medicine.imagePath,
      batchNumber: medicine.batchNumber,
      expiryDate: medicine.expiryDate,
      createdDate: medicine.createdDate,
    );
    // Hive uses dynamic keys, but we can use the ID as key for easier lookup
    await box.put(_userScopedKey(id), newMedicine);
  }

  static Future<void> updateMedicine(String id, Medicine medicine) async {
    final box = Hive.box<Medicine>(medicineBoxName);
    await box.put(_userScopedKey(id), medicine);
  }

  static Future<void> deleteMedicine(String id) async {
    final box = Hive.box<Medicine>(medicineBoxName);
    await box.delete(_userScopedKey(id));
  }

  // --- Sale Operations ---
  static List<Sale> getAllSales() {
    final box = Hive.box<Sale>(saleBoxName);
    return box
        .toMap()
        .entries
        .where((entry) => _belongsToCurrentUser(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  static Future<void> addSale(Sale sale) async {
    final box = Hive.box<Sale>(saleBoxName);
    String id =
        (sale.id == null || sale.id!.isEmpty) ? const Uuid().v4() : sale.id!;
    // Create new sale object with the ID if it was missing
    final newSale = Sale(
      id: id,
      invoiceNumber: sale.invoiceNumber,
      customerName: sale.customerName,
      customerPhone: sale.customerPhone,
      customerAddress: sale.customerAddress,
      customerPan: sale.customerPan,
      payMode: sale.payMode,
      items: sale.items,
      subTotal: sale.subTotal,
      discount: sale.discount,
      tax: sale.tax,
      grandTotal: sale.grandTotal,
      date: sale.date,
    );
    await box.put(_userScopedKey(id), newSale);

    // Decrease stock for sold medicines
    final medicineBox = Hive.box<Medicine>(medicineBoxName);
    for (var item in sale.items) {
      final medicine = medicineBox.get(_userScopedKey(item.medicineId));
      if (medicine != null) {
        medicine.currentStock -= item.quantity;
        await medicineBox.put(_userScopedKey(medicine.id), medicine);
      }
    }
  }

  // --- Bill Operations ---
  static List<PurchaseBill> getAllBills() {
    final box = Hive.box<PurchaseBill>(billBoxName);
    return box
        .toMap()
        .entries
        .where((entry) => _belongsToCurrentUser(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  static Future<void> addBill(PurchaseBill bill) async {
    final box = Hive.box<PurchaseBill>(billBoxName);
    String id = bill.id.isEmpty ? const Uuid().v4() : bill.id;
    final newBill = PurchaseBill(
      id: id,
      billNumber: bill.billNumber,
      supplierName: bill.supplierName,
      billDate: bill.billDate,
      items: bill.items,
      totalAmount: bill.totalAmount,
      entryDate: bill.entryDate,
    );
    await box.put(_userScopedKey(id), newBill);

    // Increase stock for purchased medicines
    final medicineBox = Hive.box<Medicine>(medicineBoxName);
    for (var item in bill.items) {
      // Find medicine by ID or maybe Name/Batch? Usually ID if selecting from existing list.
      // Assuming item.medicineId is valid.
      final medicine = medicineBox.get(_userScopedKey(item.medicineId));
      if (medicine != null) {
        medicine.currentStock += item.quantity;
        await medicineBox.put(_userScopedKey(medicine.id), medicine);
      }
    }
  }

  static Future<void> deleteBill(String id) async {
    final box = Hive.box<PurchaseBill>(billBoxName);
    await box.delete(_userScopedKey(id));
  }

  // --- Return Operations ---
  static List<ReturnItem> getAllReturns() {
    final box = Hive.box<ReturnItem>(returnBoxName);
    return box
        .toMap()
        .entries
        .where((entry) => _belongsToCurrentUser(entry.key))
        .map((entry) => entry.value)
        .toList();
  }

  static Future<void> addReturn(ReturnItem returnItem) async {
    final box = Hive.box<ReturnItem>(returnBoxName);
    String id = returnItem.id.isEmpty ? const Uuid().v4() : returnItem.id;
    final newReturn = ReturnItem(
      id: id,
      medicineName: returnItem.medicineName,
      batchNumber: returnItem.batchNumber,
      quantity: returnItem.quantity,
      reason: returnItem.reason,
      returnDate: returnItem.returnDate,
      refundAmount: returnItem.refundAmount,
      status: returnItem.status,
      originalBillNo: returnItem.originalBillNo,
      expiryDate: returnItem.expiryDate,
      supplierName: returnItem.supplierName,
    );
    await box.put(_userScopedKey(id), newReturn);
  }

  static Future<void> updateReturn(String id, ReturnItem item) async {
    final box = Hive.box<ReturnItem>(returnBoxName);
    // Ensure the ID matches
    if (item.id != id) {
      // Ideally we should update the item's ID or ensure it's correct.
      // For now, let's assume item has the correct ID or we're overwriting at 'id'
    }
    await box.put(_userScopedKey(id), item);
  }

  static Future<void> deleteReturn(String id) async {
    final box = Hive.box<ReturnItem>(returnBoxName);
    await box.delete(_userScopedKey(id));
  }

  static Future<void> updateReturnStatus(String id, String status) async {
    final box = Hive.box<ReturnItem>(returnBoxName);
    final item = box.get(_userScopedKey(id));
    if (item != null) {
      item.status = status;
      await box.put(_userScopedKey(id), item);
      // Note: Ideally we should create a copy instead of mutating.
      // But since we are saving it back, it might be okay depending on Hive's behavior.
      // Safer approach:
      /*
        final updated = ReturnItem(
            id: item.id,
            medicineName: item.medicineName,
            ...
            status: status
        );
        box.put(id, updated);
        */
      // However, since ReturnItem fields are final except status (which I should check),
      // let me check ReturnItem definition again. status is not final. Good.
    }
  }

  // --- Profile Operations ---
  static PharmacyProfile? getProfile() {
    final box = Hive.box<PharmacyProfile>(profileBoxName);
    return box.get(_userScopedKey('profile'));
  }

  static Future<void> saveProfile(PharmacyProfile profile) async {
    final box = Hive.box<PharmacyProfile>(profileBoxName);
    await box.put(_userScopedKey('profile'), profile);
  }
}
