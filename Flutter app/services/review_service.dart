import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config.dart';
import 'user_session_service.dart';


class ReviewService {
  final String baseUrl;

  ReviewService({String? baseUrl}) : baseUrl = baseUrl ?? kBaseUrl;

  Future<Map<String, dynamic>?> getReviewForBooking(String bookingId) async {
    final token = await UserSessionService.getUserToken();

    final url = Uri.parse('$baseUrl/reviews/booking/$bookingId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return null;
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load review');
  }

  Future<List<Map<String, dynamic>>> getReviewsForHostel(String hostelId) async {
    final url = Uri.parse('$baseUrl/reviews/hostel/$hostelId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      if (response.body.isEmpty || response.body == 'null') return [];
      final List<dynamic> data = json.decode(response.body) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception('Failed to load hostel reviews');
  }

  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final token = await UserSessionService.getUserToken();

    final url = Uri.parse('$baseUrl/reviews/booking/$bookingId');

    final body = json.encode({
      'rating': rating,
      'comment': comment,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to submit review');
  }
}