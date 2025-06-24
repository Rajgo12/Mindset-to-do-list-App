// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

const Color kAppBackground = Color(0xFFFEFCFA);
const Color kPrimaryBlue = Color(0xFF0256BF);
const Color kAccentYellow = Color(0xFFFFD600);
const Color kAccentGreen = Color(0xFF2EB872);
const Color kDarkText = Color(0xFF222222);

final OutlineInputBorder kInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(16),
  borderSide: const BorderSide(color: Colors.black26, width: 1),
);

final InputDecoration kTextFieldDecoration = InputDecoration(
  filled: true,
  fillColor: Colors.white,
  border: kInputBorder,
  enabledBorder: kInputBorder,
  focusedBorder: kInputBorder.copyWith(
    borderSide: const BorderSide(color: Color(0xFF0256BF), width: 1.5),
  ),
);

final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: kPrimaryBlue,
    secondary: kAccentYellow,
    background: kAppBackground,
  ),
  scaffoldBackgroundColor: kAppBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0256BF),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: kPrimaryBlue,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: kDarkText),
    bodyMedium: TextStyle(color: kDarkText),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: kTextFieldDecoration.filled ?? false,
    fillColor: kTextFieldDecoration.fillColor,
    border: kTextFieldDecoration.border,
    enabledBorder: kTextFieldDecoration.enabledBorder,
    focusedBorder: kTextFieldDecoration.focusedBorder,
  ),
);