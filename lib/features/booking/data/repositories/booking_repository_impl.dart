import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../domain/models/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../mappers/booking_mapper.dart';

class BookingRepositoryImpl implements BookingRepository {
  final SupabaseClient _supabase;

  BookingRepositoryImpl(this._supabase);

  @override
  Future<void> createBooking(Booking booking) async {
    try {
      // Use Mapper to prepare persistence data (Cleaner than manual removal)
      final json = BookingMapper.toPersistence(booking);

      await _supabase.from('bookings').insert(json);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  @override
  Future<List<Booking>> getMyBookings(String userId) async {
    try {
      // Note: ordered by date, then slot_id
      final response = await _supabase
          .from('bookings')
          .select('*, rooms(name, photos)')
          .eq('user_id', userId)
          .order('date', ascending: true)
          .order('slot_id', ascending: true);

      LoggerService.d('Raw Bookings Response', response);

      return (response as List).map((e) {
        try {
          return Booking.fromJson(e);
        } catch (err) {
          LoggerService.e('Failed to parse booking JSON', err);
          rethrow;
        }
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  @override
  Future<List<int>> getOccupiedSlotIds(String roomId, DateTime date) async {
    try {
      final dateStr = date.toSupabaseDate();

      final response = await _supabase
          .from('bookings')
          .select('slot_id')
          .eq('room_id', roomId)
          .eq('date', dateStr)
          .inFilter(
              'status', ['pending', 'confirmed']); // Only count active bookings

      return (response as List).map((e) => e['slot_id'] as int).toList();
    } catch (e) {
      throw Exception('Failed to fetch occupied slots: $e');
    }
  }

  @override
  Future<bool> isSlotAvailable(String roomId, DateTime date, int slotId) async {
    try {
      final dateStr = date.toSupabaseDate();

      // We count bookings for this slot. If count > 0, it's occupied.
      final count = await _supabase
          .from('bookings')
          .count(CountOption.exact)
          .eq('room_id', roomId)
          .eq('date', dateStr)
          .eq('slot_id', slotId)
          .inFilter(
              'status', ['pending', 'confirmed']); // Only count active bookings

      return count == 0;
    } catch (e) {
      LoggerService.e('Error checking availability', e);
      // If error (e.g. network), assume available to avoid blocking user?
      // Or safer to assume occupied?
      // Safer to throw or return false. Returning false might be annoying if it's just a glitch.
      // But typically we should fail closed (safe).
      throw Exception('Failed to check slot availability: $e');
    }
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').update({
        'status': 'cancelled',
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  @override
  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    int newSlotId,
  ) async {
    try {
      final dateStr = newDate.toSupabaseDate();
      await _supabase.from('bookings').update({
        'date': dateStr,
        'slot_id': newSlotId,
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to reschedule booking: $e');
    }
  }
}
