import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/story_feed_item_model.dart';
import '../../../data/services/story_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../utils/video_thumbnail_generator.dart';

class StoryController extends GetxController {
  final StoryService _storyService = StoryService();
  final StorageService _storage = StorageService();

  // Stories feed (grouped by user)
  final storiesFeed = <StoryFeedItemModel>[].obs;
  final isLoadingFeed = false.obs;
  final feedError = Rx<String?>(null);

  // My stories
  final myStories = <StoryModel>[].obs;
  final isLoadingMyStories = false.obs;
  final myStoriesError = Rx<String?>(null);

  // Current viewing stories
  final currentUserStories = <StoryModel>[].obs;
  final currentStoryIndex = 0.obs;
  final isLoadingUserStories = false.obs;

  // Create story states
  final isCreatingStory = false.obs;
  final uploadProgress = 0.0.obs;

  // Stats
  final stats = Rx<Map<String, dynamic>?>(null);

  @override
  void onInit() {
    super.onInit();
    // Only load stories if user is authenticated
    if (_storage.getToken() != null) {
      loadStoriesFeed();
    } else {
      print('⚠️ [STORY] Pas de token, pas de chargement de stories');
    }
  }

  /// Load stories feed (backend gère l'expiration 24h)
  Future<void> loadStoriesFeed({bool refresh = false}) async {
    if (isLoadingFeed.value && !refresh) return;

    if (refresh) {
      feedError.value = null;
    } else {
      isLoadingFeed.value = true;
    }

    try {
      final feed = await _storyService.getStoriesFeed();

      // Le backend gère déjà :
      // - L'expiration automatique après 24h (expires_at)
      // - Le filtrage des stories actives (->active())
      // - Le groupement par utilisateur
      // Donc on affiche directement tout ce que le backend envoie
      storiesFeed.value = feed;

      feedError.value = null;
    } catch (e) {
      feedError.value = _getErrorMessage(e);
      print('❌ Error loading stories feed: $e');

      Get.snackbar(
        'Erreur',
        feedError.value ?? 'Impossible de charger les stories',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingFeed.value = false;
    }
  }

  /// Load my stories
  Future<void> loadMyStories({int page = 1}) async {
    isLoadingMyStories.value = true;
    myStoriesError.value = null;

    try {
      final stories = await _storyService.getMyStories(page: page);
      myStories.value = stories;
      myStoriesError.value = null;
    } catch (e) {
      myStoriesError.value = _getErrorMessage(e);
      print('❌ Error loading my stories: $e');

      Get.snackbar(
        'Erreur',
        myStoriesError.value ?? 'Impossible de charger vos stories',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMyStories.value = false;
    }
  }

  /// Load user stories by ID
  Future<void> loadUserStoriesById(int userId) async {
    isLoadingUserStories.value = true;

    try {
      final result = await _storyService.getUserStoriesById(userId);
      currentUserStories.value = result['stories'] as List<StoryModel>;
      currentStoryIndex.value = 0;
    } catch (e) {
      print('❌ Error loading user stories: $e');

      // Only show snackbar for non-404 errors
      if (!e.toString().contains('404')) {
        Get.snackbar(
          'Erreur',
          _getErrorMessage(e),
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Clear current stories on error
      currentUserStories.clear();
    } finally {
      isLoadingUserStories.value = false;
    }
  }

  /// Load user stories by username
  Future<void> loadUserStoriesByUsername(String username) async {
    isLoadingUserStories.value = true;

    try {
      final result = await _storyService.getUserStoriesByUsername(username);
      currentUserStories.value = result['stories'] as List<StoryModel>;
      currentStoryIndex.value = 0;
    } catch (e) {
      print('❌ Error loading user stories: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingUserStories.value = false;
    }
  }

  /// Create text story
  Future<bool> createTextStory({
    required String content,
    String? backgroundColor,
    int duration = 5,
  }) async {
    isCreatingStory.value = true;

    try {
      final story = await _storyService.createTextStory(
        content: content,
        backgroundColor: backgroundColor,
        duration: duration,
      );

      // Add to my stories
      myStories.insert(0, story);

      // Refresh feed to get updated preview
      await loadStoriesFeed(refresh: true);

      Get.snackbar(
        'Succès',
        'Story créée avec succès !',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      print('❌ Error creating text story: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } finally {
      isCreatingStory.value = false;
    }
  }

  /// Create image story
  Future<bool> createImageStory({
    required String imagePath,
    int duration = 5,
    String? caption,
  }) async {
    isCreatingStory.value = true;
    uploadProgress.value = 0.0;

    try {
      final story = await _storyService.createImageStory(
        imagePath: imagePath,
        duration: duration,
        caption: caption,
        onUploadProgress: (sent, total) {
          uploadProgress.value = sent / total;
        },
      );

      // Add to my stories
      myStories.insert(0, story);

      // Refresh feed to get updated preview
      await loadStoriesFeed(refresh: true);

      Get.snackbar(
        'Succès',
        'Story créée avec succès !',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      print('❌ Error creating image story: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } finally {
      isCreatingStory.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Create video story
  Future<bool> createVideoStory({
    required String videoPath,
    int duration = 15,
    String? caption,
  }) async {
    isCreatingStory.value = true;
    uploadProgress.value = 0.0;

    try {
      // Generate thumbnail first
      print('📸 [STORY] Generating video thumbnail...');
      final thumbnailPath = await VideoThumbnailGenerator.generateThumbnail(
        videoPath,
        timeMs: 0, // Get first frame
      );

      if (thumbnailPath != null) {
        print('✅ [STORY] Thumbnail generated: $thumbnailPath');
      } else {
        print('⚠️ [STORY] Failed to generate thumbnail, proceeding without it');
      }

      final story = await _storyService.createVideoStory(
        videoPath: videoPath,
        duration: duration,
        caption: caption,
        thumbnailPath: thumbnailPath,
        onUploadProgress: (sent, total) {
          uploadProgress.value = sent / total;
        },
      );

      // Add to my stories
      myStories.insert(0, story);

      // Refresh feed to get updated preview
      await loadStoriesFeed(refresh: true);

      Get.snackbar(
        'Succès',
        'Story vidéo créée avec succès !',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      print('❌ Error creating video story: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } finally {
      isCreatingStory.value = false;
      uploadProgress.value = 0.0;
    }
  }

  /// Delete story
  Future<void> deleteStory(int storyId) async {
    try {
      await _storyService.deleteStory(storyId);

      // Remove from my stories
      myStories.removeWhere((story) => story.id == storyId);

      // Find current index before removing
      final deletedIndex = currentUserStories.indexWhere((story) => story.id == storyId);

      // Remove from current user stories
      currentUserStories.removeWhere((story) => story.id == storyId);

      // Adjust current story index if needed
      if (deletedIndex != -1 && currentUserStories.isNotEmpty) {
        // If we deleted the current or a previous story, adjust index
        if (currentStoryIndex.value >= currentUserStories.length) {
          currentStoryIndex.value = currentUserStories.length - 1;
        } else if (deletedIndex <= currentStoryIndex.value && currentStoryIndex.value > 0) {
          currentStoryIndex.value--;
        }
      } else if (currentUserStories.isEmpty) {
        currentStoryIndex.value = 0;
      }

      // Reload myStories from server to get fresh data
      await loadMyStories();

      // Refresh feed to update story preview
      await loadStoriesFeed(refresh: true);

      Get.snackbar(
        'Succès',
        'Story supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Error deleting story: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Mark story as viewed
  Future<void> markStoryAsViewed(int storyId) async {
    // Ne pas marquer comme vue si c'est notre propre story
    final story = currentUserStories.firstWhereOrNull((s) => s.id == storyId);
    if (story != null && story.isOwner) {
      print('⏭️ [STORY] Ne pas marquer comme vue - c\'est notre propre story');
      return;
    }

    try {
      await _storyService.markStoryAsViewed(storyId);

      // Update viewed status in current stories
      final storyIndex = currentUserStories.indexWhere((s) => s.id == storyId);
      if (storyIndex != -1) {
        // Create a new instance with updated isViewed flag
        final story = currentUserStories[storyIndex];
        final updatedStory = StoryModel(
          id: story.id,
          user: story.user,
          isAnonymous: story.isAnonymous,
          isOwner: story.isOwner,
          canReveal: story.canReveal,
          type: story.type,
          mediaUrl: story.mediaUrl,
          content: story.content,
          thumbnailUrl: story.thumbnailUrl,
          backgroundColor: story.backgroundColor,
          duration: story.duration,
          viewsCount: story.viewsCount,
          status: story.status,
          isExpired: story.isExpired,
          isActive: story.isActive,
          timeRemaining: story.timeRemaining,
          expiresAt: story.expiresAt,
          createdAt: story.createdAt,
          isViewed: true, // Mark as viewed
          viewers: story.viewers,
          viewersCount: story.viewersCount,
          hasViewerSubscription: story.hasViewerSubscription,
        );

        currentUserStories[storyIndex] = updatedStory;
        currentUserStories.refresh();

        // Reload feed to update story status (viewed/unviewed) immediately
        print('✅ [STORY] Story vue, rechargement du feed pour mise à jour...');
        await loadStoriesFeed(refresh: true);
      }
    } catch (e) {
      print('❌ Error marking story as viewed: $e');
      // Silently fail for view tracking
    }
  }

  /// Reply to a story
  Future<int?> replyToStory(int storyId, String message) async {
    try {
      final result = await _storyService.replyToStory(storyId, message);

      Get.snackbar(
        'Succès',
        'Réponse envoyée',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Retourner l'ID de la conversation pour redirection
      return result['conversation_id'] as int?;
    } catch (e) {
      print('❌ Error replying to story: $e');

      Get.snackbar(
        'Erreur',
        _getErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );

      return null;
    }
  }

  /// Go to next story in current user stories
  void nextStory() {
    if (currentStoryIndex.value < currentUserStories.length - 1) {
      currentStoryIndex.value++;
    } else {
      // Move to next user's stories
      Get.back();
    }
  }

  /// Go to previous story in current user stories
  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
    }
  }

  /// Load stories stats
  Future<void> loadStats() async {
    try {
      final result = await _storyService.getStoriesStats();
      stats.value = result;
    } catch (e) {
      print('❌ Error loading stats: $e');
    }
  }

  /// Get story viewers
  Future<Map<String, dynamic>?> getStoryViewers(int storyId) async {
    try {
      final result = await _storyService.getStoryViewers(storyId);
      return result;
    } catch (e) {
      print('❌ Error loading story viewers: $e');
      return null;
    }
  }

  /// Refresh all stories
  Future<void> refreshAll() async {
    await Future.wait([
      loadStoriesFeed(refresh: true),
      loadMyStories(),
    ]);
  }

  /// Helper to get error message from exception
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('Pas de connexion Internet') || errorStr.contains('SocketException')) {
      return 'Pas de connexion Internet';
    } else if (errorStr.contains('Délai') || errorStr.contains('TimeoutException')) {
      return 'Délai d\'attente dépassé';
    } else if (errorStr.contains('404')) {
      return 'Story non trouvée';
    } else if (errorStr.contains('401') || errorStr.contains('403')) {
      return 'Non autorisé';
    } else if (errorStr.contains('500')) {
      return 'Erreur serveur';
    } else {
      return 'Une erreur est survenue';
    }
  }

  /// Check if there are new stories to view
  bool get hasNewStories {
    return storiesFeed.any((item) => item.hasNew);
  }

  /// Get count of new stories
  int get newStoriesCount {
    return storiesFeed.where((item) => item.hasNew).length;
  }

  /// Get current story being viewed
  StoryModel? get currentStory {
    if (currentUserStories.isEmpty) return null;
    if (currentStoryIndex.value >= currentUserStories.length) return null;
    return currentUserStories[currentStoryIndex.value];
  }
}
