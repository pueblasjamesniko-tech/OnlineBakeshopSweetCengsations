import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/UserModel.dart';

class AuthStorage {
  static const String _userKey = 'auth_user';
  static const String _tokenKey = 'auth_token';

  /// Save both user and token in one call.
  static Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, user.token ?? '');
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<UserModel?> readUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(decoded);
    } catch (e) {
      // Corrupt payload or schema mismatch; clear bad value.
      await prefs.remove(_userKey);
      return null;
    }
  }

  static Future<String?> readToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<bool> hasValidSession() async {
    final user = await readUser();
    final token = await readToken();
    return user != null && token != null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }
}
