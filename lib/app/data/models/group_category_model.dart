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
}
