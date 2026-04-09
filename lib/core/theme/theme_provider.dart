import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Провайдер темы приложения
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    state = StorageService.themeMode;
  }

  void toggleTheme(bool isDark) {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    StorageService.setThemeMode(mode);
  }
}

final appAccentColorProvider =
    StateNotifierProvider<AppAccentColorNotifier, Color?>((ref) {
  return AppAccentColorNotifier();
});

class AppAccentColorNotifier extends StateNotifier<Color?> {
  AppAccentColorNotifier() : super(null) {
    _loadColor();
  }

  void _loadColor() {
    final hexString = StorageService.accentColor;
    if (hexString != null) {
      try {
        final cleanHex = hexString.replaceAll('#', '');
        state = Color(int.parse('FF$cleanHex', radix: 16));
      } catch (e) {
        // ignore
      }
    }
  }

  void setColor(Color? color) {
    state = color;
    if (color != null) {
      final hexString = '#${color.toARGB32().toRadixString(16).substring(2)}';
      StorageService.setAccentColor(hexString);
    } else {
      StorageService.setAccentColor(null);
    }
  }
}

final adaptiveThemeEnabledProvider =
    StateNotifierProvider<AdaptiveThemeNotifier, bool>((ref) {
  return AdaptiveThemeNotifier();
});

class AdaptiveThemeNotifier extends StateNotifier<bool> {
  AdaptiveThemeNotifier() : super(true) {
    _loadState();
  }

  void _loadState() {
    state = StorageService.adaptiveThemeEnabled;
  }

  void setEnabled(bool enabled) {
    state = enabled;
    StorageService.setAdaptiveThemeEnabled(enabled);
  }
}
