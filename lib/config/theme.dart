import 'package:flutter/material.dart';

// App colors
const primaryColor = Color(0xFF4CAF50);
const dangerColor = Color(0xFFF44336);
const warningColor = Color(0xFFFF9800);
const backgroundColor = Color(0xFFF5F5F5);
const cardColor = Colors.white;
const textColor = Color(0xFF333333);

final ThemeData appTheme = ThemeData(
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    primary: primaryColor,
    error: dangerColor,
    background: backgroundColor,
  ),
  scaffoldBackgroundColor: backgroundColor,
  cardTheme: const CardTheme(
    color: cardColor,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: textColor),
    bodyMedium: TextStyle(color: textColor),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  ),
);