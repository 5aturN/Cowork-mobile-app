import 'dart:io';
import '../models/user_profile.dart';

abstract class AuthRepository {
  /// Checks if a session currently exists
  bool get isAuthenticated;

  /// Current user ID if authenticated
  String? get currentUserId;

  /// Sign in using Phone Number (Facaded as Email)
  /// Returns [String] as user ID if successful
  Future<String> signInWithPhone(String phone);

  /// Check if a user profile exists in public.users table
  Future<UserProfile?> getUserProfile(String userId);

  /// Get user profile stream for realtime updates
  Stream<UserProfile?> getUserProfileStream(String userId);

  /// Create a new user profile after registration
  Future<void> createProfile(UserProfile profile);

  /// Upload avatar and return public URL
  Future<String> uploadAvatar(File file, String userId);

  /// Sign out
  Future<void> signOut();
}
