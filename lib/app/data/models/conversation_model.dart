import 'user_model.dart';
import 'chat_message_model.dart';

class ConversationModel {
  final int id;
  final int? participantOneId;
  final int? participantTwoId;
  final UserModel? otherParticipant;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final bool hasPremium;
  final bool isAnonymous;
  final bool identityRevealed;
  final bool canInitiateReveal;
  final int? anonymousMessageId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    this.participantOneId,
    this.participantTwoId,
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
    this.hasPremium = false,
    this.isAnonymous = false,
    this.identityRevealed = false,
    this.canInitiateReveal = false,
    this.anonymousMessageId,
    required this.createdAt,
    this.updatedAt,
    this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      participantOneId: json['participant_one_id'],
      participantTwoId: json['participant_two_id'],
      otherParticipant: json['other_participant'] != null
          ? UserModel.fromJson(json['other_participant'])
          : null,
      lastMessage: json['last_message'] != null
          ? ChatMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      hasPremium: json['has_premium'] ?? false,
      isAnonymous: json['is_anonymous'] ?? false,
      identityRevealed: json['identity_revealed'] ?? false,
      canInitiateReveal: json['can_initiate_reveal'] ?? false,
      anonymousMessageId: json['anonymous_message_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participant_one_id': participantOneId,
      'participant_two_id': participantTwoId,
      'other_participant': otherParticipant?.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'has_premium': hasPremium,
      'is_anonymous': isAnonymous,
      'identity_revealed': identityRevealed,
      'can_initiate_reveal': canInitiateReveal,
      'anonymous_message_id': anonymousMessageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }
}

/// Pagination metadata pour les conversations
class ConversationPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  ConversationPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory ConversationPaginationMeta.fromJson(Map<String, dynamic> json) {
    return ConversationPaginationMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
