// lib/screens/messages/messages_tab_landlord.dart
import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import '../../services/message_service.dart';
import '../../services/user_session_service.dart';
import '../../services/websocket_service.dart';
import '../../services/message_state_service.dart';

class MessagesTab extends StatefulWidget {
  final ScrollController? scrollController;

  const MessagesTab({super.key, this.scrollController});

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
  bool _isWebSocketConnected = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _scrollController = widget.scrollController ?? ScrollController();

    _initializeUser();
    _initWebSocket();

    // Listen to message state changes
    _messageState.addListener(_refreshConversations);

    print('🧑‍💼 Landlord MessagesTab initialized');
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
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
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
      if (_isDisposed || !mounted) return;

      setState(() {
        _conversations = conversations;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _refreshConversations() {
    if (!_isDisposed && mounted) {
      _loadConversations();
    }
  }

  void _initWebSocket() {
    _webSocketService.onMessageReceived = (payload) {
      if (_isDisposed || !mounted) return;

      final type = payload['type'];

      if (type == 'new_message' ||
          type == 'message_delivered' ||
          type == 'message_read' ||
          type == 'conversation_updated') {
        _loadConversations();

        final conversationId = payload['conversation_id'] ??
            payload['message']?['conversation_id'];
        if (conversationId != null) {
          _messageState.notifyConversationUpdate(conversationId.toString());
        }
      }
    };

    _webSocketService.onConnected = () {
      if (!_isDisposed && mounted) {
        setState(() {
          _isWebSocketConnected = true;
        });
      }
    };

    _webSocketService.onDisconnected = () {
      if (!_isDisposed && mounted) {
        setState(() {
          _isWebSocketConnected = false;
        });
      }
    };

    _webSocketService.onError = (error) {
      // Don't call setState on error if disposed
    };

    // Connect WebSocket
    _webSocketService.connect();
  }

  @override
  void dispose() {
    print('🧹 Cleaning up landlord MessagesTab...');
    _isDisposed = true;

    // Remove WebSocket callbacks before disposing
    _webSocketService.onConnected = null;
    _webSocketService.onDisconnected = null;
    _webSocketService.onError = null;

    _messageState.removeListener(_refreshConversations);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_isWebSocketConnected && !_isLoading)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 16, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Text(
                  'Connecting to real-time updates...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadConversations,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_conversations.length} ${_conversations.length == 1 ? 'conversation' : 'conversations'}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        if (_isWebSocketConnected)
                          Row(
                            children: [
                              Icon(Icons.circle, size: 8, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Real-time active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07746B)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading conversations...',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
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
                              backgroundColor: const Color(0xFF07746B),
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
                              (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _MessageCard(
                                message: _conversations[index],
                                currentUserId: _currentUserId ?? '',
                              ),
                            );
                          },
                          childCount: _conversations.length,
                        ),
                      ),
                    ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ],
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
                color: const Color(0xFF07746B).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Color(0xFF07746B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Messages',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF07746B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with students',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
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
    final initials = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U';
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              otherUserName: otherUserName,
              otherUserInitial: initials,
              hostelName: '',
              roomNumber: '',
              isLandlord: false,
              receiverId: message['other_user_id'].toString(),
              currentUserId: currentUserId,
              isCurrentUserLandlord: true,
              conversationId: message['conversation_id'].toString(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasUnread
              ? const Color(0xFF07746B).withAlpha(20)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFF07746B).withAlpha(51)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF07746B),
              child: Text(
                initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF07746B),
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
                  color: Color(0xFF07746B),
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