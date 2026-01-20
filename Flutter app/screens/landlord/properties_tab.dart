import 'package:flutter/material.dart';

import '../../services/user_session_service.dart';
import 'add_property_screen.dart';
import 'edit_property_screen.dart';
import 'property_details_screen.dart';
import '../../config.dart';
import '../../services/hostel_service.dart';
import '../../services/media_service.dart';



class PropertiesTab extends StatefulWidget {
  final ScrollController? scrollController;

  const PropertiesTab({super.key, this.scrollController});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  List<Map<String, dynamic>> _properties = [];
  bool _isLoading = true;
  String? _error;
  final HostelService _hostelService = HostelService();
  final MediaService _mediaService = MediaService();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get actual landlord email from session storage
      final landlordEmail = await UserSessionService.getUserEmail();
      
      if (landlordEmail == null || landlordEmail.isEmpty) {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
        return;
      }
      
      final hostels = await _hostelService.getLandlordHostels(landlordEmail);

      debugPrint('=== LANDLORD PROPERTIES TAB ===');
      debugPrint('Received ${hostels.length} hostels');
      if (hostels.isNotEmpty) {
        debugPrint('First hostel keys: ${hostels.first.keys.toList()}');
        debugPrint('First hostel lat: ${hostels.first['latitude']}');
        debugPrint('First hostel lng: ${hostels.first['longitude']}');
      }

      setState(() {
        _properties = hostels;
        _isLoading = false;
      });
      
      // Load media for each hostel
      for (var hostel in hostels) {
        _loadHostelMedia(hostel['hostel_id']);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  // Map to store hostel media with hostel ID as key
  final Map<String, List<Map<String, dynamic>>> _hostelMedia = {};
  final Map<String, bool> _isLoadingMedia = {};
  
  Future<void> _loadHostelMedia(String hostelId) async {
    setState(() {
      _isLoadingMedia[hostelId] = true;
    });
    
    try {
      final media = await _mediaService.getHostelMedia(hostelId);
      if (!mounted) return;
      setState(() {
        _hostelMedia[hostelId] = List<Map<String, dynamic>>.from(media);
        _isLoadingMedia[hostelId] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hostelMedia[hostelId] = [];
        _isLoadingMedia[hostelId] = false;
      });
    }
  }

  Future<void> _togglePropertyStatus(String hostelId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Toggle the hostel status
      await _hostelService.toggleHostelStatus(hostelId);
      
      // Update the local state immediately for better UX
      setState(() {
        _properties = _properties.map((property) {
          if (property['hostel_id'] == hostelId) {
            return {
              ...property,
              'is_active': !(property['is_active'] ?? true),
            };
          }
          return property;
        }).toList();
      });
      
      // Then refresh from the server
      await _loadProperties();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _properties.firstWhere((p) => p['hostel_id'] == hostelId)['is_active'] == true
                  ? 'Property activated successfully'
                  : 'Property deactivated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating property status: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // If there was an error, reload the properties to ensure consistency
        _loadProperties();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Error Loading Properties',
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
              onPressed: _loadProperties,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07746B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
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

    if (_properties.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Header with Add Property Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Properties',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your hostels and rooms',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddPropertyDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Property'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF07746B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Properties List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16, right: 4),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PropertyDetailsScreen(
                                hostelId: property['hostel_id'],
                                property: property,
                              ),
                        ),
                      ).then((_) => _loadProperties());
                    },
                    child: _buildPropertyCard(property),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
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
          Stack(
            children: [
              // Property Image
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF07746B),
                      Color(0xFF0DDAC9),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: _hostelMedia[property['hostel_id']] != null && _hostelMedia[property['hostel_id']]!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage('$kBaseUrl/uploads/${_hostelMedia[property['hostel_id']]![0]['url']}'),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _hostelMedia[property['hostel_id']] == null || _hostelMedia[property['hostel_id']]!.isEmpty
                    ? Center(
                        child: Icon(
                          Icons.apartment,
                          size: 48,
                          color: Colors.white.withValues(alpha:0.8),
                        ),
                      )
                    : null,
              ),
              // Status Badge
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (property['is_active'] == true)
                        ? Colors.green.withValues(alpha:0.9)
                        : Colors.orange.withValues(alpha:0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    property['is_active'] == true ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Property Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['name'] ?? 'Unnamed Property',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  property['address'] ?? 'No address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.bed,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Rooms: ${property['total_rooms'] ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Created: ${property['created_at']?.substring(0, 10) ??
                            'Unknown'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF07746B),
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPropertyScreen(property: property),
                            ),
                          ).then((_) {
                            // Refresh properties when returning from edit
                            _loadProperties();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF07746B)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(color: Color(0xFF07746B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showStatusDialog(
                            property['hostel_id'],
                            property['is_active'] == true,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: property['is_active'] == true
                                ? Colors.orange
                                : Colors.green,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          property['is_active'] == true ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: property['is_active'] == true
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
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

  void _showAddPropertyDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPropertyScreen(),
      ),
    );

    if (result == true) {
      _loadProperties();
    }
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apartment_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Properties Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first property to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddPropertyDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Your First Property'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07746B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String hostelId, bool isCurrentlyActive) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final title = isCurrentlyActive ? 'Deactivate Property' : 'Activate Property';
        final message = isCurrentlyActive
            ? 'Are you sure you want to deactivate this property? Students will no longer see it in search, but you can activate it again later.'
            : 'Do you want to activate this property? It will become visible to students in search again.';
        final actionLabel = isCurrentlyActive ? 'Deactivate' : 'Activate';
        final actionColor = isCurrentlyActive ? Colors.orange : Colors.green;
        return AlertDialog(
          title: Text(title),
          content: Text(message),
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
                _togglePropertyStatus(hostelId);
              },
              style: TextButton.styleFrom(foregroundColor: actionColor),
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }
}
