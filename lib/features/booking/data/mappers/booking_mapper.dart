import '../../../../core/utils/date_extensions.dart';
import '../../domain/models/booking.dart';

class BookingMapper {
  /// Converts a Domain [Booking] entity to a Map suitable for Supabase persistence.
  /// Handles date formatting and excludes UI-specific fields.
  static Map<String, dynamic> toPersistence(Booking booking) {
    return {
      'user_id': booking.userId,
      'room_id': booking.roomId,
      'date': booking.date.toSupabaseDate(),
      'slot_id': booking.slotId,
      'status': booking.status,
      'total_amount': booking.totalAmount,
      if (booking.comment != null) 'comment': booking.comment,
      // 'created_at' is typically handled by DB default, but if we pass it:
      if (booking.createdAt != null) 'created_at': booking.createdAt!.toIso8601String(),
    };
  }
}
