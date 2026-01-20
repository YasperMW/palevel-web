import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:io';


class User {
  final String userId;
  final String email;
  final String userType;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final bool? isVerified;
  final bool? isBlacklisted;
  final String? university;
  final int? totalProperties;
  final int? totalRooms;
  final double? occupancyRate;
  final String? createdAt;

  User({
    required this.userId,
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.isVerified,
    this.isBlacklisted,
    this.university,
    this.totalProperties,
    this.totalRooms,
    this.occupancyRate,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      isVerified: json['is_verified'],
      isBlacklisted: json['is_blacklisted'],
      university: json['university'],
      totalProperties: json['total_properties'] != null ? int.tryParse(json['total_properties'].toString()) : null,
      totalRooms: json['total_rooms'] != null ? int.tryParse(json['total_rooms'].toString()) : null,
      occupancyRate: json['occupancy_rate']?.toDouble(),
      createdAt: json['created_at'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class ApiService {
  static Future<User> getUserProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/user/profile/?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  // Hostel Management Methods

  static Future<Map<String, dynamic>> createHostel({
    required String landlordEmail,
    required String name,
    required String address,
    required String description,
    required List<String> amenities,
    required double latitude,
    required double longitude,
    required double pricePerMonth,
  }) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/hostels/'),
      );

      // Add all fields directly to the form data
      request.fields['landlord_email'] = landlordEmail;
      request.fields['name'] = name;
      request.fields['address'] = address;
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['price_per_month'] = pricePerMonth.toString();
      
      // Add amenities as a JSON-encoded array
      request.fields['amenities'] = jsonEncode(amenities);

      // Print the request for debugging


      // Send the request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseData);
      } else {

        throw Exception('Failed to create hostel: ${response.statusCode} - $responseData');
      }
    } catch (e) {

      rethrow;
    }
  }


  static Future<List<Map<String, dynamic>>> getAllHostels() async {
    try {
      const url = '$kBaseUrl/hostels/all-hostels';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );



      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {

        throw Exception('Failed to load hostels: ${response.statusCode}');
      }
    } catch (e) {

      throw Exception('Error fetching hostels: $e');
    }
  }

  

  static Future<List<Map<String, dynamic>>> getLandlordHostels(String landlordEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/?landlord_email=$landlordEmail'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load hostels');
      }
    } catch (e) {

      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getLandlordStats(String landlordEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/landlord/$landlordEmail/stats/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'totalProperties': data['total_properties'] ?? 0,
          'totalRooms': data['total_rooms'] ?? 0,
          'occupancyRate': data['occupancy_rate']?.toDouble() ?? 0.0,
        };
      } else {
        throw Exception('Failed to load landlord statistics');
      }
    } catch (e) {

      return {
        'totalProperties': 0,
        'totalRooms': 0,
        'occupancyRate': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> getHostel(String hostelId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/$hostelId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load hostel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hostel: $e');
    }
  }

  static Future<Map<String, dynamic>> updateHostel({
    required String hostelId,
    String? name,
    String? address,
    String? description,
    Map<String, dynamic>? amenities,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (description != null) body['description'] = description;
      if (amenities != null) body['amenities'] = amenities;
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }

      final response = await http.put(
        Uri.parse('$kBaseUrl/hostels/$hostelId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update hostel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating hostel: $e');
    }
  }

  static Future<void> deleteHostel(String hostelId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/hostels/$hostelId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete hostel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting hostel: $e');
    }
  }

  // Room Management Methods

  static Future<Map<String, dynamic>> createRoom({
  required String hostelId,
  required String roomNumber,
  required String roomType,
  required int capacity,
  required double pricePerMonth,
  String? description,
  required String landlordEmail,
}) async {
  try {
    // Create a multipart request for form data
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/rooms/'),
    );

    // Add form fields
    request.fields['hostel_id'] = hostelId;
    request.fields['room_number'] = roomNumber;
    request.fields['room_type'] = roomType;
    request.fields['capacity'] = capacity.toString();
    request.fields['price_per_month'] = pricePerMonth.toString();
    request.fields['landlord_email'] = landlordEmail;
    
    if (description != null) {
      request.fields['description'] = description;
    }

    // Send the request
    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseData);
    } else {

      throw Exception('Failed to create room: ${response.statusCode} - $responseData');
    }
  } catch (e) {

    rethrow;
  }
}

static Future<Map<String, dynamic>> uploadRoomImage({
  required String roomId,
  required File imageFile,
  required String uploaderEmail,
  bool isCover = true,
  int displayOrder = 0,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/rooms/$roomId/media'),
    );

    // Add the image file
    final file = await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      filename: 'room_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    request.files.add(file);

    // Add form fields
    request.fields.addAll({
      'uploader_email': uploaderEmail,
      'is_cover': isCover.toString(),
      'display_order': displayOrder.toString(),
      'media_type': 'image',
    });

    // Send the request
    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseData);
    } else {

      throw Exception('Failed to upload room image: ${response.statusCode} - $responseData');
    }
  } catch (e) {

    rethrow;
  }
}

  static Future<Map<String, dynamic>> getRoom(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/rooms/$roomId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching room: $e');
    }
  }

  static Future<Map<String, dynamic>> updateRoom({
    required String roomId,
    String? roomNumber,
    String? roomType,
    int? capacity,
    double? pricePerMonth,
    String? description,
    bool? isOccupied,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (roomNumber != null) body['room_number'] = roomNumber;
      if (roomType != null) body['room_type'] = roomType;
      if (capacity != null) body['capacity'] = capacity;
      if (pricePerMonth != null) body['price_per_month'] = pricePerMonth;
      if (description != null) body['description'] = description;
      if (isOccupied != null) body['is_occupied'] = isOccupied;

      final response = await http.put(
        Uri.parse('$kBaseUrl/rooms/$roomId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating room: $e');
    }
  }

  static Future<void> deleteRoom(String roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/rooms/$roomId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting room: $e');
    }
  }

  // Media Management Methods

  static Future<Map<String, dynamic>> uploadHostelMedia({
    required String hostelId,
    required String filePath,
    required String fileName,
    required String mediaType,
    required String uploaderEmail,
    bool isCover = false,
    int displayOrder = 0,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/hostels/$hostelId/media/'),
      );
      
      request.fields['media_type'] = mediaType;
      request.fields['is_cover'] = isCover.toString();
      request.fields['display_order'] = displayOrder.toString();
      request.fields['uploader_email'] = uploaderEmail;
      
      final file = await http.MultipartFile.fromPath('file', filePath);
      request.files.add(file);
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading media: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHostelMedia(String hostelId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/$hostelId/media'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((media) => Map<String, dynamic>.from(media)).toList();
      } else {
        throw Exception('Failed to load hostel media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hostel media: $e');
    }
  }

static Future<List<Map<String, dynamic>>> getRoomMedia(
  String roomId, {
  required String hostelName,
  required String roomNumber,
}) async {
  try {
    final response = await http.get(
      Uri.parse('$kBaseUrl/rooms/$roomId/media/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((media) => {
        'url': media['url'] as String, // Full URL from the database
        'type': media['media_type'] ?? 'image',
        'is_cover': media['is_cover'] ?? false,
        'id': media['media_id']?.toString(),
      }).toList();
    } else {

      return [];
    }
  } catch (e) {

    return [];
  }
}
  static Future<void> deleteMedia(String mediaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/media/$mediaId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting media: $e');
    }
  }

  static Future<void> setMediaAsCover(String mediaId) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/media/$mediaId/cover'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set media as cover: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting media as cover: $e');
    }
  }
}
