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
    return GroupMessageModel(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      content: json['content'],
      type: _parseMessageType(json['type']),
      mediaUrl: json['media_url'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
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
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
