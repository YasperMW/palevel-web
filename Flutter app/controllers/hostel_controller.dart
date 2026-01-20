import 'package:flutter/foundation.dart';
import '../services/room_service.dart';
import '../services/media_service.dart';

class HostelController extends ChangeNotifier {
  final String hostelId;
  List<Map<String, dynamic>> rooms = [];
  bool isLoading = false;
  String? error;
  final MediaService _mediaService = MediaService();

  HostelController({required this.hostelId});

  Future<void> loadRooms() async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Load rooms first
      final fetched = await RoomService.getHostelRooms(hostelId, userType: 'student');
      
      // For each room, load its media
      final roomsWithMedia = await Future.wait(
        fetched.map((room) async {
          try {
            final media = await _mediaService.getRoomMedia(room['room_id'] ?? room['id']);
            return {
              ...room,
              'media': media,
            };
          } catch (e) {

            return {
              ...room,
              'media': [],
            };
          }
        }).toList(),
      );
      
      rooms = roomsWithMedia;
    } catch (e) {
      error = e.toString();
      rooms = [];

    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}