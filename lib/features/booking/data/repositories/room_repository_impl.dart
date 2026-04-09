import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/date_extensions.dart';
import '../../domain/models/room.dart';
import '../../domain/models/space.dart';
import '../../domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final SupabaseClient _supabase;

  RoomRepositoryImpl(this._supabase);

  @override
  Future<List<Space>> getSpaces() async {
    try {
      final response = await _supabase.from('spaces').select();
      final data = response as List;
      return data.map((json) => Space.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load spaces: $e');
    }
  }

  @override
  Stream<List<Room>> getRooms({DateTime? date}) {
    final controller = StreamController<List<Room>>();
    final targetDate = date ?? DateTime.now();
    final targetDateStr = targetDate.toSupabaseDate();

    // Store rooms in memory to avoid refetching them constantly
    List<Room> cachedRooms = [];

    Future<void> fetchAndEmit() async {
      try {
        if (controller.isClosed) return;

        // 1. Fetch Rooms if not cached
        if (cachedRooms.isEmpty) {
          final roomsResponse = await _supabase.from('rooms').select();
          final roomsData = roomsResponse as List;
          cachedRooms = roomsData.map((json) => Room.fromJson(json)).toList();
        }

        // 2. Fetch Bookings for the specific date
        final bookingsResponse =
            await _supabase.from('bookings').select().eq('date', targetDateStr);

        final bookingsData = bookingsResponse as List;

        // 3. Map and Emit
        if (!controller.isClosed) {
          final result =
              _mapBookingsToRooms(cachedRooms, bookingsData, targetDate);
          controller.add(result);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Initial Fetch
    fetchAndEmit();

    // Realtime Subscription
    // Listen to ALL changes on 'bookings' table.
    // We don't filter by date here because DELETE events don't have the date column.
    // We just refetch our specific date whenever *anything* happens.
    final channel = _supabase.channel('public:bookings');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (payload) {
            // Optimization: You could check payload.newRecord['date'] for INSERT/UPDATE
            // but for DELETE you only have oldRecord['id'].
            // For safety and simplicity, we just refetch.
            fetchAndEmit();
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  // Helper to map bookings to rooms (moved logic here for reuse)
  List<Room> _mapBookingsToRooms(
    List<Room> rooms,
    List<dynamic> bookingsData,
    DateTime targetDate,
  ) {
    // 3. Map bookings to rooms
    final bookingsByRoom = <String, List<dynamic>>{};
    for (var booking in bookingsData) {
      final roomId = booking['room_id'] as String;
      if (!bookingsByRoom.containsKey(roomId)) {
        bookingsByRoom[roomId] = [];
      }
      bookingsByRoom[roomId]!.add(booking);
    }

    // 4. Create Rooms with occupied slots
    return rooms.map((room) {
      final roomBookings = bookingsByRoom[room.id] ?? [];

      // Defined slots: 1.5h duration, specific start times
      // TODO: Move this configuration to a shared constant or fetch from DB config
      final definedSlots = [
        '09:00',
        '10:30',
        '12:00',
        '13:30',
        '15:00',
        '16:30',
        '18:00',
        '19:30',
        '21:00',
      ];
      // Note: Logic assumes 90 min duration
      // const slotDurationMinutes = 90; // Removed as no longer needed for time overlap

      final calculatedOccupied = <String>[];

      for (var slotTime in definedSlots) {
        // Removed time-based slot calculation as no longer needed
        // final parts = slotTime.split(':');
        // final h = int.parse(parts[0]);
        // final m = int.parse(parts[1]);
        // final slotStart =
        //     DateTime(targetDate.year, targetDate.month, targetDate.day, h, m);
        // final slotEnd =
        //     slotStart.add(const Duration(minutes: slotDurationMinutes));

        bool isOverlap = false;

        // Find if this slot is taken by an active booking
        for (var booking in roomBookings) {
          final bookingSlotId = booking['slot_id'];
          final bookingStatus = booking['status'] as String?;

          // Only count active bookings (pending or confirmed)
          if (bookingStatus != 'pending' && bookingStatus != 'confirmed') {
            continue; // Skip cancelled, completed, or any other status
          }

          // Modern check: match slot_id directly
          if (bookingSlotId != null &&
              bookingSlotId is num &&
              bookingSlotId > 0) {
            final currentSlotId = definedSlots.indexOf(slotTime) + 1;
            if (bookingSlotId.toInt() == currentSlotId) {
              isOverlap = true;
              break;
            }
          }
          // Removed fallback to time overlap as no longer needed
          // else {
          //   // Fallback to time overlap
          //   final bStart = DateTime.parse(booking['start_time']).toLocal();
          //   final bEnd = DateTime.parse(booking['end_time']).toLocal();

          //   if (slotStart.isBefore(bEnd) && slotEnd.isAfter(bStart)) {
          //     isOverlap = true;
          //     break;
          //   }
          // }
        }

        if (isOverlap) {
          calculatedOccupied.add(slotTime);
        }
      }

      return Room(
        id: room.id,
        name: room.name,
        imageUrl: room.imageUrl,
        rating: room.rating,
        area: room.area,
        description: room.description,
        amenities: room.amenities,
        pricePerHour: room.pricePerHour,
        availableSlots: room.availableSlots,
        occupiedSlots: calculatedOccupied,
      );
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Room?> getRoomById(String id) async {
    try {
      final response =
          await _supabase.from('rooms').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return Room.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load room: $e');
    }
  }
}
