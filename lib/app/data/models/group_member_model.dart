class GroupMemberModel {
  final int id;
  final int userId;
  final String role;
  final DateTime? joinedAt;
  final bool isMuted;
  final bool isSelf;
  final bool isIdentityRevealed;

  // User info (if revealed or self)
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? avatarUrl;
  final String? initial;
  final String? displayName;

  GroupMemberModel({
    required this.id,
    required this.userId,
    required this.role,
    this.joinedAt,
    this.isMuted = false,
    this.isSelf = false,
    this.isIdentityRevealed = false,
    this.firstName,
    this.lastName,
    this.username,
    this.avatarUrl,
    this.initial,
    this.displayName,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      role: json['role'] as String? ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      isMuted: json['is_muted'] as bool? ?? false,
      isSelf: json['is_self'] as bool? ?? false,
      isIdentityRevealed: json['is_identity_revealed'] as bool? ?? false,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      initial: json['initial'] as String?,
      displayName: json['display_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'is_muted': isMuted,
      'is_self': isSelf,
      'is_identity_revealed': isIdentityRevealed,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'avatar_url': avatarUrl,
      'initial': initial,
      'display_name': displayName,
    };
  }

  /// Get display name (real name if revealed, otherwise anonymous)
  String get effectiveDisplayName {
    if (isIdentityRevealed || isSelf) {
      return username ?? displayName ?? 'Anonyme';
    }
    return displayName ?? 'Anonyme';
  }

  /// Get initial (real initial if revealed, otherwise 'A')
  String get effectiveInitial {
    if (isIdentityRevealed || isSelf) {
      return initial ?? 'A';
    }
    return 'A';
  }
}
