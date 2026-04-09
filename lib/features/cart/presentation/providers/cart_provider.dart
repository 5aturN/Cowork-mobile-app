import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../domain/models/cart_item.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/providers/booking_provider.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  final BookingRepository _bookingRepository;

  CartNotifier(this._bookingRepository) : super([]) {
    _loadState();
  }

  Future<void> _loadState() async {
    final itemsJson = StorageService.getCartItems();
    if (itemsJson.isNotEmpty) {
      try {
        state = itemsJson.map((e) => CartItem.fromJson(jsonDecode(e))).toList();
      } catch (e) {
        // Handle corruption
        LoggerService.e('Error loading cart', e);
      }
    }
  }

  Future<void> _saveState() async {
    final itemsJson = state.map((e) => jsonEncode(e.toJson())).toList();
    await StorageService.saveCartItems(itemsJson);
  }

  /// Adds an item to the cart.
  /// Returns [true] if successful, [false] if slot is occupied or invalid.
  Future<bool> addItem(CartItem item) async {
    // 1. Check if duplicate in local state
    final exists = state.any(
      (element) =>
          element.roomId == item.roomId &&
          element.date == item.date &&
          element.timeSlot == item.timeSlot,
    );

    if (exists) return true; // Already added, treat as success

    // 2. Check if in past
    final now = DateTime.now();
    final parts = item.timeSlot.split(':');
    final itemDateTime = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    if (itemDateTime.isBefore(now)) {
      LoggerService.i('Attempted to add past slot: $itemDateTime');
      return false;
    }

    // 3. Async Check: Is slot effectively available?
    // We check server-side state to prevent adding already booked slots.
    try {
      final isAvailable = await _bookingRepository.isSlotAvailable(
        item.roomId,
        item.date,
        item.slotId,
      );

      if (!isAvailable) {
        LoggerService.i('Slot ${item.slotId} is occupied on server.');
        return false;
      }
    } catch (e) {
      LoggerService.e('Error checking availability', e);
      // If offline or error, we might allow adding (optimistic) or block.
      // For now, let's block to be safe against double booking.
      return false;
    }

    state = [...state, item];
    _saveState();
    return true;
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
    _saveState();
  }

  void clear() {
    state = [];
    _saveState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  return CartNotifier(bookingRepo);
});

final cartTotalProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.price);
});

final unavailableSlotsProvider = StateProvider<Set<String>>((ref) => {});
