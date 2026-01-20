import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'hostel_service.dart';
import 'room_service.dart';
import 'media_service.dart';
import 'user_session_service.dart';
import 'auth_helper.dart';

// User class remains the same
class User {
  final String userId;
  final String email;
  final String userType;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final bool? isVerified;
  final bool? isBlacklisted;
  final String? university;
  final int? totalProperties;
  final int? totalRooms;
  final double? occupancyRate;
  final String? createdAt;
  final String? gender;
  final String? defaultPaymentMethod;

  User({
    required this.userId,
    required this.email,
    required this.userType,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.isVerified,
    this.isBlacklisted,
    this.university,
    this.totalProperties,
    this.totalRooms,
    this.occupancyRate,
    this.createdAt,
    this.defaultPaymentMethod,
    this.gender,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id']?.toString() ?? '',
      email: json['email'] ?? '',
      userType: json['user_type'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phoneNumber: json['phone_number'],
      isVerified: json['is_verified'],
      isBlacklisted: json['is_blacklisted'],
      university: json['university'],
      totalProperties: json['total_properties'] != null ? int.tryParse(json['total_properties'].toString()) : null,
      totalRooms: json['total_rooms'] != null ? int.tryParse(json['total_rooms'].toString()) : null,
      occupancyRate: json['occupancy_rate']?.toDouble(),
      createdAt: json['created_at'],
      defaultPaymentMethod: json['default_payment_method'],
    );
  }

  String get fullName => '$firstName $lastName';
}

class ApiService {
  // Services
  static final HostelService hostels = HostelService();
  static final RoomService rooms = RoomService();
  static final MediaService media = MediaService();

  // User related methods
  static Future<User> getUserProfile(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/user/profile/?email=$email'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes).trim();
        if (body.isEmpty || body == 'null') {
          throw Exception('Empty response from server while loading profile');
        }

        final dynamic decoded = json.decode(body);
        if (decoded == null) {
          throw Exception('Server returned null for user profile');
        }
        if (decoded is! Map<String, dynamic>) {
          throw Exception('Unexpected response type for user profile: ${decoded.runtimeType}');
        }

        return User.fromJson(decoded);
      } else if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getLandlordStats(String landlordEmail) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/landlord/$landlordEmail/stats/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'totalProperties': data['total_properties'] ?? 0,
          'totalRooms': data['total_rooms'] ?? 0,
          'occupancyRate': data['occupancy_rate']?.toDouble() ?? 0.0,
        };
      } else {
        throw Exception('Failed to load landlord statistics');
      }
    } catch (e) {

      return {
        'totalProperties': 0,
        'totalRooms': 0,
        'occupancyRate': 0.0,
      };
    }
  }

  static Future<Map<String, dynamic>> getLandlordVerificationStatus(String landlordId) async {
    try {
      final token = await UserSessionService.getUserToken();
      final response = await http.get(
         Uri.parse('$kBaseUrl/verifications/landlord-verification-status/$landlordId'), 
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'status': data['status'] ?? 'not_submitted',
          'idType': data['id_type'],
          'verifiedAt': data['verified_at'],
          'updatedAt': data['updated_at'],
        };
      } else if (response.statusCode == 404) {
        // No verification record found
        return {'status': 'not_submitted'};
      } else if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      } else {
        throw Exception('Failed to load verification status: ${response.statusCode}');
      }
    } catch (e) {

      // Return not_submitted as default if there's an error
      return {'status': 'not_submitted'};
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? university,
    required String password,
    String? defaultPaymentMethod,
  }) async {
    try {
      final token = await UserSessionService.getUserToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'university': university,
        'password': password,
        'default_payment_method': defaultPaymentMethod,
      });

      final response = await http.put(
        Uri.parse('$kBaseUrl/user/profile/'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getPaymentPreferences() async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$kBaseUrl/user/payment-preferences/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to load payment preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching payment preferences: $e');
    }
  }

  static Future<Map<String, dynamic>> addPaymentMethod(Map<String, dynamic> paymentMethod) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$kBaseUrl/user/payment-methods/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(paymentMethod),
      );

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Failed to add payment method');
      }
    } catch (e) {
      throw Exception('Error adding payment method: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getBanksAndProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/banks/providers'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to load banks and providers: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching banks and providers: $e');
    }
  }

  static Future<void> setPreferredPaymentMethod(String paymentMethodId) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$kBaseUrl/user/payment-methods/$paymentMethodId/set-preferred'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to set preferred payment method: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error setting preferred payment method: $e');
    }
  }

  static Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$kBaseUrl/user/payment-methods/$paymentMethodId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete payment method: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting payment method: $e');
    }
  }

  static Future<Map<String, dynamic>> resubmitNationalId(File idImage) async {
    try {
      final token = await UserSessionService.getUserToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest('POST', Uri.parse('$kBaseUrl/verifications/resubmit-national-id/'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      request.files.add(await http.MultipartFile.fromPath('national_id_image', idImage.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['detail'] ?? 'Failed to resubmit national ID';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Error resubmitting national ID: $e');
    }
  }
}
