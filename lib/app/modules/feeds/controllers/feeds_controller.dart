import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:weylo/app/data/services/confession_service.dart';
import 'package:weylo/app/data/services/cache_service.dart';
import 'package:weylo/app/data/models/confession_model.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/modules/feeds/views/widgets/comments_bottom_sheet.dart';
import 'package:weylo/app/routes/app_pages.dart';

enum ConfessionFilter { all, popular, recent }

class ConfessionsController extends GetxController {
  final _confessionService = ConfessionService();
  final _cache = CacheService();

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
    // Nettoyer les caches expirés au démarrage
    _cache.cleanExpiredCaches();

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

  /// Load confessions from API with smart caching persistant
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
        // Premier chargement: vérifier d'abord le cache
        isLoading.value = true;

        // Essayer de charger depuis le cache persistant
        final cachedConfessions = _cache.getConfessionsCache();
        if (cachedConfessions != null && _cache.isConfessionsCacheValid()) {
          print('📦 [CONFESSION] Utilisation du cache (${cachedConfessions.length} confessions)');

          // Charger depuis le cache
          for (final confession in cachedConfessions) {
            _confessionCache[confession.id] = confession;
          }
          confessions.value = cachedConfessions;

          // Récupérer la page actuelle du cache
          currentPage = _cache.getConfessionsCachedPage() + 1;

          // Apply current filter
          _applyFilter();

          isLoading.value = false;

          // Charger en arrière-plan pour refresh silencieux
          _silentRefreshConfessions();
          return;
        }
      } else {
        // Chargement de plus (pagination)
        isLoadingMore.value = true;
      }

      final response = await _confessionService.getConfessions(
        page: currentPage,
        perPage: 10,
      );

      if (refresh) {
        // Pull-to-refresh: remplacer les données SANS vider la liste d'abord
        // (évite le flash visuel désagréable)
        _confessionCache.clear();

        // Ajouter toutes les confessions au cache
        for (final confession in response.confessions) {
          _confessionCache[confession.id] = confession;
        }

        // Remplacer la liste directement (pas de .clear() avant)
        confessions.value = List.from(response.confessions);

        // Sauvegarder dans le cache persistant
        await _cache.saveConfessionsCache(response.confessions, page: 1);
        currentPage = 2; // Prochaine page sera 2
      } else if (confessions.isEmpty) {
        // Premier chargement: remplacer tout
        for (final confession in response.confessions) {
          _confessionCache[confession.id] = confession;
        }
        confessions.value = response.confessions;

        // Sauvegarder dans le cache persistant
        await _cache.saveConfessionsCache(response.confessions, page: 1);
        currentPage = 2; // Prochaine page sera 2
      } else {
        // Pagination: ajouter seulement les nouvelles à la fin
        final newConfessions = <ConfessionModel>[];
        for (final confession in response.confessions) {
          if (!_confessionCache.containsKey(confession.id)) {
            _confessionCache[confession.id] = confession;
            newConfessions.add(confession);
          }
        }
        confessions.addAll(newConfessions);

        // Mettre à jour le cache persistant avec toutes les confessions
        await _cache.saveConfessionsCache(confessions.toList(), page: currentPage);
        currentPage++;
      }

      hasMorePages = response.meta.hasMorePages;

      // Apply current filter
      _applyFilter();

      // Nettoyer les GlobalKeys après chargement
      _cleanupOldKeys();
    } catch (e) {
      // En cas d'erreur, essayer le cache même si expiré
      if (confessions.isEmpty) {
        final cachedConfessions = _cache.getConfessionsCache();
        if (cachedConfessions != null && cachedConfessions.isNotEmpty) {
          print('⚠️ [CONFESSION] Erreur serveur, utilisation du cache expiré');
          for (final confession in cachedConfessions) {
            _confessionCache[confession.id] = confession;
          }
          confessions.value = cachedConfessions;
          currentPage = _cache.getConfessionsCachedPage() + 1;
          _applyFilter();
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les confessions',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppThemeSystem.errorColor,
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de charger plus de confessions',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppThemeSystem.errorColor,
          colorText: Colors.white,
        );
      }
      print('Error loading confessions: $e');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      isRefreshing.value = false;
    }
  }

  /// Refresh silencieux en arrière-plan pour mettre à jour le cache
  Future<void> _silentRefreshConfessions() async {
    try {
      print('🔄 [CONFESSION] Refresh silencieux en arrière-plan');
      final response = await _confessionService.getConfessions(
        page: 1,
        perPage: 10,
      );

      // Mettre à jour le cache persistant
      await _cache.saveConfessionsCache(response.confessions, page: 1);
      print('✅ [CONFESSION] Cache mis à jour en arrière-plan');
    } catch (e) {
      print('⚠️ [CONFESSION] Erreur lors du refresh silencieux: $e');
      // Silencieux: pas de notification à l'utilisateur
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
