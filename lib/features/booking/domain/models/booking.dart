// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

@freezed
class Booking with _$Booking {
  const Booking._(); // Needed for custom methods/getters

  const factory Booking({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'room_id') required String roomId,
    @JsonKey(name: 'date') required DateTime date,
    @JsonKey(name: 'slot_id', defaultValue: 0) required int slotId,
    @Default('pending') String status,
    @JsonKey(name: 'total_amount') required double totalAmount,
    String? comment,
    @JsonKey(name: 'created_at') DateTime? createdAt,

    // Flattened Room Data
    @JsonKey(readValue: _readRoomName) @Default('Кабинет') String roomName,
    @JsonKey(readValue: _readRoomImage) @Default('') String roomImageUrl,
  }) = _Booking;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  // Helper to get formatted date
  String get formattedDate {
    return "${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}";
  }

  // Helper to get time string from slotId
  String get formattedTime {
    return getSlotTime(slotId);
  }

  // Helper to get duration in minutes
  int get duration {
    return 90; // Fixed duration 1.5h
  }

  // Helper to construct full DateTime from date + slotId
  DateTime get dateTime {
    final timeStr = getSlotTime(slotId);
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    // Assume date is already in local or UTC 00:00.
    // We want the result to be in the same timezone as the 'date' object typically,
    // but if 'date' is UTC midnight, we might want to interpret it as "Date in context".
    // given the app seems to accept Date part.

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  bool get isActive {
    if (status == 'cancelled') return false;
    // Just compare date for simplicity, or dateTime if precise
    final now = DateTime.now();
    // Compare full datetimes
    final end = dateTime.add(Duration(minutes: duration));
    return end.isAfter(now);
  }

  // Helper to get BookingStatus enum if needed, but string is fine for now
  // We can add the extension getters here directly

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppColors.primary; // or Green
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'confirmed':
        return 'Подтверждено';
      case 'completed':
        return 'Завершено';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  static String getSlotTime(int slotId) {
    switch (slotId) {
      case 1:
        return '09:00';
      case 2:
        return '10:30';
      case 3:
        return '12:00';
      case 4:
        return '13:30';
      case 5:
        return '15:00';
      case 6:
        return '16:30';
      case 7:
        return '18:00';
      case 8:
        return '19:30';
      case 9:
        return '21:00';
      default:
        return '00:00';
    }
  }
}

// Custom readers for flattened room data - Top Level
Object? _readRoomName(Map<dynamic, dynamic> json, String key) {
  if (json['rooms'] != null) {
    final room = json['rooms'] is List
        ? (json['rooms'] as List).firstOrNull
        : json['rooms'];
    if (room != null && room['name'] != null) {
      return room['name'];
    }
  }
  return json['room_name']; // Fallback
}

Object? _readRoomImage(Map<dynamic, dynamic> json, String key) {
  if (json['rooms'] != null) {
    final room = json['rooms'] is List
        ? (json['rooms'] as List).firstOrNull
        : json['rooms'];
    if (room != null) {
      if (room['photos'] != null &&
          room['photos'] is List &&
          (room['photos'] as List).isNotEmpty) {
        return room['photos'][0];
      }
      if (room['image_url'] != null) {
        return room['image_url'];
      }
    }
  }
  return json['room_image_url']; // Fallback
}
