import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../config.dart' show kBaseUrl;
import 'edit_room_screen.dart';
import '../../widgets/room_video_player.dart';
import '../../services/media_service.dart';
import '../../services/room_service.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String hostelId;
  final Map<String, dynamic> room;
  final Map<String, dynamic> property;

  const RoomDetailsScreen({
    super.key,
    required this.hostelId,
    required this.room,
    required this.property,
  });

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final MediaService _mediaService = MediaService();
  final RoomService _roomService = RoomService();
  
  List<Map<String, dynamic>> _media = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  String? _error;
  

  @override
  void initState() {
    super.initState();
    _loadRoomMedia();
  }

  Future<void> _loadRoomMedia() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final media = await _mediaService.getRoomMedia(widget.room['room_id']);
      setState(() {
        _media = media;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final property = widget.property;
    
    // Separate images and videos
    final images = _media.where((m) => (m['type'] ?? 'image') == 'image').toList();
    final videos = _media.where((m) => (m['type'] ?? '') == 'video').toList();
    

    return Scaffold(
      appBar: AppBar(
        title: Text('Room ${room['room_number']} - ${property['hostel_name']}'),
        backgroundColor: const Color(0xFF07746B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : ListView(
                  children: [
                    // Image Carousel
                    if (images.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return _buildMediaPreview(images[index]);
                              },
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(images.length, (index) {
                                    return Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == index
                                            ? Colors.white
                                            : Colors.white.withValues(alpha:0.5),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No images available', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                    // Room Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07746B).withValues(alpha:0.1),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Room ${room['room_number'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF07746B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  room['room_type'] ?? 'Standard',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (room['is_occupied'] == true)
                                  ? Colors.red.withValues(alpha:0.9)
                                  : Colors.green.withValues(alpha:0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              room['is_occupied'] == true ? 'Occupied' : 'Available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Room Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Room Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF07746B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRoomDetail(
                                  'Capacity',
                                  '${room['capacity'] ?? 0} people',
                                  Icons.people,
                                ),
                              ),
                              Expanded(
                                child: _buildRoomDetail(
                                  'Price',
                                  'MK${room['price_per_month'] ?? 0}/mo',
                                  Icons.attach_money,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (room['description'] != null && room['description'].toString().isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF07746B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Video Section
                    ..._buildVideoSection(videos),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);

                                final value = await navigator.push(
                                  MaterialPageRoute(
                                    builder: (context) => EditRoomScreen(
                                      room: widget.room,
                                      hostelId: widget.hostelId,
                                    ),
                                  ),
                                );

                                if (!mounted) return;

                                if (value == true) {
                                  navigator.pop(true);
                                }

                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF07746B)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Edit Room',
                                style: TextStyle(
                                  color: Color(0xFF07746B),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _showDeleteRoomDialog(room['room_id']);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Delete Room',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
String _buildMediaUrl(String url) {
  

  if (url.isEmpty) return '';

  String input = url.trim();

  // STEP 1: Handle the most common broken pattern from your backend
  // Pattern: http://192.168.1.179:8888 + UUID + \backslashes + spaces
  final brokenFullUrlRegex = RegExp(
    r'^(https?://)([\d.]+):(\d+)([a-f0-9-]{36})(.*)$',
    caseSensitive: false,
  );

  final match = brokenFullUrlRegex.firstMatch(input);
  if (match != null) {
    final protocol = match.group(1)!; // http:// or https://
    final ip = match.group(2)!;       // 192.168.1.179
    final port = match.group(3)!;     // 8888
    final uuid = match.group(4)!;     // e15262e2-1c80-4ae0-985d-52a32bc8e7f0
    final rest = match.group(5)!;     // \Mzuzu Main Hostel\video.mp4

    // Fix backslashes and encode each path segment
    String cleanPath = rest
        .replaceAll(r'\', '/')
        .split('/')
        .where((s) => s.isNotEmpty)
        .map((segment) => Uri.encodeComponent(segment.trim()))
        .join('/');

    final fixed = '$protocol$ip:$port/uploads/$uuid/$cleanPath';
    ('FIXED BROKEN URL → $fixed');
    return fixed;
  }

  // STEP 2: If it's a proper full URL (unlikely but safe)
  if (input.startsWith('http')) {
    try {
      final uri = Uri.parse(input.replaceAll(r'\', '/'));
      final encodedSegments = uri.pathSegments
          .map((s) => Uri.encodeComponent(s))
          .join('/');
      final fixed = uri.replace(path: '/$encodedSegments').toString();
      ('Clean full URL → $fixed');
      return fixed;
    } catch (e) {
      ('Failed to parse as full URL: $e');
    }
  }

  // STEP 3: Relative path fallback
  String normalized = input.replaceAll(r'\', '/').replaceAll(RegExp(r'^/+'), '');
  final segments = normalized
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(Uri.encodeComponent)
      .join('/');
  final result = '$kBaseUrl/uploads/$segments';
  ('Built from relative → $result');
  return result;
}

  Widget _buildMediaPreview(Map<String, dynamic> media) {
    final mediaType = media['type'] ?? 'image';
    final mediaUrl = media['url'] ?? '';
    
    if (mediaType == 'image') {
      return CachedNetworkImage(
        imageUrl: _buildMediaUrl(mediaUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text('Failed to load image', 
                   style: TextStyle(color: Colors.grey[700])),
              Text('URL: ${_buildMediaUrl(mediaUrl).length > 50 ? '${_buildMediaUrl(mediaUrl).substring(0, 50)}...' : _buildMediaUrl(mediaUrl)}',
                   style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      );
    } else if (mediaType == 'video') {
      return GestureDetector(
        onTap: () {
          _showVideoPlayerDialog(
            mediaUrl.startsWith('http') ? mediaUrl : '$kBaseUrl$mediaUrl',
            thumbnailUrl: null, // We'll let the video player handle the thumbnail
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // For videos, we'll just show a placeholder with a play button
            Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.videocam, size: 48, color: Colors.grey)),
            ),
            const Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black54,
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      color: Colors.grey[200],
      child: const Center(child: Icon(Icons.error)),
    );
  }

  List<Widget> _buildVideoSection(List<dynamic> videos) {
    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: const Text(
          'Room Video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF07746B),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: videos.isNotEmpty
            ? _buildMediaPreview(videos.first)
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.videocam_off,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No video uploaded',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement add video functionality
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Video'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF07746B),
                        side: const BorderSide(color: Color(0xFF07746B)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildRoomDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: const Color(0xFF07746B),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showVideoPlayerDialog(String videoUrl, {String? thumbnailUrl}) {
    ('VideoPlayer - Original video URL: $videoUrl');
    final processedVideoUrl = _buildMediaUrl(videoUrl);
    ('VideoPlayer - Processed video URL: $processedVideoUrl');
    
    final processedThumbnailUrl = thumbnailUrl != null ? _buildMediaUrl(thumbnailUrl) : null;
    if (thumbnailUrl != null) {
      ('VideoPlayer - Original thumbnail URL: $thumbnailUrl');
      ('VideoPlayer - Processed thumbnail URL: $processedThumbnailUrl');
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RoomVideoPlayer(
                videoUrl: processedVideoUrl,
                thumbnailUrl: processedThumbnailUrl,
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoomDialog(String roomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: const Text(
            'Are you sure you want to delete this room? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRoom(roomId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _roomService.deleteRoom(roomId);
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();
          // Return to previous screen with success flag
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        // Hide loading indicator
        if (mounted) {
          Navigator.of(context).pop();

          // Show specific error message
          String errorMessage = 'Failed to delete room. Please try again.';
          if (e.toString().contains('Cannot delete room with') && e.toString().contains('booking')) {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        if (mounted) {
          // Return to previous screen with success flag
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Hide loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
