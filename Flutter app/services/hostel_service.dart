import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

class HostelService {
  static final HostelService _instance = HostelService._internal();
  
  factory HostelService() => _instance;
  
  HostelService._internal();

  Future<Map<String, dynamic>> createHostel({
    required String landlordEmail,
    required String name,
    required String address,
    required String district,
    required String university,
    required String description,
    required List<String> amenities,
    required double latitude,
    required double longitude,
    required double pricePerMonth,
    double bookingFee = 0.0,
    String type = 'Private',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/hostels/'),
      );

      request.fields['landlord_email'] = landlordEmail;
      request.fields['name'] = name;
      request.fields['address'] = address;
      request.fields['district'] = district;
      request.fields['university'] = university;
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['price_per_month'] = pricePerMonth.toString();
      request.fields['booking_fee'] = bookingFee.toString();
      request.fields['amenities'] = jsonEncode(amenities);
      request.fields['type'] = type;

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to create hostel: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllHostels() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/all-hostels'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load hostels: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hostels: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLandlordHostels(String landlordEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/?landlord_email=$landlordEmail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load hostels for landlord: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching landlord hostels: $e');
    }
  }

  Future<Map<String, dynamic>> getHostel(String hostelId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/hostels/$hostelId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load hostel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching hostel: $e');
    }
  }

  Future<Map<String, dynamic>> updateHostel({
    required String hostelId,
    String? name,
    String? address,
    String? district,
    String? university,
    String? description,
    Map<String, dynamic>? amenities,
    double? latitude,
    double? longitude,
    String? type,
    double? pricePerMonth,
    double? bookingFee,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/hostels/update_hostel/$hostelId'),
      );

      // Add form fields
      if (name != null) request.fields['name'] = name;
      if (address != null) request.fields['address'] = address;
      if (district != null) request.fields['district'] = district;
      if (university != null) request.fields['university'] = university;
      if (description != null) request.fields['description'] = description;
      if (amenities != null) request.fields['amenities'] = jsonEncode(amenities);
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (type != null) request.fields['type'] = type;
      if (pricePerMonth != null) request.fields['price_per_month'] = pricePerMonth.toString();
      if (bookingFee != null) request.fields['booking_fee'] = bookingFee.toString();

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return json.decode(responseData);
      } else {
        throw Exception('Failed to update hostel: ${response.statusCode} - $responseData');
      }
    } catch (e) {
      throw Exception('Error updating hostel: $e');
    }
}
  Future<void> deleteHostel(String hostelId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/hostels/$hostelId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete hostel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting hostel: $e');
    }
  }

  Future<Map<String, dynamic>> toggleHostelStatus(String hostelId) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/hostels/$hostelId/change_hostel_status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to toggle hostel status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error toggling hostel status: $e');
    }
  }
}
