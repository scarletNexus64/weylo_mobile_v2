import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/api_service.dart';
import '../core/api_config.dart';
import '../models/story_model.dart';
import '../models/story_feed_item_model.dart';

class StoryService {
  final ApiService _apiService = ApiService();

  /// Get stories feed
  Future<List<StoryFeedItemModel>> getStoriesFeed() async {
    try {
      final response = await _apiService.get(ApiConfig.stories);

      final List<dynamic> storiesData = response.data['stories'] ?? [];
      print('📊 [STORY] Récupération de ${storiesData.length} groupes de stories');

      final stories = storiesData
          .map((item) {
            print('👤 [STORY] User: ${item['user']['username']}, RealID: ${item['real_user_id']}, Stories: ${item['stories_count']}');
            return StoryFeedItemModel.fromJson(item);
          })
          .toList();

      return stories;
    } catch (e) {
      print('❌ Error fetching stories feed: $e');
      rethrow;
    }
  }

  /// Get user stories by username
  Future<Map<String, dynamic>> getUserStoriesByUsername(String username) async {
    try {
      final response = await _apiService.get('${ApiConfig.stories}/$username');

      return {
        'user': response.data['user'],
        'is_anonymous': response.data['is_anonymous'] ?? false,
        'stories': (response.data['stories'] as List)
            .map((item) => StoryModel.fromJson(item))
            .toList(),
      };
    } catch (e) {
      print('❌ Error fetching user stories: $e');
      rethrow;
    }
  }

  /// Get user stories by ID
  Future<Map<String, dynamic>> getUserStoriesById(int userId) async {
    try {
      final response = await _apiService.get('${ApiConfig.stories}/user-by-id/$userId');

      return {
        'user': response.data['user'],
        'is_anonymous': response.data['is_anonymous'] ?? false,
        'stories': (response.data['stories'] as List)
            .map((item) => StoryModel.fromJson(item))
            .toList(),
      };
    } catch (e) {
      print('❌ Error fetching user stories by ID: $e');
      rethrow;
    }
  }

  /// Get my stories
  Future<List<StoryModel>> getMyStories({int page = 1, int perPage = 20}) async {
    try {
      final response = await _apiService.get(
        ApiConfig.myStories,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      final List<dynamic> storiesData = response.data['stories'] ?? [];
      return storiesData.map((item) => StoryModel.fromJson(item)).toList();
    } catch (e) {
      print('❌ Error fetching my stories: $e');
      rethrow;
    }
  }

  /// Get story details
  Future<StoryModel> getStoryDetails(int storyId) async {
    try {
      final response = await _apiService.get('${ApiConfig.stories}/$storyId');

      return StoryModel.fromJson(response.data['story']);
    } catch (e) {
      print('❌ Error fetching story details: $e');
      rethrow;
    }
  }

  /// Create text story
  Future<StoryModel> createTextStory({
    required String content,
    String? backgroundColor,
    int duration = 5,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConfig.stories,
        data: {
          'type': 'text',
          'content': content,
          'background_color': backgroundColor ?? '#6366f1',
          'duration': duration,
        },
      );

      return StoryModel.fromJson(response.data['story']);
    } catch (e) {
      print('❌ Error creating text story: $e');
      rethrow;
    }
  }

  /// Create image story
  Future<StoryModel> createImageStory({
    required String imagePath,
    int duration = 5,
    String? caption,
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      print('📸 [STORY] Creating image story...');
      print('   Path: $imagePath');
      print('   Duration: $duration');
      print('   Caption: ${caption ?? "(none)"}');

      // Verify file exists
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('Le fichier image n\'existe pas: $imagePath');
      }

      // Get file size
      final fileSize = await file.length();
      print('   File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Detect MIME type
      final fileName = imagePath.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      String? contentType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          throw Exception('Format d\'image non supporté: $extension. Utilisez JPG, PNG, GIF ou WebP');
      }

      print('   Content-Type: $contentType');

      // Create form data
      // Note: Dio will automatically detect content type from file extension
      final formData = FormData.fromMap({
        'type': 'image',
        'duration': duration.toString(),
        'media': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
        if (caption != null && caption.isNotEmpty) 'content': caption,
      });

      print('✅ [STORY] FormData created, uploading...');

      final response = await _apiService.uploadFile(
        ApiConfig.stories,
        formData: formData,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('📤 Upload progress: $progress%');
          if (onUploadProgress != null) {
            onUploadProgress(sent, total);
          }
        },
      );

      print('✅ [STORY] Image story created successfully');
      return StoryModel.fromJson(response.data['story']);
    } catch (e) {
      print('❌ Error creating image story: $e');
      rethrow;
    }
  }

  /// Create video story
  Future<StoryModel> createVideoStory({
    required String videoPath,
    int duration = 15,
    String? caption,
    String? thumbnailPath,
    Function(int, int)? onUploadProgress,
  }) async {
    try {
      print('🎥 [STORY] Creating video story...');
      print('   Path: $videoPath');
      print('   Duration: $duration');
      print('   Caption: ${caption ?? "(none)"}');

      // Verify file exists
      final file = File(videoPath);
      if (!await file.exists()) {
        throw Exception('Le fichier vidéo n\'existe pas: $videoPath');
      }

      // Get file size
      final fileSize = await file.length();
      print('   File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Detect MIME type
      final fileName = videoPath.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();
      String? contentType;

      switch (extension) {
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mov':
          contentType = 'video/quicktime';
          break;
        case 'avi':
          contentType = 'video/x-msvideo';
          break;
        case 'mkv':
          contentType = 'video/x-matroska';
          break;
        case 'webm':
          contentType = 'video/webm';
          break;
        default:
          throw Exception('Format vidéo non supporté: $extension. Utilisez MP4, MOV, AVI, MKV ou WebM');
      }

      print('   Content-Type: $contentType');

      // Create form data
      final Map<String, dynamic> formDataMap = {
        'type': 'video',
        'duration': duration.toString(),
        'media': await MultipartFile.fromFile(
          videoPath,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
        if (caption != null && caption.isNotEmpty) 'content': caption,
      };

      // Add thumbnail if provided
      if (thumbnailPath != null && await File(thumbnailPath).exists()) {
        print('📸 [STORY] Adding video thumbnail');
        final thumbnailFileName = thumbnailPath.split('/').last;
        formDataMap['thumbnail'] = await MultipartFile.fromFile(
          thumbnailPath,
          filename: thumbnailFileName,
          contentType: MediaType.parse('image/jpeg'),
        );
      }

      final formData = FormData.fromMap(formDataMap);

      print('✅ [STORY] FormData created, uploading...');

      final response = await _apiService.uploadFile(
        ApiConfig.stories,
        formData: formData,
        onSendProgress: (sent, total) {
          final progress = (sent / total * 100).toStringAsFixed(1);
          print('📤 Upload progress: $progress%');
          if (onUploadProgress != null) {
            onUploadProgress(sent, total);
          }
        },
      );

      print('✅ [STORY] Video story created successfully');
      return StoryModel.fromJson(response.data['story']);
    } catch (e) {
      print('❌ Error creating video story: $e');
      rethrow;
    }
  }

  /// Delete story
  Future<void> deleteStory(int storyId) async {
    try {
      await _apiService.delete('${ApiConfig.stories}/$storyId');
    } catch (e) {
      print('❌ Error deleting story: $e');
      rethrow;
    }
  }

  /// Mark story as viewed
  Future<Map<String, dynamic>> markStoryAsViewed(int storyId) async {
    try {
      final response = await _apiService.post('${ApiConfig.stories}/$storyId/view');

      return {
        'message': response.data['message'],
        'views_count': response.data['views_count'],
      };
    } catch (e) {
      print('❌ Error marking story as viewed: $e');
      rethrow;
    }
  }

  /// Get story viewers
  Future<Map<String, dynamic>> getStoryViewers(int storyId) async {
    try {
      final response = await _apiService.get('${ApiConfig.stories}/$storyId/viewers');

      return {
        'viewers': response.data['viewers'],
        'total_views': response.data['total_views'],
      };
    } catch (e) {
      print('❌ Error fetching story viewers: $e');
      rethrow;
    }
  }

  /// Reply to a story
  Future<Map<String, dynamic>> replyToStory(int storyId, String message) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.stories}/$storyId/reply',
        data: {
          'message': message,
        },
      );

      return {
        'conversation_id': response.data['conversation_id'],
        'message_id': response.data['message_id'],
      };
    } catch (e) {
      print('❌ Error replying to story: $e');
      rethrow;
    }
  }

  /// Get stories stats
  Future<Map<String, dynamic>> getStoriesStats() async {
    try {
      final response = await _apiService.get('${ApiConfig.stories}/stats');

      return {
        'total_stories': response.data['total_stories'] ?? 0,
        'active_stories': response.data['active_stories'] ?? 0,
        'expired_stories': response.data['expired_stories'] ?? 0,
        'total_views': response.data['total_views'] ?? 0,
      };
    } catch (e) {
      print('❌ Error fetching stories stats: $e');
      rethrow;
    }
  }
}
