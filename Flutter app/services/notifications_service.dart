// NotificationsService for app-wide push notification handling and in-app notification state
// Usage:
//   - Call NotificationsService().initialize(context) once at app startup
//   - Access NotificationsService().notificationsStream or .notifications for new in-app notifications (listen from notification page)

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'user_session_service.dart';
import '../app_navigator.dart';
import '../screens/student/notifications_page.dart';
import '../screens/landlord/notifications_page.dart';

enum NotificationType {
  booking,
  message,
  payment,
  maintenance,
  review,
  system,
  other
}

class AppNotification {
  final String id;
  final String? title;
  final String? body;
  final DateTime sentTime;
  final Map<String, dynamic> data;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    this.title,
    this.body,
    required this.sentTime,
    required this.data,
    this.type = NotificationType.other,
    this.isRead = false,
  });

  // Convert to Map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'sentTime': sentTime.toIso8601String(),
      'data': data,
      'type': type.toString(),
      'isRead': isRead,
    };
  }

  // Create from Map for deserialization
  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      sentTime: DateTime.parse(map['sentTime']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.other,
      ),
      isRead: map['isRead'] ?? false,
    );
  }

  // Convert to JSON string
  String toJson() => json.encode(toMap());

  // Create from JSON string
  factory AppNotification.fromJson(String source) =>
      AppNotification.fromMap(json.decode(source));
}

class NotificationsService {
  static final NotificationsService _instance = NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();
  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notifsController = StreamController<List<AppNotification>>.broadcast();
  static const String _storageKey = 'notifications';
  static const int _maxNotifications = 100; // Keep only the most recent 100 notifications

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Stream<List<AppNotification>> get notificationsStream => _notifsController.stream;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize(BuildContext context) async {
    // Local notifications (Android/iOS)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!);
            _markAsRead(data['id']);
            _handleNotificationNavigation(data);
          } catch (e) {//todo: add toast
          }
        }
      },
    );

    // Request notification permissions (required for iOS)
    await _firebaseMessaging.requestPermission();

    // Load saved notifications
    await _loadNotifications();

    // FCM foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message);
    });

    // Notification tap while app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleIncomingMessage(message, wasOpened: true);
    });

    // Optionally handle background messages (static/top-level only)
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  }

  // Handle navigation based on notification type and data
  void _handleNotificationNavigation(Map<String, dynamic> data) async {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final notificationType = _getNotificationType(data['type']);
      final userType = await UserSessionService.getUserType();
      
      switch (notificationType) {
        case NotificationType.payment:
          // Navigate to bookings tab with payment data
          final bookingId = data['booking_id'] as String?;

          
          if (bookingId != null) {
            if (userType == 'student') {
              // Navigate to student dashboard with bookings tab (index 1)
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/student-dashboard',
                (route) => false,
                arguments: 1, // Bookings tab index
              );
            } else if (userType == 'landlord') {
              // Navigate to landlord dashboard with bookings tab (index 2)
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/landlord-dashboard',
                (route) => false,
              );
            }
          }
          break;
          
        case NotificationType.booking:
          // Navigate to booking details
          final bookingId = data['booking_id'] as String?;
          if (bookingId != null) {
            if (userType == 'student') {
              navigatorKey.currentState?.pushNamed(
                '/student-dashboard',
                arguments: 1, // Bookings tab index
              );
            } else if (userType == 'landlord') {
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/landlord-dashboard',
                (route) => false,
              );
            }
          }
          break;
          
        case NotificationType.message:
          // Navigate to messages tab
          if (userType == 'student') {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/student-dashboard',
              (route) => false,
              arguments: 2, // Messages tab index
            );
          } else if (userType == 'landlord') {
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/landlord-dashboard',
              (route) => false,
            );
          }
          break;
          
        case NotificationType.system:
        case NotificationType.other:
        default:
          // Navigate to appropriate notifications page
          if (userType == 'student') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          } else if (userType == 'landlord') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const LandlordNotificationsPage(),
              ),
            );
          }
          break;
      }
    } catch (e) {
      // If navigation fails, default to opening notifications page
      try {
        final context = navigatorKey.currentContext;
        final userType = await UserSessionService.getUserType();
        if (context != null) {
          if (userType == 'student') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
          } else if (userType == 'landlord') {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => const LandlordNotificationsPage(),
              ),
            );
          }
        }
      } catch (e) {
        // Silent fail if navigation completely fails
      }
    }
  }

  // Handle incoming message and add to notifications
  void _handleIncomingMessage(RemoteMessage message, {bool wasOpened = false}) async {
    final notif = message.notification;
    if (notif != null) {
      // Determine notification type from data or default to 'other'
      final type = _getNotificationType(message.data['type']);
      
      // Create notification
      // Use notification_id from data if available, otherwise use messageId
      final id = message.data['notification_id'] ?? 
                 message.messageId ?? 
                 DateTime.now().millisecondsSinceEpoch.toString();

      final appNotif = AppNotification(
        id: id,
        title: notif.title,
        body: notif.body,
        sentTime: message.sentTime ?? DateTime.now(),
        data: message.data,
        type: type,
        isRead: wasOpened,
      );

      // Add to in-memory list and notify listeners
      // Check if already exists to avoid duplicates
      final existingIndex = _notifications.indexWhere((n) => n.id == id);
      if (existingIndex != -1) {
        _notifications[existingIndex] = appNotif;
      } else {
        _notifications.insert(0, appNotif);
      }
      
      // Keep only the most recent notifications
      if (_notifications.length > _maxNotifications) {
        _notifications.removeRange(_maxNotifications, _notifications.length);
      }
      
      // Save to persistent storage
      await _saveNotifications();
      _notifsController.add(List.unmodifiable(_notifications));

      // Handle navigation if notification was opened from background/terminated state
      if (wasOpened) {
        _handleNotificationNavigation(message.data);
      }

      // Show local notification if not opened from tap
      if (!wasOpened) {
        await _localPlugin.show(
          appNotif.id.hashCode,
          appNotif.title,
          appNotif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'palevel_channel',
              'Palevel Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              styleInformation: BigTextStyleInformation(
                appNotif.body ?? '',
                htmlFormatBigText: true,
                contentTitle: appNotif.title,
                htmlFormatContentTitle: true,
              ),
            ),
          ),
          payload: json.encode(appNotif.toMap()),
        );
      }
    }
  }

  // Mark a notification as read
  Future<void> _markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      await _saveNotifications();
      _notifsController.add(List.unmodifiable(_notifications));
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    for (var notif in _notifications) {
      notif.isRead = true;
    }
    await _saveNotifications();
    _notifsController.add(List.unmodifiable(_notifications));
  }

  // Delete a notification
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _saveNotifications();
    _notifsController.add(List.unmodifiable(_notifications));
  }

  // Clear all notifications for current user
  Future<void> clearAllNotifications() async {
    _notifications.clear();
    await _saveNotifications();
    _notifsController.add(List.unmodifiable(_notifications));
  }

  // Load notifications from shared preferences
  // Filters notifications to only include those for the current user
  Future<void> _loadNotifications() async {
    try {
      final currentUserId = await UserSessionService.getUserId();
      if (currentUserId == null) {
        // If no user is logged in, clear notifications
        _notifications.clear();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final allNotifications = jsonList.map((json) => AppNotification.fromMap(json)).toList();
        
        // Filter notifications to only include those for the current user
        // Backend notifications should have user_id in data, but we'll also check if they were fetched for this user
        _notifications.clear();
        _notifications.addAll(
          allNotifications.where((n) {
            // If notification has user_id in data, check it matches
            final notifUserId = n.data['user_id']?.toString();
            // If no user_id in data, assume it's for current user (legacy notifications)
            return notifUserId == null || notifUserId == currentUserId;
          }).toList(),
        );
      }
    } catch (e) {//todo: add toast
    }
  }
  
  /// Clear all notifications (useful when user logs out)
  Future<void> clearNotificationsForLogout() async {
    _notifications.clear();
    await _saveNotifications();
    _notifsController.add(List.unmodifiable(_notifications));
  }

  // Save notifications to shared preferences
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _notifications.map((n) => n.toMap()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) { //todo: add toast
    }
  }

  // Determine notification type from string
  NotificationType _getNotificationType(String? typeStr) {
    if (typeStr == null) return NotificationType.other;
    
    final typeName = typeStr.startsWith('NotificationType.') 
        ? typeStr.split('.').last 
        : typeStr;
        
    return NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeName,
      orElse: () => NotificationType.other,
    );
  }

  // ============================================
  // Backend API Integration Methods
  // ============================================

  /// Fetch notifications from backend API and merge with local notifications
  Future<List<AppNotification>> fetchNotificationsFromBackend({
    bool? isRead,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final userId = await UserSessionService.getUserId();
      if (userId == null) {
        return [];
      }

      // Build query parameters
      final queryParams = <String, String>{
        'user_id': userId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (isRead != null) {
        queryParams['is_read'] = isRead.toString();
      }
      
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$kBaseUrl/notifications').replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final notificationsList = body['notifications'] as List?;
        
        if (notificationsList == null) {
          return List.unmodifiable(_notifications);
        }

        final backendNotifications = notificationsList.map((json) {
          // Ensure user_id is in the data for filtering
          final data = Map<String, dynamic>.from(json['data'] ?? {});
          if (json['user_id'] != null) {
            data['user_id'] = json['user_id'].toString();
          } else {
            // If user_id not in data, add current user_id
            data['user_id'] = userId;
          }
          
          return AppNotification(
            id: json['notification_id'] ?? json['id'] ?? '',
            title: json['title'],
            body: json['body'],
            sentTime: DateTime.parse(json['created_at']),
            data: data,
            type: _getNotificationType(json['type']),
            isRead: json['is_read'] ?? false,
          );
        }).toList();

        // Merge backend notifications with local notifications
        // Create a map of existing notifications by ID
        final existingMap = <String, AppNotification>{};
        for (var notif in _notifications) {
          existingMap[notif.id] = notif;
        }

        // Update or add backend notifications
        for (var backendNotif in backendNotifications) {
          if (existingMap.containsKey(backendNotif.id)) {
            // Update existing notification (preserve local state if needed)
            final existing = existingMap[backendNotif.id]!;
            // Keep local read state if it's more recent, otherwise use backend state
            existingMap[backendNotif.id] = AppNotification(
              id: backendNotif.id,
              title: backendNotif.title,
              body: backendNotif.body,
              sentTime: backendNotif.sentTime,
              data: backendNotif.data,
              type: backendNotif.type,
              isRead: existing.isRead || backendNotif.isRead, // If either is read, mark as read
            );
          } else {
            // Add new notification from backend
            existingMap[backendNotif.id] = backendNotif;
          }
        }

        // Convert back to list and sort by date (newest first)
        final mergedNotifications = existingMap.values.toList()
          ..sort((a, b) => b.sentTime.compareTo(a.sentTime));

        // Filter notifications to only include those for the current user
        // Get current user ID to ensure we only store their notifications
        final currentUserId = await UserSessionService.getUserId();
        final filteredNotifications = currentUserId != null
            ? mergedNotifications.where((n) {
                // Check if notification data contains user_id that matches current user
                // If notification was fetched from backend, it's already filtered by user_id
                // But we need to filter local cached notifications too
                final notifUserId = n.data['user_id']?.toString();
                return notifUserId == null || notifUserId == currentUserId;
              }).toList()
            : mergedNotifications;

        // Update local cache - clear and add only current user's notifications
        _notifications.clear();
        _notifications.addAll(filteredNotifications);
        
        // Keep only the most recent notifications
        if (_notifications.length > _maxNotifications) {
          _notifications.removeRange(_maxNotifications, _notifications.length);
        }
        
        await _saveNotifications();
        _notifsController.add(List.unmodifiable(_notifications));

        return List.unmodifiable(_notifications);
      } else {
        return List.unmodifiable(_notifications);
      }
    } catch (e) {
      return List.unmodifiable(_notifications);
    }
  }

  /// Mark a notification as read on backend
  Future<bool> markAsReadOnBackend(String notificationId) async {
    try {
      final userId = await UserSessionService.getUserId();
      if (userId == null) {
        return false;
      }

      final uri = Uri.parse('$kBaseUrl/notifications/$notificationId/read').replace(
        queryParameters: {'user_id': userId},
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        await _markAsRead(notificationId);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read on backend
  Future<bool> markAllAsReadOnBackend({String? type}) async {
    try {
      final userId = await UserSessionService.getUserId();
      if (userId == null) {
        return false;
      }

      final queryParams = <String, String>{'user_id': userId};
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$kBaseUrl/notifications/read-all').replace(
        queryParameters: queryParams,
      );

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        await markAllAsRead();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Delete a notification on backend
  Future<bool> deleteNotificationOnBackend(String notificationId) async {
    try {
      final userId = await UserSessionService.getUserId();
      if (userId == null) {
        return false;
      }

      final uri = Uri.parse('$kBaseUrl/notifications/$notificationId').replace(
        queryParameters: {'user_id': userId},
      );

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        await deleteNotification(notificationId);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Get notification statistics from backend
  Future<Map<String, dynamic>?> getNotificationStats() async {
    try {
      final userId = await UserSessionService.getUserId();
      if (userId == null) {
        return null;
      }

      final uri = Uri.parse('$kBaseUrl/notifications/stats/summary').replace(
        queryParameters: {'user_id': userId},
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // For use in main():
  static Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
    // This is a top-level handler for background messages
    // We can't directly use the service here, so we'll save the message to be processed when the app is opened

    // You might want to save the message to shared preferences here
    // and process it when the app is opened next time
  }
}
