import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../../../core/services/logger_service.dart';
import '../providers/cart_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class GlobalCartObserver extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalCartObserver({super.key, required this.child});

  @override
  ConsumerState<GlobalCartObserver> createState() => _GlobalCartObserverState();
}

class _GlobalCartObserverState extends ConsumerState<GlobalCartObserver> {
  // Map of RoomID -> RealtimeChannel
  final Map<String, RealtimeChannel> _activeSubscriptions = {};

  @override
  void initState() {
    super.initState();
    // Initialize subscriptions based on current state
    // We use addPostFrameCallback because ref.read/watch might not be fully safe in initState for some patterns,
    // but reading the provider here is standard for initial sync.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartItems = ref.read(cartProvider);
      final roomIds = cartItems.map((e) => e.roomId).toSet().toList();
      _updateSubscriptions(roomIds);
    });
  }

  @override
  void dispose() {
    _unsubscribeAll();
    super.dispose();
  }

  void _unsubscribeAll() {
    for (final channel in _activeSubscriptions.values) {
      channel.unsubscribe();
    }
    _activeSubscriptions.clear();
  }

  void _updateSubscriptions(List<String> requiredRoomIds) {
    final currentRoomIds = _activeSubscriptions.keys.toSet();
    final requiredSet = requiredRoomIds.toSet();

    // 1. Unsubscribe from rooms no longer in cart
    final toRemove = currentRoomIds.difference(requiredSet);
    for (final roomId in toRemove) {
      LoggerService.d('[Global] Unsubscribing from room: $roomId');
      _activeSubscriptions[roomId]?.unsubscribe();
      _activeSubscriptions.remove(roomId);
    }

    // 2. Subscribe to new rooms
    final toAdd = requiredSet.difference(currentRoomIds);
    for (final roomId in toAdd) {
      _subscribeToRoom(roomId);
    }
  }

  void _subscribeToRoom(String roomId) {
    LoggerService.d('[Global] Subscribing to room: $roomId');
    // We use a specific channel name including room_id to be safe,
    // though Supabase channels multiplex if named same.
    // Best practice: logical naming.
    final channel = Supabase.instance.client
        .channel('public:bookings:room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) => _handleRealtimeEvent(payload, roomId),
        )
        .subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        LoggerService.d('[Global] Subscribed to room $roomId');
      } else if (status == RealtimeSubscribeStatus.closed) {
        LoggerService.d('[Global] Channel closed for room $roomId');
      } else if (error != null) {
        LoggerService.e('[Global] Error subscribing to room $roomId', error);
      }
    });

    _activeSubscriptions[roomId] = channel;
  }

  void _handleRealtimeEvent(
    PostgresChangePayload payload,
    String sourceRoomId,
  ) {
    final newBooking = payload.newRecord;
    if (newBooking.isEmpty) return;

    // We use ref.read because this is a callback
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    // Ignore events created by the current user (false positives during own booking)
    final currentUserId = ref.read(authRepositoryProvider).currentUserId;
    if (newBooking['user_id'] == currentUserId) {
      return;
    }

    final roomId = newBooking['room_id'] as String?;
    final dateStr = newBooking['date'] as String?; // YYYY-MM-DD
    final slotId = newBooking['slot_id'] as int?;

    if (roomId == null || dateStr == null || slotId == null) return;

    // Safety check: ensure event matches subscription intent
    if (roomId != sourceRoomId) return;

    bool collision = false;
    final currentUnavailable = ref.read(unavailableSlotsProvider);
    final newUnavailable = Set<String>.from(currentUnavailable);

    for (var item in cartItems) {
      // Optimize: Only check items for this room
      if (item.roomId != roomId) continue;

      final itemDateStr = item.date.toSupabaseDate();

      if (itemDateStr == dateStr && item.slotId == slotId) {
        LoggerService.i(
          '[Global] Collision detected for item ${item.id}',
        );
        newUnavailable.add(item.id);
        collision = true;
      }
    }

    if (collision) {
      ref.read(unavailableSlotsProvider.notifier).state = newUnavailable;
      _showCollisionSnackBar();
    }
  }

  void _showCollisionSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'К сожалению, выбранный слот только что был забронирован другим пользователем.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 5),
          showCloseIcon: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to cart changes to update subscriptions
    ref.listen(cartProvider, (previous, next) {
      final roomIds = next.map((e) => e.roomId).toSet().toList();
      _updateSubscriptions(roomIds);
    });

    return widget.child;
  }
}
