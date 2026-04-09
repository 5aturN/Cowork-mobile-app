import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/room.dart';
import '../../domain/models/space.dart';
import '../../domain/repositories/room_repository.dart';
import '../../data/repositories/room_repository_impl.dart';

// Repository Provider
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepositoryImpl(Supabase.instance.client);
});

// Spaces Provider
final spacesProvider = FutureProvider<List<Space>>((ref) async {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getSpaces();
});

// Rooms List Provider (Family with Date)
final roomsProvider = StreamProvider.family<List<Room>, DateTime>((ref, date) {
  final repository = ref.watch(roomRepositoryProvider);
  return repository.getRooms(date: date);
});

// Single Room Provider (Family)
final roomDetailsProvider =
    FutureProvider.family<Room?, String>((ref, id) async {
  final repository = ref.watch(roomRepositoryProvider);
  return await repository.getRoomById(id);
});
