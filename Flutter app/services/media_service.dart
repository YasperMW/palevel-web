import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config.dart';

class MediaService {
  static final MediaService _instance = MediaService._internal();
  
  factory MediaService() => _instance;
  
  MediaService._internal();

  Future<Map<String, dynamic>> uploadHostelMedia({
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

  Future<List<Map<String, dynamic>>> getHostelMedia(String hostelId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/$hostelId/media'),
        headers: {'Content-Type': 'application/json'},
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

  Future<List<Map<String, dynamic>>> getRoomMedia(
    String roomId,
   
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/rooms/$roomId/media/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((media) => {
          'url': media['url'] as String,
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

  Future<void> deleteMedia(String mediaId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/media/$mediaId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete media: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting media: $e');
    }
  }

  Future<void> setMediaAsCover(String mediaId) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/media/$mediaId/cover'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to set media as cover: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting media as cover: $e');
    }
  }
}
