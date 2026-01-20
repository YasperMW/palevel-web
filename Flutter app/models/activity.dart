// lib/models/activity.dart
import 'package:equatable/equatable.dart';

enum ActivityType {
  notification,
  booking,
  payment,
  review,
  maintenance,
  system,
  message,
}

class Activity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final bool isRead;
  final String? sourceId;
  final String? sourceType;

  const Activity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
    this.isRead = false,
    this.sourceId,
    this.sourceType,
  });

  @override
  List<Object?> get props => [id];

  Activity copyWith({
    bool? isRead,
    String? title,
    String? description,
  }) {
    return Activity(
      id: id,
      type: type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp,
      metadata: metadata,
      isRead: isRead ?? this.isRead,
      sourceId: sourceId,
      sourceType: sourceType,
    );
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] ?? {},
      isRead: json['isRead'] ?? false,
      sourceId: json['sourceId'],
      sourceType: json['sourceType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'isRead': isRead,
      'sourceId': sourceId,
      'sourceType': sourceType,
    };
  }
}