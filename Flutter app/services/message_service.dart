// lib/services/message_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message_model.dart';
import '../../config.dart';

class MessageService {
  static const String _baseUrl = '$kBaseUrl/messages';

  // ================= HEADERS =================
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ================= CONVERSATIONS =================
  static Future<List<Map<String, dynamic>>> getConversations() async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/conversations/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('getConversations error: $e');
      rethrow;
    }
  }

  // ================= MESSAGES =================
  static Future<List<MessageModel>> getMessages(String conversationId) async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$conversationId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MessageModel.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        throw Exception('Conversation not found');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('getMessages error: $e');
      rethrow;
    }
  }

  // ================= SEND MESSAGE =================
  // Update the sendMessage method in message_service.dart
  static Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    String? conversationId,
  }) async {
    final headers = await _getHeaders();

    final body = {
      'receiver_id': receiverId,
      'content': content,
      if (conversationId != null && conversationId.isNotEmpty)
        'conversation_id': conversationId,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('✅ Message sent successfully: $responseData');
        return responseData;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else {
        print('❌ Failed to send message: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Send message error: $e');
      rethrow;
    }
  }

  // ================= MARK AS READ =================
  static Future<void> markAsRead(String conversationId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/$conversationId/read/'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        print('Failed to mark as read: ${response.statusCode}');
      }
    } catch (e) {
      print('markAsRead error: $e');
      // Non-critical error, don't throw
    }
  }

  // ================= GET USER INFO =================
  static Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    final headers = await _getHeaders();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/users/$userId/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('getUserInfo error: $e');
      return null;
    }
  }
}