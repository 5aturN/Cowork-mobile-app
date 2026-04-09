import '../models/room.dart';
import '../models/space.dart';

abstract class RoomRepository {
  Stream<List<Room>> getRooms({DateTime? date});
  Future<Room?> getRoomById(String id);
  Future<List<Space>> getSpaces();
}
