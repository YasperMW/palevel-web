
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../config.dart';
import 'add_room_screen.dart';
import 'edit_property_screen.dart';
import 'edit_room_screen.dart';
import 'room_details_screen.dart';
import '../../widgets/room_video_player.dart';
import '../../widgets/location_map_dialog.dart';
import '../../services/media_service.dart';
import '../../services/room_service.dart';
import '../../services/review_service.dart';
import '../../services/hostel_service.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String hostelId;
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({
    super.key,
    required this.hostelId,
    required this.property,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _media = [];
  bool _isLoading = true;
  bool _isMediaLoading = true;
  String? _error;
  int _currentImageIndex = 0;

  final ReviewService _reviewService = ReviewService();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  bool _showReviews = false;
  String _selectedReviewFilter = 'Newest';

  final MediaService _mediaService = MediaService();
  final HostelService _hostelService = HostelService();
  bool _isActive = true;

  Map<String, dynamic>? _fullHostelData;
  bool _isLoadingFullHostel = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isActive = widget.property['is_active'] ?? true;
    
    // Debug: Print the property data
    //todo: add toast;
    widget.property.forEach((key, value) {

    });

    
    // Parse booking fee
    _parseBookingFee();
    _loadRooms();
    _loadMedia();
    _reviewsFuture = _reviewService.getReviewsForHostel(widget.hostelId);
    
    // Fetch full hostel data if coordinates are missing
    _loadFullHostelDataIfNeeded();
  }

  Future<void> _toggleHostelStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _hostelService.toggleHostelStatus(widget.hostelId);
      
      if (mounted) {
        setState(() {
          _isActive = !_isActive;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isActive ? 'Property activated successfully' : 'Property deactivated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update property status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _parseBookingFee() {
    try {
      final dynamic fee = widget.property['booking_fee'];
      
      if (fee == null) {
        widget.property['booking_fee'] = 0.0;
      } else if (fee is int) {
        widget.property['booking_fee'] = fee.toDouble();
      } else if (fee is double) {
        widget.property['booking_fee'] = fee;
      } else if (fee is String) {
        widget.property['booking_fee'] = double.tryParse(fee) ?? 0.0;
      } else if (fee is num) {
        widget.property['booking_fee'] = fee.toDouble();
      } else {
        widget.property['booking_fee'] = 0.0;
      }
    } catch (e) {
      widget.property['booking_fee'] = 0.0;
    }
  }

  Future<void> _loadFullHostelDataIfNeeded() async {
    // Check if coordinates are missing or zero from current data
    final currentData = _fullHostelData ?? widget.property;
    final lat = currentData['latitude'];
    final lng = currentData['longitude'];
    
    debugPrint('=== LANDLORD COORDINATE CHECK ===');
    debugPrint('Current data keys: ${currentData.keys.toList()}');
    debugPrint('Latitude: $lat (type: ${lat.runtimeType})');
    debugPrint('Longitude: $lng (type: ${lng.runtimeType})');
    debugPrint('Is loading: $_isLoadingFullHostel');
    debugPrint('Has full data: ${_fullHostelData != null}');
    
    // Don't fetch if we're already loading or already have full data
    if (_isLoadingFullHostel || _fullHostelData != null) {
      debugPrint('SKIPPING: Already loading or have data');
      return;
    }
    
    if (lat == null || lng == null || 
        (lat is num && lat == 0.0) || 
        (lng is num && lng == 0.0)) {
      debugPrint('FETCHING: Coordinates missing or zero');
      // Fetch full hostel data to get coordinates
      try {
        setState(() {
          _isLoadingFullHostel = true;
        });
        final hostelService = HostelService();
        _fullHostelData = await hostelService.getHostel(widget.hostelId);
        debugPrint('FETCHED DATA: ${_fullHostelData?.keys.toList()}');
        debugPrint('FETCHED LAT: ${_fullHostelData?['latitude']}');
        debugPrint('FETCHED LNG: ${_fullHostelData?['longitude']}');
        setState(() {
          _isLoadingFullHostel = false;
        });
      } catch (e) {
        debugPrint('Error loading full hostel data: $e');
        setState(() {
          _isLoadingFullHostel = false;
        });
      }
    } else {
      debugPrint('COORDINATES OK: Not fetching');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Map to store room images with room ID as key
  final Map<String, List<Map<String, dynamic>>> _roomImages = {};
  final Map<String, int> _currentImageIndices = {};
  final Map<String, bool> _isLoadingRoomImages = {};

  String _formatRelativeTime(dynamic createdAt) {
    if (createdAt == null) return '';
    DateTime? dt;
    if (createdAt is String) {
      try {
        dt = DateTime.parse(createdAt).toLocal();
      } catch (_) {}
    } else if (createdAt is DateTime) {
      dt = createdAt.toLocal();
    }
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '$weeks week${weeks == 1 ? '' : 's'} ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months month${months == 1 ? '' : 's'} ago';
    final years = (diff.inDays / 365).floor();
    return '$years year${years == 1 ? '' : 's'} ago';
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await RoomService.getHostelRooms(widget.hostelId, userType: 'landlord');
      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
      
      // Load images for each room
      for (var room in rooms) {
        _loadRoomImages(
          room['room_id'],
          hostelName: widget.property['hostel_name'] ?? 'Unknown Hostel',
          roomNumber: room['room_number']?.toString() ?? 'Unknown',
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadRoomImages(String roomId, {required String hostelName, required String roomNumber}) async {
    if (_isLoadingRoomImages[roomId] == true) return;

    setState(() {
      _isLoadingRoomImages[roomId] = true;
    });
    
    try {
      final response = await _mediaService.getRoomMedia(roomId);
      
      // Generate thumbnails for videos if not provided by the backend
      final processedMedia = await Future.wait(response.map((media) async {
        if (media['media_type'] == 'video' && media['thumbnail_url'] == null) {
          try {
            // This is a simplified example - in a real app, you'd want to generate
            // thumbnails on the server side or use a proper thumbnail generation service
            // For now, we'll just set a flag to indicate it's a video
            return {
              ...media,
              'is_video': true,
            };
          } catch (e) {

            return media;
          }
        }
        return media;
      }));
      
      if (mounted) {
        setState(() {
          _roomImages[roomId] = processedMedia;
          _isLoadingRoomImages[roomId] = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _isLoadingRoomImages[roomId] = false;
        });
      }
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isMediaLoading = true;
    });

    try {
      final media = await _mediaService.getHostelMedia(widget.hostelId);
      setState(() {
        _media = media;
        _isMediaLoading = false;
      });
    } catch (e) {
      setState(() {
        _isMediaLoading = false;
      });
      // Don't show error for media loading to avoid blocking the UI
    }
  }


  Future<void> _navigateToEditProperty() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPropertyScreen(property: Map<String, dynamic>.from(widget.property)),
      ),
    );

    // If the edit was successful (result is the updated property), refresh the details
    if (result is Map<String, dynamic> && mounted) {
      // Update the property with the new values
      setState(() {
        widget.property.clear();
        widget.property.addAll(Map<String, dynamic>.from(result));
        // Re-parse the booking fee to ensure it's in the correct format
        _parseBookingFee();
      });
      
      // Clear and reload rooms and media
      _rooms.clear();
      _media.clear();
      _loadRooms();
      _loadMedia();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Text(
            widget.property['name'] ?? 'Property Details',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        backgroundColor: const Color(0xFF07746B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Rooms'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProperty,
            tooltip: 'Edit Property',
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _isLoading ? null : _toggleHostelStatus,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
            icon: Icon(_isActive ? Icons.toggle_on : Icons.toggle_off, size: 28),
            label: Text(_isActive ? 'Active' : 'Inactive'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDetailsTab(),
          _buildRoomsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddRoomScreen(hostelId: widget.hostelId),
            ),
          ).then((_) => _loadRooms());
        },
        backgroundColor: const Color(0xFF07746B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showReviews = !_showReviews;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF07746B).withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF07746B).withValues(alpha:0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.reviews_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Reviews',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF07746B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'See what students are saying about this property',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _showReviews ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF07746B),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: const SizedBox(height: 12),
          crossFadeState:
              _showReviews ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (_showReviews)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF07746B),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Failed to load reviews.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade400,
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No reviews yet for this property.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              }
              // Create a sorted copy based on selected filter
              final sortedReviews = List<Map<String, dynamic>>.from(reviews);
              sortedReviews.sort((a, b) {
                final createdA = a['created_at'];
                final createdB = b['created_at'];
                DateTime? dtA;
                DateTime? dtB;
                if (createdA is String) {
                  try {
                    dtA = DateTime.parse(createdA).toLocal();
                  } catch (_) {}
                } else if (createdA is DateTime) {
                  dtA = createdA.toLocal();
                }
                if (createdB is String) {
                  try {
                    dtB = DateTime.parse(createdB).toLocal();
                  } catch (_) {}
                } else if (createdB is DateTime) {
                  dtB = createdB.toLocal();
                }

                final ratingA = (a['rating'] ?? 0).toDouble();
                final ratingB = (b['rating'] ?? 0).toDouble();

                switch (_selectedReviewFilter) {
                  case 'Oldest':
                    if (dtA == null || dtB == null) return 0;
                    return dtA.compareTo(dtB);
                  case 'Highest rating':
                    return ratingB.compareTo(ratingA);
                  case 'Lowest rating':
                    return ratingA.compareTo(ratingB);
                  case 'Newest':
                  default:
                    if (dtA == null || dtB == null) return 0;
                    return dtB.compareTo(dtA);
                }
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Newest'),
                          selected: _selectedReviewFilter == 'Newest',
                          onSelected: (_) {
                            setState(() {
                              _selectedReviewFilter = 'Newest';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Oldest'),
                          selected: _selectedReviewFilter == 'Oldest',
                          onSelected: (_) {
                            setState(() {
                              _selectedReviewFilter = 'Oldest';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Highest rating'),
                          selected: _selectedReviewFilter == 'Highest rating',
                          onSelected: (_) {
                            setState(() {
                              _selectedReviewFilter = 'Highest rating';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Lowest rating'),
                          selected: _selectedReviewFilter == 'Lowest rating',
                          onSelected: (_) {
                            setState(() {
                              _selectedReviewFilter = 'Lowest rating';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sortedReviews.map((review) {
                  final double rating = (review['rating'] ?? 0).toDouble();
                  final String comment = (review['comment'] ?? '').toString();
                  final String studentName =
                      (review['student_name'] ?? 'Student').toString();
                  final String relativeTime =
                      _formatRelativeTime(review['created_at']);

                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF07746B).withValues(alpha:0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  const Color(0xFF07746B).withValues(alpha:0.15),
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: Color(0xFF07746B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF07746B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 14,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.amber.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (relativeTime.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          relativeTime,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (comment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            comment,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
              );
            },
          ),
      ],
    );
  }

  String _getFormattedPrice(dynamic price) {
    if (price == null) return 'Not specified';
    
    try {
      // Try to parse as double first, then as int if that fails
      final doubleValue = price is num 
          ? price.toDouble() 
          : double.tryParse(price.toString()) ?? 0.0;
          
      if (doubleValue <= 0) return 'Not specified';
      
      // Format with comma as thousand separator and no decimal places
      final formatter = NumberFormat('#,##0', 'en_US');
      return 'MWK ${formatter.format(doubleValue)} / month';
    } catch (e) {

      return 'Not specified';
    }
  }
  
  String _getFormattedBookingFee(dynamic fee) {
    if (fee == null) return 'Not specified';
    
    try {
      // Try to parse as double first, then as int if that fails
      final doubleValue = fee is num 
          ? fee.toDouble() 
          : double.tryParse(fee.toString()) ?? 0.0;
          
      if (doubleValue <= 0) return 'Free';
      
      // Format with comma as thousand separator and no decimal places
      final formatter = NumberFormat('#,##0', 'en_US');
      return 'MWK ${formatter.format(doubleValue)} (one-time)';
    } catch (e) {

      return 'Not specified';
    }
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Images Carousel
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Loading or Empty State
                  if (_isMediaLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_media.isEmpty)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF07746B),
                            Color(0xFF0DDAC9),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.white.withValues(alpha:0.8),
                        ),
                      ),
                    )
                  // Image Carousel
                  else
                    Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              PageView.builder(
                                itemCount: _media.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final media = _media[index];
                                  // The URL from the backend is relative to the uploads directory
                                  final imageUrl = '$kBaseUrl/uploads/${media['url']}';
                                  
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.error),
                                    ),
                                  );
                                },
                              ),
                              if (_media.length > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 10,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(_media.length, (index) {
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _currentImageIndex == index
                                              ? const Color(0xFF07746B)
                                              : Colors.grey[400],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Dots indicator
                        if (_media.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _media.asMap().entries.map((entry) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key
                                        ? const Color(0xFF07746B)
                                        : Colors.grey[400],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (widget.property['is_active'] == true)
                            ? Colors.green.withValues(alpha:0.9)
                            : Colors.orange.withValues(alpha:0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.property['is_active'] == true ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          /// Property Details Section
Text(
  'Property Details',
  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
    color: const Color(0xFF07746B),
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 16),

// Property Name and Type
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: Text(
        widget.property['name'] ?? 'Unnamed Property',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    ),
    if (widget.property['type'] != null)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF07746B).withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.property['type'] ?? '',
          style: const TextStyle(
            color: Color(0xFF07746B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
  ],
),
const SizedBox(height: 12),

// Property Description
if (widget.property['description'] != null && widget.property['description'].toString().isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      widget.property['description'],
      style: TextStyle(
        fontSize: 15,
        color: Colors.grey[800],
        height: 1.5,
      ),
    ),
  ),

// Property Info Rows
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[50],
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey[200]!),
  ),
  child: Column(
    children: [
      // Location Information
      _buildInfoRow('Address', widget.property['address'] ?? 'Not specified'),
      const Divider(height: 24),
      _buildInfoRow('District', widget.property['district'] ?? 'Not specified'),
      if (widget.property['university'] != null) ...[
        const Divider(height: 24),
        _buildInfoRow('University', widget.property['university']),
      ],
      
      // Pricing Information
      const Divider(height: 24),
      _buildInfoRow(
        'Pricing',
        _getFormattedPrice(widget.property['price_per_month']),
      ),
      const Divider(height: 24),
      _buildInfoRow(
        'Booking Fee',
        widget.property['booking_fee'] != null ? _getFormattedBookingFee(widget.property['booking_fee']) : 'Not specified',
      ),
      
      // Room Statistics
      const Divider(height: 24),
      _buildInfoRow(
        'Rooms',
        '${widget.property['total_rooms'] ?? 0} total • '
        '${widget.property['occupied_rooms'] ?? 0} occupied • '
        '${widget.property['available_rooms'] ?? 0} available',
      ),
      
      // Dates
      const Divider(height: 24),
      _buildInfoRow(
        'Listed',
        widget.property['created_at']?.substring(0, 10) ?? 'N/A',
      ),
      if (widget.property['updated_at'] != null) ...[
        const Divider(height: 24),
        _buildInfoRow(
          'Last Updated',
          widget.property['updated_at']?.substring(0, 10) ?? 'N/A',
        ),
      ],
    ],
  ),
),
          const SizedBox(height: 24),
          
          // Amenities
          if (widget.property['amenities'] != null)
            _buildAmenitiesSection(),

          const SizedBox(height: 24),

          _buildReviewsSection(),
          
          const SizedBox(height: 24),
          
          // Location - Always show since every hostel has a location
          _buildLocationSection(),
        ],
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
  // Handle different formats of amenities
  final amenities = widget.property['amenities'];
  List<String> amenitiesList = [];

  if (amenities is List) {
    amenitiesList = amenities.whereType<String>().toList();
  } else if (amenities is Map) {
    amenitiesList = amenities.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .whereType<String>()
        .toList();
  }

  if (amenitiesList.isEmpty) {
    return const SizedBox.shrink(); // Hide section if no amenities
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Amenities',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF07746B),
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          spacing: 8,
          runSpacing: 12,
          children: amenitiesList.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF07746B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF07746B).withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Color(0xFF07746B)),
                  const SizedBox(width: 6),
                  Text(
                    amenity.toString().splitMapJoin(
                      RegExp(r'[A-Z]'),
                      onMatch: (m) => ' ${m.group(0)}',
                      onNonMatch: (n) => n,
                    ).trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF07746B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}
  Widget _buildLocationSection() {
    // Use full hostel data if available, otherwise fall back to widget.property
    final hostelData = _fullHostelData ?? widget.property;
    
    // Extract latitude and longitude, handling different data types
    double? latitude;
    double? longitude;
    
    final lat = hostelData['latitude'];
    final lng = hostelData['longitude'];
    
    if (lat != null) {
      if (lat is num) {
        latitude = lat.toDouble();
      } else if (lat is String) {
        latitude = double.tryParse(lat);
      }
    }
    
    if (lng != null) {
      if (lng is num) {
        longitude = lng.toDouble();
      } else if (lng is String) {
        longitude = double.tryParse(lng);
      }
    }
    
    // If coordinates are still missing, try to fetch them
    if ((latitude == null || latitude == 0.0) || (longitude == null || longitude == 0.0)) {
      if (!_isLoadingFullHostel) {
        // Try to fetch full hostel data
        _loadFullHostelDataIfNeeded().then((_) {
          if (mounted) {
            setState(() {}); // Rebuild to show updated coordinates
          }
        });
      }
    }
    
    final hasValidLocation = latitude != null && 
                            longitude != null && 
                            latitude != 0.0 && 
                            longitude != 0.0 &&
                            latitude >= -90 && 
                            latitude <= 90 && 
                            longitude >= -180 && 
                            longitude <= 180;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF07746B),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _showLocationDialog,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF07746B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF07746B).withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Color(0xFF07746B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostelData['address'] ?? 'Address not specified',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF07746B),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasValidLocation)
                        Text(
                          'Tap to view on map',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        Text(
                          'Location coordinates not available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (hasValidLocation)
                  const Icon(
                    Icons.open_in_new,
                    size: 12,
                    color: Color(0xFF07746B),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLocationDialog() {
    // Use full hostel data if available, otherwise fall back to widget.property
    final hostelData = _fullHostelData ?? widget.property;
    
    // Extract latitude and longitude, handling different data types
    double? latitude;
    double? longitude;
    
    final lat = hostelData['latitude'];
    final lng = hostelData['longitude'];
    
    if (lat != null) {
      if (lat is num) {
        latitude = lat.toDouble();
      } else if (lat is String) {
        latitude = double.tryParse(lat);
      }
    }
    
    if (lng != null) {
      if (lng is num) {
        longitude = lng.toDouble();
      } else if (lng is String) {
        longitude = double.tryParse(lng);
      }
    }
    
    // If coordinates are still missing, try to fetch them (but only if not already loading)
    if ((latitude == null || latitude == 0.0) || (longitude == null || longitude == 0.0)) {
      if (!_isLoadingFullHostel && _fullHostelData == null) {
        // Try to fetch full hostel data
        _loadFullHostelDataIfNeeded().then((_) {
          if (mounted) {
            _showLocationDialog(); // Retry after loading
          }
        });
        return;
      } else {
        // Show message that coordinates are not available
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location coordinates not available'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    LocationMapDialog.show(
      context: context,
      latitude: latitude,
      longitude: longitude,
      title: hostelData['name'] ?? 'Property Location',
      address: hostelData['address'] ?? 'Unknown address',
      markerLabel: hostelData['name'],
      onGetDirections: () {
        // TODO: Add directions functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directions feature coming soon!')),
        );
      },
    );
  }

  Widget _buildRoomsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07746B)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Rooms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadRooms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bed_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Rooms Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first room to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rooms.length,
        itemBuilder: (context, index) {
          final room = _rooms[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildRoomCard(room),
          );
        },
      ),
    );
  }

  void _showVideoPlayerDialog(String videoUrl, {String? thumbnailUrl}) {
    ('VideoPlayer - Loading video from URL: $videoUrl');
    if (thumbnailUrl != null) {
      ('VideoPlayer - Thumbnail URL: $thumbnailUrl');
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: RoomVideoPlayer(
            videoUrl: videoUrl,
            thumbnailUrl: thumbnailUrl,
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(dynamic media) {
    final mediaUrl = '$kBaseUrl/uploads/${media['url']}';
    final isVideo = media['media_type'] == 'video';
    
    if (isVideo) {
      final thumbnailUrl = media['thumbnail_url'] != null 
          ? '$kBaseUrl/uploads/${media['thumbnail_url']}'
          : null;
          
      return GestureDetector(
        onTap: () => _showVideoPlayerDialog(mediaUrl, thumbnailUrl: thumbnailUrl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.videocam, size: 48, color: Colors.grey),
                    ),
                  )
                : Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.videocam, size: 48, color: Colors.grey),
                    ),
                  ),
            const Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.black54,
                child: Icon(
                  Icons.play_arrow,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: mediaUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final roomId = room['room_id'];
    final roomMedia = _roomImages[roomId] ?? [];
    final currentMediaIndex = _currentImageIndices[roomId] ?? 0;
    final isLoadingMedia = _isLoadingRoomImages[roomId] ?? false;
    
    // Separate videos and images - check both media_type and is_video flag
    final videos = roomMedia.where((m) => 
      (m['media_type'] == 'video' || m['is_video'] == true) && 
      m['url'] != null && m['url'].toString().isNotEmpty
    ).toList();
    
    // Only use non-video media for the carousel
    final images = roomMedia.where((m) => 
      m['media_type'] != 'video' && m['is_video'] != true
    ).toList();
    
    // Only use images for the carousel
    final carouselMedia = [...images];
    
 
    if (videos.isNotEmpty) {
      // Videos are handled separately, not in the carousel
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Media Carousel (Images only)
          if (isLoadingMedia)
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (carouselMedia.isNotEmpty)
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: carouselMedia.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndices[roomId] = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildMediaPreview(carouselMedia[index]);
                    },
                  ),
                  if (carouselMedia.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(carouselMedia.length, (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: currentMediaIndex == index
                                  ? const Color(0xFF07746B)
                                  : Colors.grey[400],
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
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF07746B).withValues(alpha:0.8),
                    const Color(0xFF0DDAC9).withValues(alpha:0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.white70),
                    SizedBox(height: 8),
                    Text('No images available', style: TextStyle(color: Colors.white70)),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF07746B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room['room_type'] ?? 'Standard',
                        style: TextStyle(
                          fontSize: 14,
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
                      fontSize: 12,
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
                const SizedBox(height: 12),
                if (room['description'] != null && room['description'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF07746B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomDetailsScreen(
                                hostelId: widget.hostelId,
                                room: room,
                                property: widget.property,
                              ),
                            ),
                          ).then((value) {
                            // Refresh rooms if any changes were made
                            if (value == true) {
                              _loadRooms();
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF07746B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditRoomScreen(
                              room: room,
                              hostelId: widget.hostelId,
                            ),
                          ),
                        ).then((value) {
                          // Refresh rooms if any changes were made
                          if (value == true) {
                            _loadRooms();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 

  Widget _buildRoomDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

}
