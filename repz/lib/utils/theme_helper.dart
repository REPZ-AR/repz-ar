import 'package:flutter/material.dart';

class AppTheme {
  static Color getAccentColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFFCFF500) : const Color(0xFFA66CFF);
  }

  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF121212) : Colors.white;
  }

  static Color getCardColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  }

  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black;
  }

  static Color? getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[400] : Colors.grey[600];
  }

  static Color getButtonColor(bool isDarkMode) {
    return isDarkMode ? Colors.grey[700]! : const Color(0xFF4A4A4A);
  }
}