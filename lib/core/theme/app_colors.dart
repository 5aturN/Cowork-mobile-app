import 'package:flutter/material.dart';

/// Цветовая палитра приложения (черная тема как в веб-версии)
class AppColors {
  // Primary Colors (синий как в веб-версии)
  static const Color primary = Color(0xFF0066FF);
  static const Color primaryLight = Color(0xFF3385FF);
  static const Color primaryDark = Color(0xFF0052CC);

  // Background Colors (черная тема)
  static const Color backgroundLight =
      Color(0xFFFFFFFF); // для светлой темы (не используется)
  static const Color backgroundDark = Color(0xFF000000); // Чистый черный фон

  // Text Colors
  static const Color textDark = Color(0xFF000000);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Card colors
  static const Color cardDark = Color(0xFF1A1A1A); // Темные карточки
  static const Color cardLight = Color(0xFFFFFFFF);

  // Neutral Colors (серые оттенки)
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF3A3A3A);
  static const Color grey700 = Color(0xFF2A2A2A);
  static const Color grey800 = Color(0xFF1A1A1A);
  static const Color grey900 = Color(0xFF0A0A0A);

  // Semantic Colors
  static const Color success = Color(0xFF28A745);
  static const Color green = Color(0xFF28A745); // Alias for success
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545); // Красный для занятых слотов
  static const Color info = Color(0xFF17A2B8);

  // Overlay & Shadow
  static const Color overlay = Color(0x80000000);
  static const Color shadow = Color(0x1A000000);
}
