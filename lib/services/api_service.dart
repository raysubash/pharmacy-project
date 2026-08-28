// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_model.dart';
import '../models/bill_model.dart';
import '../models/return_model.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/sale_model.dart';
import '../models/stock_transaction_model.dart';

class ApiService {
  // Production Render URL for release APK and network connections
  static const String baseUrl = 'https://pharmacy-project-wkdo.onrender.com/api';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
          options.headers['Cache-Control'] =
              'no-cache, no-store, must-revalidate';
          options.headers['Pragma'] = 'no-cache';
          options.headers['Expires'] = '0';
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Retry on connection timeout, receive timeout, or 503 Service Unavailable (Render waking up)
          final isTimeout = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout;
          final is503 = error.response?.statusCode == 503 ||
              error.response?.statusCode == 504;

          final retryCount = (error.requestOptions.extra['retryCount'] as int?) ?? 0;

          if ((isTimeout || is503) && retryCount < 2) {
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );

  // Medicine Operations
  static Future<List<Medicine>> getAllMedicines() async {
    try {
      final response = await _dio.get('/medicines');
      return (response.data as List)
          .map((json) => Medicine.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching medicines: $e');
      return [];
    }
  }

  static Future<Medicine?> addMedicine(Medicine medicine) async {
    try {
      final response = await _dio.post('/medicines', data: medicine.toJson());
      return Medicine.fromJson(response.data);
    } catch (e) {
      print('Error adding medicine: $e');
      rethrow;
    }
  }

  static Future<Medicine?> updateMedicine(String id, Medicine medicine) async {
    try {
      final response = await _dio.put(
        '/medicines/$id',
        data: medicine.toJsonForUpdate(),
      );
      return Medicine.fromJson(response.data);
    } catch (e) {
      print('Error updating medicine: $e');
      rethrow;
    }
  }

  static Future<void> deleteMedicine(String id) async {
    try {
      await _dio.delete('/medicines/$id');
    } catch (e) {
      print('Error deleting medicine: $e');
      rethrow;
    }
  }

  // Bill Operations
  static Future<List<PurchaseBill>> getAllBills() async {
    try {
      final response = await _dio.get('/bills');
      return (response.data as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching bills: $e');
      return [];
    }
  }

  static Future<PurchaseBill?> addPurchaseBill(PurchaseBill bill) async {
    try {
      final response = await _dio.post('/bills', data: bill.toJson());
      return PurchaseBill.fromJson(response.data);
    } catch (e) {
      print('Error adding bill: $e');
      rethrow;
    }
  }

  static Future<void> deleteBill(String id) async {
    try {
      await _dio.delete('/bills/$id');
    } catch (e) {
      print('Error deleting bill: $e');
      rethrow;
    }
  }

  // Return Operations
  static Future<List<ReturnItem>> getAllReturns() async {
    try {
      final response = await _dio.get('/returns');
      return (response.data as List)
          .map((json) => ReturnItem.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching returns: $e');
      rethrow; // Rethrow to let UI handle error state
    }
  }

  static Future<ReturnItem?> addReturn(ReturnItem returnItem) async {
    try {
      final response = await _dio.post('/returns', data: returnItem.toJson());
      return ReturnItem.fromJson(response.data);
    } catch (e) {
      print('Error adding return: $e');
      rethrow;
    }
  }

  static Future<void> deleteReturn(String id) async {
    try {
      await _dio.delete('/returns/$id');
    } catch (e) {
      print('Error deleting return: $e');
      rethrow;
    }
  }

  // Profile Operations
  static Future<PharmacyProfile?> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      return PharmacyProfile.fromJson(response.data);
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  static Future<PharmacyProfile?> saveProfile(PharmacyProfile profile) async {
    try {
      final response = await _dio.post('/profile', data: profile.toJson());
      return PharmacyProfile.fromJson(response.data);
    } catch (e) {
      print('Error saving profile: $e');
      rethrow;
    }
  }

  // Sale Operations
  static Future<List<Sale>> getAllSales() async {
    try {
      final response = await _dio.get('/sales');
      return (response.data as List)
          .map((json) => Sale.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching sales: $e');
      return [];
    }
  }

  static Future<Sale?> addSale(Sale sale) async {
    try {
      final response = await _dio.post('/sales', data: sale.toJson());
      return Sale.fromJson(response.data);
    } catch (e) {
      print('Error adding sale: $e');
      rethrow;
    }
  }

  static Future<void> deleteAllSales() async {
    try {
      await _dio.delete('/sales');
    } catch (e) {
      print('Error deleting sales: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> initiateKhaltiPayment({
    required String amount,
    required String purchaseOrderId,
    required String purchaseOrderName,
    required Map<String, dynamic> customerInfo,
  }) async {
    try {
      final response = await _dio.post(
        '/subscription/initiate-khalti',
        data: {
          'amount': amount,
          'purchase_order_id': purchaseOrderId,
          'purchase_order_name': purchaseOrderName,
          'customer_info': customerInfo,
          'return_url':
              "https://pharmacy-project-wkdo.onrender.com/api/subscription/khalti-callback", // Override if needed
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        print('Error initiating Khalti payment: ${e.response?.data}');
        throw Exception(
          e.response?.data['message'] ?? 'Failed to initiate payment',
        );
      } else {
        print('Error initiating Khalti payment: $e');
        throw Exception('Failed to connect to server');
      }
    } catch (e) {
      print('Error initiating Khalti payment: $e');
      rethrow;
    }
  }

  static Future<void> updateSubscription(
    String pharmacyId,
    String plan,
    String amount,
    String paymentReference,
  ) async {
    try {
      await _dio.post(
        '/subscription/update',
        data: {
          'pharmacyId': pharmacyId,
          'plan': plan,
          'amount': amount,
          'paymentReference': paymentReference,
        },
      );
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  static Future<void> uploadStatement({
    required String pharmacyId,
    required String plan,
    required String amount,
    required String paymentProofImage,
  }) async {
    try {
      await _dio.post(
        '/subscription/upload-statement',
        data: {
          'pharmacyId': pharmacyId,
          'plan': plan,
          'amount': amount,
          'paymentProofImage': paymentProofImage,
        },
      );
    } catch (e) {
      print('Error uploading statement: $e');
      rethrow;
    }
  }

  static Future<void> reportProblem({
    required String pharmacyId,
    required String description,
  }) async {
    try {
      await _dio.post(
        '/subscription/report-problem',
        data: {'pharmacyId': pharmacyId, 'problemDescription': description},
      );
    } catch (e) {
      print('Error reporting problem: $e');
      rethrow;
    }
  }

  // Admin Operations
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return response.data;
    } catch (e) {
      print('Error fetching users: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/admin/users/$id');
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // ─── Stock Movement Operations ──────────────────────────────────────

  /// Record a stock movement (ADJUSTMENT, DAMAGE, INITIAL, RETURN_IN, RETURN_OUT)
  static Future<Map<String, dynamic>> recordStockMovement({
    required String medicineId,
    required String type,
    required int quantity,
    String? referenceId,
    String reason = '',
    String userId = 'manual',
  }) async {
    try {
      final response = await _dio.post('/stock/movement', data: {
        'medicineId': medicineId,
        'type': type,
        'quantity': quantity,
        'referenceId': referenceId,
        'reason': reason,
        'userId': userId,
      });
      return response.data;
    } catch (e) {
      print('Error recording stock movement: $e');
      rethrow;
    }
  }

  /// Get stock transaction history for a medicine
  static Future<List<StockTransaction>> getStockTransactions(
    String medicineId, {
    int limit = 100,
  }) async {
    try {
      final response = await _dio.get(
        '/stock/transactions/$medicineId',
        queryParameters: {'limit': limit},
      );
      return (response.data as List)
          .map((json) => StockTransaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching stock transactions: $e');
      return [];
    }
  }

  /// Reconcile stock for a single medicine
  static Future<Map<String, dynamic>> reconcileStock(
    String medicineId,
  ) async {
    try {
      final response = await _dio.get('/stock/reconcile/$medicineId');
      return response.data;
    } catch (e) {
      print('Error reconciling stock: $e');
      rethrow;
    }
  }
}
