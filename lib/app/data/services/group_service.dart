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

      final meta = GroupMessagePaginationMeta.fromJson(data['meta']);

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
