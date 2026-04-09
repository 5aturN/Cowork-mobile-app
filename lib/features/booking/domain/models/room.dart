/// Модель кабинета
class Room {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int area; // в квадратных метрах
  final String description;
  final String amenities; // например, "Кресла", "Кушетка"
  final int pricePerHour;
  final List<String> availableSlots; // ["10:00", "14:00", "18:00"]
  final List<String> occupiedSlots; // ["16:00"]

  const Room({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.area,
    required this.description,
    required this.amenities,
    required this.pricePerHour,
    required this.availableSlots,
    required this.occupiedSlots,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: (json['photos'] is List && (json['photos'] as List).isNotEmpty)
          ? (json['photos'] as List)[0] as String
          : (json['image_url'] as String? ?? ''),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      area: (json['area'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      amenities: json['amenities'] is List
          ? (json['amenities'] as List).join(', ')
          : (json['amenities'] as String? ?? ''),
      pricePerHour: (json['price_per_hour'] as num?)?.toInt() ?? 0,
      availableSlots: (json['available_slots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      occupiedSlots: (json['occupied_slots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'rating': rating,
      'area': area,
      'description': description,
      'amenities': amenities,
      'price_per_hour': pricePerHour,
      'available_slots': availableSlots,
      'occupied_slots': occupiedSlots,
    };
  }
}
