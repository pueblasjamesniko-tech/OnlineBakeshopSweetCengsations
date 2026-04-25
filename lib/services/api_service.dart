import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../models/user_session.dart';
import '../models/UserModel.dart';
import '../models/cart_item.dart';

class ApiService {
  static const String baseUrl =
      'http://10.224.229.192:5112'; // one place to change

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // =============================================
  // AUTH
  // =============================================

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login/UserLogin'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 200 && data['data'] != null) {
          final userData = data['data'];

          final user = UserModel(
            id: userData['userId']?.toString() ?? '',
            name: userData['fullName'] ?? userData['name'] ?? 'User',
            email: userData['email'] ?? '',
            phone: userData['contactNo'] ?? userData['contactno'],
            savedAddresses: userData['address'] != null &&
                    userData['address'].toString().isNotEmpty
                ? [userData['address'].toString()]
                : [],
          );

          UserSession.instance.setUser(user);
          return {'success': true, 'data': data};
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Wrong email or password.',
        };
      }

      return {
        'success': false,
        'message': 'Wrong email or password. Please try again.',
      };
    } catch (e) {
      print('LOGIN ERROR: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullname,
    required String email,
    required String password,
    required String contactno,
    required String address,
  }) async {
    try {
      final body = {
        'fullName': fullname,
        'email': email,
        'password': password,
        'address': address,
        'contactNo': contactno,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/Register/UserRegister'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      print('REGISTER ERROR: $e');
      return {
        'success': false,
        'message': 'Cannot connect to server. Please try again.',
      };
    }
  }

  static void logout() {
    UserSession.instance.clearUser();
  }

  // =============================================
  // CART PERSISTENCE
  // Keys are per-user so carts don't bleed between accounts.
  // =============================================

  static String _cartKey(String userId) => 'cart_$userId';

  /// Save the current cart list to SharedPreferences.
  static Future<void> saveCart(String userId, List<CartItem> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only persist regular (non-custom) items — custom orders are already
      // saved on the server the moment the user submits them.
      final regularItems = cart.where((i) => !i.isCustom).toList();
      final encoded = jsonEncode(regularItems.map((i) => i.toJson()).toList());
      await prefs.setString(_cartKey(userId), encoded);
    } catch (e) {
      print('saveCart error: $e');
    }
  }

  /// Load the persisted cart for this user from SharedPreferences.
  static Future<List<CartItem>> loadCart(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cartKey(userId));
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('loadCart error: $e');
      return [];
    }
  }

  /// Clear the persisted cart for this user (e.g. after placing all orders).
  static Future<void> clearCart(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey(userId));
    } catch (e) {
      print('clearCart error: $e');
    }
  }

  // =============================================
  // PRODUCTS
  // =============================================

  static Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Product/GetAllProducts'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        print('response: $body');
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => ProductModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('GetAllProducts error: $e');
      return [];
    }
  }

  // =============================================
  // REGULAR ORDERS
  // =============================================

  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required int productId,
    required int quantity,
    required double totalPrice,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    String? specialNotes,
  }) async {
    try {
      final body = {
        'userId': userId,
        'productId': productId,
        'quantity': quantity,
        'totalPrice': totalPrice,
        'deliveryDate': deliveryDate,
        'deliveryTime': deliveryTime,
        'deliveryAddress': deliveryAddress,
        'specialNotes': specialNotes ?? '',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/Orders/CreateOrder'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) return {'success': true};
        return {'success': false, 'message': data['message'] ?? 'Order failed'};
      }

      if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Validation failed'
        };
      }

      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      print('CreateOrder error: $e');
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  static Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Orders/GetOrdersByUserId?userId=$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print('GetOrdersByUser error: $e');
      return [];
    }
  }

  // =============================================
  // CUSTOM ORDERS
  // =============================================

  static Future<Map<String, dynamic>> createCustomOrder({
    required int userId,
    required String orderType,
    required String flavor,
    required String size,
    required String colorTheme,
    String? messageOnCake,
    int? numberOfLayers,
    String? specialNotes,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    String? referenceImage,
  }) async {
    try {
      // Get current user info from session
      final user = UserSession.instance.currentUser;

      final body = {
        'customOrderId': 0,
        'userId': userId,
        'orderType': orderType,
        'flavor': flavor,
        'size': size,
        'colorTheme': colorTheme,
        'messageOnCake': messageOnCake ?? '',
        'numberOfLayers': numberOfLayers ?? 1,
        'referenceImage': referenceImage ?? '',
        'specialNotes': specialNotes ?? '',
        'deliveryDate': deliveryDate,
        'deliveryTime': deliveryTime,
        'deliveryAddress': deliveryAddress,
        'paymentStatus': 'Unpaid',
        'orderStatus': 'Awaiting Quote',
        'dateOrdered': DateTime.now().toUtc().toIso8601String(),
        'quotedPrice': 0,
        'fullName': user?.name ?? '',
        'email': user?.email ?? '',
        'contactNo': user?.phone ?? '',
      };

      print('CreateCustomOrder body: ${jsonEncode(body)}'); // debug log

      final response = await http.post(
        Uri.parse('$baseUrl/CustomOrder/CreateCustomOrder'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('CreateCustomOrder status: ${response.statusCode}');
      print('CreateCustomOrder response: ${response.body}'); // debug log

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 || data['status'] == 201) {
          return {'success': true};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to submit custom order'
        };
      }

      if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Validation failed'
        };
      }

      return {
        'success': false,
        'message': 'Server error (${response.statusCode}): ${response.body}'
      };
    } catch (e) {
      print('CreateCustomOrder error: $e');
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> getCustomOrdersByUser(
      int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/CustomOrder/GetAllCustomOrders'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> all = body['data'];
          return List<Map<String, dynamic>>.from(
            all.where((o) => o['userId'] == userId),
          );
        }
      }
      return [];
    } catch (e) {
      print('GetCustomOrders error: $e');
      return [];
    }
  }
}
