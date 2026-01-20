class Room {
  final String id;
  final String? imageUrl;
  final String? roomNumber;
  final String? type;
  final double? pricePerMonth;
  final int? capacity;
  final bool isAvailable;

  Room({
    required this.id,
    this.imageUrl,
    this.roomNumber,
    this.type,
    this.pricePerMonth,
    this.capacity,
    required this.isAvailable,
  });

  factory Room.fromMap(Map<String, dynamic> m) {
    return Room(
      id: m['id']?.toString() ?? '',
      imageUrl: m['image_url']?.toString() ?? m['image']?.toString(),
      roomNumber: m['room_number']?.toString() ?? m['room']?.toString(),
      type: m['type']?.toString() ?? m['room_type']?.toString(),
      pricePerMonth: (m['price_per_month'] is num) ? (m['price_per_month'] as num).toDouble() : null,
      capacity: m['capacity'] is int ? m['capacity'] as int : (m['capacity'] is num ? (m['capacity'] as num).toInt() : null),
      isAvailable: m['is_available'] == true,
    );
  }
}
