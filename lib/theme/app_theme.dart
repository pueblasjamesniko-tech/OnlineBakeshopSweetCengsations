import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color cream = Color(0xFFFDF6EC);
  static const Color warmWhite = Color(0xFFFFF8F0);
  static const Color caramel = Color(0xFFD4874E);
  static const Color deepCaramel = Color(0xFFB86830);
  static const Color chocolate = Color(0xFF3E1C00);
  static const Color darkChoco = Color(0xFF2A1200);
  static const Color roseDust = Color(0xFFE8B4A0);
  static const Color blush = Color(0xFFF5D6C8);
  static const Color gold = Color(0xFFE8C547);
  static const Color dustyRose = Color(0xFFD4907A);
  static const Color sage = Color(0xFF8B9D77);
  static const Color ivoryLight = Color(0xFFFAF3E7);

  // ── Gradient Presets ──────────────────────────────────────
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF5E6D3), Color(0xFFE8C9A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient chocolateGradient = LinearGradient(
    colors: [Color(0xFF3E1C00), Color(0xFF6B3A1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient caramelGradient = LinearGradient(
    colors: [Color(0xFFD4874E), Color(0xFFE8A96A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: cream,
      fontFamily: 'serif',
      colorScheme: ColorScheme.fromSeed(
        seedColor: caramel,
        primary: caramel,
        secondary: chocolate,
        background: cream,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: caramel,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roseDust.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: roseDust.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: caramel, width: 2),
        ),
        labelStyle: TextStyle(color: chocolate.withOpacity(0.6), fontSize: 14),
        hintStyle: TextStyle(color: chocolate.withOpacity(0.4), fontSize: 14),
      ),
    );
  }
}
