import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class OSRMRoutingService {
  static const String _baseUrl = 'https://routing.openstreetmap.de/routed-car';

  /// Get route between two points using OSRM API
  static Future<RouteResult?> getRoute(
    LatLng start,
    LatLng end, {
    bool alternatives = false,
  }) async {
    try {
      final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      final url = '$_baseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson&alternatives=$alternatives';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return RouteResult.fromJson(route);
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting route: $e');
      return null;
    }
  }

  /// Get multiple routes between two points
  static Future<List<RouteResult>> getRoutes(
    LatLng start,
    LatLng end, {
    int maxAlternatives = 3,
  }) async {
    try {
      final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      final url = '$_baseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson&alternatives=true';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final routes = data['routes']
              .take(maxAlternatives + 1)
              .map((route) => RouteResult.fromJson(route))
              .toList();
          return routes;
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) print('Error getting routes: $e');
      return [];
    }
  }

  /// Get distance and duration between two points (no geometry)
  static Future<DistanceResult?> getDistance(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final coordinates = '${start.longitude},${start.latitude};${end.longitude},${end.latitude}';
      final url = '$_baseUrl/route/v1/driving/$coordinates?overview=false';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          return DistanceResult(
            distance: route['distance'], // in meters
            duration: route['duration'], // in seconds
          );
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting distance: $e');
      return null;
    }
  }

  /// Find nearest point on road network
  static Future<LatLng?> findNearestRoad(LatLng point) async {
    try {
      final coordinates = '${point.longitude},${point.latitude}';
      final url = '$_baseUrl/nearest/v1/driving/$coordinates?number=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'palevel-app/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['waypoints'].isNotEmpty) {
          final waypoint = data['waypoints'][0];
          final location = waypoint['location'];
          return LatLng(location[1], location[0]);
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) print('Error finding nearest road: $e');
      return null;
    }
  }
}

class RouteResult {
  final double distance; // in meters
  final double duration; // in seconds
  final List<LatLng> geometry;
  final List<RouteStep> steps;

  RouteResult({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.steps,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final geometry = <LatLng>[];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      final coordinates = json['geometry']['coordinates'] as List;
      for (var coord in coordinates) {
        geometry.add(LatLng(coord[1], coord[0]));
      }
    }

    final steps = <RouteStep>[];
    if (json['legs'] != null && json['legs'].isNotEmpty) {
      for (var leg in json['legs']) {
        if (leg['steps'] != null) {
          for (var step in leg['steps']) {
            steps.add(RouteStep.fromJson(step));
          }
        }
      }
    }

    return RouteResult(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      geometry: geometry,
      steps: steps,
    );
  }

  /// Get distance in kilometers
  double get distanceKm => distance / 1000;

  /// Get duration in minutes
  double get durationMinutes => duration / 60;

  /// Get formatted distance string
  String get distanceText {
    if (distanceKm < 1) {
      return '${(distance).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Get formatted duration string
  String get durationText {
    final minutes = (durationMinutes).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }
}

class RouteStep {
  final double distance;
  final double duration;
  final String instruction;
  final String maneuver;
  final List<LatLng> geometry;

  RouteStep({
    required this.distance,
    required this.duration,
    required this.instruction,
    required this.maneuver,
    required this.geometry,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final geometry = <LatLng>[];
    if (json['geometry'] != null && json['geometry']['coordinates'] != null) {
      final coordinates = json['geometry']['coordinates'] as List;
      for (var coord in coordinates) {
        geometry.add(LatLng(coord[1], coord[0]));
      }
    }

    return RouteStep(
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
      instruction: json['maneuver']?['instruction'] ?? json['instruction'] ?? '',
      maneuver: json['maneuver']?['type'] ?? '',
      geometry: geometry,
    );
  }

  /// Get distance in meters
  String get distanceText {
    if (distance < 1000) {
      return '${(distance).round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  /// Get duration in minutes
  String get durationText {
    final minutes = (duration / 60).round();
    return '$minutes min';
  }
}

class DistanceResult {
  final double distance; // in meters
  final double duration; // in seconds

  DistanceResult({
    required this.distance,
    required this.duration,
  });

  /// Get distance in kilometers
  double get distanceKm => distance / 1000;

  /// Get duration in minutes
  double get durationMinutes => duration / 60;

  /// Get formatted distance string
  String get distanceText {
    if (distanceKm < 1) {
      return '${(distance).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Get formatted duration string
  String get durationText {
    final minutes = (durationMinutes).round();
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }
}
