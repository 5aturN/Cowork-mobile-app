import '../models/booking.dart';

abstract class BookingRepository {
  Future<void> createBooking(Booking booking);
  Future<List<Booking>> getMyBookings(String userId);
  Future<List<int>> getOccupiedSlotIds(String roomId, DateTime date);

  /// Checks if a specific slot is available. Returns true if available (not occupied).
  Future<bool> isSlotAvailable(String roomId, DateTime date, int slotId);

  /// Cancel a booking (sets status to 'cancelled')
  Future<void> cancelBooking(String bookingId);

  /// Reschedule a booking to a new date and time slot
  Future<void> rescheduleBooking(
    String bookingId,
    DateTime newDate,
    int newSlotId,
  );
}
