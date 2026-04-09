// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'space.freezed.dart';
part 'space.g.dart';

@freezed
class Space with _$Space {
  const factory Space({
    required String id,
    required String name,
    String? address,
    String? description,
    @JsonKey(name: 'photo_path') String? photoPath,
    // working_hours is JSONB, usually Map<String, dynamic> or similar. We can type it if known, or generic Map.
    @JsonKey(name: 'working_hours') Map<String, dynamic>? workingHours,
    @Default([]) List<String> amenities,
  }) = _Space;

  factory Space.fromJson(Map<String, dynamic> json) => _$SpaceFromJson(json);
}
