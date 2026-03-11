import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/modules/feeds/views/widgets/comments_bottom_sheet.dart';
import 'package:weylo/app/routes/app_pages.dart';
import 'story_controller.dart';

enum ConfessionFilter { all, popular, recent }

class ConfessionsController extends GetxController {
  final _confessionService = ConfessionService();

  // Scroll controller for scroll to top functionality
  final scrollController = ScrollController();

  // GlobalKeys for each confession to enable precise scrolling
  final confessionKeys = <int, GlobalKey>{}; // Map confession ID to GlobalKey

  // Currently highlighted confession (for visual feedback)
  final highlightedConfessionId = Rxn<int>();

  // Filter selection
  final selectedFilter = ConfessionFilter.all.obs;

  // Stories data
  final stories = <Map<String, dynamic>>[].obs;

  // Confessions data
  final confessions = <ConfessionModel>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isRefreshing = false.obs;

  // Pagination (gérée par le backend)
  int currentPage = 1;
  bool hasMorePages = true;

  // Cache mémoire (pour éviter les doublons dans la même session)
  final _confessionCache = <int, ConfessionModel>{}; // Cache par ID

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
        'avatarUrl': confession.authorAvatarUrl,
        'initial': confession.isIdentityRevealed && confession.author != null
            ? confession.author!.initial
            : confession.authorInitial,
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

  /// Vérifier la santé du scroll controller
  bool _isScrollControllerHealthy() {
    try {
      return scrollController.hasClients &&
             scrollController.position.hasContentDimensions &&
             scrollController.position.hasPixels;
    } catch (e) {
      print('⚠️ [SCROLL] ScrollController en mauvais état: $e');
      return false;
    }
  }

  /// Réinitialiser le scroll si nécessaire
  void _ensureScrollHealthy() {
    if (!_isScrollControllerHealthy() && scrollController.hasClients) {
      try {
        // Forcer une petite animation pour réinitialiser le scroll
        scrollController.jumpTo(scrollController.offset);
      } catch (e) {
        print('⚠️ [SCROLL] Impossible de réinitialiser le scroll: $e');
      }
    }
  }

  /// Méthode publique pour vérifier et réparer le scroll (appelée par HomeController)
  void ensureScrollHealthy() {
    print('🔧 [SCROLL] Vérification de la santé du scroll demandée');

    // Attendre que le widget soit complètement rendu
    Future.delayed(const Duration(milliseconds: 150), () {
      try {
        if (scrollController.hasClients) {
          final currentPosition = scrollController.offset;
          final maxScroll = scrollController.position.maxScrollExtent;
          final minScroll = scrollController.position.minScrollExtent;

          // Vérifier si la position est dans les limites valides
          if (currentPosition < minScroll || currentPosition > maxScroll) {
            print('⚠️ [SCROLL] Position invalide ($currentPosition), limites: [$minScroll, $maxScroll]');
            // Réinitialiser au début si hors limites
            scrollController.jumpTo(0);
            print('✅ [SCROLL] Scroll réinitialisé à 0');
          } else {
            // Position valide, juste "réveiller" le scroll
            scrollController.jumpTo(currentPosition);
            print('✅ [SCROLL] Scroll réveillé à la position $currentPosition');
          }
        } else {
          print('⚠️ [SCROLL] ScrollController n\'a pas de clients');
        }
      } catch (e) {
        print('⚠️ [SCROLL] Erreur lors du réveil: $e');
        // Essayer de réinitialiser à 0 en cas d'erreur
        try {
          if (scrollController.hasClients) {
            scrollController.jumpTo(0);
            print('✅ [SCROLL] Scroll réinitialisé à 0 après erreur');
          }
        } catch (e2) {
          print('❌ [SCROLL] Impossible de réinitialiser: $e2');
        }
      }

      _ensureScrollHealthy();
      _cleanupOldKeys();
    });
  }

  /// Nettoyer les GlobalKeys des confessions qui ne sont plus visibles
  void _cleanupOldKeys() {
    final currentConfessionIds = confessions.map((c) => c.id).toSet();
    final keysToRemove = <int>[];

    for (final id in confessionKeys.keys) {
      if (!currentConfessionIds.contains(id)) {
        keysToRemove.add(id);
      }
    }

    for (final id in keysToRemove) {
      confessionKeys.remove(id);
    }

    if (keysToRemove.isNotEmpty) {
      print('🧹 [CONFESSION] Nettoyage de ${keysToRemove.length} GlobalKeys inutilisées');
    }
  }

  /// Scroll to top of the feed with smooth animation
  /// Rafraîchit aussi les stories et le feed
  void scrollToTop() {
    // Vérifier et nettoyer avant de scroller
    _ensureScrollHealthy();
    _cleanupOldKeys();

    if (scrollController.hasClients) {
      try {
        scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        print('⚠️ [SCROLL] Erreur lors du scroll vers le haut: $e');
        // Essayer un jump en dernier recours
        try {
          scrollController.jumpTo(0);
        } catch (e2) {
          print('❌ [SCROLL] Impossible de scroller: $e2');
        }
      }
    }

    // Rafraîchir les stories ET le feed quand on clique sur l'icône Confession
    print('🔄 [REFRESH] Rafraîchissement des stories et du feed via scroll to top');
    _loadStories();
    loadConfessions(refresh: true);
  }

  /// Get or create GlobalKey for a confession
  GlobalKey getConfessionKey(int confessionId) {
    if (!confessionKeys.containsKey(confessionId)) {
      confessionKeys[confessionId] = GlobalKey();
    }
    return confessionKeys[confessionId]!;
  }

  /// Navigate to a specific confession detail page
  /// Returns true if navigation was successful
  Future<bool> navigateToConfession(int confessionId, {double? screenHeight}) async {
    try {
      print('🎯 [CONFESSION] Navigation vers la page de détail de la confession $confessionId');

      // Naviguer vers la page de détail et attendre le retour
      await Get.toNamed(
        Routes.CONFESSION_DETAIL.replaceAll(':id', confessionId.toString()),
      );

      // Quand on revient, vérifier le scroll
      print('↩️ [CONFESSION] Retour de la page de détail');

      // Attendre un frame pour que la UI se stabilise
      await Future.delayed(const Duration(milliseconds: 100));

      // Vérifier et réparer le scroll si nécessaire
      _ensureScrollHealthy();
      _cleanupOldKeys();

      return true;
    } catch (e) {
      print('❌ [CONFESSION] Erreur lors de la navigation: $e');
      return false;
    }
  }

  /// Legacy method: Scroll to a specific confession in the feed
  /// (kept for backward compatibility)
  Future<void> scrollToConfession(int confessionId) async {
    final found = await navigateToConfession(confessionId);

    if (!found) {
      Get.snackbar(
        'Confession introuvable',
        'Cette confession n\'est plus disponible dans le feed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppThemeSystem.warningColor,
        colorText: Colors.white,
      );
    }
  }


  void setFilter(ConfessionFilter filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  /// Load confessions from API (pagination simple)
  Future<void> loadConfessions({bool refresh = false}) async {
    // Prevent multiple simultaneous loads
    if (isLoading.value || isLoadingMore.value || isRefreshing.value) return;
    if (!hasMorePages && !refresh) return;

    try {
      if (refresh) {
        isRefreshing.value = true;
        currentPage = 1;
        hasMorePages = true;
      } else if (confessions.isEmpty) {
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      final response = await _confessionService.getConfessions(
        page: currentPage,
        perPage: 10,
      );

      if (refresh) {
        // Pull-to-refresh: remplacer les données
        _confessionCache.clear();

        for (final confession in response.confessions) {
          _confessionCache[confession.id] = confession;
        }

        confessions.value = List.from(response.confessions);
        currentPage = 2;
      } else if (confessions.isEmpty) {
        // Premier chargement
        for (final confession in response.confessions) {
          _confessionCache[confession.id] = confession;
        }
        confessions.value = response.confessions;
        currentPage = 2;
      } else {
        // Pagination: ajouter les nouvelles
        final newConfessions = <ConfessionModel>[];
        for (final confession in response.confessions) {
          if (!_confessionCache.containsKey(confession.id)) {
            _confessionCache[confession.id] = confession;
            newConfessions.add(confession);
          }
        }
        confessions.addAll(newConfessions);
        currentPage++;
      }

      hasMorePages = response.meta.hasMorePages;

      // Apply current filter
      _applyFilter();

      // Nettoyer les GlobalKeys après chargement
      _cleanupOldKeys();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        confessions.isEmpty
          ? 'Impossible de charger les confessions'
          : 'Impossible de charger plus de confessions',
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
    try {
      // Délai minimum pour une meilleure UX (évite que le spinner disparaisse trop vite)
      await Future.wait([
        loadConfessions(refresh: true),
        Future.delayed(const Duration(milliseconds: 500)), // Délai minimum
      ]);

      _loadStories();

      // Feedback visuel de succès (subtil, pas intrusif)
      // Ne pas afficher de snackbar car le RefreshIndicator suffit
    } catch (e) {
      // L'erreur est déjà gérée dans loadConfessions
      print('Error refreshing feed: $e');
    }
  }

  void _loadStories() {
    try {
      // Obtenir le StoryController et rafraîchir les stories
      final storyController = Get.find<StoryController>();
      storyController.loadStoriesFeed(refresh: true);
      print('✅ [STORIES] Stories rafraîchies');
    } catch (e) {
      print('⚠️ [STORIES] Erreur lors du rafraîchissement des stories: $e');
      // Silencieux: pas de notification à l'utilisateur
    }
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
      if (index == -1) {
        print('⚠️ [LIKE] Confession ID $confessionId not found in list');
        return;
      }

      final confession = confessions[index];
      print('🎯 [LIKE] Toggling like for confession $confessionId, current likes: ${confession.likesCount}, isLiked: ${confession.isLiked}');

      if (confession.isLiked) {
        // Unlike
        print('👎 [LIKE] Unliking confession $confessionId');
        final result = await _confessionService.unlikeConfession(confessionId);
        print('✅ [LIKE] Unlike response: $result');

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
          likesCount: result['likes_count'] as int,
          viewsCount: confession.viewsCount,
          commentsCount: confession.commentsCount,
          isLiked: result['is_liked'] as bool,
          createdAt: confession.createdAt,
        );

        print('📊 [LIKE] Updated confession likes_count: ${confessions[index].likesCount}');
      } else {
        // Like
        print('👍 [LIKE] Liking confession $confessionId');
        final result = await _confessionService.likeConfession(confessionId);
        print('✅ [LIKE] Like response: $result');

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
          likesCount: result['likes_count'] as int,
          viewsCount: confession.viewsCount,
          commentsCount: confession.commentsCount,
          isLiked: result['is_liked'] as bool,
          createdAt: confession.createdAt,
        );

        print('📊 [LIKE] Updated confession likes_count: ${confessions[index].likesCount}');
      }

      // Mettre à jour le cache mémoire
      _confessionCache[confessionId] = confessions[index];

      confessions.refresh();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de liker la confession',
        snackPosition: SnackPosition.BOTTOM,
      );
      print('❌ [LIKE] Error toggling like: $e');
    }
  }

  /// Open comments for a confession
  Future<void> commentPost(int id) async {
    final confession = confessions.firstWhereOrNull((c) => c.id == id);
    if (confession == null) {
      // Si la confession n'est pas dans la liste actuelle, essayer de la charger depuis le service
      print('⚠️ [CONFESSION] Confession ID $id non trouvée dans la liste locale, tentative de chargement...');
      try {
        // Charger les confessions si la liste est vide
        if (confessions.isEmpty) {
          await loadConfessions();
        }

        // Réessayer de trouver la confession
        final confessionRetry = confessions.firstWhereOrNull((c) => c.id == id);
        if (confessionRetry == null) {
          print('❌ [CONFESSION] Confession ID $id introuvable même après chargement');
          Get.snackbar(
            'Confession introuvable',
            'Cette confession n\'est plus disponible',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        // Ouvrir les commentaires avec la confession trouvée
        await _openCommentsSheet(confessionRetry);
      } catch (e) {
        print('❌ [CONFESSION] Erreur lors du chargement de la confession: $e');
        Get.snackbar(
          'Erreur',
          'Impossible de charger la confession',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    // Ouvrir les commentaires
    await _openCommentsSheet(confession);
  }

  /// Helper to open comments bottom sheet
  Future<void> _openCommentsSheet(ConfessionModel confession) async {
    // Ouvrir le bottomsheet des commentaires et attendre les counts mis à jour
    final result = await Get.bottomSheet<Map<String, int>>(
      CommentsBottomSheet(confession: confession),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );

    // Mettre à jour les counts si on a un résultat
    if (result != null) {
      final index = confessions.indexWhere((c) => c.id == confession.id);
      if (index != -1) {
        confessions[index] = confessions[index].copyWith(
          likesCount: result['likesCount'],
          commentsCount: result['commentsCount'],
        );
        confessions.refresh();
      }
    }
  }

  /// Share a confession
  Future<void> sharePost(int id) async {
    try {
      final confession = confessions.firstWhereOrNull((c) => c.id == id);
      if (confession == null) return;

      // Construire le message de partage
      String shareText = confession.content;

      if (confession.isIdentityRevealed) {
        shareText += '\n\n- ${confession.authorName}';
      } else {
        shareText += '\n\n- Confession anonyme';
      }

      shareText += '\n\nPartagé depuis Weylo';

      // Partager via le plugin share_plus
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Confession de ${confession.authorName}',
        ),
      );
    } catch (e) {
      print('Error sharing confession: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de partager la confession',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Legacy methods for backward compatibility
  void likePost(int id) => toggleLike(id);
  void likeConfession(int id) => toggleLike(id);
  void commentOnConfession(int id) => commentPost(id);
}
