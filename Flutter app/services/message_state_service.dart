// lib/services/message_state_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class MessageStateService with ChangeNotifier {
  static final MessageStateService _instance = MessageStateService._internal();
  factory MessageStateService() => _instance;
  MessageStateService._internal();

  // Track conversations that need updating
  final Set<String> _conversationsToUpdate = {};
  final Map<String, List<VoidCallback>> _conversationListeners = {};

  // Track message delivery status
  final Map<String, bool> _messageDeliveryStatus = {};
  final Map<String, bool> _messageReadStatus = {};

  // Track unread counts
  final Map<String, int> _conversationUnreadCounts = {};

  void addConversationListener(String conversationId, VoidCallback listener) {
    if (!_conversationListeners.containsKey(conversationId)) {
      _conversationListeners[conversationId] = [];
    }

    // Check if listener already exists
    if (!_conversationListeners[conversationId]!.contains(listener)) {
      _conversationListeners[conversationId]!.add(listener);
    }
  }

  void removeConversationListener(String conversationId, VoidCallback listener) {
    _conversationListeners[conversationId]?.remove(listener);
  }

  void notifyConversationUpdate(String conversationId) {
    _conversationsToUpdate.add(conversationId);

    // Notify specific conversation listeners
    final listeners = _conversationListeners[conversationId];
    if (listeners != null) {
      for (final listener in List.from(listeners)) {
        try {
          listener();
        } catch (e) {
          print('Error in conversation listener: $e');
        }
      }
    }

    // Notify global listeners (for MessagesTab)
    notifyListeners();
  }

  void setMessageDelivered(String messageId) {
    _messageDeliveryStatus[messageId] = true;
    notifyListeners();
  }

  void setMessageRead(String messageId) {
    _messageReadStatus[messageId] = true;
    _messageDeliveryStatus[messageId] = true;
    notifyListeners();
  }

  void setConversationUnreadCount(String conversationId, int count) {
    _conversationUnreadCounts[conversationId] = count;
    notifyListeners();
  }

  bool isMessageDelivered(String messageId) {
    return _messageDeliveryStatus[messageId] ?? false;
  }

  bool isMessageRead(String messageId) {
    return _messageReadStatus[messageId] ?? false;
  }

  int getConversationUnreadCount(String conversationId) {
    return _conversationUnreadCounts[conversationId] ?? 0;
  }

  bool shouldUpdateConversation(String conversationId) {
    return _conversationsToUpdate.contains(conversationId);
  }

  void clearConversationUpdate(String conversationId) {
    _conversationsToUpdate.remove(conversationId);
  }

  void clearAll() {
    _conversationsToUpdate.clear();
    _conversationListeners.clear();
    _messageDeliveryStatus.clear();
    _messageReadStatus.clear();
    _conversationUnreadCounts.clear();
    notifyListeners();
  }
}