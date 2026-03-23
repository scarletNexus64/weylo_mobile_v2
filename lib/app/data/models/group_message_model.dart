import 'user_model.dart';

enum GroupMessageType { text, image, audio, video, gift, system }

class GroupMessageModel {
  final int id;
  final int groupId;
  final int? senderId;
  final UserModel? sender;
  final String? content;
  final GroupMessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool isSystemMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    this.senderId,
    this.sender,
    this.content,
    required this.type,
    this.mediaUrl,
    this.metadata,
    this.isSystemMessage = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMessageModel.fromJson(Map<String, dynamic> json) {
    // Parse metadata en tolérant les Lists
    Map<String, dynamic>? parsedMetadata;
    if (json['metadata'] != null) {
      if (json['metadata'] is Map) {
        parsedMetadata = Map<String, dynamic>.from(json['metadata']);
      } else if (json['metadata'] is String) {
        // Si c'est une chaîne JSON, la parser
        try {
          final decoded = json['metadata'];
          if (decoded is Map) {
            parsedMetadata = Map<String, dynamic>.from(decoded);
          }
        } catch (e) {
          print('⚠️ [GroupMessageModel] Error parsing metadata: $e');
        }
      }
      // Ignorer si c'est une List ou autre type non supporté
    }

    // Parse sender - soit depuis l'objet sender, soit depuis les champs plats
    UserModel? sender;
    if (json['sender'] != null && json['sender'] is Map) {
      // Cas 1: sender est un objet imbriqué
      sender = UserModel.fromJson(json['sender'] as Map<String, dynamic>);
    } else if (json['sender_first_name'] != null || json['sender_username'] != null) {
      // Cas 2: les infos du sender sont dans des champs plats (depuis l'API groups)
      final firstName = json['sender_first_name'] ?? '';
      final lastName = json['sender_last_name'] ?? '';
      final fullName = lastName.isNotEmpty ? '$firstName $lastName'.trim() : firstName;

      sender = UserModel(
        id: json['sender_id'] ?? 0,
        firstName: firstName,
        lastName: lastName,
        fullName: fullName,
        username: json['sender_username'] ?? 'unknown',
        email: '', // Non fourni dans ce contexte
        phone: '', // Non fourni dans ce contexte
        avatar: json['sender_avatar_url'],
        avatarUrl: json['sender_avatar_url'],
        isPremium: json['sender_is_premium'] ?? false,
        isVerified: json['sender_is_verified'] ?? false,
        createdAt: DateTime.now(), // Non fourni dans ce contexte
        updatedAt: DateTime.now(), // Non fourni dans ce contexte
      );
    }

    return GroupMessageModel(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      sender: sender,
      content: json['content'],
      type: _parseMessageType(json['type']),
      mediaUrl: json['media_url'],
      metadata: parsedMetadata,
      isSystemMessage: json['is_system_message'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static GroupMessageType _parseMessageType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return GroupMessageType.text;
      case 'image':
        return GroupMessageType.image;
      case 'audio':
        return GroupMessageType.audio;
      case 'video':
        return GroupMessageType.video;
      case 'gift':
        return GroupMessageType.gift;
      case 'system':
        return GroupMessageType.system;
      default:
        return GroupMessageType.text;
    }
  }

  static String messageTypeToString(GroupMessageType type) {
    switch (type) {
      case GroupMessageType.text:
        return 'text';
      case GroupMessageType.image:
        return 'image';
      case GroupMessageType.audio:
        return 'audio';
      case GroupMessageType.video:
        return 'video';
      case GroupMessageType.gift:
        return 'gift';
      case GroupMessageType.system:
        return 'system';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'sender_id': senderId,
      'sender': sender?.toJson(),
      'content': content,
      'type': messageTypeToString(type),
      'media_url': mediaUrl,
      'metadata': metadata,
      'is_system_message': isSystemMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helpers pour vérifier le type de message
  bool get isTextMessage => type == GroupMessageType.text;
  bool get isImageMessage => type == GroupMessageType.image;
  bool get isAudioMessage => type == GroupMessageType.audio;
  bool get isVideoMessage => type == GroupMessageType.video;
  bool get isGiftMessage => type == GroupMessageType.gift;
}

/// Pagination metadata pour les messages de groupe
class GroupMessagePaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  GroupMessagePaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory GroupMessagePaginationMeta.fromJson(Map<String, dynamic> json) {
    return GroupMessagePaginationMeta(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 50,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
