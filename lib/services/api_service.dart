import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/user_session.dart';
import '../models/UserModel.dart';
import '../models/cart_item.dart';
import 'package:flutter/foundation.dart';

// This file handles ALL communication between the app and the server
// The address of our server — all requests go here
class ApiService {
  static const String baseUrl = 'http://172.23.201.192:5112';

  // Every request tells the server we're sending JSON data
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  //
  // AUTH
  //
  // Sends the user's email and password to the server to log in
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
          final String token = data['token'] ?? '';
          final String refreshToken = data['refreshToken'] ?? ''; // ✅ get it

          // Save the login tokens so the app remembers the user is logged in
          UserSession.instance.setToken(token);
          UserSession.instance.setRefreshToken(refreshToken); // ✅ save it

          final userId =
              int.tryParse(userData['userId']?.toString() ?? '') ?? 0;
          String? profilePicture = userData['profilePicture'];
          // If no profile picture came with login, go fetch it separately
          if (userId > 0 &&
              (profilePicture == null || profilePicture.isEmpty)) {
            try {
              final profileResponse = await http.get(
                Uri.parse('$baseUrl/User/GetUserById?userId=$userId'),
                headers: _headers,
              );
              if (profileResponse.statusCode == 200) {
                final profileData = jsonDecode(profileResponse.body);
                if (profileData['status'] == 200 &&
                    profileData['data'] != null) {
                  profilePicture = profileData['data']['profilePicture'];
                }
              }
            } catch (_) {}
          }
          // Build the user object and save it to the session
          final user = UserModel(
            id: userData['userId']?.toString() ?? '',
            name: userData['fullName'] ?? userData['name'] ?? 'User',
            email: userData['email'] ?? '',
            phone: userData['contactNo'] ?? userData['contactno'],
            profilePicture: profilePicture,
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
      // If something went wrong connecting to the server
      return {
        'success': false,
        'message': 'Cannot connect to server. Please try again.',
      };
    }
  }

  // Registers the user's phone/device so they can receive push notifications
  static Future<void> registerDevice({
    required String fcmToken,
    required String platform,
  }) async {
    try {
      final token = UserSession.instance.token;
      if (token.isEmpty) {
        debugPrint('❌ No token found, skipping FCM registration');
        return;
      }

      // ✅ FIXED: correct route matching your DevicesController
      final response = await http.post(
        Uri.parse('$baseUrl/api/devices/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // prove the user is logged in
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'platform': platform,
          'deviceName': 'Flutter App',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ FCM device registered successfully');
      } else {
        debugPrint(
            '❌ FCM register failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }

  // Uploads a new profile picture for the user
  static Future<Map<String, dynamic>> updateProfilePicture({
    required int userId,
    required XFile imageFile,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/User/UpdateProfilePicture');
      // MultipartRequest is used when sending a file (not just text)
      final request = http.MultipartRequest('POST', uri);
      request.fields['userId'] = userId.toString();
      final Uint8List bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: imageFile.name,
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          return {'success': true, 'imageUrl': data['imageUrl'] ?? ''};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Upload failed'
        };
      }
      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}'
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Creates a new account by sending the user's info to the server
  static Future<Map<String, dynamic>> registerUser({
    required String fullname,
    required String email,
    required String password,
    required String contactno,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Register/UserRegister'),
        headers: _headers,
        body: jsonEncode({
          'fullName': fullname,
          'email': email,
          'password': password,
          'address': address,
          'contactNo': contactno,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Registration failed.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot connect to server. Please try again.',
      };
    }
  }

  static void logout() => UserSession.instance.clearUser();

  //
  // CART
  //
  // Fetches all items currently in the user's cart from the server
  static Future<List<CartItem>> loadCart(String userId) async {
    try {
      final uid = int.tryParse(userId) ?? 0;
      if (uid == 0) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/Cart/GetCartByUser?userId=$uid'),
        headers: _headers,
      );

      if (response.statusCode != 200) return [];
      final body = jsonDecode(response.body);
      if (body['status'] != 200 || body['data'] == null) return [];

      final List<dynamic> data = body['data'];
      return data.map((row) {
        final product = ProductModel(
          productId: row['productId'] as int? ?? 0,
          productName: row['productName']?.toString() ?? '',
          description: row['description']?.toString() ?? '',
          price: (row['price'] as num?)?.toDouble() ?? 0.0,
          imageUrl: row['imageUrl']?.toString(),
          isAvailable: true,
        );
        final item = CartItem.regular(
          product: product,
          quantity: row['quantity'] as int? ?? 1,
          deliveryDate: row['deliveryDate']?.toString() ?? '',
          deliveryTime: row['deliveryTime']?.toString() ?? '',
          deliveryAddress: row['deliveryAddress']?.toString() ?? '',
          specialNotes: row['specialNotes']?.toString(),
          paymentMethod: row['paymentMethod']?.toString() ?? 'COD',
          fulfillmentType: row['fulfillmentType']?.toString() ?? 'Delivery',
          meetupPlace: row['meetupPlace']?.toString(),
        );
        item.cartId = row['cartId'] as int?;
        return item;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Adds or updates a single item in the cart on the server
  static Future<void> saveCartItem(String userId, CartItem item) async {
    try {
      final uid = int.tryParse(userId) ?? 0;
      if (uid == 0 || item.product == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/Cart/UpsertCartItem'),
        headers: _headers,
        body: jsonEncode({
          'userId': uid,
          'productId': item.product!.productId,
          'quantity': item.quantity,
          'deliveryDate': item.deliveryDate ?? '',
          'deliveryTime': item.deliveryTime ?? '',
          'deliveryAddress': item.deliveryAddress ?? '',
          'specialNotes': item.specialNotes ?? '',
          'paymentMethod': item.paymentMethod ?? 'COD',
          'fulfillmentType': item.fulfillmentType ?? 'Delivery',
          'meetupPlace': item.meetupPlace ?? '',
        }),
      );

      // Save the cartId the server gives back so we can update/delete it later
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final cartId = body['data']?['cartId'];
        if (cartId != null && cartId != 0) {
          item.cartId = cartId as int;
        }
      }
    } catch (_) {}
  }

  // Changes the quantity of an item already in the cart
  static Future<void> updateCartItemQty(String userId, CartItem item) async {
    try {
      final uid = int.tryParse(userId) ?? 0;
      if (uid == 0 || item.cartId == null) return;

      await http.put(
        Uri.parse(
            '$baseUrl/Cart/UpdateCartItemQty?cartId=${item.cartId}&userId=$uid&quantity=${item.quantity}'),
        headers: _headers,
      );
    } catch (_) {}
  }

  // Removes one specific item from the cart
  static Future<void> removeCartItem(String userId, CartItem item) async {
    try {
      final uid = int.tryParse(userId) ?? 0;
      if (uid == 0 || item.cartId == null) return;

      await http.delete(
        Uri.parse(
            '$baseUrl/Cart/RemoveCartItem?cartId=${item.cartId}&userId=$uid'),
        headers: _headers,
      );
    } catch (_) {}
  }

  // Deletes every item in the cart at once (used after placing an order)
  static Future<void> clearCart(String userId) async {
    try {
      final uid = int.tryParse(userId) ?? 0;
      if (uid == 0) return;

      await http.delete(
        Uri.parse('$baseUrl/Cart/ClearCart?userId=$uid'),
        headers: _headers,
      );
    } catch (_) {}
  }

  //
  // PRODUCTS
  //
  // Gets all products that are currently available in the bakeshop
  static Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Product/GetAvailableProducts'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          final List<dynamic> list = body['data'];
          return list.map((e) => ProductModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  //
  // REGULAR ORDERS
  //
  // Places a regular order for a product (like buying a cake from the menu)
  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required int productId,
    required int quantity,
    required double totalPrice,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    String? specialNotes,
    required String paymentMethod,
    required String fulfillmentType,
    String? meetupPlace,
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
        'paymentMethod': paymentMethod,
        'fulfillmentType': fulfillmentType,
        'meetupPlace': meetupPlace ?? '',
      };
      final response = await http.post(
        Uri.parse('$baseUrl/Orders/CreateOrder'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          return {
            'success': true,
            'orderId': data['data']?['orderId'] ?? 0,
          };
        }
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
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  // Uploads a photo of the payment receipt for a regular order
  static Future<Map<String, dynamic>> uploadOrderReceipt({
    required int orderId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/Orders/UploadReceipt');
      final request = http.MultipartRequest('POST', uri);
      request.fields['orderId'] = orderId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          return {'success': true, 'imageUrl': data['imageUrl'] ?? ''};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Upload failed'
        };
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Gets all past and current orders belonging to a specific user
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
    } catch (_) {
      return [];
    }
  }

  // Cancels an order that the user no longer wants
  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Orders/CancelOrder?orderId=$orderId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) return {'success': true};
        return {'success': false, 'message': data['message'] ?? 'Failed'};
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  //
  // CUSTOM ORDERS
  //
  // Submits a custom cake order (user picks flavor, size, design, etc.)
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
        'orderStatus': 'Awaiting Approval',
        'dateOrdered': DateTime.now().toUtc().toIso8601String(),
        'quotedPrice': 0,
        'fullName': user?.name ?? '',
        'email': user?.email ?? '',
        'contactNo': user?.phone ?? '',
      };
      final response = await http.post(
        Uri.parse('$baseUrl/CustomOrder/CreateCustomOrder'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200 || data['status'] == 201) {
          return {
            'success': true,
            'customOrderId': data['data']?['customOrderId'] ?? 0,
          };
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
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // Officially places a custom order after the admin has approved and quoted a price
  static Future<Map<String, dynamic>> placeCustomOrder({
    required int customOrderId,
    required String paymentMethod,
    required String deliveryDate,
    required String deliveryTime,
    required String deliveryAddress,
    required String fulfillmentType,
    String? meetupPlace,
  }) async {
    try {
      final params = {
        'customOrderId': customOrderId.toString(),
        'paymentMethod': paymentMethod,
        'deliveryDate': deliveryDate,
        'deliveryTime': deliveryTime,
        'deliveryAddress': deliveryAddress,
        'fulfillmentType': fulfillmentType,
        if (meetupPlace != null && meetupPlace.isNotEmpty)
          'meetupPlace': meetupPlace,
      };
      final uri = Uri.parse('$baseUrl/CustomOrder/PlaceCustomOrder')
          .replace(queryParameters: params);
      final response = await http.put(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) return {'success': true};
        return {'success': false, 'message': data['message'] ?? 'Failed'};
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  // Uploads a payment receipt photo for a custom order
  static Future<Map<String, dynamic>> uploadCustomOrderReceipt({
    required int customOrderId,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/CustomOrder/UploadReceipt');
      final request = http.MultipartRequest('POST', uri);
      request.fields['customOrderId'] = customOrderId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType('image', 'jpeg'),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          return {'success': true, 'imageUrl': data['imageUrl'] ?? ''};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Upload failed'
        };
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Gets all custom cake orders made by a specific user
  static Future<List<Map<String, dynamic>>> getCustomOrdersByUser(
      int userId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/CustomOrder/GetCustomOrdersByUserId?userId=$userId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelCustomOrder(
      int customOrderId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/CustomOrder/CancelCustomOrder?customOrderId=$customOrderId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) return {'success': true};
        return {'success': false, 'message': data['message'] ?? 'Failed'};
      }
      return {'success': false, 'message': 'Server error'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

//
// NOTIFICATIONS
//
// Gets all notifications for the user (like order updates, promos, etc.)
  static Future<List<Map<String, dynamic>>> getNotificationsByUser(
      int userId) async {
    try {
      final token = UserSession.instance.token;
      if (token.isEmpty) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/me?page=1&pageSize=50'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 200 && body['data'] != null) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // Marks one notification as read (so it stops showing as new)
  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final token = UserSession.instance.token;
      if (token.isEmpty) return;

      await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  // Marks ALL notifications as read at once
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final token = UserSession.instance.token;
      if (token.isEmpty) return;

      await http.patch(
        Uri.parse('$baseUrl/api/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }

  // Permanently deletes a notification so it disappears from the list
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final token = UserSession.instance.token;
      if (token.isEmpty) return;

      await http.delete(
        Uri.parse('$baseUrl/api/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {}
  }
}
