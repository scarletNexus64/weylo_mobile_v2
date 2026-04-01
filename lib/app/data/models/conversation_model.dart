import 'user_model.dart';
import 'chat_message_model.dart';

/// Flame level enum matching backend
enum FlameLevel {
  none,
  yellow,
  orange,
  purple;

  static FlameLevel fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'yellow':
        return FlameLevel.yellow;
      case 'orange':
        return FlameLevel.orange;
      case 'purple':
        return FlameLevel.purple;
      default:
        return FlameLevel.none;
    }
  }
}

/// Streak data for a conversation
class StreakData {
  final int count;
  final FlameLevel flameLevel;
  final DateTime? streakUpdatedAt;

  StreakData({
    required this.count,
    required this.flameLevel,
    this.streakUpdatedAt,
  });

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      count: json['count'] ?? 0,
      flameLevel: FlameLevel.fromString(json['flame_level']),
      streakUpdatedAt: json['streak_updated_at'] != null
          ? DateTime.parse(json['streak_updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'flame_level': flameLevel.name,
      'streak_updated_at': streakUpdatedAt?.toIso8601String(),
    };
  }

  bool get hasStreak => count > 0;

  /// Calculate progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (count >= 30) return 1.0; // Max level reached
    if (count >= 7) return (count - 7) / 23.0; // Progress to purple (7-30)
    if (count >= 2) return (count - 2) / 5.0; // Progress to orange (2-7)
    return count / 2.0; // Progress to yellow (0-2)
  }

  /// Get the next milestone
  int get nextMilestone {
    if (count >= 30) return 30;
    if (count >= 7) return 30;
    if (count >= 2) return 7;
    return 2;
  }
}

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
  final StreakData? streak;

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
    this.streak,
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
      streak: json['streak'] != null
          ? StreakData.fromJson(json['streak'])
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
      'streak': streak?.toJson(),
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
