import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/group_model.dart';
import '../models/group_message_model.dart';
import '../models/group_category_model.dart';

class GroupService {
  final _api = ApiService();

  /// Get user's groups with pagination
  Future<GroupListResponse> getMyGroups({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.groups,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final groups = (data['groups'] as List)
          .map((json) => GroupModel.fromJson(json))
          .toList();

      final meta = GroupPaginationMeta.fromJson(data['meta']);

      return GroupListResponse(
        groups: groups,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Discover public groups with pagination and optional category filter
  Future<GroupListResponse> discoverGroups({
    int page = 1,
    int perPage = 20,
    int? categoryId,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'per_page': perPage,
      };

      // Ajouter category_id seulement si fourni
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _api.get(
        ApiConfig.discoverGroups,
        queryParameters: queryParams,
      );

      final data = response.data;
      final groups = (data['groups'] as List)
          .map((json) => GroupModel.fromJson(json))
          .toList();

      final meta = GroupPaginationMeta.fromJson(data['meta']);

      return GroupListResponse(
        groups: groups,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get all group categories
  Future<List<GroupCategoryModel>> getCategories() async {
    try {
      final response = await _api.get(ApiConfig.groupCategories);
      final data = response.data;

      final categories = (data['categories'] as List)
          .map((json) => GroupCategoryModel.fromJson(json))
          .toList();

      return categories;
    } catch (e) {
      rethrow;
    }
  }

  /// Get group details
  Future<GroupModel> getGroup(int groupId) async {
    try {
      final response = await _api.get('${ApiConfig.groups}/$groupId');
      return GroupModel.fromJson(response.data['group']);
    } catch (e) {
      rethrow;
    }
  }

  /// Get messages for a specific group with pagination
  Future<GroupMessageListResponse> getMessages({
    required int groupId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.groups}/$groupId/messages',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final data = response.data;
      final messages = (data['messages'] as List)
          .map((json) => GroupMessageModel.fromJson(json))
          .toList();

      final meta = GroupMessagePaginationMeta.fromJson(data['meta'] ?? {});

      return GroupMessageListResponse(
        messages: messages,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Mark group as read
  Future<void> markAsRead(int groupId) async {
    try {
      await _api.post('${ApiConfig.groups}/$groupId/read');
    } catch (e) {
      rethrow;
    }
  }

  /// Get total unread count for all groups
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get('${ApiConfig.groups}/unread-count');
      return response.data['total_unread_count'] as int? ?? 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Get group statistics
  Future<GroupStats> getGroupStats() async {
    try {
      final response = await _api.get('${ApiConfig.groups}/stats');
      return GroupStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Join a group by group ID (for public groups)
  Future<GroupModel> joinGroupById(int groupId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.groups}/join',
        data: {
          'group_id': groupId,
        },
      );
      return GroupModel.fromJson(response.data['group']);
    } catch (e) {
      rethrow;
    }
  }

  /// Join a group by invite code (for private groups)
  Future<GroupModel> joinGroupByCode(String inviteCode) async {
    try {
      final response = await _api.post(
        '${ApiConfig.groups}/join',
        data: {
          'invite_code': inviteCode,
        },
      );
      return GroupModel.fromJson(response.data['group']);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    String? description,
    int? categoryId,
    bool isPublic = false,
    bool isDiscoverable = true,
    int? maxMembers,
  }) async {
    try {
      final data = {
        'name': name,
        'is_public': isPublic,
        'is_discoverable': isDiscoverable,
      };

      if (description != null && description.isNotEmpty) {
        data['description'] = description;
      }

      if (categoryId != null) {
        data['category_id'] = categoryId;
      }

      if (maxMembers != null) {
        data['max_members'] = maxMembers;
      }

      final response = await _api.post(
        ApiConfig.groups,
        data: data,
      );

      return GroupModel.fromJson(response.data['group']);
    } catch (e) {
      rethrow;
    }
  }

  /// Search/filter public groups with pagination
  Future<GroupListResponse> searchGroups({
    required String search,
    int page = 1,
    int perPage = 20,
    int? categoryId,
    String sortBy = 'recent',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'per_page': perPage,
        'search': search,
        'sort_by': sortBy,
      };

      // Ajouter category_id seulement si fourni
      if (categoryId != null) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _api.get(
        ApiConfig.discoverGroups,
        queryParameters: queryParams,
      );

      final data = response.data;
      final groups = (data['groups'] as List)
          .map((json) => GroupModel.fromJson(json))
          .toList();

      final meta = GroupPaginationMeta.fromJson(data['meta']);

      return GroupListResponse(
        groups: groups,
        meta: meta,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send a message in a group
  Future<GroupMessageModel> sendMessage({
    required int groupId,
    String? content,
    String type = 'text',
    File? audioFile,
    File? imageFile,
    Map<String, dynamic>? metadata,
    String? voiceType,
    int? replyToMessageId,
  }) async {
    try {
      // Si on a un fichier, utiliser multipart/form-data
      if (audioFile != null || imageFile != null) {
        final formData = FormData();

        // Ajouter les champs texte
        formData.fields.add(MapEntry('content', content ?? ''));
        formData.fields.add(MapEntry('type', type));

        // Ajouter voice_type si fourni
        if (voiceType != null) {
          formData.fields.add(MapEntry('voice_type', voiceType));
        }

        // Ajouter reply_to_message_id si fourni
        if (replyToMessageId != null) {
          formData.fields.add(MapEntry('reply_to_message_id', replyToMessageId.toString()));
        }

        // Ajouter les metadata si fournis
        if (metadata != null) {
          // FormData nécessite des strings, donc encoder en JSON
          formData.fields.add(MapEntry('metadata', jsonEncode(metadata)));
        }

        // Ajouter le fichier
        if (audioFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              audioFile.path,
              filename: audioFile.path.split('/').last,
            ),
          ));
        } else if (imageFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ));
        }

        final response = await _api.post(
          '${ApiConfig.groups}/$groupId/messages',
          data: formData,
        );

        return GroupMessageModel.fromJson(response.data['message']);
      } else {
        // Sinon, utiliser JSON classique pour les messages texte
        final data = <String, dynamic>{
          'content': content,
          'type': type,
        };

        // Ajouter reply_to_message_id si fourni
        if (replyToMessageId != null) {
          data['reply_to_message_id'] = replyToMessageId;
        }

        // Encoder metadata en JSON string (le backend attend une string JSON)
        if (metadata != null) {
          data['metadata'] = jsonEncode(metadata);
        }

        final response = await _api.post(
          '${ApiConfig.groups}/$groupId/messages',
          data: data,
        );

        return GroupMessageModel.fromJson(response.data['message']);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message in a group
  Future<void> deleteMessage({
    required int groupId,
    required int messageId,
  }) async {
    try {
      await _api.delete('${ApiConfig.groups}/$groupId/messages/$messageId');
    } catch (e) {
      rethrow;
    }
  }
}

/// Response wrapper for group list with pagination
class GroupListResponse {
  final List<GroupModel> groups;
  final GroupPaginationMeta meta;

  GroupListResponse({
    required this.groups,
    required this.meta,
  });
}

/// Response wrapper for group message list with pagination
class GroupMessageListResponse {
  final List<GroupMessageModel> messages;
  final GroupMessagePaginationMeta meta;

  GroupMessageListResponse({
    required this.messages,
    required this.meta,
  });
}

/// Group statistics
class GroupStats {
  final int totalGroups;
  final int totalMembers;
  final int totalMessages;

  GroupStats({
    required this.totalGroups,
    required this.totalMembers,
    required this.totalMessages,
  });

  factory GroupStats.fromJson(Map<String, dynamic> json) {
    return GroupStats(
      totalGroups: json['total_groups'] ?? 0,
      totalMembers: json['total_members'] ?? 0,
      totalMessages: json['total_messages'] ?? 0,
    );
  }
}
