import 'package:flutter/material.dart';

class AppTheme {
  // Základní barvy
  static const _primaryColor = Color(0xD932E6B6);
  static const _backgroundColor = Colors.black;
  static const _surfaceColor = Color(0xFF1C1C1E);
  static const _cardColor = Color(0xFF2C2C2E);
  static const _lightBackgroundColor = Color(0xFFF8F9FA);
  
  // Text colors
  static const _darkTextColor = Colors.white;
  static const _darkSecondaryTextColor = Color(0xFF8E8E93);
  static const _lightTextColor = Color(0xFF212121);
  static const _lightSecondaryTextColor = Color(0xFF757575);

  // Konstanty pro spacing a zaoblení
  static const double _cardBorderRadius = 12.0;
  static const double _buttonBorderRadius = 28.0;
  static const double _contentPadding = 16.0;

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      surface: Colors.white,
      background: _lightBackgroundColor,
      onSurface: _lightTextColor,
      secondary: _lightSecondaryTextColor,
      onSecondary: Colors.white,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        side: BorderSide(
          color: _primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide(color: _primaryColor),
      ),
      contentPadding: const EdgeInsets.all(_contentPadding),
      hintStyle: TextStyle(color: _lightSecondaryTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _contentPadding * 1.5,
          vertical: _contentPadding * 0.75,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.1),
      indicatorColor: Colors.transparent,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _primaryColor,
          );
        }
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _lightSecondaryTextColor,
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(
            color: _primaryColor,
            size: 24,
          );
        }
        return IconThemeData(
          color: _lightSecondaryTextColor,
          size: 24,
        );
      }),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: _primaryColor,
      surface: _surfaceColor,
      background: _backgroundColor,
      onSurface: _darkTextColor,
      secondary: _darkSecondaryTextColor,
      onSecondary: _darkTextColor,
      surfaceVariant: _cardColor,
    ),
    cardTheme: CardTheme(
      color: _surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        borderSide: BorderSide(color: _primaryColor),
      ),
      contentPadding: const EdgeInsets.all(_contentPadding),
      hintStyle: TextStyle(color: _darkSecondaryTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_buttonBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _contentPadding * 1.5,
          vertical: _contentPadding * 0.75,
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _backgroundColor,
      elevation: 0,
      indicatorColor: _primaryColor.withOpacity(0.2),
      labelTextStyle: MaterialStateProperty.all(
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _darkTextColor,
        ),
      ),
    ),
  );
} 