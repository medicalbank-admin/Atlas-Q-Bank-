import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlanModel {
  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.features,
    required this.accessPermissions,
    required this.isActive,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final int durationDays;
  final double price;
  final String currency;
  final List<String> features;

  /// Permissions configured by the academy administrator.
  /// These values must be enforced by trusted backend services.
  final Map<String, bool> accessPermissions;

  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubscriptionPlanModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? {};

    return SubscriptionPlanModel(
      id: document.id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      durationDays: (data['durationDays'] as num?)?.toInt() ?? 30,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      currency: data['currency']?.toString() ?? 'USD',
      features: List<String>.from(
        data['features'] ?? const [],
      ),
      accessPermissions: Map<String, bool>.from(
        data['accessPermissions'] ?? const {},
      ),
      isActive: data['isActive'] == true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: _dateFrom(data['createdAt']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'durationDays': durationDays,
      'price': price,
      'currency': currency,
      'features': features,
      'accessPermissions': accessPermissions,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  SubscriptionPlanModel copyWith({
    String? id,
    String? name,
    String? description,
    int? durationDays,
    double? price,
    String? currency,
    List<String>? features,
    Map<String, bool>? accessPermissions,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      durationDays: durationDays ?? this.durationDays,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      features: features ?? this.features,
      accessPermissions:
          accessPermissions ?? this.accessPermissions,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
