import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_profile.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

// State for Auth (Loading, Authenticated, Unauthenticated)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// Current User Profile Provider
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final authState = ref.watch(authStateProvider);

  final user = authState.value?.session?.user;
  if (user == null) {
    yield null;
    return;
  }

  final repo = ref.read(authRepositoryProvider);
  yield* repo.getUserProfileStream(user.id);
});
