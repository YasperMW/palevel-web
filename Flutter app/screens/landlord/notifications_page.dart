import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/notifications_service.dart';

class LandlordNotificationsPage extends StatefulWidget {
  const LandlordNotificationsPage({super.key});

  @override
  State<LandlordNotificationsPage> createState() => _LandlordNotificationsPageState();
}

class _LandlordNotificationsPageState extends State<LandlordNotificationsPage> {
  final List<NotificationItem> _notifications = [];
  bool _isLoading = false;
  late final StreamSubscription<List<AppNotification>> _notifSub;

  @override
  void initState() {
    super.initState();
    
    // Load initial notifications from local cache first (instant display)
    final current = NotificationsService().notifications;
    if (current.isNotEmpty) {
      setState(() {
        _notifications.clear();
        _notifications.addAll(current.map(_mapAppNotification));
      });
    }
    
    // Then fetch from backend to sync
    _loadNotificationsFromBackend();

    // Listen for app notifications (FCM push notifications) - this will update instantly
    _notifSub = NotificationsService().notificationsStream.listen((notifs) {
      if (mounted) {
        setState(() {
          _notifications.clear();
          _notifications.addAll(notifs.map(_mapAppNotification));
        });
      }
    });
  }

  @override
  void dispose() {
    _notifSub.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationsFromBackend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await NotificationsService().fetchNotificationsFromBackend();
      setState(() {
        _notifications.clear();
        _notifications.addAll(notifications.map(_mapAppNotification));
        _isLoading = false;
      });
    } catch (e) {
      //todo: add toast;
      setState(() {
        _isLoading = false;
      });
    }
  }

  NotificationItem _mapAppNotification(AppNotification n) {
    // Map notification type from backend (AppNotification uses NotificationType from service)
    // We need to map from the service's NotificationType to the local NotificationType enum
    NotificationType type = NotificationType.booking;
    
    // n.type is from notifications_service.dart enum which includes: booking, message, payment, maintenance, review, system, other
    if (n.type.toString().contains('booking')) {
      type = NotificationType.booking;
    } else if (n.type.toString().contains('payment')) {
      type = NotificationType.payment;
    } else if (n.type.toString().contains('message')) {
      type = NotificationType.message;
    } else if (n.type.toString().contains('maintenance')) {
      type = NotificationType.maintenance;
    } else if (n.type.toString().contains('review')) {
      type = NotificationType.review;
    } else if (n.type.toString().contains('system')) {
      type = NotificationType.maintenance; // Map system to maintenance for landlord
    } else {
      // other or unknown
      type = NotificationType.booking;
    }
    
    return NotificationItem(
      id: n.id,
      title: n.title ?? 'Notification',
      message: n.body ?? '',
      time: n.sentTime,
      type: type,
      isRead: n.isRead,
    );
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF07746B),
              Color(0xFF0DDAC9),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        'Mark all as read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Notifications list
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _loadNotificationsFromBackend,
                      color: const Color(0xFF07746B),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF07746B)))
                          : _notifications.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.only(top: 16),
                                  itemCount: _notifications.length,
                                  itemBuilder: (context, index) {
                                    return _buildNotificationItem(_notifications[index]);
                                  },
                                ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }

  void _showFullNotificationDialog(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and close button
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type).withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Full message
                Text(
                  notification.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time
                Text(
                  _formatFullDateTime(notification.time),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF07746B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFullDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy at hh:mm a').format(date);
  }

  Future<void> _markAllAsRead() async {
    // Update UI immediately
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i].isRead = true;
        }
      }
    });
    
    // Sync with backend
    await NotificationsService().markAllAsReadOnBackend();
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final iconData = _getNotificationIcon(notification.type);
    final iconColor = _getNotificationColor(notification.type);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 30),
      ),
      onDismissed: (direction) async {
        final deletedNotification = notification;
        setState(() {
          _notifications.removeWhere((item) => item.id == notification.id);
        });
        
        // Sync with backend
        await NotificationsService().deleteNotificationOnBackend(notification.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notification deleted'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () async {
                  // Note: Backend doesn't support undo, so we just restore UI
                  setState(() {
                    _notifications.insert(
                      _notifications.length,
                      deletedNotification,
                    );
                  });
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF0F9F8),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha:0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _formatTime(notification.time),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
            ],
          ),
          onTap: () {
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationItem notification) async {
    // Mark as read if unread
    if (!notification.isRead) {
      setState(() {
        notification.isRead = true;
      });
      // Sync with backend
      await NotificationsService().markAsReadOnBackend(notification.id);
    }

    // Show full notification dialog
    _showFullNotificationDialog(notification);
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today_outlined;
      case NotificationType.message:
        return Icons.message_outlined;
      case NotificationType.payment:
        return Icons.payment_outlined;
      case NotificationType.maintenance:
        return Icons.handyman_outlined;
      case NotificationType.review:
        return Icons.star_border_outlined;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return const Color(0xFF07746B);
      case NotificationType.message:
        return const Color(0xFF2196F3);
      case NotificationType.payment:
        return const Color(0xFF4CAF50);
      case NotificationType.maintenance:
        return const Color(0xFFFF9800);
      case NotificationType.review:
        return const Color(0xFFFFC107);
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(time);
    }
  }
}

enum NotificationType {
  booking,
  message,
  payment,
  maintenance,
  review,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final NotificationType type;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}