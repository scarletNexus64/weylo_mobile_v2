import 'package:get/get.dart';
import 'package:weylo/app/data/models/story_feed_item_model.dart';
import 'package:weylo/app/modules/feeds/controllers/story_controller.dart';

/// Model to represent story status for a conversation
class ConversationStoryStatus {
  final bool hasStories;
  final bool hasUnviewedStories;
  final int storiesCount;
  final DateTime? latestStoryAt;

  ConversationStoryStatus({
    required this.hasStories,
    required this.hasUnviewedStories,
    this.storiesCount = 0,
    this.latestStoryAt,
  });

  factory ConversationStoryStatus.noStories() {
    return ConversationStoryStatus(
      hasStories: false,
      hasUnviewedStories: false,
    );
  }

  factory ConversationStoryStatus.fromStoryFeedItem(StoryFeedItemModel item) {
    return ConversationStoryStatus(
      hasStories: true,
      hasUnviewedStories: item.hasNew,
      storiesCount: item.storiesCount,
      latestStoryAt: item.latestStoryAt,
    );
  }
}

/// Service to manage story status for conversations
/// Maps user IDs to their story status from the story feed
class ConversationStoryService extends GetxService {
  static ConversationStoryService get to => Get.find();

  // Story controller reference
  StoryController? _storyController;

  // Cache of story statuses by user ID
  final _storyStatusCache = <int, ConversationStoryStatus>{}.obs;

  // Trigger for reactive updates
  final _updateTrigger = 0.obs;

  @override
  void onInit() {
    super.onInit();
    print('🔄 [ConversationStoryService] Initializing...');

    // Try to get StoryController
    try {
      _storyController = Get.find<StoryController>();
      print('✅ [ConversationStoryService] StoryController found');

      // Listen to story feed updates
      ever(_storyController!.storiesFeed, (_) {
        _updateStoryStatusCache();
      });

      // Initial update
      _updateStoryStatusCache();
    } catch (e) {
      print('⚠️ [ConversationStoryService] StoryController not found yet: $e');
    }
  }

  /// Update story status cache from story feed
  void _updateStoryStatusCache() {
    if (_storyController == null) return;

    final storiesFeed = _storyController!.storiesFeed;
    print('🔄 [ConversationStoryService] Updating cache with ${storiesFeed.length} story feeds');

    // Clear old cache
    _storyStatusCache.clear();

    // Build new cache
    for (final item in storiesFeed) {
      _storyStatusCache[item.realUserId] = ConversationStoryStatus.fromStoryFeedItem(item);
    }

    // Trigger reactive update
    _updateTrigger.value++;

    print('✅ [ConversationStoryService] Cache updated: ${_storyStatusCache.length} users with stories');
  }

  /// Get story status for a user by ID
  ConversationStoryStatus getStoryStatus(int? userId) {
    // Access trigger to make this reactive
    _updateTrigger.value;
    if (userId == null) return ConversationStoryStatus.noStories();
    return _storyStatusCache[userId] ?? ConversationStoryStatus.noStories();
  }

  /// Check if user has stories
  bool hasStories(int? userId) {
    // Access trigger to make this reactive
    _updateTrigger.value;
    if (userId == null) return false;
    return _storyStatusCache.containsKey(userId);
  }

  /// Check if user has unviewed stories
  bool hasUnviewedStories(int? userId) {
    // Access trigger to make this reactive
    _updateTrigger.value;
    if (userId == null) return false;
    final status = _storyStatusCache[userId];
    return status?.hasUnviewedStories ?? false;
  }

  /// Manually refresh story status cache
  Future<void> refreshStoryStatus() async {
    if (_storyController == null) {
      // Try to get StoryController again
      try {
        _storyController = Get.find<StoryController>();
        print('✅ [ConversationStoryService] StoryController found on refresh');
      } catch (e) {
        print('⚠️ [ConversationStoryService] StoryController still not available');
        return;
      }
    }

    // Reload story feed from API
    await _storyController!.loadStoriesFeed(refresh: true);
    _updateStoryStatusCache();
  }

  /// Get all users with stories
  List<int> getUsersWithStories() {
    return _storyStatusCache.keys.toList();
  }

  /// Get count of users with unviewed stories
  int getUnviewedStoriesCount() {
    return _storyStatusCache.values.where((status) => status.hasUnviewedStories).length;
  }
}
