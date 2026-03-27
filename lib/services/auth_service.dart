import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.69.85.192:5112';

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
        print('LOGIN RESPONSE: $data');
        if (data['status'] == 200) {
          currentUser = data['data'];
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
      final body = {
        'fullName': fullname,
        'email': email,
        'password': password,
        'address': address,
        'contactNo': contactno,
      };

      print('REGISTER URL: $baseUrl/Register/UserRegister');
      print('REGISTER BODY: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse('$baseUrl/Register/UserRegister'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER RESPONSE: ${response.body}');

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
}
