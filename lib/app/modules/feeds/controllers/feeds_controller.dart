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
    // Simulate loading stories
    stories.value = List.generate(15, (index) => {
      'id': index,
      'username': 'User ${index + 1}',
      'image': null, // You can add image URLs here
      'isViewed': index % 4 == 0,
      'timestamp': DateTime.now().subtract(Duration(hours: index)),
    });
  }

  void _loadFeedItems() {
    // Simulate loading feed items (mix of posts and ads)
    final posts = List.generate(25, (index) {
      final hasImage = index % 3 == 0;
      final isAnonymous = index % 4 == 0;

      return {
        'id': index,
        'type': 'post',
        'username': 'User ${index + 1}',
        'isAnonymous': isAnonymous,
        'isVerified': index % 5 == 0 && !isAnonymous,
        'content': _generatePostContent(index),
        'image': hasImage ? null : null, // Add image URLs if needed
        'reactions': (index + 1) * 12,
        'comments': (index + 1) * 8,
        'shares': (index + 1) * 3,
        'timestamp': DateTime.now().subtract(Duration(hours: index, minutes: index * 15)),
      };
    });

    feedItems.value = posts;
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

  String _generatePostContent(int index) {
    final contents = [
      'Quelle belle journée pour partager des moments avec la communauté! 🌟',
      'Je viens de découvrir cette application et c\'est incroyable! Merci à tous pour l\'accueil chaleureux.',
      'Quelqu\'un aurait des recommandations pour un bon restaurant dans le coin?',
      'Partage de mon expérience aujourd\'hui, c\'était vraiment enrichissant!',
      'À la recherche de nouvelles connexions et d\'échanges intéressants.',
      'Cette plateforme est vraiment géniale pour rester connecté!',
      'Merci pour tous vos messages de soutien, vous êtes les meilleurs!',
      'Nouveau défi relevé aujourd\'hui! Qui est partant pour le suivant?',
      'Belle soirée à tous! N\'oubliez pas de profiter de chaque instant.',
      'Inspiré par toutes ces belles histoires partagées ici!',
    ];

    return contents[index % contents.length];
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
