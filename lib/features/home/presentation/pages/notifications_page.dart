import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/notification_item.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notifications_provider.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    // Mark all as read when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAllAsRead();
    });
  }

  Future<void> _loadNotifications() async {
    // Simulate slight delay for smooth UI
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      await StorageService.init(); // Explicitly ensure init
      final rawList = StorageService.getNotificationHistory();
      debugPrint('Loaded raw notifications: $rawList');
      if (mounted) {
        setState(() {
          _notifications = rawList
              .map((e) {
                try {
                  return NotificationItem.fromJson(e);
                } catch (e) {
                  debugPrint('Skipping invalid notification: $e');
                  return null;
                }
              })
              .whereType<NotificationItem>()
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _notifications = [];
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    await StorageService.clearNotifications();
    setState(() {
      _notifications = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Очистить историю?'),
                    content: const Text(
                      'Вы уверены, что хотите удалить все уведомления?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Отмена'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearHistory();
                        },
                        child: const Text(
                          'Очистить',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: theme.disabledColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет уведомлений',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(item.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatTime(DateTime time) {
    // Simple formatter, e.g., "10:30" or "Yesterday"
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } else if (diff.inDays == 1) {
      return 'Вчера';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }
}
