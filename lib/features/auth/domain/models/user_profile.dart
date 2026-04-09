// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'patronymic') String? patronymic,
    @JsonKey(name: 'phone') String? phone,
    @JsonKey(name: 'role') @Default('patient') String role,
    @JsonKey(name: 'education') String? education,
    @JsonKey(name: 'work_direction') String? workDirection,
    @JsonKey(name: 'social_network') String? socialNetwork,
    @JsonKey(name: 'work_format') String? workFormat,
    @Default(0) double balance,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    // Legacy field for backwards compatibility during migration
    @JsonKey(name: 'name') String? name,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}
