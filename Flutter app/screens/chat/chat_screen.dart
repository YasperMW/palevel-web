// lib/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../models/message_model.dart';
import '../../services/message_service.dart';
import '../../services/websocket_service.dart';
import '../../services/message_state_service.dart';
import '../../services/user_session_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserName;
  final String otherUserInitial;
  final String? hostelName;
  final String? roomNumber;
  final bool isLandlord;
  final String receiverId;
  final String? currentUserId;
  final bool isCurrentUserLandlord;
  final String? conversationId;

  const ChatScreen({
    super.key,
    required this.otherUserName,
    required this.otherUserInitial,
    this.hostelName,
    this.roomNumber,
    required this.isLandlord,
    required this.receiverId,
    this.currentUserId,
    required this.isCurrentUserLandlord,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final WebSocketService _webSocketService = WebSocketService();
  final MessageStateService _messageState = MessageStateService();

  List<MessageModel> _messages = [];
  String? _conversationId;
  late String _receiverId;
  String? _currentUserId;
  String? _currentUserType;
  bool _isLoading = false;
  bool _isSending = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _receiverId = widget.receiverId;
    _conversationId = widget.conversationId;

    _initializeUser();
    _initWebSocket();
  }

  Future<void> _initializeUser() async {
    try {
      final userData = await UserSessionService.getCurrentUserData();
      if (userData != null) {
        _currentUserId = userData['user_id'];
        _currentUserType = userData['user_type'];
      } else {
        _currentUserId = widget.currentUserId;
        _currentUserType = widget.isCurrentUserLandlord ? 'landlord' : 'student';
      }

      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }

      await _loadMessages();
      _markMessagesAsRead();
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load user data';
        });
      }
    }
  }

  // ================= WEBSOCKET INIT =================
  void _initWebSocket() {
    _webSocketService.onMessageReceived = (data) {
      if (_isDisposed || !mounted) return;

      final type = data['type'];
      final convId = data['conversation_id'] ?? data['message']?['conversation_id'];

      if (_conversationId != null && convId != null && convId != _conversationId) {
        return;
      }

      if (type == 'new_message') {
        _handleNewMessage(data['message']);
      } else if (type == 'message_delivered') {
        final messageId = data['message_id'];
        if (messageId != null) {
          _updateMessageDeliveryStatus(messageId.toString());
        }
      } else if (type == 'message_read') {
        _handleMessageRead(data);
      } else if (type == 'conversation_updated') {
        _messageState.notifyConversationUpdate(convId.toString());
      }
    };

    _webSocketService.onConnected = () {
      // Optional: You can handle connection success here
    };

    _webSocketService.onDisconnected = () {
      // Optional: You can handle disconnection here
    };

    _webSocketService.onError = (error) {
      // Don't call setState on error if disposed
    };

    if (!_webSocketService.isConnected) {
      _webSocketService.connect();
    }

    if (_conversationId != null) {
      _messageState.addConversationListener(_conversationId!, _onConversationUpdate);
    }

    _messageState.addListener(_updateMessageStatus);
  }

  void _onConversationUpdate() {
    if (!_isDisposed && mounted && !_isSending) {
      _loadMessages();
    }
  }

  void _updateMessageStatus() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _messages = _messages.map((message) {
        final messageId = message.id;
        if (_messageState.isMessageRead(messageId)) {
          return message.copyWith(isRead: true, isDelivered: true);
        } else if (_messageState.isMessageDelivered(messageId)) {
          return message.copyWith(isDelivered: true);
        }
        return message;
      }).toList();
    });
  }

  void _updateMessageDeliveryStatus(String messageId) {
    if (_isDisposed || !mounted) return;

    setState(() {
      _messages = _messages.map((message) {
        if (message.id == messageId) {
          return message.copyWith(isDelivered: true);
        }
        return message;
      }).toList();
    });
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    if (_isDisposed || !mounted) return;

    final messageIds = data['message_ids'] as List<dynamic>?;
    if (messageIds != null) {
      setState(() {
        _messages = _messages.map((message) {
          if (messageIds.contains(message.id) && message.senderId == _currentUserId) {
            return message.copyWith(isRead: true, isDelivered: true);
          }
          return message;
        }).toList();
      });
    }
  }

  // ================= MESSAGE HANDLERS =================
  void _handleNewMessage(Map<String, dynamic>? messageData) {
    if (messageData == null) return;

    try {
      final newMessage = MessageModel.fromJson(messageData);

      final exists = _messages.any((msg) => msg.id == newMessage.id);
      if (exists) return;

      if (_conversationId == null && messageData['conversation_id'] != null) {
        _conversationId = messageData['conversation_id'].toString();
        _messageState.addConversationListener(_conversationId!, _onConversationUpdate);
      }

      if (!_isDisposed && mounted) {
        setState(() {
          _messages.add(newMessage);
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        });

        _scrollToBottom();
      }

      if (newMessage.receiverId == _currentUserId && !newMessage.isRead) {
        _markMessagesAsRead();
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  // ================= LOAD MESSAGES =================
  Future<void> _loadMessages() async {
    if (_receiverId.isEmpty || _currentUserId == null) return;

    if (_isLoading) return;
    _isLoading = true;

    try {
      if (_conversationId == null) {
        final conversations = await MessageService.getConversations();
        final existing = conversations.firstWhere(
              (c) => c['other_user_id'].toString() == _receiverId,
          orElse: () => {},
        );

        if (existing.isNotEmpty) {
          _conversationId = existing['conversation_id']?.toString();
          if (_conversationId != null) {
            _messageState.addConversationListener(_conversationId!, _onConversationUpdate);
          }
        }
      }

      if (_conversationId != null) {
        final messages = await MessageService.getMessages(_conversationId!);
        if (_isDisposed || !mounted) return;

        if (!_isDisposed && mounted) {
          setState(() {
            _messages = messages..sort((a, b) => a.createdAt.compareTo(b.createdAt));
            _hasError = false;
          });

          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Load messages error: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (_conversationId != null && _currentUserId != null) {
      try {
        await MessageService.markAsRead(_conversationId!);

        if (!_isDisposed && mounted) {
          setState(() {
            _messages = _messages.map((message) {
              if (message.receiverId == _currentUserId && !message.isRead) {
                return message.copyWith(isRead: true, isDelivered: true);
              }
              return message;
            }).toList();
          });
        }
      } catch (e) {
        print('Mark as read error: $e');
      }
    }
  }

  // ================= SEND MESSAGE =================
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _isSending) return;

    _messageController.clear();
    _isSending = true;

    // Create temporary message
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = MessageModel(
      id: tempId,
      content: text,
      senderId: _currentUserId!,
      senderType: _currentUserType ?? 'student',
      receiverId: _receiverId,
      receiverType: widget.isLandlord ? 'landlord' : 'student',
      createdAt: DateTime.now(),
      isRead: false,
      isDelivered: false,
    );

    // Add to UI immediately
    if (!_isDisposed && mounted) {
      setState(() {
        _messages.add(tempMessage);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

      _scrollToBottom();
    }

    try {
      final response = await MessageService.sendMessage(
        receiverId: _receiverId,
        content: text,
        conversationId: _conversationId,
      );

      // Get real message ID
      final realMessageId = response['message_id']?.toString() ?? response['id']?.toString();
      final newConvId = response['conversation_id']?.toString();

      if (realMessageId != null) {
        // Update conversation ID if needed
        if (newConvId != null && _conversationId != newConvId) {
          _conversationId = newConvId;
          _messageState.addConversationListener(_conversationId!, _onConversationUpdate);
        }

        // Replace temp message with real message
        final realMessage = tempMessage.copyWith(
          id: realMessageId,
          createdAt: DateTime.parse(response['created_at']),
        );

        if (!_isDisposed && mounted) {
          setState(() {
            final index = _messages.indexWhere((msg) => msg.id == tempId);
            if (index != -1) {
              _messages[index] = realMessage;
            }
          });
        }

        // Notify via WebSocket
        _webSocketService.send({
          'type': 'message_sent',
          'message_id': realMessageId,
          'conversation_id': _conversationId,
        });

      }

    } catch (e) {
      print('Send message error: $e');

      // Update temp message to show error state
      if (!_isDisposed && mounted) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.id == tempId);
          if (index != -1) {
            // Keep the message but mark it visually as failed
            _messages[index] = _messages[index].copyWith(
              // You could add an error property to MessageModel
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // ================= UI HELPERS =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildMessageTicks(MessageModel message) {
    final isMine = message.senderId == _currentUserId;
    if (!isMine) return const SizedBox();

    if (message.isRead) {
      return const Icon(Icons.done_all, size: 14, color: Colors.blue);
    } else if (message.isDelivered) {
      return const Icon(Icons.done_all, size: 14, color: Colors.grey);
    } else if (message.id.startsWith('temp-')) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
        ),
      );
    } else {
      return const Icon(Icons.done, size: 14, color: Colors.grey);
    }
  }

  Widget _buildMessage(MessageModel message) {
    final isMine = message.senderId == _currentUserId;
    final isPending = message.id.startsWith('temp-');

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? (isPending ? Colors.grey[300] : AppColors.primary)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine
                    ? (isPending ? Colors.grey[700] : Colors.white)
                    : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMine
                        ? (isPending ? Colors.grey[600] : Colors.white70)
                        : Colors.grey[600],
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  _buildMessageTicks(message),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (_isLoading && _messages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading messages...',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_hasError && _messages.isEmpty)
            Expanded(
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
                      'Error loading messages',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMessages,
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
          else if (_messages.isEmpty && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Send your first message to start the conversation',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final m = _messages[i];
                    final showDate = i == 0 ||
                        !_isSameDay(
                          m.createdAt,
                          _messages[i - 1].createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate)
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(m.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        _buildMessage(m),
                      ],
                    );
                  },
                ),
              ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: _isSending ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('🧹 Cleaning up ChatScreen...');
    _isDisposed = true;

    // Clear WebSocket callbacks
    _webSocketService.onMessageReceived = null;
    _webSocketService.onConnected = null;
    _webSocketService.onDisconnected = null;
    _webSocketService.onError = null;

    if (_conversationId != null) {
      _messageState.removeConversationListener(
        _conversationId!,
        _onConversationUpdate,
      );
    }
    _messageState.removeListener(_updateMessageStatus);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}