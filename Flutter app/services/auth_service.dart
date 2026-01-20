import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthService {
  /// Authenticates a user with email and password.
  /// Returns a Map containing the response data (token, user info) if successful.
  /// Throws an Exception if authentication fails.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/authenticate/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        
        if (token == null || token.isEmpty) {
          throw Exception('Authentication failed: No token received.');
        }
        
        return data;
      } else {
        String msg = 'Login failed. Please check your credentials.';
        try {
          final err = jsonDecode(response.body);
          if (err['detail'] is String) msg = err['detail'];
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      if (e.toString().contains('No token received')) {
        rethrow;
      }
      // Wrap other errors
      if (e is Exception) rethrow;
      throw Exception('Error connecting to server: $e');
    }
  }
}
