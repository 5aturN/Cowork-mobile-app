import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/booking.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(Supabase.instance.client);
});

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.session?.user.id;

  if (userId == null) return [];

  return ref.watch(bookingRepositoryProvider).getMyBookings(userId);
});
