// lib/screens/student/home_tab.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:latlong2/latlong.dart';
import 'hostel_detail_page.dart';
import '../../theme/app_colors.dart';

import '../../config.dart';
import '../../services/hostel_service.dart';
import '../../services/user_session_service.dart';
import '../../utils/university_coordinates.dart';



class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final ScrollController _scrollController;
  late Future<List<Map<String, dynamic>>> _hostelsFuture;
  String _selectedFilter = 'All';
  String _selectedUniversity = 'All';
  String _searchQuery = '';
  String? _error;
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  final HostelService _hostelService = HostelService();


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _hostelsFuture = _loadHostels();
    _initializeUniversityFilter();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const List<String> universities = [
    'All',
    'MUST',
    'UNIMA',
    'LUANAR',
    'KUHeS',
    'MZUNI',
    'Catholic University',
    'Nkhoma',
    'DMI',
  ];

  String _normalizeUniversityLabel(String? value) {
    if (value == null || value.isEmpty) return 'All';
    final v = value.toLowerCase();

    if (v.contains('must')) return 'MUST';
    if (v.contains('unima') || v.contains('university of malawi')) return 'UNIMA';
    if (v.contains('luanar') || v.contains('agriculture and natural resources')) return 'LUANAR';
    if (v.contains('kuhes') || v.contains('kamuzu university of health sciences')) return 'KUHeS';
    if (v.contains('mzuni') || v.contains('mzuzu university')) return 'MZUNI';
    if (v.contains('catholic university')) return 'Catholic University';
    if (v.contains('nkhoma')) return 'Nkhoma';
    if (v.contains('dmi')) return 'DMI';

    if (universities.contains(value)) return value;
    return 'All';
  }

  Future<void> _initializeUniversityFilter() async {
    final savedUniversity = await UserSessionService.getUniversity();

    if (!mounted) return;

    if (savedUniversity != null && savedUniversity.isNotEmpty) {
      final normalized = _normalizeUniversityLabel(savedUniversity);
      setState(() {
        _selectedUniversity = normalized;
      });
    }
  }

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.apps_rounded, 'type': 'all'},
    {'label': 'Private', 'icon': Icons.lock_rounded, 'type': 'private'},
    {'label': 'Shared', 'icon': Icons.people_rounded, 'type': 'shared'},
    {'label': 'Self-contained', 'icon': Icons.home_rounded, 'type': 'self_contained'},
    {'label': 'Nearby', 'icon': Icons.near_me_rounded, 'type': 'nearby'},
  ];

  // Filter hostels based on selected university and filter
  List<Map<String, dynamic>> _filterHostels(List<Map<String, dynamic>> hostels) {
    return hostels.where((hostel) {
      // Filter out hostels with no available rooms by default
      final roomsAvailable = hostel['rooms_available'] as int? ?? 0;
      if (roomsAvailable <= 0) {
        return false;
      }

      // Apply university filter
      final matchesUniversity = _selectedUniversity == 'All' || 
          (hostel['university']?.toString().toLowerCase() ?? '').contains(_selectedUniversity.toLowerCase());

      // Apply search query filter
      final query = _searchQuery.trim().toLowerCase();
      bool matchesSearch = true;
      if (query.isNotEmpty) {
        final title = hostel['title']?.toString().toLowerCase() ?? '';
        final description = hostel['description']?.toString().toLowerCase() ?? '';
        final address = hostel['address']?.toString().toLowerCase() ?? '';
        final district = hostel['district']?.toString().toLowerCase() ?? '';
        final university = hostel['university']?.toString().toLowerCase() ?? '';
        final amenitiesList = (hostel['amenities'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];

        matchesSearch =
            title.contains(query) ||
            description.contains(query) ||
            address.contains(query) ||
            district.contains(query) ||
            university.contains(query) ||
            amenitiesList.any((amenity) => amenity.contains(query));
      }
      
      // Apply type filter
      bool matchesFilter = true;
      final hostelType = (hostel['type']?.toString() ?? '').toLowerCase();
      final amenities = (hostel['amenities'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      
      switch (_selectedFilter.toLowerCase()) {
        case 'private':
          matchesFilter = hostelType == 'private' || amenities.contains('private');
          break;
        case 'shared':
          matchesFilter = hostelType == 'shared' || amenities.contains('shared');
          break;
        case 'self-contained':
          matchesFilter = hostelType == 'self-contained' || amenities.contains('self-contained');
          break;
        case 'nearby':
          // Assuming 'distance' is already calculated in _loadHostels
          // Only filter by distance if distance is available
          final distance = hostel['distance'];
          if (distance != null && distance is num) {
            matchesFilter = distance < 2.0; // Within 2km
          } else {
            // If no distance available, don't filter it out (show it)
            matchesFilter = true;
          }
          break;
        // 'All' or any other filter - no additional filtering needed
      }
      
      return matchesUniversity && matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _refreshHostels() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final hostels = await _loadHostels();
      if (mounted) {
        setState(() {
          _hostelsFuture = Future.value(hostels);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadHostels() async {
    try {
      // Clear any previous errors
      setState(() => _error = null);
      
      // Try to fetch real data from backend
      final hostels = await _hostelService.getAllHostels();
      
      debugPrint('=== STUDENT HOME TAB ===');
      debugPrint('Received ${hostels.length} hostels');
      if (hostels.isNotEmpty) {
        debugPrint('First hostel keys: ${hostels.first.keys.toList()}');
        debugPrint('First hostel lat: ${hostels.first['latitude']}');
        debugPrint('First hostel lng: ${hostels.first['longitude']}');
      }
      
      // Transform backend data to match frontend structure with defaults
      final transformedHostels = await Future.wait(hostels.map((hostel) async {
        // Extract image URL from media array or use default
        String imageUrl = 'https://images.unsplash.com/photo-1522708323590-d24dbb6b026e?w=400';

        if (hostel['media'] != null && hostel['media'].isNotEmpty) {
          final coverImage = hostel['media'].firstWhere(
            (media) => media['is_cover'] == true,
            orElse: () => hostel['media'].first,
          );
          imageUrl = '$kBaseUrl/uploads/${coverImage['url']}';

        } else {

        }
        
        // Extract amenities from backend or use defaults
        List<String> amenities = ['WiFi', 'Security']; // Default amenities
        if (hostel['amenities'] != null) {
          final amenitiesMap = hostel['amenities'] as Map<String, dynamic>;
          // Filter for amenities that are true and get their keys as amenity names
          final trueAmenities = amenitiesMap.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString()) // Get the key (amenity name)
              .where((amenity) => amenity.isNotEmpty)
              .toList();
          
          if (trueAmenities.isNotEmpty) {
            amenities = trueAmenities;
          } else {
            amenities = ['No amenities specified'];
          }
        }
        
        // Get available rooms from backend
        int roomsAvailable = hostel['available_rooms'] ?? 0;
        
        // Calculate distance using Nominatim API
        final distance = await _calculateDistance(
          hostel['latitude'], 
          hostel['longitude'],
          hostel['university'],
        );
        
        return {
          'id': hostel['hostel_id'] ?? hostel['id'] ?? '',
          'hostel_id': hostel['hostel_id'] ?? hostel['id'] ?? '',
          'title': hostel['name'] ?? 'Unknown Hostel',
          'name': hostel['name'] ?? 'Unknown Hostel',
          'description': hostel['description'] ?? 'No description available',
          'price': (hostel['price_per_month'] ?? 85000).toDouble(),
          'address': hostel['address'] ?? 'Unknown Address',
          'district': hostel['district'] ?? 'Unknown District',
          'university': hostel['university'] ?? 'N/A',
          'distance': distance,
          'type': hostel['type'] ?? 'Private', // Use type from API or default to 'Private'
          'amenities': amenities,
          'image': imageUrl,
          'rating': (hostel['average_rating'] ?? 0).toDouble(),
          'reviews': hostel['reviews_count'] ?? 0,
          'landlord_id': hostel['landlord_id'],
          'landlord': hostel['landlord_name'] ?? 'Property Owner',
          'phone': hostel['landlord_phone'] ?? '+265 888 123 456',
          'rooms_available': roomsAvailable,
          'total_rooms': hostel['total_rooms'] ?? 0,
          'latitude': hostel['latitude'] != null ? (hostel['latitude'] is num ? hostel['latitude'].toDouble() : double.tryParse(hostel['latitude'].toString()) ?? 0.0) : null,
          'longitude': hostel['longitude'] != null ? (hostel['longitude'] is num ? hostel['longitude'].toDouble() : double.tryParse(hostel['longitude'].toString()) ?? 0.0) : null,
        };
      }));
      
      return transformedHostels;
    } catch (e) {
      debugPrint('Error loading hostels: $e');
      if (mounted) {
        setState(() {
          _error = 'An error occurred. Please check your internet connection and try again.';
          _hostelsFuture = Future.value([]);
        });
      }
      return [];
    }
  }
  

  
  /// Calculate distance between hostel location and university location
  /// Uses Nominatim API to fetch university coordinates dynamically
  /// Returns distance in kilometers, or null if coordinates are missing
  Future<double?> _calculateDistance(dynamic latitude, dynamic longitude, dynamic university) async {
    // Get hostel coordinates
    double? hostelLat;
    double? hostelLng;
    
    if (latitude != null) {
      hostelLat = latitude is num ? latitude.toDouble() : double.tryParse(latitude.toString());
    }
    if (longitude != null) {
      hostelLng = longitude is num ? longitude.toDouble() : double.tryParse(longitude.toString());
    }
    
    // If hostel coordinates are missing, return null
    if (hostelLat == null || hostelLng == null) {
      return null;
    }
    
    // Get university coordinates using Nominatim API (with caching)
    final Map<String, double>? universityCoords = await UniversityCoordinates.getCoordinates(
      university?.toString(),
    );
    
    // If we don't have university coordinates, return null (don't show distance)
    if (universityCoords == null) {
      return null;
    }
    
    final universityLat = universityCoords['latitude']!;
    final universityLng = universityCoords['longitude']!;
    
    // Calculate distance using Haversine formula
    const distance = Distance();
    final hostelPoint = LatLng(hostelLat, hostelLng);
    final universityPoint = LatLng(universityLat, universityLng);
    
    // Calculate distance in meters, then convert to kilometers
    final distanceInMeters = distance(hostelPoint, universityPoint);
    final distanceInKm = distanceInMeters / 1000.0;
    
    // Round to 1 decimal place
    return double.parse(distanceInKm.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshHostels,
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Modern Search Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                _buildModernSearchBar(),
                const SizedBox(height: 20),
                
                // University Selector
                _buildUniversitySelector(),
                const SizedBox(height: 20),
                
                // Filter Chips
                _buildFilterChips(),
              ],
            ),
          ),
        ),

        // Hostels List
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _hostelsFuture,
          builder: (context, snapshot) {
            // Show error message if there's an error
            if (_error != null) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load hostels',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _refreshHostels,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: _ShimmerHostelCard(),
                    ),
                    childCount: 3,
                  ),
                ),
              );
            }

            final hostels = snapshot.data ?? [];

            if (hostels.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hostels found',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredHostels = _filterHostels(hostels);

            if (filteredHostels.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 80,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hostels found',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final hostel = filteredHostels[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _ModernHostelCard(
                        hostel: hostel,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HostelDetailPage(hostel: hostel),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: filteredHostels.length,
                ),
              ),
            );
          },
        ),

        // Bottom Padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha:0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search hostels, locations, amenities...',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildUniversitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha:0.08),
            AppColors.primaryLight.withValues(alpha:0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha:0.2),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUniversity,
          isExpanded: true,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
          items: universities.map((uni) {
            return DropdownMenuItem<String>(
              value: uni,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(uni),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedUniversity = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['label'];
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['label']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: AppColors.primaryGradient,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.primary.withValues(alpha:0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha:0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    filter['label']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ======================== SHIMMER CARD ========================
class _ShimmerHostelCard extends StatelessWidget {
  const _ShimmerHostelCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================== MODERN HOSTEL CARD ========================
class _ModernHostelCard extends StatelessWidget {
  Widget _buildPlaceholderIcon() {
    return const Icon(
      Icons.apartment_rounded,
      size: 64,
      color: AppColors.primary,
    );
  }

  final Map<String, dynamic> hostel;
  final VoidCallback onTap;

  const _ModernHostelCard({
    required this.hostel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rating = hostel['rating'] as double? ?? 0.0;
    final roomsAvailable = hostel['rooms_available'] as int? ?? 0;
    final imageUrl = hostel['image'] as String? ?? '';
    final title = hostel['title'] as String? ?? 'No Title';
    final description = hostel['description'] as String? ?? 'No Description';

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'hostel_${hostel['id']}',
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primaryLight.withOpacity(0.1),
                          ],
                        ),
                      )
                      child: imageUrl.toString().isNotEmpty &&
                             (imageUrl.toString().startsWith('http') || imageUrl.toString().startsWith('https'))
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                  ),
                  
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha:0.3),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  // Rating Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.rating,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rooms Available Badge
                  if (roomsAvailable > 0)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha:0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bed_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$roomsAvailable left',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha:0.15),
                                AppColors.primaryLight.withValues(alpha:0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha:0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            hostel['type'] ?? '',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Location Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha:0.2),
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
                                  hostel['address'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${hostel['district'] ?? 'N/A'} • ${hostel['university'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'MK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${((hostel['price'] as double? ?? 0.0) / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '/month',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
