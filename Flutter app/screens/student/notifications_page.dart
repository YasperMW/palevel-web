import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';


class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String? imageUrl;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.imageUrl,
    this.isRead = false,
    this.type = NotificationType.general,
  });
}

enum NotificationType {
  booking,
  payment,
  message,
  general,
  system,
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final StreamSubscription<List<AppNotification>> _notifSub;
  final List<NotificationItem> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
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
          _notifications
            ..clear()
            ..addAll(notifs.map(_mapAppNotification));
        });
      }
    });
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
    NotificationType type = NotificationType.general;
    
    // n.type is from notifications_service.dart enum which includes: booking, message, payment, maintenance, review, system, other
    if (n.type.toString().contains('booking')) {
      type = NotificationType.booking;
    } else if (n.type.toString().contains('payment')) {
      type = NotificationType.payment;
    } else if (n.type.toString().contains('message')) {
      type = NotificationType.message;
    } else if (n.type.toString().contains('system')) {
      type = NotificationType.system;
    } else {
      // other, maintenance, review, or unknown -> map to general
      type = NotificationType.general;
    }
    
    return NotificationItem(
      id: n.id,
      title: n.title ?? 'Notification',
      message: n.body ?? '',
      date: n.sentTime,
      type: type,
      isRead: n.isRead,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifSub.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 30 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 30 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    // Update UI immediately
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
    
    // Sync with backend
    await NotificationsService().markAsReadOnBackend(id);
  }

  Future<void> _markAllAsRead() async {
    // Update UI immediately
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
    });
    
    // Sync with backend
    await NotificationsService().markAllAsReadOnBackend();
  }

  Future<void> _deleteNotification(String id) async {
    // Update UI immediately
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    
    // Sync with backend
    await NotificationsService().deleteNotificationOnBackend(id);
  }

  @override
  Widget build(BuildContext context) {

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.white,
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: AppColors.white),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotificationsFromBackend,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : _buildNotificationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: AppColors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.white.withValues(alpha:0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_notifications.length} total • ${_notifications.where((n) => !n.isRead).length} unread',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white.withValues(alpha:0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(notification);
              },
              childCount: _notifications.length,
            ),
          ),
        ),
      ],
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
              color: AppColors.white,
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
                      icon: const Icon(Icons.close, color: AppColors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Full message
                Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time
                Text(
                  _formatFullDateTime(notification.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
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

  Widget _buildNotificationItem(NotificationItem notification) {
    final isUnread = !notification.isRead;
    final timeAgo = _formatTimeAgo(notification.date);
    
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text('Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: const Text('DELETE'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteNotification(notification.id),
      child: GestureDetector(
        onTap: () {
          if (isUnread) {
            _markAsRead(notification.id);
          }
          // Show full notification dialog
          _showFullNotificationDialog(notification);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread 
                  ? AppColors.primary.withValues(alpha:0.2)
                  : AppColors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withValues(alpha:0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: isUnread ? AppColors.black.withOpacity(0.87) : AppColors.grey.shade700,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return AppColors.primary;
      case NotificationType.payment:
        return AppColors.success;
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.system:
        return AppColors.warning;
      case NotificationType.general:
        return AppColors.info;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.assignment_turned_in_rounded;
      case NotificationType.payment:
        return Icons.payment_rounded;
      case NotificationType.message:
        return Icons.message_rounded;
      case NotificationType.system:
        return Icons.home_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

extension NotificationItemExtension on NotificationItem {
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    String? imageUrl,
    bool? isRead,
    NotificationType? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
