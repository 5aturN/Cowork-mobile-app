import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, int>((ref) {
  return NotificationsNotifier();
});

class NotificationsNotifier extends StateNotifier<int> {
  NotificationsNotifier() : super(0) {
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    // Ensure initialized
    await StorageService.init();
    state = StorageService.getUnreadNotificationsCount();
  }

  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  Future<void> markAllAsRead() async {
    await StorageService.markAllNotificationsAsRead();
    state = 0;
  }
}
