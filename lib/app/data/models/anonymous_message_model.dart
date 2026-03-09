import 'gift_model.dart';

class AnonymousMessageModel {
  final int id;
  final String content;
  final String senderInitial;
  final MessageSender? sender; // null si pas révélé
  final bool isRead;
  final DateTime? readAt;
  final bool isIdentityRevealed;
  final DateTime? revealedAt;
  final DateTime createdAt;
  final String mediaType; // 'none', 'audio', 'image'
  final String? mediaUrl;
  final String? voiceType; // 'normal', 'robot', 'alien', 'mystery', 'chipmunk'
  final List<GiftTransactionModel>? giftTransactions;

  AnonymousMessageModel({
    required this.id,
    required this.content,
    required this.senderInitial,
    this.sender,
    required this.isRead,
    this.readAt,
    required this.isIdentityRevealed,
    this.revealedAt,
    required this.createdAt,
    this.mediaType = 'none',
    this.mediaUrl,
    this.voiceType,
    this.giftTransactions,
  });

  factory AnonymousMessageModel.fromJson(Map<String, dynamic> json) {
    return AnonymousMessageModel(
      id: json['id'],
      content: json['content'] ?? '',
      senderInitial: json['sender_initial'],
      sender: json['sender'] != null
          ? MessageSender.fromJson(json['sender'])
          : null,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      isIdentityRevealed: json['is_identity_revealed'] ?? false,
      revealedAt: json['revealed_at'] != null
          ? DateTime.parse(json['revealed_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      mediaType: json['media_type'] ?? 'none',
      mediaUrl: json['media_url'],
      voiceType: json['voice_type'],
      giftTransactions: json['gift_transactions'] != null
          ? (json['gift_transactions'] as List)
              .map((e) => GiftTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_initial': senderInitial,
      'sender': sender?.toJson(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'is_identity_revealed': isIdentityRevealed,
      'revealed_at': revealedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'media_type': mediaType,
      'media_url': mediaUrl,
      'voice_type': voiceType,
      'gift_transactions': giftTransactions?.map((e) => e.toJson()).toList(),
    };
  }

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'Il y a ${years}an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a ${months}mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  /// Check if message has media
  bool get hasMedia => mediaType != 'none' && mediaUrl != null;

  /// Check if message has audio
  bool get hasAudio => mediaType == 'audio' && mediaUrl != null;

  /// Check if message has image
  bool get hasImage => mediaType == 'image' && mediaUrl != null;

  /// Check if message has gifts
  bool get hasGifts => giftTransactions != null && giftTransactions!.isNotEmpty;
}

/// Sender information (only available when identity is revealed)
class MessageSender {
  final int id;
  final String username;
  final String firstName;
  final String? lastName;
  final String? avatar;

  MessageSender({
    required this.id,
    required this.username,
    required this.firstName,
    this.lastName,
    this.avatar,
  });

  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatar,
    };
  }

  String get fullName => lastName != null && lastName!.isNotEmpty
      ? '$firstName $lastName'
      : firstName;
}

/// Pagination metadata
class MessagePaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  MessagePaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory MessagePaginationMeta.fromJson(Map<String, dynamic> json) {
    return MessagePaginationMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}

/// User share link response
class UserShareLink {
  final String link;
  final String username;
  final String shareText;
  final ShareOptions shareOptions;

  UserShareLink({
    required this.link,
    required this.username,
    required this.shareText,
    required this.shareOptions,
  });

  factory UserShareLink.fromJson(Map<String, dynamic> json) {
    return UserShareLink(
      link: json['link'],
      username: json['username'],
      shareText: json['share_text'],
      shareOptions: ShareOptions.fromJson(json['share_options']),
    );
  }
}

class ShareOptions {
  final String whatsapp;
  final String facebook;
  final String twitter;

  ShareOptions({
    required this.whatsapp,
    required this.facebook,
    required this.twitter,
  });

  factory ShareOptions.fromJson(Map<String, dynamic> json) {
    return ShareOptions(
      whatsapp: json['whatsapp'],
      facebook: json['facebook'],
      twitter: json['twitter'],
    );
  }
}
