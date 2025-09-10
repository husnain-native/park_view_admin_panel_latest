import 'package:flutter/material.dart';

enum PropertyType {
  commercial('Commercial', Icons.business),
  residential('Residential', Icons.home),
  buy('Buy', Icons.shopping_cart),
  rent('Rent', Icons.key),
  plot('Plot', Icons.terrain),
  apartment('Apartment', Icons.apartment);

  final String label;
  final IconData icon;
  const PropertyType(this.label, this.icon);
}

enum PropertyStatus {
  available('Available'),
  sold('Sold'),
  rented('Rented'),
  underContract('Under Contract');

  final String label;
  const PropertyStatus(this.label);
}

enum PropertyApprovalStatus {
  pending('Pending'),
  approved('Approved'),
  rejected('Rejected');

  final String label;
  const PropertyApprovalStatus(this.label);
}

class Property {
  final String id;
  final String title;
  final String description;
  final double price;
  final PropertyType type;
  final PropertyStatus status;
  final String location;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<String> imageUrls;
  final String agentName;
  final String agentId;
  final DateTime createdAt;
  final bool isFeatured;
  final Map<String, dynamic> amenities;
  final PropertyApprovalStatus approvalStatus;
  final String createdBy; // 'admin' or user UID

  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.type,
    required this.status,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.imageUrls,
    required this.agentName,
    required this.agentId,
    required this.createdAt,
    this.isFeatured = false,
    this.amenities = const {},
    required this.approvalStatus,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'type': type.name,
      'status': status.name,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'imageUrls': imageUrls,
      'agentName': agentName,
      'agentId': agentId,
      'createdAt': createdAt.toIso8601String(),
      'isFeatured': isFeatured,
      'amenities': amenities,
      'approvalStatus': approvalStatus.name,
      'createdBy': createdBy,
    };
  }

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      type: _parsePropertyType(map['type']),
      status: _parsePropertyStatus(map['status']),
      location: map['location'] ?? '',
      bedrooms: (map['bedrooms'] is int ? map['bedrooms'] : int.tryParse('${map['bedrooms']}') ?? 0),
      bathrooms: (map['bathrooms'] is int ? map['bathrooms'] : int.tryParse('${map['bathrooms']}') ?? 0),
      area: (map['area'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      agentName: map['agentName'] ?? '',
      agentId: map['agentId'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      isFeatured: map['isFeatured'] ?? false,
      amenities: Map<String, dynamic>.from(map['amenities'] ?? {}),
      approvalStatus: _parseApprovalStatus(map['approvalStatus']),
      createdBy: map['createdBy'] ?? 'admin',
    );
  }

  static PropertyType _parsePropertyType(dynamic type) {
    final String value = (type ?? 'residential').toString();
    try {
      return PropertyType.values.byName(value);
    } catch (_) {
      return PropertyType.residential;
    }
  }

  static PropertyStatus _parsePropertyStatus(dynamic status) {
    final String value = (status ?? 'available').toString();
    try {
      return PropertyStatus.values.byName(value);
    } catch (_) {
      return PropertyStatus.available;
    }
  }

  static PropertyApprovalStatus _parseApprovalStatus(dynamic status) {
    final String value = (status ?? 'approved').toString();
    try {
      return PropertyApprovalStatus.values.byName(value);
    } catch (_) {
      return PropertyApprovalStatus.approved;
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String) {
        return DateTime.parse(value);
      }
    } catch (_) {}
    return DateTime.now();
  }

  String get formattedPrice {
    if (price >= 1000000) {
      return 'Rs ${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return 'Rs ${(price / 1000).toStringAsFixed(0)}K';
    }
    return 'Rs ${price.toStringAsFixed(0)}';
  }

  String get timeAgo {
    final Duration d = DateTime.now().difference(createdAt);
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  String get typeLabel {
    return type.label;
  }

  String get statusLabel {
    return status.label;
  }
}

extension PropertyTypeX on PropertyType {
  String get label {
    return this.label;
  }

  IconData get icon {
    return this.icon;
  }
}