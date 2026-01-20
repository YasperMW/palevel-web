// lib/models/message_model.dart
class MessageModel {
  final String id;
  final String content;
  final String senderId;
  final String senderType; // 'student' or 'landlord'
  final String receiverId;
  final String receiverType; // 'student' or 'landlord'
  final DateTime createdAt;
  bool isRead;
  bool isDelivered;

  MessageModel({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderType,
    required this.receiverId,
    required this.receiverType,
    required this.createdAt,
    this.isRead = false,
    this.isDelivered = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? json['message_id']?.toString() ?? '',
      content: json['content'] ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderType: json['sender_type'] ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      receiverType: json['receiver_type'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      isDelivered: json['is_delivered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'sender_type': senderType,
      'receiver_id': receiverId,
      'receiver_type': receiverType,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'is_delivered': isDelivered,
    };
  }

  MessageModel copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderType,
    String? receiverId,
    String? receiverType,
    DateTime? createdAt,
    bool? isRead,
    bool? isDelivered,
  }) {
    return MessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      receiverId: receiverId ?? this.receiverId,
      receiverType: receiverType ?? this.receiverType,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
    );
  }
}