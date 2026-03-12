import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/feeds_controller.dart';
import 'widgets/stories_vertical_bar.dart';
import 'widgets/confession_shimmer_loader.dart';
import 'widgets/feed_video_player.dart';
import 'widgets/confession_actions_bottom_sheet.dart';
import 'widgets/sponsored_ads_carousel.dart';
import 'image_viewer_page.dart';

class ConfessionsView extends StatefulWidget {
  const ConfessionsView({super.key});

  @override
  State<ConfessionsView> createState() => _ConfessionsViewState();
}

class _ConfessionsViewState extends State<ConfessionsView>
    with AutomaticKeepAliveClientMixin<ConfessionsView> {

  @override
  bool get wantKeepAlive => true;

  ConfessionsController get controller => Get.find<ConfessionsController>();

  @override
  void initState() {
    super.initState();
    print('🎬 [FEEDS_VIEW] initState() - ConfessionsView initialisé');
    // S'assurer que le scroll est sain au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // Vérification silencieuse
          if (controller.scrollController.hasClients) {
            final offset = controller.scrollController.offset;
            print('✅ [FEEDS_VIEW] initState() - Scroll OK, offset: $offset');
          } else {
            print('⚠️ [FEEDS_VIEW] initState() - Scroll n\'a pas encore de clients');
          }
        } catch (e) {
          print('❌ [FEEDS_VIEW] initState() - Erreur: $e');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 [FEEDS_VIEW] didChangeDependencies() - Retour au tab Confessions');
    // Vérifier le scroll quand les dépendances changent (retour au tab)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        print('⚠️ [FEEDS_VIEW] Widget non monté, abandon');
        return;
      }

      // Vérifier immédiatement si le scroll est dans un état invalide
      if (controller.scrollController.hasClients) {
        try {
          final position = controller.scrollController.position;

          // Attendre que les dimensions soient disponibles
          if (!position.hasContentDimensions) {
            print('⏳ [FEEDS] En attente des dimensions du contenu...');
            // Réessayer après un court délai
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                _checkAndFixScroll();
              }
            });
            return;
          }

          _checkAndFixScroll();
        } catch (e) {
          print('⚠️ [FEEDS] Erreur lors de la vérification initiale du scroll: $e');
        }
      }

      // Puis vérifier la santé globale du scroll après un délai
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          controller.ensureScrollHealthy();
        }
      });
    });
  }

  /// Vérifier et corriger le scroll si nécessaire
  void _checkAndFixScroll() {
    if (!controller.scrollController.hasClients) return;

    try {
      final offset = controller.scrollController.offset;
      final position = controller.scrollController.position;
      final maxExtent = position.maxScrollExtent;
      final minExtent = position.minScrollExtent;

      // Toujours réinitialiser le scroll à 0 quand on revient au tab
      if (offset != 0) {
        print('🚨 [FEEDS] Scroll décalé détecté (offset: $offset, limites: [$minExtent, $maxExtent])');

        // Utiliser animateTo si le décalage est petit, sinon jumpTo
        if (offset < 100 && offset > 0) {
          print('🔄 [FEEDS] Animation douce vers le haut');
          controller.scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        } else {
          print('🔄 [FEEDS] Saut immédiat vers le haut');
          controller.scrollController.jumpTo(0);
        }
        print('✅ [FEEDS] Scroll réinitialisé à 0');
      } else {
        print('✅ [FEEDS] Scroll déjà à 0, tout est bon');
      }
    } catch (e) {
      print('⚠️ [FEEDS] Erreur lors de la vérification du scroll: $e');
      // En cas d'erreur, forcer la réinitialisation
      try {
        controller.scrollController.jumpTo(0);
        print('✅ [FEEDS] Scroll réinitialisé à 0 après erreur');
      } catch (e2) {
        print('❌ [FEEDS] Impossible de réinitialiser le scroll: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshFeed();
      },
      color: AppThemeSystem.primaryColor,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppThemeSystem.darkCardColor
          : Colors.white,
      displacement: 40.0, // Distance avant de déclencher le refresh
      strokeWidth: 2.5, // Épaisseur de l'indicateur
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Infinite scroll: détecter quand on arrive à 80% du scroll
          // Vérifier que les métriques sont valides avant de continuer
          if (!controller.isLoadingMore.value &&
              scrollInfo.metrics.hasContentDimensions &&
              scrollInfo.metrics.maxScrollExtent > 0 &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.8) {
            controller.loadConfessions();
          }
          return false;
        },
        child: CustomScrollView(
          key: const PageStorageKey<String>('confessions_scroll'),
          controller: controller.scrollController,
          primary: false, // IMPORTANT: Ne pas se coordonner avec NestedScrollView parent
          physics: const AlwaysScrollableScrollPhysics(),
          cacheExtent: 1000, // Précharger pour éviter les rebuilds
          slivers: [
            // Create Post Button
            SliverToBoxAdapter(
              child: _buildCreatePostButton(context),
            ),

            // Stories Vertical Bar (Facebook style)
            const SliverToBoxAdapter(
              child: StoriesVerticalBar(),
            ),

            // Feed Content
            Obx(() {
              // Premier chargement: afficher shimmer
              if (controller.isLoading.value && controller.confessions.isEmpty) {
                return SliverToBoxAdapter(
                  child: ConfessionShimmerLoader(itemCount: 3),
                );
              }

              // Aucune confession et pas de chargement: état vide
              if (controller.confessions.isEmpty && !controller.isLoading.value) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context),
                );
              }

              // Afficher les confessions
              const confessionsBetweenAds = 7;
              final hasAds = controller.sponsoredAds.isNotEmpty;
              final combinedCount = hasAds
                  ? (controller.confessions.length +
                      (controller.confessions.length ~/ confessionsBetweenAds))
                  : controller.feedItems.length;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    bool isAdSlot(int i) {
                      if (!hasAds) return false;
                      if (i <= 0) return false;
                      return i % (confessionsBetweenAds + 1) == confessionsBetweenAds;
                    }

                    if (isAdSlot(index)) {
                      final ads = controller.sponsoredAds;
                      const perCarousel = 5;
                      final slotNumber = index ~/ (confessionsBetweenAds + 1);
                      final start = ads.isEmpty ? 0 : (slotNumber * perCarousel) % ads.length;
                      final count = ads.length < perCarousel ? ads.length : perCarousel;
                      final adsForSlot = List.generate(count, (i) => ads[(start + i) % ads.length]);

                      return SponsoredAdsCarousel(
                        ads: adsForSlot,
                        onImpression: controller.trackAdImpression,
                      );
                    }

                    final adsBefore = hasAds ? (index ~/ (confessionsBetweenAds + 1)) : 0;
                    final confessionIndex = index - adsBefore;
                    final confession = controller.confessions[confessionIndex];
                    final item = controller.feedItems[confessionIndex];
                    final confessionKey = controller.getConfessionKey(confession.id);

                    return Obx(() {
                      final isHighlighted = controller.highlightedConfessionId.value == confession.id;

                      return Container(
                        key: confessionKey,
                        decoration: BoxDecoration(
                          border: isHighlighted
                              ? Border.all(
                                  color: AppThemeSystem.primaryColor,
                                  width: 3,
                                )
                              : null,
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: _buildPostCard(context, item),
                      );
                    });
                  },
                  childCount: combinedCount,
                ),
              );
            }),

            // Loader en bas pour la pagination
            Obx(() {
              if (controller.isLoadingMore.value) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(context.elementSpacing * 2),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppThemeSystem.primaryColor,
                      ),
                    ),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }),
          ],
        ),
      ),
    );
  }

  // Vertical Stories Section (Instagram/Facebook style)
  Widget _buildVerticalStoriesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    // Taille responsive des stories verticales
    double storyWidth;
    double storyHeight;
    switch (deviceType) {
      case DeviceType.mobile:
        storyWidth = 110;
        storyHeight = 180;
        break;
      case DeviceType.tablet:
        storyWidth = 140;
        storyHeight = 220;
        break;
      case DeviceType.largeTablet:
      case DeviceType.iPadPro13:
        storyWidth = 160;
        storyHeight = 260;
        break;
      case DeviceType.desktop:
        storyWidth = 180;
        storyHeight = 280;
        break;
    }

    return Container(
      height: storyHeight + 10,
      margin: EdgeInsets.only(
        top: context.elementSpacing * 0.8,
        bottom: context.elementSpacing * 0.5,
      ),
      child: Obx(() {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          itemCount: controller.stories.length + 1,
          itemBuilder: (context, index) {
            // First item: Create Story
            if (index == 0) {
              return _buildCreateStoryCard(context, storyWidth, storyHeight, isDark, deviceType);
            }

            // Regular stories
            final story = controller.stories[index - 1];
            return _buildStoryCard(context, story, storyWidth, storyHeight, isDark, deviceType);
          },
        );
      }),
    );
  }

  Widget _buildCreateStoryCard(BuildContext context, double width, double height, bool isDark, DeviceType deviceType) {
    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(right: context.elementSpacing),
      child: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  AppThemeSystem.secondaryColor.withValues(alpha: 0.3),
                ],
              ),
              border: Border.all(
                color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                size: deviceType == DeviceType.mobile ? 50 : 60,
                color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
              ),
            ),
          ),
          // Add Button
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: AppThemeSystem.primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeSystem.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: deviceType == DeviceType.mobile ? 20 : 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, Map<String, dynamic> story, double width, double height, bool isDark, DeviceType deviceType) {
    final isViewed = story['isViewed'] as bool;

    return Container(
      width: width,
      height: height,
      margin: EdgeInsets.only(right: context.elementSpacing),
      child: Stack(
        children: [
          // Story Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isViewed
                    ? (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300)
                    : AppThemeSystem.primaryColor,
                width: isViewed ? 1.5 : 3,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
                stops: const [0.4, 1.0],
              ),
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: story['image'] != null
                  ? Image.network(
                      story['image'] as String,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        // Shimmer pendant le chargement
                        return Shimmer.fromColors(
                          baseColor: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
                          highlightColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey200,
                          child: Container(
                            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              size: 40,
                              color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.image_rounded,
                        size: 40,
                        color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
                      ),
                    ),
            ),
          ),
          // Profile Picture
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: deviceType == DeviceType.mobile ? 36 : 42,
              height: deviceType == DeviceType.mobile ? 36 : 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isViewed ? AppThemeSystem.grey500 : AppThemeSystem.primaryColor,
                  width: 2.5,
                ),
                color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
              ),
              child: Icon(
                Icons.person_rounded,
                size: deviceType == DeviceType.mobile ? 18 : 22,
                color: Colors.white,
              ),
            ),
          ),
          // Username
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Text(
              story['username'] as String,
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.elementSpacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: deviceType == DeviceType.mobile ? 80 : 100,
              color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
            ),
            SizedBox(height: context.elementSpacing * 1.5),
            Text(
              'Aucune confession',
              style: context.textStyle(FontSizeType.h5).copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
              ),
            ),
            SizedBox(height: context.elementSpacing * 0.5),
            Text(
              'Soyez le premier à partager une confession',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.elementSpacing * 2),
            ElevatedButton.icon(
              onPressed: () {
                Get.toNamed('/create-confession');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemeSystem.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing * 2,
                  vertical: context.elementSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppThemeSystem.getBorderRadius(context, BorderRadiusType.medium),
                  ),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Créer une confession',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Create Post Button
  Widget _buildCreatePostButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      margin: EdgeInsets.only(
        bottom: context.elementSpacing * 0.5,
      ),
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: deviceType == DeviceType.mobile ? 40 : 48,
            height: deviceType == DeviceType.mobile ? 40 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.primaryColor,
                  AppThemeSystem.secondaryColor,
                ],
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: deviceType == DeviceType.mobile ? 20 : 24,
            ),
          ),
          SizedBox(width: context.elementSpacing),
          // Input placeholder
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.toNamed('/create-confession');
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.elementSpacing,
                  vertical: context.elementSpacing * 0.8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.5)
                      : AppThemeSystem.grey100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Quoi de neuf ?',
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: context.elementSpacing),
          // Photo button
          GestureDetector(
            onTap: () {
              Get.toNamed('/create-confession');
            },
            child: Container(
              padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 8 : 10),
              decoration: BoxDecoration(
                color: AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.image_outlined,
                color: AppThemeSystem.primaryColor,
                size: deviceType == DeviceType.mobile ? 20 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Post Card
  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;
    final isAnonymous = post['isAnonymous'] as bool;
    final hasMedia = post['mediaType'] != null && post['mediaType'] != 'none';
    final mediaType = post['mediaType'] as String?;
    final mediaUrl = post['mediaUrl'] as String?;

    // Find the corresponding ConfessionModel from controller
    final confession = controller.confessions.firstWhereOrNull(
      (c) => c.id == post['id'],
    );

    return Container(
      margin: EdgeInsets.only(
        bottom: context.elementSpacing * 1.2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
          bottom: BorderSide(
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: deviceType == DeviceType.mobile ? 22 : 26,
                  backgroundColor: isAnonymous
                      ? AppThemeSystem.grey700
                      : AppThemeSystem.primaryColor,
                  backgroundImage: !isAnonymous && post['avatarUrl'] != null
                      ? NetworkImage('${post['avatarUrl']}?t=${DateTime.now().millisecondsSinceEpoch}')
                      : null,
                  child: isAnonymous
                      ? Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: deviceType == DeviceType.mobile ? 22 : 26,
                        )
                      : (post['avatarUrl'] == null
                          ? Text(
                              (post['initial'] as String?)?.isNotEmpty == true
                                  ? (post['initial'] as String).toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: deviceType == DeviceType.mobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null),
                ),
                SizedBox(width: context.elementSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAnonymous ? 'Anonyme' : post['username'] as String,
                            style: context.textStyle(FontSizeType.body1).copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppThemeSystem.blackColor,
                            ),
                          ),
                          if (post['isVerified'] == true) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppThemeSystem.primaryColor,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getTimeAgo(post['timestamp'] as DateTime),
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  ),
                  onPressed: () {
                    if (confession != null) {
                      _showPostActions(context, confession);
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Media (Image or Video) - Afficher en premier
          if (hasMedia && mediaUrl != null)
            Padding(
              padding: EdgeInsets.only(top: context.elementSpacing * 0.8),
              child: mediaType == 'image'
                  ? GestureDetector(
                      onTap: () {
                        Get.to(
                          () => ImageViewerPage(
                            imageUrl: mediaUrl,
                            content: post['content'] as String,
                          ),
                          transition: Transition.fadeIn,
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: Image.network(
                          mediaUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              // Image chargée, afficher l'image avec une animation de fondu
                              return child;
                            }
                            // Image en cours de chargement, afficher le shimmer
                            return Shimmer.fromColors(
                              baseColor: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                              highlightColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey100,
                              child: Container(
                                width: double.infinity,
                                height: 320,
                                color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 320,
                              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
                              child: Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 60,
                                  color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : FeedVideoPlayer(
                      videoUrl: mediaUrl,
                      videoId: post['id'].toString(),
                    ),
            ),

          // Content - Afficher après le média
          if (post['content'] != null && (post['content'] as String).isNotEmpty)
            Padding(
              padding: EdgeInsets.all(context.elementSpacing),
              child: Text(
                post['content'] as String,
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: isDark ? AppThemeSystem.grey200 : AppThemeSystem.grey900,
                  height: 1.5,
                ),
              ),
            ),

          // Reactions Summary
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                // Reactions count - Toujours afficher, même si 0
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppThemeSystem.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post['reactions'] ?? 0}',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Comments count
                Text(
                  '${post['comments'] ?? 0} commentaires',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.elementSpacing * 0.5,
              vertical: context.elementSpacing * 0.5,
            ),
            child: Row(
              children: [
                _buildLikeButton(
                  context: context,
                  post: post,
                  isDark: isDark,
                ),
                _buildPostActionButton(
                  context: context,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Commenter',
                  onTap: () => controller.commentPost(post['id'] as int),
                  isDark: isDark,
                ),
                _buildPostActionButton(
                  context: context,
                  icon: Icons.share_outlined,
                  label: 'Partager',
                  onTap: () => controller.sharePost(post['id'] as int),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton({
    required BuildContext context,
    required Map<String, dynamic> post,
    required bool isDark,
  }) {
    final isLiked = post['isLiked'] as bool;

    return Expanded(
      child: InkWell(
        onTap: () => controller.likePost(post['id'] as int),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(isLiked),
                  size: 20,
                  color: isLiked
                      ? AppThemeSystem.errorColor
                      : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'J\'aime',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isLiked
                      ? AppThemeSystem.errorColor
                      : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}sem';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  void _showPostActions(BuildContext context, confession) {
    Get.bottomSheet(
      ConfessionActionsBottomSheet(
        confession: confession,
        onDeleted: () {
          // Refresh the feed after deletion
          controller.confessions.removeWhere((c) => c.id == confession.id);
          controller.confessions.refresh();
        },
        onEdited: () {
          // Refresh will be handled when coming back from edit page
        },
        onFavoriteToggled: () {
          // No need to refresh, just show success message
        },
        onIdentityRevealed: () {
          // Refresh to show revealed identity
          controller.loadConfessions(refresh: true);
        },
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }
}
