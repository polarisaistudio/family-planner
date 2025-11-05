import 'package:equatable/equatable.dart';

/// Entity representing a task category
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? nameZh; // Chinese translation
  final String icon; // Icon code point as string
  final String colorHex; // Color in hex format
  final bool isPredefined; // System categories vs user categories
  final int order; // For sorting

  const CategoryEntity({
    required this.id,
    required this.name,
    this.nameZh,
    required this.icon,
    required this.colorHex,
    required this.isPredefined,
    required this.order,
  });

  /// Get the icon code point as int
  int get iconCodePoint => int.parse(icon);

  /// Get the color value as int
  int get colorValue => int.parse(colorHex.replaceFirst('#', '0xff'));

  /// Get localized name based on language
  String getLocalizedName(String languageCode) {
    if (languageCode == 'zh' && nameZh != null) {
      return nameZh!;
    }
    return name;
  }

  /// Create a copy with modified fields
  CategoryEntity copyWith({
    String? id,
    String? name,
    String? nameZh,
    String? icon,
    String? colorHex,
    bool? isPredefined,
    int? order,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      nameZh: nameZh ?? this.nameZh,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isPredefined: isPredefined ?? this.isPredefined,
      order: order ?? this.order,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameZh': nameZh,
      'icon': icon,
      'colorHex': colorHex,
      'isPredefined': isPredefined,
      'order': order,
    };
  }

  /// Create from JSON
  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      nameZh: json['nameZh'] as String?,
      icon: json['icon'] as String,
      colorHex: json['colorHex'] as String,
      isPredefined: json['isPredefined'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nameZh,
        icon,
        colorHex,
        isPredefined,
        order,
      ];
}

/// Predefined categories
class PredefinedCategories {
  // Material Icons code points (from Flutter MaterialIcons)
  static const int _workIcon = 0xe570; // work icon
  static const int _personIcon = 0xe7fd; // person icon
  static const int _shoppingCartIcon = 0xe8cc; // shopping_cart icon
  static const int _familyRestroomIcon = 0xe53b; // family_restroom icon
  static const int _favoriteIcon = 0xe87d; // favorite icon
  static const int _attachMoneyIcon = 0xe227; // attach_money icon
  static const int _homeIcon = 0xe88a; // home icon
  static const int _directionsRunIcon = 0xe566; // directions_run icon

  static final List<CategoryEntity> categories = [
    CategoryEntity(
      id: 'work',
      name: 'Work',
      nameZh: '工作',
      icon: _workIcon.toString(),
      colorHex: '#FF2196F3', // Blue
      isPredefined: true,
      order: 1,
    ),
    CategoryEntity(
      id: 'personal',
      name: 'Personal',
      nameZh: '个人',
      icon: _personIcon.toString(),
      colorHex: '#FF4CAF50', // Green
      isPredefined: true,
      order: 2,
    ),
    CategoryEntity(
      id: 'shopping',
      name: 'Shopping',
      nameZh: '购物',
      icon: _shoppingCartIcon.toString(),
      colorHex: '#FFFF9800', // Orange
      isPredefined: true,
      order: 3,
    ),
    CategoryEntity(
      id: 'family',
      name: 'Family',
      nameZh: '家庭',
      icon: _familyRestroomIcon.toString(),
      colorHex: '#FFE91E63', // Pink
      isPredefined: true,
      order: 4,
    ),
    CategoryEntity(
      id: 'health',
      name: 'Health',
      nameZh: '健康',
      icon: _favoriteIcon.toString(),
      colorHex: '#FFF44336', // Red
      isPredefined: true,
      order: 5,
    ),
    CategoryEntity(
      id: 'finance',
      name: 'Finance',
      nameZh: '财务',
      icon: _attachMoneyIcon.toString(),
      colorHex: '#FF4CAF50', // Green
      isPredefined: true,
      order: 6,
    ),
    CategoryEntity(
      id: 'home',
      name: 'Home',
      nameZh: '家务',
      icon: _homeIcon.toString(),
      colorHex: '#FF9C27B0', // Purple
      isPredefined: true,
      order: 7,
    ),
    CategoryEntity(
      id: 'errands',
      name: 'Errands',
      nameZh: '跑腿',
      icon: _directionsRunIcon.toString(),
      colorHex: '#FF00BCD4', // Cyan
      isPredefined: true,
      order: 8,
    ),
  ];

  static CategoryEntity? getCategoryById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
