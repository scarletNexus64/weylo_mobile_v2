class LegalPageModel {
  final int id;
  final String slug;
  final String title;
  final String? content;
  final String? updatedAt;
  final int? order;

  LegalPageModel({
    required this.id,
    required this.slug,
    required this.title,
    this.content,
    this.updatedAt,
    this.order,
  });

  factory LegalPageModel.fromJson(Map<String, dynamic> json) {
    return LegalPageModel(
      id: json['id'] as int,
      slug: json['slug'] as String,
      title: json['title'] as String,
      content: json['content'] as String?,
      updatedAt: json['updated_at'] as String?,
      order: json['order'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      if (content != null) 'content': content,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (order != null) 'order': order,
    };
  }
}
