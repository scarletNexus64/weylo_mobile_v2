class ConfessionModel {
  final int id;
  final String content;
  final String type; // 'public' or 'private'
  final bool isPublic;
  final bool isPrivate;
  final String status; // 'approved', 'pending', 'rejected'
  final bool isApproved;
  final bool isPending;

  // Media (image or video)
  final String mediaType; // 'none', 'image', 'video'
  final String? mediaUrl;
  final String? thumbnailUrl; // For video thumbnails

  // Author info
  final String authorInitial;
  final ConfessionAuthor? author;
  final bool isIdentityRevealed;

  // Stats (for public confessions)
  final int likesCount;
  final int viewsCount;
  final int commentsCount;
  final bool isLiked;

  final DateTime createdAt;

  ConfessionModel({
    required this.id,
    required this.content,
    required this.type,
    required this.isPublic,
    required this.isPrivate,
    required this.status,
    required this.isApproved,
    required this.isPending,
    required this.mediaType,
    this.mediaUrl,
    this.thumbnailUrl,
    required this.authorInitial,
    this.author,
    required this.isIdentityRevealed,
    required this.likesCount,
    required this.viewsCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
  });

  factory ConfessionModel.fromJson(Map<String, dynamic> json) {
    return ConfessionModel(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      type: json['type'] as String? ?? 'public',
      isPublic: json['is_public'] as bool? ?? true,
      isPrivate: json['is_private'] as bool? ?? false,
      status: json['status'] as String? ?? 'approved',
      isApproved: json['is_approved'] as bool? ?? false,
      isPending: json['is_pending'] as bool? ?? false,
      mediaType: json['media_type'] as String? ?? 'none',
      mediaUrl: json['media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      authorInitial: json['author_initial'] as String? ?? '?',
      author: json['author'] != null
          ? ConfessionAuthor.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      isIdentityRevealed: json['is_identity_revealed'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'is_public': isPublic,
      'is_private': isPrivate,
      'status': status,
      'is_approved': isApproved,
      'is_pending': isPending,
      'media_type': mediaType,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'author_initial': authorInitial,
      'author': author?.toJson(),
      'is_identity_revealed': isIdentityRevealed,
      'likes_count': likesCount,
      'views_count': viewsCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // CopyWith pour mettre à jour les counts
  ConfessionModel copyWith({
    int? likesCount,
    int? viewsCount,
    int? commentsCount,
    bool? isLiked,
  }) {
    return ConfessionModel(
      id: id,
      content: content,
      type: type,
      isPublic: isPublic,
      isPrivate: isPrivate,
      status: status,
      isApproved: isApproved,
      isPending: isPending,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      authorInitial: authorInitial,
      author: author,
      isIdentityRevealed: isIdentityRevealed,
      likesCount: likesCount ?? this.likesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }

  // Helper pour obtenir le nom de l'auteur (anonyme ou révélé)
  String get authorName {
    if (isIdentityRevealed && author != null) {
      return author!.name;
    }
    return 'Anonyme';
  }

  // Helper pour l'avatar (null si anonyme)
  String? get authorAvatarUrl {
    if (isIdentityRevealed && author != null) {
      return author!.avatarUrl;
    }
    return null;
  }
}

class ConfessionAuthor {
  final int id;
  final String name;
  final String username;
  final String initial;
  final String? avatarUrl;

  ConfessionAuthor({
    required this.id,
    required this.name,
    required this.username,
    required this.initial,
    this.avatarUrl,
  });

  factory ConfessionAuthor.fromJson(Map<String, dynamic> json) {
    // Clean avatar URL - fix malformed URLs with multiple ? in query params
    String? avatarUrl = json['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.contains('?')) {
      // Replace any subsequent ? with & after the first one
      final parts = avatarUrl.split('?');
      if (parts.length > 2) {
        avatarUrl = '${parts[0]}?${parts.sublist(1).join('&')}';
      }
    }

    return ConfessionAuthor(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      initial: json['initial'] as String? ?? '?',
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

class ConfessionListResponse {
  final List<ConfessionModel> confessions;
  final ConfessionMeta meta;

  ConfessionListResponse({
    required this.confessions,
    required this.meta,
  });

  factory ConfessionListResponse.fromJson(Map<String, dynamic> json) {
    return ConfessionListResponse(
      confessions: (json['confessions'] as List)
          .map((item) => ConfessionModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ConfessionMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class ConfessionMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ConfessionMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ConfessionMeta.fromJson(Map<String, dynamic> json) {
    return ConfessionMeta(
      currentPage: json['current_page'] as int,
      lastPage: json['last_page'] as int,
      perPage: json['per_page'] as int,
      total: json['total'] as int,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
