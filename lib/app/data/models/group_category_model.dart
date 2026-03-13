import 'package:flutter/material.dart';

class GroupCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;
  final String? description;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
    this.description,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupCategoryModel.fromJson(Map<String, dynamic> json) {
    return GroupCategoryModel(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      color: json['color'],
      description: json['description'],
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon': icon,
      'color': color,
      'description': description,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Format le nom de la catégorie pour l'affichage (enlève les underscores et capitalise)
  String get displayName {
    return name
        .split('_')
        .map((word) => word.isNotEmpty
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : '')
        .join(' ');
  }

  /// Convertit le nom d'icône Material en IconData Flutter
  IconData? get iconData {
    final iconMap = {
      'computer': Icons.computer,
      'sports_soccer': Icons.sports_soccer,
      'music_note': Icons.music_note,
      'school': Icons.school,
      'sports_esports': Icons.sports_esports,
      'palette': Icons.palette,
      'flight': Icons.flight,
      'restaurant': Icons.restaurant,
      'spa': Icons.spa,
      'more_horiz': Icons.more_horiz,
    };

    return iconMap[icon];
  }

  /// Retourne un emoji de fallback si l'icône n'est pas reconnue
  String get emojiIcon {
    final emojiMap = {
      'computer': '💻',
      'sports_soccer': '⚽',
      'music_note': '🎵',
      'school': '🎓',
      'sports_esports': '🎮',
      'palette': '🎨',
      'flight': '✈️',
      'restaurant': '🍽️',
      'spa': '🧘',
      'more_horiz': '📁',
    };

    return emojiMap[icon] ?? '📁';
  }
}
