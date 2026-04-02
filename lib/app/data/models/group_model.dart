import 'dart:math';
import 'user_model.dart';
import 'group_message_model.dart';
import 'group_category_model.dart';

class GroupModel {
  final int id;
  final String name;
  final String? description;
  final String? avatarUrl;
  final int? categoryId;
  final GroupCategoryModel? category;
  final int creatorId;
  final String inviteCode;
  final bool isPublic;
  final String postingPermission; // 'everyone' or 'admins_only'
  final int maxMembers;
  final int membersCount;
  final int messagesCount;
  final GroupMessageModel? lastMessage;
  final int unreadCount;
  final bool isCreator;
  final bool isAdmin;
  final bool? isMember; // Pour les groupes discover
  final bool? canJoin; // Pour les groupes discover
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    this.avatarUrl,
    this.categoryId,
    this.category,
    required this.creatorId,
    required this.inviteCode,
    this.isPublic = false,
    this.postingPermission = 'everyone',
    this.maxMembers = 50,
    this.membersCount = 0,
    this.messagesCount = 0,
    this.lastMessage,
    this.unreadCount = 0,
    this.isCreator = false,
    this.isAdmin = false,
    this.isMember,
    this.canJoin,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatarUrl: json['avatar_url'],
      categoryId: json['category_id'],
      category: json['category'] != null
          ? GroupCategoryModel.fromJson(json['category'])
          : null,
      creatorId: json['creator_id'],
      inviteCode: json['invite_code'],
      isPublic: json['is_public'] ?? false,
      postingPermission: json['posting_permission'] ?? 'everyone',
      maxMembers: json['max_members'] ?? 50,
      membersCount: json['members_count'] ?? 0,
      messagesCount: json['messages_count'] ?? 0,
      lastMessage: json['last_message'] != null
          ? GroupMessageModel.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      isCreator: json['is_creator'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isMember: json['is_member'],
      canJoin: json['can_join'],
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
      'avatar_url': avatarUrl,
      'category_id': categoryId,
      'category': category?.toJson(),
      'creator_id': creatorId,
      'invite_code': inviteCode,
      'is_public': isPublic,
      'posting_permission': postingPermission,
      'max_members': maxMembers,
      'members_count': membersCount,
      'messages_count': messagesCount,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'is_creator': isCreator,
      'is_admin': isAdmin,
      'is_member': isMember,
      'can_join': canJoin,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get initials from group name
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'G';
    if (words.length == 1) {
      return words[0].substring(0, min(2, words[0].length)).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Helpers
  bool get isFull => membersCount >= maxMembers;
  bool get hasUnreadMessages => unreadCount > 0;

  /// Check if current user can post messages
  bool get canPost {
    if (postingPermission == 'everyone') {
      return true;
    }
    // If posting is restricted to admins only
    return isCreator || isAdmin;
  }
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
