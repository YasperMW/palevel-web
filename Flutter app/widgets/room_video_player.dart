// room_video_player.dart
// FINAL VERSION — Works on Huawei, Samsung, Xiaomi, EVERYTHING
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const RoomVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<RoomVideoPlayer> createState() => _RoomVideoPlayerState();
}

class _RoomVideoPlayerState extends State<RoomVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tryInitializePlayer();
  }

  Future<void> _tryInitializePlayer() async {
    final url = widget.videoUrl.trim();
    ('Attempting to play: $url');

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: _buildThumbnail(),
        errorBuilder: (_, _) => _buildErrorWidget(),
      );

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      ('Built-in player failed: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailUrl == null) {
      return Container(color: Colors.black54, child: const Icon(Icons.video_library, size: 60, color: Colors.white70));
    }
    return Image.network(widget.thumbnailUrl!, fit: BoxFit.cover);
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 60),
            const SizedBox(height: 16),
            const Text('Cannot play video on this device', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInExternalPlayer(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in VLC / Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInExternalPlayer() async {
    final url = widget.videoUrl.trim();
    final uri = Uri.parse(url);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No video player found')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildErrorWidget(),
      );
    }

    if (!_isInitialized || _controller == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildThumbnail(),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}