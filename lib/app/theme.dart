import 'package:flutter/material.dart';

const lime = Color(0xFFB6FF3B);
const cyan = Color(0xFF00D4FF);
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: lime,
    brightness: Brightness.dark,
  ).copyWith(primary: lime, secondary: cyan, surface: const Color(0xFF151B23));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0B0F14),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0F14),
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1C2430),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Color(0xFF151B23),
    ),
  );
}
