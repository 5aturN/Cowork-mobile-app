import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/string_utils.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  bool get isAuthenticated => _supabase.auth.currentSession != null;

  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  @override
  Future<String> signInWithPhone(String phone) async {
    // 1. Format phone to strict format if needed (e.g. +7...)
    final cleanPhone = StringUtils.cleanPhoneNumber(phone);
    // Assuming format 79991234567

    // 2. Facade: Generate fake email
    final email = '$cleanPhone@example.com';

    // 3. Facade: Constant dev password
    const password = 'dev-password-123!';

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw Exception('Login failed');
      }
      return response.user!.id;
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        // User doesn't exist? Try to Sign Up implicitly?
        // Actually, for this flow, we might want to SignUp if SignIn fails?
        // Let's try SignUp
        try {
          final response = await _supabase.auth.signUp(
            email: email,
            password: password,
          );
          if (response.user == null) {
            throw Exception('Registration failed');
          }
          return response.user!.id;
        } catch (signupError) {
          throw Exception('Auth Error: $signupError');
        }
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      // Log error
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  @override
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) {
          if (event.isEmpty) return null;
          return UserProfile.fromJson(event.first);
        });
  }

  @override
  Future<void> createProfile(UserProfile profile) async {
    try {
      await _supabase.from('users').upsert(profile.toJson());
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  @override
  Future<String> uploadAvatar(File file, String userId) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await _supabase.storage.from('avatars').upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(fileName);
      return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
