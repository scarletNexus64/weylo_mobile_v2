import 'dart:convert';
import 'user_model.dart';

enum ChatMessageType { text, image, audio, video, gift, system }

class ChatGiftData {
  final int? id;
  final String name;
  final String icon;
  final String? emojiImageUrl; // URL de l'image Twemoji
  final String? animation;
  final int? price;
  final String? formattedPrice;
  final String? tier;
  final String? tierColor;
  final String? backgroundColor;
  final String? description;
  final int? amount;
  final bool isAnonymous;

  ChatGiftData({
    this.id,
    required this.name,
    required this.icon,
    this.emojiImageUrl,
    this.animation,
    this.price,
    this.formattedPrice,
    this.tier,
    this.tierColor,
    this.backgroundColor,
    this.description,
    this.amount,
    this.isAnonymous = false,
  });

  factory ChatGiftData.fromJson(Map<String, dynamic> json) {
    return ChatGiftData(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? 'Cadeau',
      icon: json['icon'] as String? ?? '🎁',
      emojiImageUrl: json['emoji_image_url'] as String?,
      animation: json['animation'] as String?,
      price: (json['price'] as num?)?.toInt(),
      formattedPrice: json['formatted_price'] as String?,
      tier: json['tier'] as String?,
      tierColor: json['tier_color'] as String?,
      backgroundColor: json['background_color'] as String?,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toInt(),
      isAnonymous: json['is_anonymous'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'emoji_image_url': emojiImageUrl,
      'animation': animation,
      'price': price,
      'formatted_price': formattedPrice,
      'tier': tier,
      'tier_color': tierColor,
      'background_color': backgroundColor,
      'description': description,
      'amount': amount,
      'is_anonymous': isAnonymous,
    };
  }
}

/// Représente un message anonyme simplifié lié à un message de chat
class AnonymousMessageInfo {
  final int id;
  final String content;
  final DateTime createdAt;

  AnonymousMessageInfo({
    required this.id,
    required this.content,
    required this.createdAt,
  });

  factory AnonymousMessageInfo.fromJson(Map<String, dynamic> json) {
    return AnonymousMessageInfo(
      id: json['id'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Représente une story simplifiée liée à un message de chat
class StoryReplyInfo {
  final int id;
  final String type; // 'image', 'video', 'text'
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? backgroundColor;
  final DateTime createdAt;
  final StoryUserInfo? user;

  StoryReplyInfo({
    required this.id,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.backgroundColor,
    required this.createdAt,
    this.user,
  });

  factory StoryReplyInfo.fromJson(Map<String, dynamic> json) {
    return StoryReplyInfo(
      id: json['id'],
      type: json['type'] ?? 'text',
      content: json['content'],
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      backgroundColor: json['background_color'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? StoryUserInfo.fromJson(json['user']) : null,
    );
  }
}

/// Représente l'utilisateur d'une story simplifiée
class StoryUserInfo {
  final int id;
  final String username;
  final String fullName;
  final String avatarUrl;

  StoryUserInfo({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
  });

  factory StoryUserInfo.fromJson(Map<String, dynamic> json) {
    return StoryUserInfo(
      id: json['id'],
      username: json['username'] ?? '',
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
}

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final UserModel? sender;
  final String? content;
  final ChatMessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final ChatGiftData? giftData;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt; // Date d'édition du message
  final AnonymousMessageInfo? anonymousMessage; // Message anonyme original si applicable
  final StoryReplyInfo? story; // Story à laquelle ce message répond
  final bool isMine; // Indique si le message a été envoyé par l'utilisateur actuel

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    this.content,
    required this.type,
    this.mediaUrl,
    this.metadata,
    this.giftData,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
    this.anonymousMessage,
    this.story,
    this.isMine = false,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Pour les messages simplifiés (last_message dans conversation), certains champs peuvent manquer
    final now = DateTime.now();

    final giftDataRaw = json['gift_data'];
    final ChatGiftData? parsedGiftData = giftDataRaw is Map
        ? ChatGiftData.fromJson(Map<String, dynamic>.from(giftDataRaw))
        : null;

    return ChatMessageModel(
      id: json['id'] ?? 0,
      conversationId: json['conversation_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      content: json['content'],
      type: _parseMessageType(json['type']),
      mediaUrl: json['media_url'],
      metadata: _parseMetadata(json['metadata']),
      giftData: parsedGiftData,
      isRead: json['is_read'] ?? json['is_mine'] == true, // Si c'est mon message, considérer comme lu
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : now,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : now,
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      anonymousMessage: json['anonymous_message'] != null
          ? AnonymousMessageInfo.fromJson(json['anonymous_message'])
          : null,
      story: json['story'] != null
          ? StoryReplyInfo.fromJson(json['story'])
          : null,
      isMine: json['is_mine'] ?? false, // Utiliser le flag fourni par le backend
    );
  }

  static Map<String, dynamic>? _parseMetadata(dynamic metadata) {
    if (metadata == null) return null;

    // Si c'est déjà un Map, retourner tel quel
    if (metadata is Map<String, dynamic>) {
      return metadata;
    }

    // Si c'est un Map avec un autre type de clés, convertir
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }

    // Si c'est une String JSON, la décoder
    if (metadata is String) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        print('Error parsing metadata JSON: $e');
        return null;
      }
    }

    return null;
  }

  static ChatMessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return ChatMessageType.text;
      case 'image':
        return ChatMessageType.image;
      case 'audio':
        return ChatMessageType.audio;
      case 'video':
        return ChatMessageType.video;
      case 'gift':
        return ChatMessageType.gift;
      case 'system':
        return ChatMessageType.system;
      default:
        return ChatMessageType.text;
    }
  }

  static String messageTypeToString(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.text:
        return 'text';
      case ChatMessageType.image:
        return 'image';
      case ChatMessageType.audio:
        return 'audio';
      case ChatMessageType.video:
        return 'video';
      case ChatMessageType.gift:
        return 'gift';
      case ChatMessageType.system:
        return 'system';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'type': messageTypeToString(type),
      'media_url': mediaUrl,
      'metadata': metadata,
      'gift_data': giftData?.toJson(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'is_mine': isMine,
      if (anonymousMessage != null)
        'anonymous_message': {
          'id': anonymousMessage!.id,
          'content': anonymousMessage!.content,
          'created_at': anonymousMessage!.createdAt.toIso8601String(),
        },
      if (story != null)
        'story': {
          'id': story!.id,
          'type': story!.type,
          'content': story!.content,
          'media_url': story!.mediaUrl,
          'thumbnail_url': story!.thumbnailUrl,
          'background_color': story!.backgroundColor,
          'created_at': story!.createdAt.toIso8601String(),
        },
    };
  }

  /// Helpers pour vérifier le type de message
  bool get isTextMessage => type == ChatMessageType.text;
  bool get isImageMessage => type == ChatMessageType.image;
  bool get isAudioMessage => type == ChatMessageType.audio;
  bool get isVideoMessage => type == ChatMessageType.video;
  bool get isGiftMessage => type == ChatMessageType.gift;
  bool get isSystemMessage => type == ChatMessageType.system;

  /// Vérifier si le message a été édité
  bool get isEdited => editedAt != null;

  /// Vérifier si le message peut être édité (< 15 min et texte uniquement)
  bool canBeEdited(int currentUserId) {
    if (senderId != currentUserId) return false;
    if (type != ChatMessageType.text) return false;

    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes < 15;
  }
}

/// Pagination metadata pour les messages
class ChatMessagePaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ChatMessagePaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ChatMessagePaginationMeta.fromJson(Map<String, dynamic> json) {
    return ChatMessagePaginationMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
