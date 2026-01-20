import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  // Stream controllers for FCM messages
  final StreamController<RemoteMessage> _messageStreamController = 
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestNotificationPermissions();
      // Get and register FCM token (no message handlers here — NotificationsService handles messages)
      await _setupFcmToken();
    } catch (e) {//todo: add toast
    }
  }
  
  Future<void> _requestNotificationPermissions() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
    } catch (e) {//todo: add toast
    }
  }
  
  Future<void> _setupFcmToken() async {
    try {
      String? fcmToken = await _firebaseMessaging.getToken();

      if (fcmToken != null) {
        await _registerTokenWithServer(fcmToken);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _registerTokenWithServer(newToken);
      });
    } catch (e) {//todo: add toast
    }
  }
  
  /// Re-registers the FCM token with the server using the current user ID from SharedPreferences
  Future<void> registerTokenWithCurrentUser() async {
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _registerTokenWithServer(token);
    }
  }

  Future<void> _registerTokenWithServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        await http.post(
          Uri.parse('$kBaseUrl/notifications/register-token'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'token': token,
            'platform': 'android',
          }),
        );
      }
    } catch (e) {
      // Handle errorstodo: add toast
  }}
  
  // Public method to request notification permissions
  Future<NotificationSettings> requestNotificationPermissions() {
    return _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }
  
  // Public method to get the current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
  
  // Method to handle when the user taps on a notification
  void setOnNotificationClick(Function(RemoteMessage) onNotificationClick) {
    _messageStreamController.stream.listen((message) {
      onNotificationClick(message);
    });
  }
  
  // Clean up resources
  void dispose() {
    _messageStreamController.close();
  }

  /// Remove the FCM token from server (called during logout)
  Future<void> removeDeviceToken() async {
    try {
      // Get user_id and token before any session clearing
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = await _firebaseMessaging.getToken();
      
      if (token != null && userId != null) {
        await _unregisterTokenFromServer(token, userId);
      }
      
      // Delete the FCM token from the device
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      // Handle errors silently during logout

    }
  }

  Future<void> _unregisterTokenFromServer(String token, String userId) async {
    try {
      await http.delete(
        Uri.parse('$kBaseUrl/notifications/unregister-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'token': token,
        }),
      );
    } catch (e) {
      // Handle errors silently during logout

    }
  }
}