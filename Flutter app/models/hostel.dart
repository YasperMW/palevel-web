class Hostel {
  final String id;
  final String? title;
  final String? image;
  final String? landlord;
  final String? landlordId;
  final String? phone;
  final String type; // Added type field (non-nullable with default value)

  Hostel({
    required this.id,
    this.title,
    this.image, 
    this.landlord, 
    this.landlordId, 
    this.phone,
    this.type = 'Private', // Default to 'Private' if not provided
  });

  factory Hostel.fromMap(Map<String, dynamic> m) {
    return Hostel(
      id: m['id']?.toString() ?? m['hostel_id']?.toString() ?? '',
      title: m['title']?.toString(),
      image: m['image']?.toString(),
      landlord: m['landlord']?.toString(),
      landlordId: m['landlord_id']?.toString() ?? m['landlordId']?.toString(),
      phone: m['phone']?.toString(),
      type: m['type']?.toString() ?? 'Private', // Handle null case with default
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'landlord': landlord,
      'landlord_id': landlordId,
      'phone': phone,
      'type': type, // Include type in the map
    };
}
}
