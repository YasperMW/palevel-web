import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class Place {
  final String displayName;
  final LatLng location;
  final String? type;
  final String? importance;
  final Map<String, dynamic>? address;

  Place({
    required this.displayName,
    required this.location,
    this.type,
    this.importance,
    this.address,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      displayName: json['display_name'] ?? '',
      location: LatLng(
        double.parse(json['lat'] ?? '0'),
        double.parse(json['lon'] ?? '0'),
      ),
      type: json['type'],
      importance: json['importance']?.toString(),
      address: json['address'],
    );
  }

  /// Get a simple name for display
  String get simpleName {
    if (displayName.contains(',')) {
      return displayName.split(',')[0].trim();
    }
    return displayName;
  }

  /// Get city name if available
  String? get city {
    return address?['city'] ?? address?['town'] ?? address?['village'];
  }

  /// Get country name if available
  String? get country {
    return address?['country'];
  }
}

class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Search for places by query
  static Future<List<Place>> searchPlaces(
    String query, {
    int limit = 10,
    String? countryCodes,
    String? acceptLanguage,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
      };

      if (countryCodes != null) {
        params['countrycodes'] = countryCodes;
      }

      if (acceptLanguage != null) {
        params['accept-language'] = acceptLanguage;
      }

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((place) => Place.fromJson(place)).toList();
      } else {
        if (kDebugMode) print('Search failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error searching places: $e');
      return [];
    }
  }

  /// Reverse geocode coordinates to get address
  static Future<Place?> reverseGeocode(
    LatLng location, {
    int zoom = 18,
    String? acceptLanguage,
  }) async {
    try {
      final params = <String, String>{
        'lat': location.latitude.toString(),
        'lon': location.longitude.toString(),
        'format': 'json',
        'addressdetails': '1',
        'extratags': '1',
        'zoom': zoom.toString(),
      };

      if (acceptLanguage != null) {
        params['accept-language'] = acceptLanguage;
      }

      final uri = Uri.parse('$_baseUrl/reverse').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] != null) {
          return null;
        }
        return Place.fromJson(data);
      } else {
        if (kDebugMode) print('Reverse geocoding failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('Error reverse geocoding: $e');
      return null;
    }
  }

  /// Search with autocomplete-like behavior (searches as you type)
  static Future<List<Place>> autocompleteSearch(
    String query, {
    int minChars = 2,
    int limit = 5,
  }) async {
    if (query.length < minChars) return [];
    
    // For autocomplete, we can use the regular search but with smaller limit
    return await searchPlaces(
      query,
      limit: limit,
    );
  }

  /// Search for places near a specific location
  static Future<List<Place>> searchNearby(
    LatLng location,
    String query, {
    int radius = 1000, // meters
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = <String, String>{
        'q': query,
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'viewbox': '${location.longitude - 0.01},${location.latitude - 0.01},${location.longitude + 0.01},${location.latitude + 0.01}',
        'bounded': '1',
      };

      final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((place) => Place.fromJson(place)).toList();
      } else {
        if (kDebugMode) print('Nearby search failed with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error searching nearby places: $e');
      return [];
    }
  }
}
