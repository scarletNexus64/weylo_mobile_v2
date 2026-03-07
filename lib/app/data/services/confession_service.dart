import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/confession_model.dart';

class ConfessionService {
  final _api = ApiService();

  /// Get public confessions feed with pagination
  Future<ConfessionListResponse> getConfessions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.confessions,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return ConfessionListResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single confession by ID
  Future<ConfessionModel> getConfession(int id) async {
    try {
      final response = await _api.get('${ApiConfig.confessions}/$id');
      return ConfessionModel.fromJson(response.data['confession']);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new confession
  Future<ConfessionModel> createConfession({
    required String content,
    String type = 'public',
    String? recipientUsername,
    bool isAnonymous = false,
    String? mediaPath,
    String mediaType = 'none', // 'none', 'image', 'video'
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      // Si pas de média, utiliser la requête POST normale
      if (mediaType == 'none' || mediaPath == null) {
        final response = await _api.post(
          ApiConfig.confessions,
          data: {
            'content': content,
            'type': type,
            'is_identity_revealed': !isAnonymous,
            'media_type': 'none',
            if (recipientUsername != null) 'recipient_username': recipientUsername,
          },
        );

        return ConfessionModel.fromJson(response.data['confession']);
      }

      // Avec média, utiliser FormData
      print('📤 [CONFESSION] Creating confession with media...');
      print('   Type: $type');
      print('   Media type: $mediaType');
      print('   Media path: $mediaPath');

      // Vérifier que le fichier existe
      final file = File(mediaPath);
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas: $mediaPath');
      }

      final fileName = mediaPath.split('/').last;
      final formDataMap = {
        'content': content,
        'type': type,
        'is_identity_revealed': !isAnonymous ? '1' : '0',
        'media_type': mediaType,
        'media': await MultipartFile.fromFile(
          mediaPath,
          filename: fileName,
        ),
        if (recipientUsername != null) 'recipient_username': recipientUsername,
      };

      final formData = FormData.fromMap(formDataMap);

      final response = await _api.uploadFile(
        ApiConfig.confessions,
        formData: formData,
        onSendProgress: (sent, total) {
          if (onUploadProgress != null) {
            onUploadProgress(sent, total);
          }
        },
      );

      print('✅ [CONFESSION] Confession created successfully');
      return ConfessionModel.fromJson(response.data['confession']);
    } catch (e) {
      print('❌ Error creating confession: $e');
      rethrow;
    }
  }

  /// Like a confession
  Future<int> likeConfession(int confessionId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.confessions}/$confessionId/like',
      );

      return response.data['likes_count'] as int;
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike a confession
  Future<int> unlikeConfession(int confessionId) async {
    try {
      final response = await _api.delete(
        '${ApiConfig.confessions}/$confessionId/like',
      );

      return response.data['likes_count'] as int;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a confession
  Future<void> deleteConfession(int confessionId) async {
    try {
      await _api.delete('${ApiConfig.confessions}/$confessionId');
    } catch (e) {
      rethrow;
    }
  }

  /// Report a confession
  Future<void> reportConfession({
    required int confessionId,
    required String reason,
    String? description,
  }) async {
    try {
      await _api.post(
        '${ApiConfig.confessions}/$confessionId/report',
        data: {
          'reason': reason,
          if (description != null) 'description': description,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get comments for a confession
  Future<List<ConfessionComment>> getComments(int confessionId) async {
    try {
      final response = await _api.get(
        '${ApiConfig.confessions}/$confessionId/comments',
      );

      final comments = (response.data['comments'] as List)
          .map((json) => ConfessionComment.fromJson(json as Map<String, dynamic>))
          .toList();

      return comments;
    } catch (e) {
      rethrow;
    }
  }

  /// Add a comment to a confession
  Future<ConfessionComment> addComment({
    required int confessionId,
    required String content,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.confessions}/$confessionId/comments',
        data: {
          'content': content,
          'is_anonymous': isAnonymous,
        },
      );

      return ConfessionComment.fromJson(response.data['comment']);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment({
    required int confessionId,
    required int commentId,
  }) async {
    try {
      await _api.delete(
        '${ApiConfig.confessions}/$confessionId/comments/$commentId',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get received confessions (private ones)
  Future<ConfessionListResponse> getReceivedConfessions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.receivedConfessions,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return ConfessionListResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get sent confessions
  Future<ConfessionListResponse> getSentConfessions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.sentConfessions,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return ConfessionListResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Get confession stats
  Future<ConfessionStats> getStats() async {
    try {
      final response = await _api.get('${ApiConfig.confessions}/stats');
      return ConfessionStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle favorite (bookmark) a confession
  Future<void> toggleFavorite(int confessionId) async {
    try {
      await _api.post(
        '${ApiConfig.confessions}/$confessionId/favorite',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Reveal the identity of an anonymous confession author
  Future<Map<String, dynamic>> revealIdentity(int confessionId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.confessions}/$confessionId/reveal-identity',
      );

      return {
        'name': response.data['author']['name'] as String,
        'username': response.data['author']['username'] as String,
        'avatar_url': response.data['author']['avatar_url'] as String?,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get favorite confessions
  Future<ConfessionListResponse> getFavoriteConfessions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.confessions}/favorites',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      return ConfessionListResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a confession
  Future<ConfessionModel> updateConfession({
    required int confessionId,
    required String content,
    String? mediaPath,
    String? mediaType,
    bool removeMedia = false,
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      // Si pas de nouveau média, utiliser une requête PUT normale
      if (mediaPath == null || mediaType == null || mediaType == 'none') {
        final response = await _api.put(
          '${ApiConfig.confessions}/$confessionId',
          data: {
            'content': content,
            // Si removeMedia est true, envoyer 'none' pour supprimer le média
            if (removeMedia) 'media_type': 'none',
            if (removeMedia) 'remove_media': true,
          },
        );

        return ConfessionModel.fromJson(response.data['confession']);
      }

      // Avec média, utiliser FormData avec _method: PUT
      print('📤 [CONFESSION] Updating confession with new media...');

      final fileName = mediaPath.split('/').last;
      final formDataMap = {
        '_method': 'PUT',
        'content': content,
        'media_type': mediaType,
        'media': await MultipartFile.fromFile(
          mediaPath,
          filename: fileName,
        ),
      };

      final formData = FormData.fromMap(formDataMap);

      final response = await _api.uploadFile(
        '${ApiConfig.confessions}/$confessionId',
        formData: formData,
        onSendProgress: (sent, total) {
          if (onUploadProgress != null) {
            onUploadProgress(sent, total);
          }
        },
      );

      print('✅ [CONFESSION] Confession updated successfully');
      return ConfessionModel.fromJson(response.data['confession']);
    } catch (e) {
      print('❌ Error updating confession: $e');
      rethrow;
    }
  }
}

/// Model for confession comments
class ConfessionComment {
  final int id;
  final String content;
  final bool isAnonymous;
  final ConfessionCommentAuthor author;
  final DateTime createdAt;
  final bool isMine;

  ConfessionComment({
    required this.id,
    required this.content,
    required this.isAnonymous,
    required this.author,
    required this.createdAt,
    required this.isMine,
  });

  factory ConfessionComment.fromJson(Map<String, dynamic> json) {
    return ConfessionComment(
      id: json['id'] as int,
      content: json['content'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      author: ConfessionCommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      isMine: json['is_mine'] as bool? ?? false,
    );
  }
}

class ConfessionCommentAuthor {
  final int? id;
  final String name;
  final String? username;
  final String initial;
  final String? avatarUrl;

  ConfessionCommentAuthor({
    this.id,
    required this.name,
    this.username,
    required this.initial,
    this.avatarUrl,
  });

  factory ConfessionCommentAuthor.fromJson(Map<String, dynamic> json) {
    return ConfessionCommentAuthor(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Anonyme',
      username: json['username'] as String?,
      initial: json['initial'] as String? ?? '?',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Model for confession statistics
class ConfessionStats {
  final int receivedCount;
  final int sentCount;
  final int publicApprovedCount;
  final int pendingCount;

  ConfessionStats({
    required this.receivedCount,
    required this.sentCount,
    required this.publicApprovedCount,
    required this.pendingCount,
  });

  factory ConfessionStats.fromJson(Map<String, dynamic> json) {
    return ConfessionStats(
      receivedCount: json['received_count'] as int? ?? 0,
      sentCount: json['sent_count'] as int? ?? 0,
      publicApprovedCount: json['public_approved_count'] as int? ?? 0,
      pendingCount: json['pending_count'] as int? ?? 0,
    );
  }
}
