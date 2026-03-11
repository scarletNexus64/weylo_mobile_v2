import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/confession_model.dart';
import '../../utils/video_thumbnail_generator.dart';

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

      // Générer le thumbnail pour les vidéos
      String? thumbnailPath;
      if (mediaType == 'video') {
        print('📸 [CONFESSION] Generating video thumbnail...');
        thumbnailPath = await VideoThumbnailGenerator.generateThumbnail(
          mediaPath,
          timeMs: 1000, // Capture à 1 seconde
        );

        if (thumbnailPath != null) {
          print('✅ [CONFESSION] Thumbnail generated: $thumbnailPath');
        } else {
          print('⚠️ [CONFESSION] Failed to generate thumbnail, proceeding without it');
        }
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

      // Ajouter le thumbnail si disponible
      if (thumbnailPath != null) {
        formDataMap['thumbnail'] = await MultipartFile.fromFile(
          thumbnailPath,
          filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

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
  Future<Map<String, dynamic>> likeConfession(int confessionId) async {
    try {
      final response = await _api.post(
        '${ApiConfig.confessions}/$confessionId/like',
      );

      return {
        'likes_count': response.data['likes_count'] as int,
        'is_liked': response.data['is_liked'] as bool? ?? true,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike a confession
  Future<Map<String, dynamic>> unlikeConfession(int confessionId) async {
    try {
      final response = await _api.delete(
        '${ApiConfig.confessions}/$confessionId/like',
      );

      return {
        'likes_count': response.data['likes_count'] as int,
        'is_liked': response.data['is_liked'] as bool? ?? false,
      };
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

  /// Get comments for a confession with pagination
  Future<CommentsResponse> getComments(
    int confessionId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _api.get(
        '${ApiConfig.confessions}/$confessionId/comments',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final comments = (response.data['comments'] as List)
          .map((json) => ConfessionComment.fromJson(json as Map<String, dynamic>))
          .toList();

      return CommentsResponse(
        comments: comments,
        currentPage: response.data['current_page'] as int? ?? page,
        totalPages: response.data['total_pages'] as int? ?? 1,
        hasMore: response.data['has_more'] as bool? ?? false,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Add a comment to a confession
  Future<ConfessionComment> addComment({
    required int confessionId,
    String? content,
    bool isAnonymous = false,
    int? parentId, // Pour les réponses
    File? audioFile,
    File? imageFile,
    String? voiceType, // Type de voix pour les commentaires vocaux anonymes
  }) async {
    try {
      FormData formData;

      // Si on a un fichier (audio ou image), utiliser multipart/form-data
      if (audioFile != null || imageFile != null) {
        formData = FormData();

        // Ajouter les champs texte
        formData.fields.add(MapEntry('content', content ?? ''));
        formData.fields.add(MapEntry('is_anonymous', isAnonymous ? '1' : '0'));
        if (parentId != null) {
          formData.fields.add(MapEntry('parent_id', parentId.toString()));
        }

        if (audioFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              audioFile.path,
              filename: audioFile.path.split('/').last,
            ),
          ));
          formData.fields.add(const MapEntry('media_type', 'audio'));
          // Ajouter le type de voix si spécifié
          if (voiceType != null) {
            formData.fields.add(MapEntry('voice_type', voiceType));
          }
        } else if (imageFile != null) {
          formData.files.add(MapEntry(
            'media',
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.path.split('/').last,
            ),
          ));
          formData.fields.add(const MapEntry('media_type', 'image'));
        }

        final response = await _api.post(
          '${ApiConfig.confessions}/$confessionId/comments',
          data: formData,
        );

        return ConfessionComment.fromJson(response.data['comment']);
      } else {
        // Sinon, utiliser JSON classique
        final Map<String, dynamic> data = {
          'content': content ?? '',
          'is_anonymous': isAnonymous,
        };

        if (parentId != null) {
          data['parent_id'] = parentId;
        }

        final response = await _api.post(
          '${ApiConfig.confessions}/$confessionId/comments',
          data: data,
        );

        return ConfessionComment.fromJson(response.data['comment']);
      }
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

  /// Like a comment
  Future<Map<String, dynamic>> likeComment({
    required int confessionId,
    required int commentId,
  }) async {
    try {
      final response = await _api.post(
        '${ApiConfig.confessions}/$confessionId/comments/$commentId/like',
      );

      return {
        'likes_count': response.data['likes_count'] as int,
        'is_liked': response.data['is_liked'] as bool,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Unlike a comment
  Future<Map<String, dynamic>> unlikeComment({
    required int confessionId,
    required int commentId,
  }) async {
    try {
      final response = await _api.delete(
        '${ApiConfig.confessions}/$confessionId/comments/$commentId/like',
      );

      return {
        'likes_count': response.data['likes_count'] as int,
        'is_liked': response.data['is_liked'] as bool,
      };
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

  /// Get favorite confessions with pagination
  Future<ConfessionListResponse> getFavoriteConfessions({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.favoriteConfessions,
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
  final String mediaType; // 'none', 'audio', 'image'
  final String? mediaUrl;
  final ConfessionCommentAuthor author;
  final DateTime createdAt;
  final bool isMine;
  final int likesCount;
  final bool isLiked;
  final int repliesCount;
  final List<ConfessionComment> replies;

  ConfessionComment({
    required this.id,
    required this.content,
    required this.isAnonymous,
    this.mediaType = 'none',
    this.mediaUrl,
    required this.author,
    required this.createdAt,
    required this.isMine,
    this.likesCount = 0,
    this.isLiked = false,
    this.repliesCount = 0,
    this.replies = const [],
  });

  factory ConfessionComment.fromJson(Map<String, dynamic> json) {
    return ConfessionComment(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      mediaType: json['media_type'] as String? ?? 'none',
      mediaUrl: json['media_url'] as String?,
      author: ConfessionCommentAuthor.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      isMine: json['is_mine'] as bool? ?? false,
      likesCount: json['likes_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      repliesCount: json['replies_count'] as int? ?? 0,
      replies: (json['replies'] as List?)
          ?.map((reply) => ConfessionComment.fromJson(reply as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  ConfessionComment copyWith({
    int? likesCount,
    bool? isLiked,
    int? repliesCount,
    List<ConfessionComment>? replies,
  }) {
    return ConfessionComment(
      id: id,
      content: content,
      isAnonymous: isAnonymous,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      author: author,
      createdAt: createdAt,
      isMine: isMine,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      repliesCount: repliesCount ?? this.repliesCount,
      replies: replies ?? this.replies,
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
    // Clean avatar URL - fix malformed URLs with multiple ? in query params
    String? avatarUrl = json['avatar_url'] as String?;
    if (avatarUrl != null && avatarUrl.contains('?')) {
      final parts = avatarUrl.split('?');
      if (parts.length > 2) {
        avatarUrl = '${parts[0]}?${parts.sublist(1).join('&')}';
      }
    }

    return ConfessionCommentAuthor(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Anonyme',
      username: json['username'] as String?,
      initial: json['initial'] as String? ?? '?',
      avatarUrl: avatarUrl,
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

/// Response for paginated comments
class CommentsResponse {
  final List<ConfessionComment> comments;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  CommentsResponse({
    required this.comments,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });
}
