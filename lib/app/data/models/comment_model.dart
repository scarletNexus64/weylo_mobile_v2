class CommentModel {
  final int id;
  final String content;
  final bool isAnonymous;
  final CommentAuthor author;
  final DateTime createdAt;
  final bool isMine;

  CommentModel({
    required this.id,
    required this.content,
    required this.isAnonymous,
    required this.author,
    required this.createdAt,
    required this.isMine,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      content: json['content'] as String,
      isAnonymous: json['is_anonymous'] as bool,
      author: CommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      isMine: json['is_mine'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_anonymous': isAnonymous,
      'author': author.toJson(),
      'created_at': createdAt.toIso8601String(),
      'is_mine': isMine,
    };
  }

  String get authorName => isAnonymous ? 'Anonyme' : author.name;
  String get authorInitial => isAnonymous ? '?' : author.initial;
  String? get authorAvatarUrl => isAnonymous ? null : author.avatarUrl;
}

class CommentAuthor {
  final int? id; // Null si anonyme
  final String name;
  final String? username;
  final String initial;
  final String? avatarUrl;

  CommentAuthor({
    this.id,
    required this.name,
    this.username,
    required this.initial,
    this.avatarUrl,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    // Clean avatar URL - fix malformed URLs with multiple ? in query params
    String? avatarUrl = json['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.contains('?')) {
      final parts = avatarUrl.split('?');
      if (parts.length > 2) {
        avatarUrl = '${parts[0]}?${parts.sublist(1).join('&')}';
      }
    }

    return CommentAuthor(
      id: json['id'] as int?,
      name: json['name'] as String,
      username: json['username'] as String?,
      initial: json['initial'] as String,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'initial': initial,
      'avatar_url': avatarUrl,
    };
  }
}
