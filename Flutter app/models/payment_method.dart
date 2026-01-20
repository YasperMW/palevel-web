class PaymentMethod {
  final String id;
  final String type;
  final Map<String, dynamic> details;
  final bool isPreferred;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.details,
    this.isPreferred = false,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      details: Map<String, dynamic>.from(json['details'] as Map),
      isPreferred: json['isPreferred'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'details': details,
      'isPreferred': isPreferred,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }



PaymentMethod copyWith({
  String? id,
  String? type,
  Map<String, dynamic>? details,
  bool? isPreferred,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return PaymentMethod(
    id: id ?? this.id,
    type: type ?? this.type,
    details: details ?? Map.from(this.details),
    isPreferred: isPreferred ?? this.isPreferred,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

}