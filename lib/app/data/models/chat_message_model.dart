import 'user_model.dart';

enum ChatMessageType { text, image, audio, video, gift, system }

class ChatMessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final UserModel? sender;
  final String? content;
  final ChatMessageType type;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    this.content,
    required this.type,
    this.mediaUrl,
    this.metadata,
    this.isRead = false,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'],
      sender: json['sender'] != null ? UserModel.fromJson(json['sender']) : null,
      content: json['content'],
      type: _parseMessageType(json['type']),
      mediaUrl: json['media_url'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
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
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helpers pour vérifier le type de message
  bool get isTextMessage => type == ChatMessageType.text;
  bool get isImageMessage => type == ChatMessageType.image;
  bool get isAudioMessage => type == ChatMessageType.audio;
  bool get isVideoMessage => type == ChatMessageType.video;
  bool get isGiftMessage => type == ChatMessageType.gift;
  bool get isSystemMessage => type == ChatMessageType.system;
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
