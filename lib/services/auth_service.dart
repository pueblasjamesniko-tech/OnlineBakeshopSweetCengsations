import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.26.228.192:5112';

  // ✅ Stores the logged-in user's data globally
  static Map<String, dynamic>? currentUser;

  // ── Login ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Login/UserLogin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('LOGIN RESPONSE: $data'); // temporary - remove later
        if (data['status'] == 200) {
          currentUser = data['data']; // ✅ Save user data after login
          return {'success': true, 'data': data};
        }
        throw Exception('wrong password/login');
      }
      throw Exception('wrong password/login');
    } catch (e) {
      throw Exception(e);
    }
  }

  // ── Register ──────────────────────────────────────────────
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
          'contactno': contactno,
          'address': address,
        }),
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
      return {
        'success': false,
        'message': 'Cannot connect to server. Please try again.',
      };
    }
  }
}
