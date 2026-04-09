import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String id,
    required String roomId,
    required String roomName,
    required String imageUrl,
    required DateTime date,
    required String timeSlot, // "09:00"
    required int slotId,
    required int price,
    required int durationMinutes,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);
}
