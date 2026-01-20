import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config.dart';
import 'user_session_service.dart';
import 'auth_helper.dart';


class BookingService {
  final String baseUrl = kBaseUrl;
  String? _authToken;

  // Get authentication token (use UserSessionService to keep keys consistent)
  Future<String?> _getAuthToken() async {
    if (_authToken != null) return _authToken;
    _authToken = await UserSessionService.getUserToken();
    return _authToken;
  }

  // Create a new booking
  Future<Map<String, dynamic>> createBooking({
    required String roomId,
    required String studentEmail,
    required String checkInDate,
    required int durationMonths,
    required double amount,
    required String paymentType,
    required String paymentMethod,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'room_id': roomId,
        'student_email': studentEmail,
        'check_in_date': checkInDate,
        'duration_months': durationMonths,
        'amount': amount,
        'payment_type': paymentType,
        'payment_method': paymentMethod,
        'status': 'pending',
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to create booking: ${response.body}');
    }
  }

  // Initiate PayChangu payment
  Future<Map<String, dynamic>> initiatePayChanguPayment({
    required String bookingId,
    required double amount,
    required String email,
    required String phoneNumber,
    required String firstName,
    required String lastName,
  }) async {

    
    final token = await _getAuthToken();
    if (token == null) {

      throw Exception('User not authenticated');
    }
    final payload = {
      'booking_id': bookingId,
      'amount': amount,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'currency': 'MWK',
    };


    final url = '$baseUrl/payments/paychangu/initiate/';

    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      


      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return responseData;
      } else {

        
        if (response.statusCode == 401) {

          await AuthHelper.handleUnauthorized();
          throw Exception('Unauthorized');
        }
        throw Exception('Failed to initiate payment: ${response.body}');
      }
    } catch (e) {

      rethrow;
    }
  }

  // Verify payment status
  Future<Map<String, dynamic>> verifyPayment(String reference) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/payments/verify/?reference=$reference'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to verify payment: ${response.body}');
    }
  }

  // Get user's bookings
  Future<List<dynamic>> getUserBookings() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my-bookings/?include_payment_details=true'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to load bookings: ${response.body}');
    }
  }

  // Cancel a booking
  Future<void> cancelBooking(String bookingId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to cancel booking: ${response.body}');
    }
  }

  /// High-level convenience method to create a booking and initiate PayChangu payment.
  /// Returns the payment URL to open in a browser.
  Future<String> bookRoom({
    required Map<String, dynamic> room,
    required String studentEmail,
    required String startDate,
    required int duration,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    String paymentMethod = 'paychangu',
    required String paymentType,
  }) async {



    final roomId = room['room_id']?.toString() ?? room['id']?.toString();
    if (roomId == null) {
      throw Exception('Room ID is missing and required for booking.');
    }
    
    // Get price per month
  double pricePerMonth = 0.0;
  if (room['price_per_month'] is num) {
    pricePerMonth = (room['price_per_month'] as num).toDouble();
  } else if (room['price_per_month'] != null) {
    pricePerMonth = double.tryParse(room['price_per_month'].toString()) ?? 0.0;
  }

  // Get booking fee from room or hostel data
  double bookingFee = 0.0;
  if (room['booking_fee'] is num) {
    bookingFee = (room['booking_fee'] as num).toDouble();
  } else if (room['booking_fee'] != null) {
    bookingFee = double.tryParse(room['booking_fee'].toString()) ?? 0.0;
  } else if (room['hostel'] != null && room['hostel']['booking_fee'] != null) {
    if (room['hostel']['booking_fee'] is num) {
      bookingFee = (room['hostel']['booking_fee'] as num).toDouble();
    } else {
      bookingFee = double.tryParse(room['hostel']['booking_fee'].toString()) ?? 0.0;
    }
  }



  // Calculate total amount based on payment type
  double baseAmount;
  if (paymentType == 'booking_fee') {
    baseAmount = bookingFee;

  } else {
    baseAmount = pricePerMonth * duration;

  }
  
  // Add platform fee (2500 MWK)
  const double platformFee = 2500.0;
  final totalAmount = baseAmount + platformFee;

    // Create booking
    final booking = await createBooking(
      roomId: roomId,
      studentEmail: studentEmail,
      checkInDate: startDate,
      durationMonths: duration,
      amount: totalAmount,
      paymentType: paymentType,
      paymentMethod: paymentMethod,
    );

    // Initiate payment
    final paymentResponse = await initiatePayChanguPayment(
      bookingId: booking['booking_id'].toString(),
      amount: totalAmount,
      email: studentEmail,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
    );

    final paymentUrl = paymentResponse['payment_url']?.toString();
    if (paymentUrl == null || paymentUrl.isEmpty) {
      throw Exception('Payment initiation did not return a payment URL');
    }

    return paymentUrl;
  }

  // Verify payment for student's own booking
  Future<Map<String, dynamic>> verifyMyPayment(String bookingId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-my-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'booking_id': bookingId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to verify payment: ${response.body}');
    }
  }

  // Verify payment specifically for booking extensions
  Future<Map<String, dynamic>> verifyExtensionPayment(String paymentId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-extension-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_id': paymentId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to verify extension payment: ${response.body}');
    }
  }

  // Update extension status when user proceeds to payment
  Future<Map<String, dynamic>> updateExtensionStatus({
    required String bookingId,
    required int additionalMonths,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/extension-status-update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'additional_months': additionalMonths,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to update extension status: ${response.body}');
    }
  }

  // Reset stuck extension status
  Future<Map<String, dynamic>> resetExtensionStatus(String bookingId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/reset-extension-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to reset extension status: ${response.body}');
    }
  }

  /// Variant of bookRoom that returns the raw payment initiation response
  /// (useful when launching an SDK payment widget that needs tx_ref or other fields).
  Future<Map<String, dynamic>> bookRoomForSdk({
    required Map<String, dynamic> room,
    required String studentEmail,
    required String startDate,
    required int duration,
    required paymentType,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    String paymentMethod = 'paychangu',
  }) async {

    final roomId = room['room_id']?.toString() ?? room['id']?.toString();
    if (roomId == null) {
      throw Exception('Room ID is missing and required for booking.');
    }
    // compute amount
    double pricePerMonth = 0.0;
    if (room['price_per_month'] is num) {
      pricePerMonth = (room['price_per_month'] as num).toDouble();
    } else if (room['price_per_month'] != null) {
      pricePerMonth = double.tryParse(room['price_per_month'].toString()) ?? 0.0;
    }
    final amount = pricePerMonth * duration;

    // Create booking
    final booking = await createBooking(
      roomId: roomId,
      studentEmail: studentEmail,
      checkInDate: startDate,
      durationMonths: duration,
      amount: amount,
      paymentType: paymentType,
      paymentMethod: paymentMethod,
    );

    // Initiate payment
    final paymentResponse = await initiatePayChanguPayment(
      bookingId: booking['booking_id'].toString(),
      amount: amount,
      email: studentEmail,
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
    );


    
    if (paymentResponse['payment_url'] == null) {

    } else {

    }
    
    return paymentResponse;
  }

  // Extend booking functionality
  Future<Map<String, dynamic>> extendBooking({
    required String bookingId,
    required int additionalMonths,
    required String paymentMethod,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/extend/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'additional_months': additionalMonths,
        'payment_method': paymentMethod,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to extend booking: ${response.body}');
    }
  }

  // Initiate payment for booking extension
  Future<Map<String, dynamic>> initiateExtensionPayment({
    required String bookingId,
    required int additionalMonths,
    required String email,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    String paymentMethod = 'paychangu',
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final payload = {
      'booking_id': bookingId,
      'additional_months': additionalMonths,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'payment_method': paymentMethod,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/payments/extend/initiate/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to initiate extension payment: ${response.body}');
    }
  }

  // Initiate payment for completing booking fee to full payment
  Future<Map<String, dynamic>> initiateCompletePayment({
    required String bookingId,
    required double remainingAmount,
    required String email,
    required String phoneNumber,
    required String firstName,
    required String lastName,
    String paymentMethod = 'paychangu',
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final payload = {
      'booking_id': bookingId,
      'remaining_amount': remainingAmount,
      'email': email,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'payment_method': paymentMethod,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/payments/complete/initiate/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to initiate complete payment: ${response.body}');
    }
  }

  // Fetch current room price for extension calculations
  Future<Map<String, dynamic>> getExtensionPricing({
    required String bookingId,
    required int additionalMonths,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId/extension-pricing?additional_months=$additionalMonths'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to fetch extension pricing: ${response.body}');
    }
  }

  // Fetch pricing for completing booking fee to full payment
  Future<Map<String, dynamic>> getCompletePaymentPricing({
    required String bookingId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId/complete-payment-pricing'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to fetch complete payment pricing: ${response.body}');
    }
  }

  // Verify complete payment
  Future<Map<String, dynamic>> verifyCompletePayment(String paymentId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-complete-payment/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'payment_id': paymentId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to verify complete payment: ${response.body}');
    }
  }

  // Update complete payment status when user proceeds to payment
  Future<Map<String, dynamic>> updateCompletePaymentStatus({
    required String bookingId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/complete-payment-status-update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}), // Empty payload as we don't need additional data
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to update complete payment status: ${response.body}');
    }
  }

  // Reset complete payment status when payment gets stuck
  Future<Map<String, dynamic>> resetCompletePaymentStatus({
    required String bookingId,
  }) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/reset-complete-payment-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({}), // Empty payload
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401) {
        await AuthHelper.handleUnauthorized();
        throw Exception('Unauthorized');
      }
      throw Exception('Failed to reset complete payment status: ${response.body}');
    }
  }

  // Verify extension payment when stuck (finds payment by booking ID)
  Future<Map<String, dynamic>> verifyStuckExtensionPayment(String bookingId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    // First, get the booking details to find the extension payment
    final bookingResponse = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (bookingResponse.statusCode != 200) {
      throw Exception('Failed to get booking details: ${bookingResponse.body}');
    }


    
    // Look for extension payments in the booking data
    // The backend should return payment information, try to find extension payment
    try {
      // Try to verify using the booking ID directly (backend will find the payment)
      final response = await http.post(
        Uri.parse('$baseUrl/payments/verify-stuck-extension-payment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.statusCode == 401) {
          await AuthHelper.handleUnauthorized();
          throw Exception('Unauthorized');
        }
        throw Exception('Failed to verify stuck extension payment: ${response.body}');
      }
    } catch (e) {
      // If the endpoint doesn't exist, fall back to regular verification
      throw Exception('Extension payment verification not available: $e');
    }
  }

  // Verify complete payment when stuck (finds payment by booking ID)
  Future<Map<String, dynamic>> verifyStuckCompletePayment(String bookingId) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception('User not authenticated');

    // First, get the booking details to find the complete payment
    final bookingResponse = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (bookingResponse.statusCode != 200) {
      throw Exception('Failed to get booking details: ${bookingResponse.body}');
    }


    
    // Look for complete payments in the booking data
    try {
      // Try to verify using the booking ID directly (backend will find the payment)
      final response = await http.post(
        Uri.parse('$baseUrl/payments/verify-stuck-complete-payment/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'booking_id': bookingId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.statusCode == 401) {
          await AuthHelper.handleUnauthorized();
          throw Exception('Unauthorized');
        }
        throw Exception('Failed to verify stuck complete payment: ${response.body}');
      }
    } catch (e) {
      // If the endpoint doesn't exist, fall back to regular verification
      throw Exception('Complete payment verification not available: $e');
    }
  }
}
