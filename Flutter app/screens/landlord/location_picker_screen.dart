import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/nominatim_service.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _isSearching = false;
  String _address = 'Select a location';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Place> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _markers.add(
        Marker(
          point: _selectedLocation!,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      _getAddressFromCoordinates(_selectedLocation!);
    }
    // Don't auto-get current location on init to avoid infinite loading
    // User can click the location button when needed
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // Store context and messenger at the start
    final currentContext = context;
    final scaffoldMessenger = ScaffoldMessenger.of(currentContext);
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS/location services.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant permission to access your location.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location permissions in app settings.');
      }

      // Try to get current location with shorter timeout and fallback accuracy
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        // Fallback to lower accuracy if high accuracy times out
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('High accuracy GPS timed out, trying lower accuracy...')),
          );
        }
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }

      if (!mounted) return;
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = currentLocation;
        _markers.clear();
        _markers.add(
          Marker(
            point: _selectedLocation!,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      });
      
      await _getAddressFromCoordinates(currentLocation);
      
      // Move map to current location
      if (!mounted) return;
      _mapController.move(currentLocation, 15);
      
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Location found successfully!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      String errorMessage = e.toString();
      
      // Provide more user-friendly error messages
      if (errorMessage.contains('timeout') || errorMessage.contains('timed out')) {
        errorMessage = 'Could not get location within time limit. Please try again or ensure GPS is enabled.';
      } else if (errorMessage.contains('disabled')) {
        errorMessage = 'Location services are disabled. Please enable GPS/location services in your device settings.';
      } else if (errorMessage.contains('denied')) {
        errorMessage = 'Location permission denied. Please grant location permission to use this feature.';
      }
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () async {
              // Open app settings
              await Geolocator.openAppSettings();
            },
          ),
        ),
      );
      
      // Fallback: suggest manual search if GPS fails
      if (mounted) {
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && _searchFocusNode.canRequestFocus) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Tip: Try searching for your location manually using the search bar above.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      setState(() {
        _address = 'Address not available';
      });
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          point: location,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });
    _getAddressFromCoordinates(location);
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _address,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await NominatimService.searchPlaces(query, limit: 5);
      setState(() {
        _searchResults = results;
        _showSearchResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _searchResults.clear();
        _showSearchResults = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    // Debounce search - wait a bit before searching
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _searchPlaces(query);
      }
    });
  }

  void _selectPlace(Place place) {
    setState(() {
      _selectedLocation = place.location;
      _markers.clear();
      _markers.add(
        Marker(
          point: place.location,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
      _address = place.displayName;
      _showSearchResults = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });

    // Move map to selected place
    _mapController.move(place.location, 15);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _showSearchResults = false;
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF07746B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search for a place...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF07746B)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.grey,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07746B)),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Address display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Address:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          
          // Map
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF07746B),
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation ?? const LatLng(-13.9893, 33.7753),
                      initialZoom: 15,
                      onTap: (tapPosition, point) => _onMapTap(point),
                      minZoom: 3,
                      maxZoom: 19,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.palevel',
                      ),
                      MarkerLayer(
                        markers: _markers.toList(),
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                            textStyle: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          
          // Confirm button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF07746B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
            ],
          ),
          
          // Search results overlay
          if (_showSearchResults && _searchResults.isNotEmpty)
            Positioned(
              top: 120, // Position below search bar
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final place = _searchResults[index];
                    return ListTile(
                      leading: const Icon(Icons.place, color: Color(0xFF07746B)),
                      title: Text(
                        place.simpleName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        place.city != null && place.country != null
                            ? '${place.city}, ${place.country}'
                            : place.displayName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
