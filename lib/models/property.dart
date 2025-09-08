import 'package:flutter/material.dart';

enum PropertyType { commercial, residential, buy, rent }

enum PropertyStatus { available, sold, rented, underContract }

extension PropertyStatusX on PropertyStatus {
  String get label {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.underContract:
        return 'Under Contract';
    }
  }
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
  final double area; // in sq ft
  final List<String> imageUrls;
  final String agentName;
  final String agentId;
  final DateTime createdAt;
  final bool isFeatured;
  final Map<String, dynamic> amenities;

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
  });

  // Create a Property from a Map (useful for Firebase data)
  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      type: _parsePropertyType(map['type']),
      status: _parsePropertyStatus(map['status']),
      location: map['location'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      area: (map['area'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      agentName: map['agentName'] ?? '',
      agentId: map['agentId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isFeatured: map['isFeatured'] ?? false,
      amenities: Map<String, dynamic>.from(map['amenities'] ?? {}),
    );
  }

  // Convert to Map (useful for saving to Firebase)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
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
    };
  }

  // Helper methods to parse enums from strings
  static PropertyType _parsePropertyType(String type) {
    switch (type) {
      case 'commercial': return PropertyType.commercial;
      case 'residential': return PropertyType.residential;
      case 'buy': return PropertyType.buy;
      case 'rent': return PropertyType.rent;
      default: return PropertyType.residential;
    }
  }

  static PropertyStatus _parsePropertyStatus(String status) {
    switch (status) {
      case 'available': return PropertyStatus.available;
      case 'sold': return PropertyStatus.sold;
      case 'rented': return PropertyStatus.rented;
      case 'underContract': return PropertyStatus.underContract;
      default: return PropertyStatus.available;
    }
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
    switch (type) {
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.residential:
        return 'Residential';
      case PropertyType.buy:
        return 'Buy';
      case PropertyType.rent:
        return 'Rent';
    }
  }

  String get statusLabel {
    switch (status) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.sold:
        return 'Sold';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.underContract:
        return 'Under Contract';
    }
  }
}

extension PropertyTypeX on PropertyType {
  String get label {
    switch (this) {
      case PropertyType.commercial:
        return 'Commercial';
      case PropertyType.residential:
        return 'Residential';
      case PropertyType.buy:
        return 'Buy';
      case PropertyType.rent:
        return 'Rent';
    }
  }

  IconData get icon {
    switch (this) {
      case PropertyType.commercial:
        return Icons.business;
      case PropertyType.residential:
        return Icons.home;
      case PropertyType.buy:
        return Icons.shopping_cart;
      case PropertyType.rent:
        return Icons.key;
    }
  }
}