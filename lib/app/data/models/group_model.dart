import 'user_model.dart';
import 'group_message_model.dart';

class GroupModel {
  final int id;
  final String name;
  final String? description;
  final int creatorId;
  final String inviteCode;
  final bool isPublic;
  final int maxMembers;
  final int membersCount;
  final GroupMessageModel? lastMessage;
  final int unreadCount;
  final bool isCreator;
  final bool isAdmin;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.inviteCode,
    this.isPublic = false,
    this.maxMembers = 50,
    this.membersCount = 0,
    this.lastMessage,
    this.unreadCount = 0,
    this.isCreator = false,
    this.isAdmin = false,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      creatorId: json['creator_id'],
      inviteCode: json['invite_code'],
      isPublic: json['is_public'] ?? false,
      maxMembers: json['max_members'] ?? 50,
      membersCount: json['members_count'] ?? 0,
      lastMessage: json['last_message'] != null
          ? GroupMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isCreator: json['is_creator'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'invite_code': inviteCode,
      'is_public': isPublic,
      'max_members': maxMembers,
      'members_count': membersCount,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_creator': isCreator,
      'is_admin': isAdmin,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Helpers
  bool get isFull => membersCount >= maxMembers;
  bool get hasUnreadMessages => unreadCount > 0;
}

/// Pagination metadata pour les groupes
class GroupPaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  GroupPaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory GroupPaginationMeta.fromJson(Map<String, dynamic> json) {
    return GroupPaginationMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasMorePages => currentPage < lastPage;
}
