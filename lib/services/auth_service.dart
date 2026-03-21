import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.26.228.192:5112';

  // ── Login ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        // Uri.parse('$baseUrl/login'),
        Uri.parse('$baseUrl/Login/UserLogin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          return {'success': true, 'data': data};
        }
        throw Exception('wrong password/login');
      }
      throw Exception('wrong password/login');
      // else {
      //   final error = jsonDecode(response.body);
      //   return {
      //     'success': false,
      //     'message': error['message'] ?? 'Login failed. Please try again.',
      //   };
      // }
    } catch (e) {
      throw Exception(e);
    }
  }

  // ── Register ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String contactno,
    required String address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': contactno,
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
      // Demo mode
      return {'success': true};
    }
  }
}
