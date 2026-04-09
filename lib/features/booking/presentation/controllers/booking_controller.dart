import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../../../wallet/domain/models/transaction_model.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../providers/booking_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Controller for managing bookings (cancel, reschedule, etc.)
class BookingController {
  final BookingRepository _bookingRepository;
  final WalletRepository _walletRepository;
  final AuthRepository _authRepository;

  BookingController({
    required BookingRepository bookingRepository,
    required WalletRepository walletRepository,
    required AuthRepository authRepository,
  })  : _bookingRepository = bookingRepository,
        _walletRepository = walletRepository,
        _authRepository = authRepository;

  /// Check if booking can be refunded (24 hours or more before start)
  bool canRefund(DateTime bookingDateTime) {
    final now = DateTime.now();
    final hoursUntil = bookingDateTime.difference(now).inHours;
    return hoursUntil >= 24;
  }

  /// Cancel a booking with refund logic based on 24-hour policy
  Future<CancellationResult> cancelBooking(Booking booking) async {
    try {
      final canGetRefund = canRefund(booking.dateTime);

      debugPrint('📋 Cancelling booking: ${booking.id}');
      debugPrint('⏰ Booking dateTime: ${booking.dateTime}');
      debugPrint('💰 Can refund: $canGetRefund');
      debugPrint('💵 Total amount: ${booking.totalAmount}');

      // Update booking status to cancelled
      await _bookingRepository.cancelBooking(booking.id);
      debugPrint('✅ Booking status updated to cancelled');

      // If eligible for refund, create refund transaction
      if (canGetRefund) {
        final userId = _authRepository.currentUserId;
        debugPrint('👤 Current userId: $userId');

        if (userId != null) {
          // Generate UUID for transaction
          final transactionId = const Uuid().v4();
          debugPrint('🆔 Generated transaction ID: $transactionId');

          final transaction = TransactionModel(
            id: transactionId, // Use generated UUID
            userId: userId,
            amount: booking.totalAmount,
            type: 'refund',
            description:
                'Возврат за отмену бронирования #${booking.id.substring(0, 8)}',
            bookingId: booking.id,
            metadata: {
              'room_name': booking.roomName,
              'date': booking.date.toIso8601String(),
              'time_slot': booking.formattedTime,
            },
          );
          debugPrint('💸 Creating refund transaction: ${transaction.toJson()}');
          await _walletRepository.createTransaction(transaction);
          debugPrint('✅ Refund transaction created successfully');
        } else {
          debugPrint('❌ No userId found, cannot create refund');
        }
      }

      return CancellationResult(
        success: true,
        refunded: canGetRefund,
        refundAmount: canGetRefund ? booking.totalAmount : 0,
      );
    } catch (e) {
      debugPrint('❌ Error cancelling booking: $e');
      return CancellationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Reschedule a booking to a new date and slot
  Future<bool> rescheduleBooking(
    Booking booking,
    DateTime newDate,
    int newSlotId,
  ) async {
    try {
      // Check if new slot is available
      final isAvailable = await _bookingRepository.isSlotAvailable(
        booking.roomId,
        newDate,
        newSlotId,
      );

      if (!isAvailable) {
        throw Exception('Выбранный слот уже занят');
      }

      // Reschedule the booking
      await _bookingRepository.rescheduleBooking(
        booking.id,
        newDate,
        newSlotId,
      );

      return true;
    } catch (e) {
      debugPrint('Error rescheduling booking: $e');
      return false;
    }
  }
}

/// Result of a booking cancellation
class CancellationResult {
  final bool success;
  final bool refunded;
  final double refundAmount;
  final String? error;

  CancellationResult({
    required this.success,
    this.refunded = false,
    this.refundAmount = 0,
    this.error,
  });
}

/// Provider for booking controller
final bookingControllerProvider = Provider<BookingController>((ref) {
  return BookingController(
    bookingRepository: ref.watch(bookingRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});
