import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config.dart';

class RoomService {
  static final RoomService _instance = RoomService._internal();
  
  factory RoomService() => _instance;
  
  RoomService._internal();

  Future<Map<String, dynamic>> createRoom({
    required String hostelId,
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double pricePerMonth,
    required String landlordEmail,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/rooms/'),
      );

      request.fields['hostel_id'] = hostelId;
      request.fields['room_number'] = roomNumber;
      request.fields['room_type'] = roomType;
      request.fields['capacity'] = capacity.toString();
      request.fields['price_per_month'] = pricePerMonth.toString();
      request.fields['landlord_email'] = landlordEmail;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to create room: \${response.statusCode} - $responseData');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadRoomImage({
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

      final file = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: 'room_\${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(file);

      request.fields.addAll({
        'uploader_email': uploaderEmail,
        'is_cover': isCover.toString(),
        'display_order': displayOrder.toString(),
        'media_type': 'image',
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to upload room image: \${response.statusCode} - $responseData');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRoom(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/rooms/$roomId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load room: \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching room: $e');
    }
  }

  Future<Map<String, dynamic>> updateRoom({
    required String roomId,
    String? roomNumber,
    String? roomType,
    int? capacity,
    double? pricePerMonth,
    bool? isOccupied,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/rooms/$roomId/update'),
      );

      if (roomNumber != null) request.fields['room_number'] = roomNumber;
      if (roomType != null) request.fields['room_type'] = roomType;
      if (capacity != null) request.fields['capacity'] = capacity.toString();
      if (pricePerMonth != null) request.fields['price_per_month'] = pricePerMonth.toString();
      if (isOccupied != null) request.fields['is_occupied'] = isOccupied.toString();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to update room: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Error updating room: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/rooms/$roomId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 409) {
        // Handle booking conflict error
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Cannot delete room with existing bookings');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to delete room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting room: $e');
    }
  }
  static Future<List<Map<String, dynamic>>> getHostelRooms(String hostelId, {String? userType}) async {
    try {
      var url = '$kBaseUrl/rooms?hostel_id=$hostelId';
      if (userType != null) {
        url += '&user_type=$userType';
      }

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

        throw Exception('Failed to load rooms: \${response.statusCode}');
      }
    } catch (e) {

      throw Exception('Error fetching rooms: $e');
    }
  }
}
