// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'user_session_service.dart';
import 'message_state_service.dart';

class WebSocketService {
  // ================= SINGLETON =================
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  String? _userId;
  String? _token;
  bool _isConnecting = false;
  bool _manualDisconnect = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // Queue for messages to send when connection is restored
  final List<Map<String, dynamic>> _messageQueue = [];

  // ================= CALLBACKS =================
  void Function(Map<String, dynamic>)? onMessageReceived;
  void Function()? onConnected;
  void Function()? onDisconnected;
  void Function(dynamic)? onError;

  // ================= CONSTANTS =================
  static const int _pingInterval = 25;
  static const int _reconnectDelay = 3;

  // ================= CONNECT =================
  Future<void> connect() async {
    if (_isConnecting || isConnected) return;

    _isConnecting = true;
    _manualDisconnect = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      _token = prefs.getString('user_token');

      if (_userId == null || _token == null) {
        print('❌ No user session found for WebSocket');
        _isConnecting = false;
        _scheduleReconnect();
        return;
      }

      print('🔗 Connecting WebSocket for user: $_userId');

      final wsUrl = '$kWebSocketUrl?user_id=$_userId&token=$_token';

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _channel!.stream.listen(
        _handleIncoming,
        onDone: _handleDisconnect,
        onError: _handleError,
        cancelOnError: true,
      );

      _startPing();
      _isConnecting = false;
      onConnected?.call();
      print('✅ WebSocket connected successfully');

      // Send any queued messages
      _flushMessageQueue();

    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnecting = false;
      _handleError(e);
    }
  }

  // ================= INCOMING MESSAGE HANDLER =================
  void _handleIncoming(dynamic message) {
    try {
      if (message is String) {
        if (message == 'pong') {
          return;
        }

        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          final type = decoded['type'];

          // Notify MessageStateService for UI updates
          if (type == 'new_message' ||
              type == 'message_delivered' ||
              type == 'message_read' ||
              type == 'conversation_updated') {

            final conversationId = decoded['conversation_id'] ??
                decoded['message']?['conversation_id'];

            if (conversationId != null) {
              MessageStateService().notifyConversationUpdate(conversationId.toString());
            }
          }

          // Call the callback
          onMessageReceived?.call(decoded);
        }
      }
    } catch (e) {
      print('WebSocket parse error: $e');
    }
  }

  // ================= PING =================
  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(
      Duration(seconds: _pingInterval),
          (_) {
        if (isConnected) {
          try {
            _channel?.sink.add('ping');
          } catch (e) {
            _handleError(e);
          }
        }
      },
    );
  }

  // ================= DISCONNECT HANDLERS =================
  void _handleDisconnect() {
    print('🔌 WebSocket disconnected');
    _cleanup();
    onDisconnected?.call();

    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _handleError(dynamic error) {
    print('❌ WebSocket error: $error');
    _cleanup();
    onError?.call(error);

    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: _reconnectDelay),
          () {
        print('🔄 Attempting WebSocket reconnection...');
        connect();
      },
    );
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      _channel?.sink.close(status.goingAway);
    } catch (_) {}

    _channel = null;
    _isConnecting = false;
  }

  // ================= MESSAGE QUEUE =================
  void _flushMessageQueue() {
    if (_messageQueue.isEmpty || !isConnected) return;

    for (final message in List.from(_messageQueue)) {
      try {
        _channel?.sink.add(jsonEncode(message));
        _messageQueue.remove(message);
      } catch (e) {
        print('❌ Error sending queued message: $e');
        break;
      }
    }
  }

  // ================= PUBLIC API =================
  bool get isConnected => _channel != null;

  void send(Map<String, dynamic> message) {
    // If not connected, queue the message
    if (!isConnected) {
      _messageQueue.add(message);

      // Try to connect if not already connecting
      if (!_isConnecting) {
        connect();
      }
      return;
    }

    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('❌ Error sending message: $e');
      // Queue message for retry
      _messageQueue.add(message);
      _handleError(e);
    }
  }

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _messageQueue.clear();
    _cleanup();
  }

  void clearQueue() {
    _messageQueue.clear();
  }

  // Clear callbacks (important for widget disposal)
  void clearCallbacks() {
    onMessageReceived = null;
    onConnected = null;
    onDisconnected = null;
    onError = null;
  }
}