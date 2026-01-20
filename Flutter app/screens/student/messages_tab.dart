// lib/screens/messages/messages_tab_student.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../chat/chat_screen.dart';
import '../../services/message_service.dart';
import '../../services/user_session_service.dart';
import '../../services/websocket_service.dart';
import '../../services/message_state_service.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  late final ScrollController _scrollController;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _currentUserId;
  String? _currentUserType;
  final WebSocketService _webSocketService = WebSocketService();
  final MessageStateService _messageState = MessageStateService();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _initializeUser();
    _initWebSocket();

    // Listen to message state changes
    _messageState.addListener(_refreshConversations);

    // Set up periodic refresh (every 30 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  Future<void> _initializeUser() async {
    try {
      final userData = await UserSessionService.getCurrentUserData();
      if (userData != null) {
        _currentUserId = userData['user_id'];
        _currentUserType = userData['user_type'];
      }
      await _loadConversations();
    } catch (e) {
      print('Initialize user error: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _refreshConversations() {
    if (mounted) {
      _loadConversations();
    }
  }

  Future<void> _loadConversations() async {
    try {
      if (_currentUserId == null) {
        final userData = await UserSessionService.getCurrentUserData();
        if (userData != null) {
          _currentUserId = userData['user_id'];
          _currentUserType = userData['user_type'];
        }
      }

      final conversations = await MessageService.getConversations();
      if (!mounted) return;

      // Update unread counts from MessageStateService
      for (var conversation in conversations) {
        final convId = conversation['conversation_id']?.toString();
        if (convId != null) {
          final unreadCount = _messageState.getConversationUnreadCount(convId);
          if (unreadCount > 0) {
            conversation['unread_count'] = unreadCount;
          }
        }
      }

      setState(() {
        _conversations = conversations;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      print('Load conversations error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _initWebSocket() {
    _webSocketService.onMessageReceived = (event) {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'new_message' ||
          type == 'message_delivered' ||
          type == 'message_read' ||
          type == 'conversation_updated') {
        _loadConversations();

        // Update unread count for specific conversation
        final conversationId = event['conversation_id'];
        if (conversationId != null && type == 'new_message') {
          final message = event['message'];
          if (message != null && message['receiver_id'] == _currentUserId) {
            _messageState.setConversationUnreadCount(
              conversationId.toString(),
              (_messageState.getConversationUnreadCount(conversationId.toString()) ?? 0) + 1,
            );
          }
        }
      }
    };

    _webSocketService.connect();
  }

  @override
  void dispose() {
    _messageState.removeListener(_refreshConversations);
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${_conversations.length} ${_conversations.length == 1 ? 'conversation' : 'conversations'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (_hasError)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading conversations',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadConversations,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          else if (_conversations.isEmpty)
              _buildEmptyState()
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _MessageCard(
                        message: _conversations[index],
                        currentUserId: _currentUserId ?? '',
                      ),
                    ),
                    childCount: _conversations.length,
                  ),
                ),
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with landlords',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final String currentUserId;

  const _MessageCard({
    required this.message,
    required this.currentUserId,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildTicks() {
    final lastSender = message['last_message_sender_id']?.toString();
    final isMine = lastSender == currentUserId;
    if (!isMine) return const SizedBox();

    final isRead = message['is_read'] == true;
    final unreadCount = message['unread_count'] ?? 0;
    final isDelivered = unreadCount == 0 && !isRead;

    if (isRead) {
      return const Icon(Icons.done_all, size: 16, color: Colors.blue);
    }
    if (isDelivered) {
      return Icon(Icons.done_all, size: 16, color: Colors.grey.shade500);
    }
    return Icon(Icons.done, size: 16, color: Colors.grey.shade500);
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = message['other_user_name']?.toString() ?? 'User';
    final hostelName = message['hostel_name']?.toString();
    final displayName = hostelName != null && hostelName.isNotEmpty
        ? '$hostelName Landlord'
        : otherUserName;

    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final lastMessage = message['last_message']?.toString() ?? '';
    final unreadCount = message['unread_count'] ?? 0;
    final hasUnread = unreadCount > 0;

    String timeAgo = '';
    if (message['last_message_time'] != null) {
      try {
        timeAgo = _formatTimeAgo(
          DateTime.parse(message['last_message_time'].toString()),
        );
      } catch (_) {
        timeAgo = '';
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserName: displayName,
              otherUserInitial: initials,
              hostelName: hostelName,
              isLandlord: true,
              receiverId: message['other_user_id'].toString(),
              currentUserId: currentUserId,
              isCurrentUserLandlord: false,
              conversationId: message['conversation_id'].toString(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? AppColors.primary.withAlpha(51)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildTicks(),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}