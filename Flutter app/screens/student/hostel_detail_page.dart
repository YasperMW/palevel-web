
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../services/user_session_service.dart';
import '../../controllers/hostel_controller.dart';
import '../../services/review_service.dart';
import '../../services/hostel_service.dart';
import 'widgets/room_card.dart';
import 'widgets/hostel_hero.dart';
import 'widgets/landlord_card.dart';
import '../../widgets/booking_dialog.dart';
import '../../widgets/location_map_dialog.dart';
import '../../models/hostel.dart';
import '../../services/booking_service.dart';
import '../payment_webview.dart';



class HostelDetailPage extends StatefulWidget {
  final Map<String, dynamic> hostel;

  const HostelDetailPage({super.key, required this.hostel});

  @override
  State<HostelDetailPage> createState() => _HostelDetailPageState();
}

class _HostelDetailPageState extends State<HostelDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final _currencyFormat = NumberFormat.currency(
    symbol: 'MWK ',
    decimalDigits: 2,
  );
  bool _isScrolled = false;
  late final HostelController _controller;
  int _selectedIndex = 0;
  final ReviewService _reviewService = ReviewService();
  late Future<List<Map<String, dynamic>>> _reviewsFuture;
  bool _showReviews = false;
  String _selectedReviewFilter = 'Newest';


  Map<String, dynamic>? _fullHostelData;
  bool _isLoadingFullHostel = false;

  @override
  void initState() {
    super.initState();

    final hostelId = widget.hostel['id']?.toString() ?? widget.hostel['hostel_id']?.toString() ?? '';
    _controller = HostelController(hostelId: hostelId);
    _controller.loadRooms();

    if (hostelId.isNotEmpty) {
      _reviewsFuture = _reviewService.getReviewsForHostel(hostelId);
      // Fetch full hostel data if coordinates are missing
      _loadFullHostelDataIfNeeded(hostelId);
    } else {
      _reviewsFuture = Future.value([]);
    }
    
    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 100;
      });
    });
  }

  Future<void> _loadFullHostelDataIfNeeded(String hostelId) async {
    // Check if coordinates are missing or zero
    final lat = widget.hostel['latitude'];
    final lng = widget.hostel['longitude'];
    
    debugPrint('=== STUDENT COORDINATE CHECK ===');
    debugPrint('Hostel data keys: ${widget.hostel.keys.toList()}');
    debugPrint('Latitude: $lat (type: ${lat.runtimeType})');
    debugPrint('Longitude: $lng (type: ${lng.runtimeType})');
    debugPrint('Is loading: $_isLoadingFullHostel');
    debugPrint('Has full data: ${_fullHostelData != null}');
    
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
        _fullHostelData = await hostelService.getHostel(hostelId);
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

  double _roundRating(double rating) {
    return (rating * 10).round() / 10.0;
  }

  String _formatRating(double rating) {
    return _roundRating(rating).toStringAsFixed(1);
  }

  Widget _buildReviewsSection(double rating, int reviewsCount) {
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
              color: AppColors.primary.withValues(alpha:0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha:0.2),
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
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Reviews & Ratings',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        reviewsCount > 0
                            ? '${_formatRating(rating)} • $reviewsCount review${reviewsCount == 1 ? '' : 's'}'
                            : 'No reviews yet. Be the first to review after!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _showReviews ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
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
                      color: AppColors.primary,
                    ),
                  ),
                );
              }

              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No reviews yet for this hostel.',
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
                 SizedBox(
                  height: 48, // Fixed height for the scrollable row
                  child: SingleChildScrollView(
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
                 ),
                  const SizedBox(height: 8),
                  ...sortedReviews.map((review) {
                  final dynamic rawRating = review['rating'];
                  final double r = rawRating is num ? rawRating.toDouble() : 0.0;
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
                        color: AppColors.primary.withValues(alpha:0.12),
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
                                  AppColors.primary.withValues(alpha:0.15),
                              child: Text(
                                studentName.isNotEmpty
                                    ? studentName[0].toUpperCase()
                                    : 'S',
                                style: const TextStyle(
                                  color: AppColors.primary,
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
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
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
                                        _formatRating(r),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final dynamic ratingValue = widget.hostel['rating'];
    double rating = 0.0;
    if (ratingValue is num) {
      rating = ratingValue.toDouble();
    } else if (ratingValue is String) {
      rating = double.tryParse(ratingValue) ?? 0.0;
    }
    rating = _roundRating(rating);
    final reviews = widget.hostel['reviews'] as int? ?? 0;
    final roomsAvailable = widget.hostel['rooms_available'] as int? ?? 0;
    final totalRooms = widget.hostel['total_rooms'] as int? ?? 0;



    final amenities = widget.hostel['amenities'] as List<dynamic>? ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.mainGradient,
            stops: [0.0, 0.2, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              _buildModernAppBar(context),
              
              // Content
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      setState(() {
                        _isScrolled = notification.metrics.pixels > 30;
                      });
                    }
                    return false;
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Hero Image
                          SliverToBoxAdapter(
                            child: _buildHeroImage(),
                          ),

                          // Content
                          SliverPadding(
                            padding: const EdgeInsets.all(24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                // Title and Rating
                                _buildTitleSection(rating, reviews),
                                const SizedBox(height: 20),

                                // Price and Location
                                _buildPriceLocationSection(),
                                const SizedBox(height: 24),

                                // Quick Info Cards - Show both total and available rooms
                                _buildQuickInfoCards(totalRooms, roomsAvailable, rating),
                                const SizedBox(height: 24),

                                // Reviews toggle section
                                _buildReviewsSection(rating, reviews),
                                const SizedBox(height: 24),

                                // Description
                                _buildDescriptionSection(),
                                const SizedBox(height: 24),

                                // Amenities
                                _buildAmenitiesSection(amenities),
                                const SizedBox(height: 24),

                                // Available Rooms
                                _buildAvailableRoomsSection(),
                                const SizedBox(height: 24),

                                // Landlord Info
                                _buildLandlordSection(),
                                const SizedBox(height: 100),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(context),
    );
  }

  Widget _buildModernAppBar(BuildContext context) {
    final verticalPadding = _isScrolled ? 8.0 : 12.0;
    final iconSize = _isScrolled ? 20.0 : 24.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: verticalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(_isScrolled ? 10 : 12),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Share Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(_isScrolled ? 10 : 12),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: iconSize,
              ),
              onPressed: () {
                // Share functionality
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    // Replaced by dedicated widget in widgets/hostel_hero.dart
    return HostelHero(hostel: widget.hostel);
  }

  Widget _buildTitleSection(double rating, int reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.hostel['title'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha:0.15),
                    AppColors.primaryLight.withValues(alpha:0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha:0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.hostel['type'],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceLocationSection() {
    return Row(
      children: [
        // Price - Fixed width
        Container(
          padding: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MK',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(widget.hostel['price'] / 1000).toStringAsFixed(0)}k',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Text(
                '/month',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Location - Takes remaining space
        Expanded(
          child: GestureDetector(
            onTap: _showLocationDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hostel['address'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view location',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        // Distance temporarily hidden
                        // if (widget.hostel['distance'] != null)
                        //   Row(
                        //     children: [
                        //       Text(
                        //         '${widget.hostel['distance']} km from campus',
                        //         style: TextStyle(
                        //           fontSize: 12,
                        //           color: Colors.grey.shade600,
                        //         ),
                        //         maxLines: 1,
                        //         overflow: TextOverflow.ellipsis,
                        //       ),
                        //       const SizedBox(width: 4),
                        //       const Icon(
                        //         Icons.open_in_new,
                        //         size: 12,
                        //         color: AppColors.primary,
                        //       ),
                        //     ],
                        //   ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCards(int totalRooms, int roomsAvailable, double rating) {
    final List<Map<String, dynamic>> cards = [
      {
        'icon': Icons.bed_rounded,
        'title': 'Total Rooms',
        'value': '$totalRooms',
        'color': AppColors.primary,
      },
      {
        'icon': Icons.king_bed_rounded,
        'title': 'Available',
        'value': '$roomsAvailable',
        'color': AppColors.primaryLight,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Rating',
        'value': rating > 0 ? _formatRating(rating) : 'N/A',
        'color': AppColors.rating,
      },
      {
        'icon': Icons.reviews_rounded,
        'title': 'Reviews',
        'value': '${widget.hostel['reviews'] ?? '0'}',
        'color': AppColors.info,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _buildInfoCard(
          icon: cards[index]['icon'] as IconData,
          title: cards[index]['title'] as String,
          value: cards[index]['value'] as String,
          color: cards[index]['color'] as Color,
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha:0.1),
            color.withValues(alpha:0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha:0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.1,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 9,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.hostel['description'],
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey.shade700,
            height: 1.6,
          ),
        ),
      ],
    );
  }
  Widget _buildAmenitiesSection(List<dynamic> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the available width for each item
            final itemWidth = (constraints.maxWidth - 16) / 3; // 16 = 2 * 8 (spacing)
            
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) {
                final amenityText = amenity.toString();
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: itemWidth,
                    maxWidth: itemWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getAmenityIcon(amenityText),
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 4),
                        Flexible(
                          child: Text(
                            amenityText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAvailableRoomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Rooms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            if (_controller.rooms.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha:0.1),
                      AppColors.primaryLight.withValues(alpha:0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha:0.2),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bed_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'No rooms available',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: _controller.rooms
                  .map((room) => RoomCard(room: room, onBook: () => _bookRoom(room)))
                  .toList(),
            );
          },
        ),
      ],
    );
  }




// In hostel_detail_page.dart

  Future<void> _bookRoom(Map<String, dynamic> room) async {
    // Store context in a local variable before any async operations
    final currentContext = context;
    

    try {
      // 1. Get user details
      final userProfile = await UserSessionService.getCachedUserData();
      if (!mounted) return;
      
      final userEmail = await UserSessionService.getUserEmail();
      if (userEmail == null) {
        if (!mounted) return;
        // Use the current context directly since we just checked mounted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to book a room')),
          );
        }
        return;
      }

      // 2. Check if user has an active confirmed booking
      try {
        final bookingServiceCheck = BookingService();
        final userBookings = await bookingServiceCheck.getUserBookings();
        if (userBookings.isNotEmpty) {
          final now = DateTime.now();
          bool hasActiveConfirmed = false;
          Map<String, dynamic>? activeBooking;

          for (final b in userBookings) {
            final statusRaw = (b['status'] ?? b['booking_status'] ?? '').toString().toLowerCase();
            if (!statusRaw.contains('confirm')) continue;

            final checkOutStr = (b['check_out_date'] ?? b['checkOut'] ?? b['check_out'] ?? '').toString();
            final checkInStr = (b['check_in_date'] ?? b['checkIn'] ?? b['check_in'] ?? '').toString();

            DateTime? checkOut = DateTime.tryParse(checkOutStr);
            DateTime? checkIn = DateTime.tryParse(checkInStr);
            if (checkOut != null) checkOut = checkOut.toLocal();
            if (checkIn != null) checkIn = checkIn.toLocal();

            // Consider booking active if its check-out date is today or in the future
            if (checkOut == null) {
              hasActiveConfirmed = true;
              activeBooking = b as Map<String, dynamic>?;
              break;
            }

            if (!now.isAfter(checkOut)) {
              hasActiveConfirmed = true;
              activeBooking = b as Map<String, dynamic>?;
              break;
            }
          }

          if (hasActiveConfirmed) {
            final hostelName = (activeBooking?['room']?['hostel']?['name'] ??
                activeBooking?['room']?['hostel_name'] ??
                activeBooking?['hostel_name'] ??
                '')
                .toString();
            final roomNum =
            (activeBooking?['room']?['room_number'] ?? activeBooking?['room_number'] ?? '')
                .toString();
            final checkOutStr =
            (activeBooking?['check_out_date'] ?? activeBooking?['checkOut'] ?? '').toString();
            final parsedCheckOut = DateTime.tryParse(checkOutStr);
            final formattedCheckOut =
            parsedCheckOut != null ? parsedCheckOut.toLocal().toIso8601String().split('T')[0] : 'N/A';

            if (!currentContext.mounted) return;

            final proceed = await showDialog<bool>(
              context: currentContext,
              builder: (dialogCtx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: const Text('Active Booking Detected'),
                content: Text(
                  'You already have an active confirmed booking'
                      '${hostelName.isNotEmpty ? ' at $hostelName' : ''}'
                      '${roomNum.isNotEmpty ? ' (Room $roomNum)' : ''}'
                      ' until $formattedCheckOut. Do you want to continue and make another booking?',
                ),
                actions: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                      colors: AppColors.errorGradient,
                    ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                    ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (proceed != true) {
              return;
            }
          }

        }
      } catch (e) {
        // Non-blocking: if we fail to fetch bookings, allow the booking flow to continue

      }

      // 3. Show booking dialog
      if (!mounted) return;
      final result = await BookingDialog.show(
        context, 
        hostel: widget.hostel, 
        room: room,
        initialPhone: userProfile?.phoneNumber ?? '',
      );
      if (result == null || !mounted) return;

      // 3. Calculate end date
      final startDate = DateTime.parse(result['startDate']);
      final endDate = DateTime(
        startDate.year,
        startDate.month + (result['duration'] as int),
        startDate.day,
      );

      // Platform fee is a constant
      const double platformFee = 2500.0;
      
      // [REWRITTEN GENDER CHECK LOGIC]
      // Calculate the base amount (without platform fee)
      final double baseAmount;
      if (result['isFullPayment'] == true) {
        // 1. Get room and user gender specs, converting to lowercase for reliable comparison.


        // For full payment, subtract platform fee from the total
        baseAmount = (result['amount'] ?? 0).toDouble() - platformFee;
      } else if (result['isFullPayment'] == false) {
        // For booking fee, use the booking fee directly
        baseAmount = (result['bookingFee'] ?? room['booking_fee'] ?? 0).toDouble();
      } else {
        // Fallback: assume amount doesn't include platform fee
        baseAmount = (result['amount'] ?? 0).toDouble();
      }

      // 2. Determine if the gender combination is a mismatch.
      bool isMismatch = false;

      final roomSpec = (room['room_type'] ?? room['type'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      final userGenderLower =
      (await UserSessionService.getUserGender())?.toLowerCase();

// STRICT room gender parsing
      final bool isFemaleRoom = roomSpec.endsWith('-female');
      final bool isMaleRoom = roomSpec.endsWith('-male');
      final bool isMixedRoom = !isFemaleRoom && !isMaleRoom;

// Determine mismatch
      if (userGenderLower == 'male' && isFemaleRoom) {
        isMismatch = true;
      } else if (userGenderLower == 'female' && isMaleRoom) {
        isMismatch = true;
      }

// DEBUG
      debugPrint(
        'GenderCheck → user=$userGenderLower room=$roomSpec '
            'female=$isFemaleRoom male=$isMaleRoom mixed=$isMixedRoom '
            'mismatch=$isMismatch',
      );

// SHOW DIALOG IF MISMATCH
      if (isMismatch) {
        if (!currentContext.mounted) return;

        final bool? shouldProceed = await showDialog<bool>(
          context: currentContext,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Gender Mismatch Warning'),
            content: Text(
              'This room is reserved for '
                  '${isFemaleRoom ? 'female' : 'male'} residents.\n\n'
                  'Your profile is set to "$userGenderLower".\n\n'
                  'Do you want to proceed anyway?',
            ),
            actions: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.errorGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Proceed Anyway',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

          ),
        );

        // STOP booking if user cancels
        if (shouldProceed != true) {
          return;
        }
      }
      // [END GENDER CHECK LOGIC]

      // 4. Show confirmation dialog first
      if (!currentContext.mounted) return;

      final shouldProceed = await showDialog<bool>(
        context: currentContext,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Booking'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please confirm your booking details:'),
                const SizedBox(height: 12),
                Text('• Hostel: ${widget.hostel['name'] ?? widget.hostel['title'] ?? 'N/A'}'),
                Text('• Room: ${room['room_number'] ?? 'N/A'} (${room['room_type'] ?? room['type'] ?? 'N/A'})'),
                const SizedBox(height: 8),
                Text('• Check-in: ${result['startDate']}'),
                Text('• Check-out: ${endDate.toIso8601String().split('T')[0]}'),
                Text('• Duration: ${result['duration']} month${result['duration'] > 1 ? 's' : ''}'),
                const SizedBox(height: 12),
                const Text('Payment Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildFeeRow(
                  result['isFullPayment'] == true ? 'Room Rent' : 'Booking Fee',
                  baseAmount,
                ),
                _buildFeeRow('Platform Fee', platformFee),
                const Divider(),
                _buildFeeRow(
                  'Total Amount',
                  baseAmount + platformFee,
                  isTotal: true,
                ),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.errorGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm & Pay',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],

        ),
      );

      if (shouldProceed != true) return;

      // 5. Show loading
      if (!currentContext.mounted) return;

      // Show loading dialog and store its navigator context
      final loadingDialogContext = currentContext;
      showDialog(
        context: currentContext,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 6. Create booking and get payment URL
        final bookingService = BookingService();
        final paymentUrl = await bookingService.bookRoom(
          room: room,
          studentEmail: userEmail,
          startDate: result['startDate'],
          duration: result['duration'] is int 
              ? result['duration'] as int 
              : int.tryParse(result['duration'].toString()) ?? 1,
          phoneNumber: result['phoneNumber'] ?? userProfile?.phoneNumber ?? '',
          firstName: userProfile?.firstName ?? '',
          lastName: userProfile?.lastName ?? '',
          paymentType: (result['isFullPayment'] == true) ? 'full' : 'booking_fee',
        );

        if (!currentContext.mounted) return;

        Navigator.of(loadingDialogContext, rootNavigator: true).pop(); // Close loading

        // 7. Show loading for payment
        if (!mounted) return;
        final paymentLoadingContext = currentContext;
        showDialog(
          context: currentContext,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // 8. Check if we have a valid payment URL
          if (paymentUrl.isNotEmpty) {
            if (!mounted) return;
            Navigator.of(paymentLoadingContext, rootNavigator: true).pop(); // Close loading
            
            if (!mounted) return;
            await Navigator.push(
              currentContext,
              MaterialPageRoute(
                builder: (context) => PaymentWebView(
                  url: paymentUrl,
                ),
              ),
            );
              
            // After returning from webview, show success message
            if (!currentContext.mounted) return;

            // Use the stored context for showing snackbar
            if (ScaffoldMessenger.maybeOf(currentContext) != null) {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                const SnackBar(
                  content: Text('Payment Webview closed!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Failed to get payment URL');
          }
        } catch (e) {
          if (!mounted) return;
          if (Navigator.canPop(currentContext)) {
            Navigator.of(currentContext, rootNavigator: true).pop(); // Close loading
          }
          if (ScaffoldMessenger.maybeOf(currentContext) != null) {
            ScaffoldMessenger.of(currentContext).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (!mounted) return;
        if (Navigator.canPop(currentContext)) {
          Navigator.of(currentContext, rootNavigator: true).pop(); // Close loading if still open
        }
        if (ScaffoldMessenger.maybeOf(currentContext) != null) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text('Error during booking process: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Close any open dialogs
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } 
  }


// Helper method to build fee rows
Widget _buildFeeRow(String label, dynamic amount, {bool isTotal = false}) {
  final amountValue = (amount is num) 
      ? amount.toDouble() 
      : double.tryParse(amount.toString()) ?? 0.0;
      
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isTotal 
              ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              : null,
          ),
        ),
        Text(
          amountValue > 0 ? _currencyFormat.format(amountValue) : 'MWK 0.00',
          style: isTotal 
            ? const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              )
            : null,
        ),
      ],
    ),
  );
}

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi_rounded;
    } else if (lower.contains('laundry')) {
      return Icons.local_laundry_service_rounded;
    } else if (lower.contains('security')) {
      return Icons.security_rounded;
    } else if (lower.contains('power') || lower.contains('backup')) {
      return Icons.power_rounded;
    } else if (lower.contains('study')) {
      return Icons.school_rounded;
    } else if (lower.contains('kitchen')) {
      return Icons.kitchen_rounded;
    } else if (lower.contains('parking')) {
      return Icons.local_parking_rounded;
    } else if (lower.contains('gym')) {
      return Icons.fitness_center_rounded;
    } else if (lower.contains('rooftop')) {
      return Icons.roofing_rounded;
    } else if (lower.contains('cctv')) {
      return Icons.videocam_rounded;
    }
    return Icons.check_circle_rounded;
  }

  Widget _buildLandlordSection() {
    final hostel = Hostel.fromMap(widget.hostel);
    return FutureBuilder<String?>(
      future: UserSessionService.getUserId(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return LandlordCard(
           hostel: hostel.toMap(), // Convert Hostel back to map if needed
        currentUserId: snapshot.data ?? '',
        );
      },
    );
  }

  Widget _buildModernBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.bookmark_outline_rounded, 'Bookings', 1),
              _buildNavItem(Icons.chat_bubble_outline_rounded, 'Messages', 2),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha:0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: AppColors.mainGradient,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 10 : 9,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    switch (index) {
      case 0:
        // Navigate back to dashboard with home tab
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/student-dashboard',
          (Route<dynamic> route) => false,
          arguments: 0,
        );
        break;
      case 1:
        // Navigate to dashboard with bookings tab selected
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/student-dashboard',
          (Route<dynamic> route) => false,
          arguments: 1,
        );
        break;
      case 2:
        // Navigate to dashboard with messages tab selected
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/student-dashboard',
          (Route<dynamic> route) => false,
          arguments: 2,
        );
        break;
      case 3:
        // Navigate to dashboard with profile tab selected
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/student-dashboard',
          (Route<dynamic> route) => false,
          arguments: 3,
        );
        break;
    }
  }

  void _showLocationDialog() {
    // Use full hostel data if available, otherwise fall back to widget.hostel
    final hostelData = _fullHostelData ?? widget.hostel;
    
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
      final hostelId = widget.hostel['id']?.toString() ?? widget.hostel['hostel_id']?.toString() ?? '';
      if (hostelId.isNotEmpty && !_isLoadingFullHostel) {
        // Try to fetch full hostel data
        _loadFullHostelDataIfNeeded(hostelId).then((_) {
          if (mounted) {
            _showLocationDialog(); // Retry after loading
          }
        });
        return;
      }
    }
    
    LocationMapDialog.show(
      context: context,
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      title: hostelData['name'] ?? hostelData['title'] ?? 'Hostel',
      address: hostelData['address'] ?? 'Unknown address',
      markerLabel: hostelData['name'] ?? hostelData['title'],
      onGetDirections: () {
        // TODO: Add directions functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Directions feature coming soon!')),
        );
      },
    );
  }

}
