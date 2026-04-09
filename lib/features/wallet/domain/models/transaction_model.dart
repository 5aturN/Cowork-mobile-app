// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

@freezed
class TransactionModel with _$TransactionModel {
  const factory TransactionModel({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    required double amount,
    required String type, // 'deposit', 'payment', 'refund'
    String? description,
    @JsonKey(name: 'booking_id') String? bookingId,
    Map<String, dynamic>? metadata, // Room name, date, slot, etc.
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TransactionModel;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);
}
