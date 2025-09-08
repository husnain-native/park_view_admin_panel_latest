class CityCard {
  final String id;
  final String title;
  final String subtitle;
  final String buttonText;
  final String imagePath;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CityCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imagePath,
    required this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CityCard.fromMap(Map<String, dynamic> map) {
    return CityCard(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      buttonText: map['buttonText'] ?? '',
      imagePath: map['imagePath'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  CityCard copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? buttonText,
    String? imagePath,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CityCard(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      buttonText: buttonText ?? this.buttonText,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 