import 'package:flutter/material.dart';

const lime = Color(0xFFB6FF3B);
const cyan = Color(0xFF00D4FF);
const amber = Color(0xFFFFB547);
const purple = Color(0xFFA855F7);
const emerald = Color(0xFF10B981);

Color getAccentColor(String? name) {
  switch (name?.toLowerCase()) {
    case 'cyan':
      return cyan;
    case 'amber':
      return amber;
    case 'purple':
      return purple;
    case 'emerald':
      return emerald;
    case 'lime':
    default:
      return lime;
  }
}

Color getSecondaryColor(String? accentName) {
  switch (accentName?.toLowerCase()) {
    case 'cyan':
      return lime;
    case 'amber':
      return purple;
    case 'purple':
      return cyan;
    case 'emerald':
      return cyan;
    case 'lime':
    default:
      return cyan;
  }
}

ThemeData buildTheme({
  String accentColor = 'lime',
  Brightness brightness = Brightness.dark,
}) {
  final isDark = brightness == Brightness.dark;
  final primary = getAccentColor(accentColor);
  final secondary = getSecondaryColor(accentColor);
  final onPrimary = primary.computeLuminance() > 0.4 ? Colors.black : Colors.white;

  final baseBg = isDark ? const Color(0xFF0B0F14) : const Color(0xFFF4F6F9);
  final surface = isDark ? const Color(0xFF151B23) : Colors.white;
  final cardBg = isDark ? const Color(0xFF1C2430) : Colors.white;
  final borderColor = isDark ? const Color(0xFF283241) : const Color(0xFFE2E8F0);
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFFA7B0BF) : const Color(0xFF64748B);

  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    surface: surface,
    surfaceContainer: cardBg,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: baseBg,
    appBarTheme: AppBarTheme(
      backgroundColor: baseBg,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary);
        }
        return IconThemeData(color: textSecondary);
      }),
    ),
  );
}
