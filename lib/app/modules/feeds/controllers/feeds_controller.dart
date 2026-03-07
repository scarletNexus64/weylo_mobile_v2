import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

enum ConfessionFilter { all, popular, recent }

class ConfessionsController extends GetxController {
  final _confessionService = ConfessionService();

  // Scroll controller for scroll to top functionality
  final scrollController = ScrollController();

  // Filter selection
  final selectedFilter = ConfessionFilter.all.obs;

  // Stories data
  final stories = <Map<String, dynamic>>[].obs;

  // Confessions data
  final confessions = <ConfessionModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;

  // Pagination
  int currentPage = 1;
  bool hasMorePages = true;

  // Cache
  final _confessionCache = <int, ConfessionModel>{}; // Cache par ID
  DateTime? _lastFetchTime;

  // Legacy feed items for backward compatibility
  RxList<Map<String, dynamic>> get feedItems {
    // Convert confessions to legacy format
    return confessions.map((confession) {
      return {
        'id': confession.id,
        'type': 'post',
        'username': confession.authorName,
        'isAnonymous': !confession.isIdentityRevealed,
        'isVerified': false,
        'content': confession.content,
        'image': confession.mediaType != 'none' ? confession.mediaUrl : null,
        'mediaType': confession.mediaType, // 'none', 'image', 'video'
        'mediaUrl': confession.mediaUrl,
        'reactions': confession.likesCount,
        'comments': confession.commentsCount,
        'shares': 0,
        'timestamp': confession.createdAt,
        'isLiked': confession.isLiked,
      };
    }).toList().obs;
  }

  @override
  void onInit() {
    super.onInit();
    _loadStories();
    loadConfessions();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// Scroll to top of the feed with smooth animation
  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }


  void setFilter(ConfessionFilter filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  /// Load confessions from API with smart caching
  Future<void> loadConfessions({bool refresh = false}) async {
    // Prevent multiple simultaneous loads
    if (isLoading.value || isLoadingMore.value || isRefreshing.value) return;
    if (!hasMorePages && !refresh) return;

    try {
      if (refresh) {
        // Pull-to-refresh: ne pas vider la liste, juste marquer qu'on rafraîchit
        isRefreshing.value = true;
        currentPage = 1;
        hasMorePages = true;
      } else if (confessions.isEmpty) {
        // Premier chargement
        isLoading.value = true;
      } else {
        // Chargement de plus (pagination)
        isLoadingMore.value = true;
      }

      final response = await _confessionService.getConfessions(
        page: currentPage,
        perPage: 10,
      );

      // Ajouter au cache et éviter les doublons
      final newConfessions = <ConfessionModel>[];
      for (final confession in response.confessions) {
        if (!_confessionCache.containsKey(confession.id)) {
          _confessionCache[confession.id] = confession;
          newConfessions.add(confession);
        }
      }

      if (refresh) {
        // Pull-to-refresh: ajouter les nouvelles au début
        if (newConfessions.isNotEmpty) {
          confessions.insertAll(0, newConfessions);

          Get.snackbar(
            'Actualisé',
            '${newConfessions.length} nouvelle(s) confession(s)',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
            backgroundColor: AppThemeSystem.successColor.withValues(alpha: 0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(8),
          );
        }
      } else if (confessions.isEmpty) {
        // Premier chargement: remplacer tout
        confessions.value = response.confessions;
      } else {
        // Pagination: ajouter à la fin
        confessions.addAll(newConfessions);
      }

      currentPage++;
      hasMorePages = response.meta.hasMorePages;
      _lastFetchTime = DateTime.now();

      // Apply current filter
      _applyFilter();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les confessions',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.errorColor,
        colorText: Colors.white,
      );
      print('Error loading confessions: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      isRefreshing.value = false;
    }
  }

  /// Refresh feed
  Future<void> refreshFeed() async {
    _loadStories();
    await loadConfessions(refresh: true);
  }

  void _loadStories() {
    // Load stories from API
    // TODO: Implement API call when story feed is ready
    stories.value = [];
  }

  void _applyFilter() {
    // Sort confessions based on selected filter
    final sortedList = List<ConfessionModel>.from(confessions);

    switch (selectedFilter.value) {
      case ConfessionFilter.all:
        // Default order (by creation date descending)
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ConfessionFilter.popular:
        // Sort by likes count
        sortedList.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case ConfessionFilter.recent:
        // Sort by creation date (most recent first)
        sortedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    confessions.value = sortedList;
  }

  /// Like or unlike a confession
  Future<void> toggleLike(int confessionId) async {
    try {
      final index = confessions.indexWhere((c) => c.id == confessionId);
      if (index == -1) return;

      final confession = confessions[index];

      if (confession.isLiked) {
        // Unlike
        final newCount = await _confessionService.unlikeConfession(confessionId);
        confessions[index] = ConfessionModel(
          id: confession.id,
          content: confession.content,
          type: confession.type,
          isPublic: confession.isPublic,
          isPrivate: confession.isPrivate,
          status: confession.status,
          isApproved: confession.isApproved,
          isPending: confession.isPending,
          mediaType: confession.mediaType,
          mediaUrl: confession.mediaUrl,
          authorInitial: confession.authorInitial,
          author: confession.author,
          isIdentityRevealed: confession.isIdentityRevealed,
          likesCount: newCount,
          viewsCount: confession.viewsCount,
          commentsCount: confession.commentsCount,
          isLiked: false,
          createdAt: confession.createdAt,
        );
      } else {
        // Like
        final newCount = await _confessionService.likeConfession(confessionId);
        confessions[index] = ConfessionModel(
          id: confession.id,
          content: confession.content,
          type: confession.type,
          isPublic: confession.isPublic,
          isPrivate: confession.isPrivate,
          status: confession.status,
          isApproved: confession.isApproved,
          isPending: confession.isPending,
          mediaType: confession.mediaType,
          mediaUrl: confession.mediaUrl,
          authorInitial: confession.authorInitial,
          author: confession.author,
          isIdentityRevealed: confession.isIdentityRevealed,
          likesCount: newCount,
          viewsCount: confession.viewsCount,
          commentsCount: confession.commentsCount,
          isLiked: true,
          createdAt: confession.createdAt,
        );
      }

      confessions.refresh();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de liker la confession',
        snackPosition: SnackPosition.BOTTOM,
      );
      print('Error toggling like: $e');
    }
  }

  /// Open comments for a confession
  void commentPost(int id) {
    // TODO: Navigate to comments page
    Get.snackbar(
      'Commenter',
      'Fonctionnalité de commentaire à venir',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Share a confession
  void sharePost(int id) {
    // TODO: Implement share functionality
    Get.snackbar(
      'Partagé',
      'Post partagé avec succès!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Legacy methods for backward compatibility
  void likePost(int id) => toggleLike(id);
  void likeConfession(int id) => toggleLike(id);
  void commentOnConfession(int id) => commentPost(id);
}
