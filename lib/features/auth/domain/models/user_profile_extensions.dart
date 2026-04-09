// Extension to add helper methods to UserProfile
import 'user_profile.dart';

extension UserProfileExtensions on UserProfile {
  /// Get full name from firstName, lastName, and patronymic
  /// Falls back to legacy 'name' field if new fields are not available
  String get fullName {
    if (firstName != null && lastName != null) {
      if (patronymic != null && patronymic!.isNotEmpty) {
        return '$firstName $patronymic $lastName';
      }
      return '$firstName $lastName';
    }
    // Fallback to legacy name field during migration
    return name ?? 'Пользователь';
  }

  /// Get short name (firstName + lastName)
  String get shortName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name ?? 'Пользователь';
  }
}
