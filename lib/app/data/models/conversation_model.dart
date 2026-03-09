import 'user_model.dart';
import 'chat_message_model.dart';

class ConversationModel {
  final int id;
  final int participantOneId;
  final int participantTwoId;
  final UserModel? otherParticipant;
  final ChatMessageModel? lastMessage;
  final int unreadCount;
  final bool hasPremium;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.participantOneId,
    required this.participantTwoId,
    this.otherParticipant,
    this.lastMessage,
    this.unreadCount = 0,
    this.hasPremium = false,
    this.isAnonymous = false,
    required this.createdAt,
    required this.updatedAt,
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
