import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Сервис для работы с локальным хранилищем
class StorageService {
  static const String _keyIsAuthenticated = 'is_authenticated';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyUserName = 'user_name';
  static const String _keyAvatarUrl = 'avatar_url';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAccentColor = 'accent_color';
  static const String _keyAdaptiveThemeEnabled = 'adaptive_theme_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('StorageService initialized');
  }

  static Future<void> _ensureInit() async {
    if (_prefs == null) {
      debugPrint('StorageService was null, re-initializing...');
      await init();
    }
  }

  // Authentication
  static Future<void> saveAuthData({
    required String phoneNumber,
    String? userName,
  }) async {
    await _prefs?.setBool(_keyIsAuthenticated, true);
    await _prefs?.setString(_keyPhoneNumber, phoneNumber);
    if (userName != null) {
      await _prefs?.setString(_keyUserName, userName);
    }
  }

  static bool get isAuthenticated =>
      _prefs?.getBool(_keyIsAuthenticated) ?? false;
  static String? get phoneNumber => _prefs?.getString(_keyPhoneNumber);
  static String? get userName => _prefs?.getString(_keyUserName);

  static Future<void> setUserName(String name) async {
    await _prefs?.setString(_keyUserName, name);
  }

  static Future<void> setAvatarUrl(String url) async {
    await _prefs?.setString(_keyAvatarUrl, url);
  }

  static String? get avatarUrl => _prefs?.getString(_keyAvatarUrl);

  static Future<void> logout() async {
    await _prefs?.setBool(_keyIsAuthenticated, false);
    await _prefs?.remove(_keyPhoneNumber);
    await _prefs?.remove(_keyUserName);
    await _prefs?.remove(_keyAvatarUrl);
  }

  // Theme
  static Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString(_keyThemeMode, mode.toString());
  }

  static ThemeMode get themeMode {
    final modeString = _prefs?.getString(_keyThemeMode);
    if (modeString == null) return ThemeMode.dark;

    switch (modeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark;
    }
  }

  // Accent Color
  static Future<void> setAccentColor(String? color) async {
    if (color == null) {
      await _prefs?.remove(_keyAccentColor);
    } else {
      await _prefs?.setString(_keyAccentColor, color);
    }
  }

  static String? get accentColor => _prefs?.getString(_keyAccentColor);

  // Notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationsEnabled, enabled);
  }

  static bool get notificationsEnabled =>
      _prefs?.getBool(_keyNotificationsEnabled) ?? true;

  // Adaptive Theme
  static Future<void> setAdaptiveThemeEnabled(bool enabled) async {
    await _prefs?.setBool(_keyAdaptiveThemeEnabled, enabled);
  }

  static bool get adaptiveThemeEnabled =>
      _prefs?.getBool(_keyAdaptiveThemeEnabled) ?? true;

  // Notification History
  static const String _keyNotificationHistory = 'notification_history';

  static List<String> get _notificationHistory =>
      _prefs?.getStringList(_keyNotificationHistory) ?? [];

  static Future<void> addNotification(String title, String body) async {
    await _ensureInit();
    final history = _notificationHistory;
    final timestamp = DateTime.now().toIso8601String();

    // Use jsonEncode for safety
    final itemMap = {
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'isRead': false,
    };
    final itemJson = jsonEncode(itemMap);

    debugPrint('Adding notification: $itemJson');

    history.insert(0, itemJson); // Add to top
    if (history.length > 50) {
      history.removeLast(); // Keep max 50
    }

    await _prefs?.setStringList(_keyNotificationHistory, history);
  }

  static List<Map<String, dynamic>> getNotificationHistory() {
    final history = _notificationHistory;
    return history.map((e) {
      // Basic manual parsing to avoid imports overhead if possible,
      // but easier to just use manual string manipulation or standard jsonDecode
      // if I import dart:convert.
      // Let's assume standard jsonDecode is available if I import it.
      // Wait, I should import dart:convert at the top.

      // For now, let's just return the raw strings and parse in UI or model
      // But standard is better. I will add import dart:convert.
      return Map<String, dynamic>.from(_jsonDecodeSafe(e));
    }).toList();
  }

  static Map<String, dynamic> _jsonDecodeSafe(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding notification: $e');
      return {};
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    final history = _notificationHistory;
    final updatedHistory = history.map((e) {
      final map = Map<String, dynamic>.from(_jsonDecodeSafe(e));
      map['isRead'] = true;
      return jsonEncode(map);
    }).toList();

    await _prefs?.setStringList(_keyNotificationHistory, updatedHistory);
  }

  static int getUnreadNotificationsCount() {
    final history = _notificationHistory;
    return history.where((e) {
      final map = _jsonDecodeSafe(e);
      return map['isRead'] == false;
    }).length;
  }

  static Future<void> clearNotifications() async {
    await _prefs?.remove(_keyNotificationHistory);
  }

  // Cart Persistence
  static const String _keyCart = 'cart_items';

  static Future<void> saveCartItems(List<String> itemsJson) async {
    await _prefs?.setStringList(_keyCart, itemsJson);
  }

  static List<String> getCartItems() {
    return _prefs?.getStringList(_keyCart) ?? [];
  }
}
