import 'package:get/get.dart';

enum ConfessionFilter { all, popular, recent }

class ConfessionsController extends GetxController {
  // Filter selection
  final selectedFilter = ConfessionFilter.all.obs;

  // Stories data
  final stories = <Map<String, dynamic>>[].obs;

  // Feed items (posts + ads mixed)
  final feedItems = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadStories();
    _loadFeedItems();
  }


  void setFilter(ConfessionFilter filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  void refreshFeed() {
    _loadStories();
    _loadFeedItems();
  }

  void _loadStories() {
    // Load stories from API
    // TODO: Implement API call
    stories.value = [];
  }

  void _loadFeedItems() {
    // Load feed items from API
    // TODO: Implement API call
    feedItems.value = [];
  }

  void _applyFilter() {
    // Apply filter logic here
    switch (selectedFilter.value) {
      case ConfessionFilter.all:
        _loadFeedItems();
        break;
      case ConfessionFilter.popular:
        // Sort by reactions
        feedItems.sort((a, b) {
          final aReactions = a['reactions'] as int? ?? 0;
          final bReactions = b['reactions'] as int? ?? 0;
          return bReactions.compareTo(aReactions);
        });
        break;
      case ConfessionFilter.recent:
        // Sort by timestamp
        feedItems.sort((a, b) {
          final aTime = a['timestamp'] as DateTime;
          final bTime = b['timestamp'] as DateTime;
          return bTime.compareTo(aTime);
        });
        break;
    }
  }

  void likePost(int id) {
    final index = feedItems.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      final currentReactions = feedItems[index]['reactions'] as int;
      feedItems[index]['reactions'] = currentReactions + 1;
      feedItems.refresh();
    }
  }

  void commentPost(int id) {
    Get.snackbar(
      'Commenter',
      'Fonctionnalité de commentaire à venir',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void sharePost(int id) {
    final index = feedItems.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      final currentShares = feedItems[index]['shares'] as int;
      feedItems[index]['shares'] = currentShares + 1;
      feedItems.refresh();

      Get.snackbar(
        'Partagé',
        'Post partagé avec succès!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Legacy methods for backward compatibility
  void likeConfession(int id) => likePost(id);
  void commentOnConfession(int id) => commentPost(id);
}
