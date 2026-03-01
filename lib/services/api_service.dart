import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine_model.dart';
import '../models/bill_model.dart';
import '../models/return_model.dart';
import '../models/pharmacy_profile_model.dart';
import '../models/sale_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator/Web/Desktop
  // static const String baseUrl = 'http://localhost:5000/api';
  
  // Use local backend for development (Replace localhost with your IP if testing on real phone)
  // static const String baseUrl = 'http://localhost:5000/api'; 
  
  // Use the live server URL from Render (Uncomment when deploying)
  static const String baseUrl =
     'https://pharmacy-project-wkdo.onrender.com/api';

  static final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null) {
            options.headers['Authorization'] =
                'Bearer $token'; // Adjust based on your API
          }
          return handler.next(options);
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
      throw e;
    }
  }

  static Future<Medicine?> updateMedicine(String id, Medicine medicine) async {
    try {
      final response = await _dio.put(
        '/medicines/$id',
        data: medicine.toJson(),
      );
      return Medicine.fromJson(response.data);
    } catch (e) {
      print('Error updating medicine: $e');
      throw e;
    }
  }

  static Future<void> deleteMedicine(String id) async {
    try {
      await _dio.delete('/medicines/$id');
    } catch (e) {
      print('Error deleting medicine: $e');
      throw e;
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
      throw e;
    }
  }

  static Future<void> deleteBill(String id) async {
    try {
      await _dio.delete('/bills/$id');
    } catch (e) {
      print('Error deleting bill: $e');
      throw e;
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
      throw e; // Rethrow to let UI handle error state
    }
  }

  static Future<ReturnItem?> addReturn(ReturnItem returnItem) async {
    try {
      final response = await _dio.post('/returns', data: returnItem.toJson());
      return ReturnItem.fromJson(response.data);
    } catch (e) {
      print('Error adding return: $e');
      throw e;
    }
  }

  static Future<void> deleteReturn(String id) async {
    try {
      await _dio.delete('/returns/$id');
    } catch (e) {
      print('Error deleting return: $e');
      throw e;
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
      throw e;
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
      throw e;
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
      throw e;
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
      throw e;
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
      throw e;
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
      throw e;
    }
  }

  // Admin Operations
  static Future<List<dynamic>> getAllUsers() async {
    try {
      final response = await _dio.get('/admin/users');
      return response.data;
    } catch (e) {
      print('Error fetching users: $e');
      throw e;
    }
  }

  static Future<void> deleteUser(String id) async {
    try {
      await _dio.delete('/admin/users/$id');
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }
}
