import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/room_video_player.dart';
import '../../../config.dart';

class RoomCard extends StatefulWidget {
  final Map<String, dynamic> room;
  final Future<void> Function() onBook;

  const RoomCard({super.key, required this.room, required this.onBook});

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isBooking = false;

  bool get hasVideo {
    if (widget.room['media'] != null && widget.room['media'] is List) {
      final hasVid = (widget.room['media'] as List).any((media) =>
        media is Map &&
        (media['type'] == 'video' || media['media_type'] == 'video')
      );
      return hasVid;
    }
   return false;
  }

Widget _buildVideoPlayer(String roomImageUrl) {
  if (!hasVideo) {
    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text(
          'No video available',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  final videoMedia = (widget.room['media'] as List<dynamic>).firstWhere(
    (media) => media is Map<String, dynamic> && 
              (media['type'] == 'video' || media['media_type'] == 'video'),
    orElse: () => <String, dynamic>{},
  );

  if (videoMedia.isEmpty) {
    return const SizedBox.shrink();
  }

  final rawVideoUrl = videoMedia['url']?.toString() ?? '';
  final videoUrl = _buildMediaUrl(rawVideoUrl);
  


  // Add URL validation
  if (videoUrl.isEmpty) {
    return Container(
      height: 50,
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: const Text(
        'Invalid video URL',
        style: TextStyle(color: Colors.orange, fontSize: 14),
      ),
    );
  }

  return Container(
    height: 200,
    width: double.infinity,
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(8),
    ),
    child: RoomVideoPlayer(
      videoUrl: videoUrl,
      thumbnailUrl: roomImageUrl,
    ),
  );
}

String _buildMediaUrl(String url) {
 

  if (url.isEmpty) return '';

  String input = url.trim();

  // Handle the most common broken pattern from your backend
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
        .replaceAll(r'\', '/')
        .split('/')
        .where((s) => s.isNotEmpty)
        .map((segment) => Uri.encodeComponent(segment.trim()))
        .join('/');

    final fixed = '$protocol$ip:$port/uploads/$uuid/$cleanPath';
    ('FIXED BROKEN URL → $fixed');
    return fixed;
  }

  // If it's a proper full URL
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

  // Relative path fallback
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
  @override
  Widget build(BuildContext context) {
    String roomImageUrl = 'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=400';
    if (widget.room['image_url'] != null && widget.room['image_url'].toString().isNotEmpty) {
      roomImageUrl = '$kBaseUrl${widget.room['image_url']}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha:0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              roomImageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 180,
                color: AppColors.primary.withValues(alpha:0.1),
                child: const Center(
                  child: Icon(
                    Icons.bed_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),

          // Video Player Section
          _buildVideoPlayer(roomImageUrl),

          // Room Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${widget.room['room_number'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha:0.1),
                            AppColors.primaryLight.withValues(alpha:0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha:0.2),
                        ),
                      ),
                      child: Text(
                        widget.room['type']?.toString().toUpperCase() ?? 'STANDARD',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MKW ${widget.room['price_per_month']?.toStringAsFixed(0) ?? 'N/A'}/month',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                            widget.room['booking_fee'] != null && (widget.room['booking_fee'] as num) > 0
                                ? 'Booking Fee: MWK ${(widget.room['booking_fee'] as num).toStringAsFixed(2)}'
                                : 'No booking fee',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (widget.room['capacity'] != null)
                          Text(
                            'Capacity: ${widget.room['capacity']} person${widget.room['capacity'] == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _isBooking ? null : () async {
                        setState(() {
                          _isBooking = true;
                        });
                        
                        try {
                          await widget.onBook();
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isBooking = false;
                            });
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isBooking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (widget.room['is_available'] == true)
                        ? AppColors.success.withValues(alpha:0.1)
                        : AppColors.error.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (widget.room['is_available'] == true)
                          ? AppColors.success.withValues(alpha:0.3)
                          : AppColors.error.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (widget.room['is_available'] == true)
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        size: 16,
                        color: (widget.room['is_available'] == true)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (widget.room['is_available'] == true) ? 'Available' : 'Occupied',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (widget.room['is_available'] == true)
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}