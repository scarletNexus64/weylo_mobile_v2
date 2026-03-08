class UserModel {
  final int id;
  final String firstName;
  final String? lastName;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String? avatar;
  final String? avatarUrl;
  final String? coverPhoto;
  final String? coverPhotoUrl;
  final String? bio;
  final String? profileUrl;
  final bool isVerified;
  final bool isOnline;
  final String? role;
  final double walletBalance;
  final String? formattedBalance;
  final Map<String, dynamic>? settings;
  final bool isPremium;
  final bool hasActivePremium;
  final DateTime? premiumStartedAt;
  final DateTime? premiumExpiresAt;
  final bool premiumAutoRenew;
  final int? premiumDaysRemaining;
  final bool isBanned;
  final String? bannedReason;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    this.avatar,
    this.avatarUrl,
    this.coverPhoto,
    this.coverPhotoUrl,
    this.bio,
    this.profileUrl,
    this.isVerified = false,
    this.isOnline = false,
    this.role,
    this.walletBalance = 0.0,
    this.formattedBalance,
    this.settings,
    this.isPremium = false,
    this.hasActivePremium = false,
    this.premiumStartedAt,
    this.premiumExpiresAt,
    this.premiumAutoRenew = false,
    this.premiumDaysRemaining,
    this.isBanned = false,
    this.bannedReason,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper method to safely parse a value to double
  /// Handles both string and numeric types from JSON
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Clean URLs - fix malformed URLs with multiple ? in query params
    String? avatarUrl = json['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.contains('?')) {
      final parts = avatarUrl.split('?');
      if (parts.length > 2) {
        avatarUrl = '${parts[0]}?${parts.sublist(1).join('&')}';
      }
    }

    String? coverPhotoUrl = json['cover_photo_url'] as String?;
    if (coverPhotoUrl != null && coverPhotoUrl.contains('?')) {
      final parts = coverPhotoUrl.split('?');
      if (parts.length > 2) {
        coverPhotoUrl = '${parts[0]}?${parts.sublist(1).join('&')}';
      }
    }

    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? json['first_name'],
      username: json['username'],
      email: json['email'],
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      avatarUrl: avatarUrl,
      coverPhoto: json['cover_photo'],
      coverPhotoUrl: coverPhotoUrl,
      bio: json['bio'],
      profileUrl: json['profile_url'],
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      role: json['role'],
      walletBalance: _parseDouble(json['wallet_balance']),
      formattedBalance: json['formatted_balance'],
      settings: json['settings'] != null
          ? Map<String, dynamic>.from(json['settings'])
          : null,
      isPremium: json['is_premium'] ?? false,
      hasActivePremium: json['has_active_premium'] ?? false,
      premiumStartedAt: json['premium_started_at'] != null
          ? DateTime.parse(json['premium_started_at'])
          : null,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'])
          : null,
      premiumAutoRenew: json['premium_auto_renew'] ?? false,
      premiumDaysRemaining: json['premium_days_remaining'],
      isBanned: json['is_banned'] ?? false,
      bannedReason: json['banned_reason'],
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'])
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.parse(json['phone_verified_at'])
          : null,
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  /// Check if user has uploaded a real avatar (not ui-avatars.com)
  bool get hasRealAvatar {
    if (avatarUrl == null || avatarUrl!.isEmpty) return false;
    return !avatarUrl!.contains('ui-avatars.com');
  }

  /// Check if user has uploaded a real cover photo
  bool get hasRealCoverPhoto {
    return coverPhotoUrl != null && coverPhotoUrl!.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'bio': bio,
      'profile_url': profileUrl,
      'is_verified': isVerified,
      'is_online': isOnline,
      'role': role,
      'wallet_balance': walletBalance,
      'formatted_balance': formattedBalance,
      'settings': settings,
      'is_premium': isPremium,
      'has_active_premium': hasActivePremium,
      'premium_started_at': premiumStartedAt?.toIso8601String(),
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'premium_auto_renew': premiumAutoRenew,
      'premium_days_remaining': premiumDaysRemaining,
      'is_banned': isBanned,
      'banned_reason': bannedReason,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
