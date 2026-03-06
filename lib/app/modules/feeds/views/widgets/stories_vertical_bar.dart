import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import '../../controllers/story_controller.dart';
import '../story_viewer.dart';
import '../my_stories_management_view.dart';
import 'create_story_bottom_sheet.dart';

/// Vertical stories feed bar (Facebook style)
class StoriesVerticalBar extends StatelessWidget {
  const StoriesVerticalBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<StoryController>();
      return _StoriesVerticalBarContent(controller: controller);
    } catch (e) {
      print('⚠️ StoryController not found: $e');
      return const SizedBox.shrink();
    }
  }
}

class _StoriesVerticalBarContent extends StatelessWidget {
  final StoryController controller;

  const _StoriesVerticalBarContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    // Responsive story dimensions
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

    return Obx(() {
      if (controller.isLoadingFeed.value && controller.storiesFeed.isEmpty) {
        return _buildLoadingState(storyWidth, storyHeight, deviceType, isDark, context);
      }

      if (controller.feedError.value != null && controller.storiesFeed.isEmpty) {
        return _buildErrorState(controller, storyHeight, isDark);
      }

      // Vérifier si l'utilisateur a des stories
      final myStoryFeedItem = controller.storiesFeed.firstWhereOrNull(
        (item) => item.isOwner,
      );

      // Filtrer les stories des autres utilisateurs (exclure la mienne si elle existe)
      final otherStories = controller.storiesFeed.where((item) => !item.isOwner).toList();

      // Sort other stories: unviewed first, then viewed
      otherStories.sort((a, b) {
        if (a.hasNew && !b.hasNew) return -1;
        if (!a.hasNew && b.hasNew) return 1;
        return b.latestStoryAt.compareTo(a.latestStoryAt);
      });

      return Container(
        height: storyHeight + 10,
        margin: EdgeInsets.only(
          top: context.elementSpacing * 0.8,
          bottom: context.elementSpacing * 0.5,
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          itemCount: 1 + otherStories.length, // Toujours 1 pour ma story + les autres
          itemBuilder: (context, index) {
            // First item: Ma story (toujours en position 1)
            if (index == 0) {
              return _buildMyStoryCard(context, myStoryFeedItem, storyWidth, storyHeight, isDark, deviceType);
            }

            // Regular stories
            final feedItem = otherStories[index - 1];
            return _buildStoryCard(
              context,
              feedItem,
              storyWidth,
              storyHeight,
              isDark,
              deviceType,
            );
          },
        ),
      );
    });
  }

  /// Nouvelle card "Ma Story" unifiée (toujours en position 1)
  Widget _buildMyStoryCard(
    BuildContext context,
    dynamic myStoryFeedItem,
    double width,
    double height,
    bool isDark,
    DeviceType deviceType,
  ) {
    final hasStories = myStoryFeedItem != null;

    return GestureDetector(
      onTap: () {
        // Si j'ai des stories, ouvrir la page de gestion
        if (hasStories) {
          _openMyStoriesManagement(context);
        } else {
          // Sinon, ouvrir le bottomsheet de création
          _openCreateStoryBottomSheet(context);
        }
      },
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: context.elementSpacing),
        child: Stack(
          children: [
            // Background avec ou sans gradient selon si j'ai des stories
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: hasStories
                      ? LinearGradient(
                          colors: [
                            AppThemeSystem.primaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                            AppThemeSystem.secondaryColor.withValues(alpha: 0.3),
                          ],
                        ),
                  border: Border.all(
                    color: hasStories
                        ? AppThemeSystem.primaryColor
                        : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300),
                    width: hasStories ? 3 : 1.5,
                  ),
                ),
                child: hasStories
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _buildPreviewContent(
                          myStoryFeedItem.preview,
                          isDark,
                          context,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: deviceType == DeviceType.mobile ? 50 : 60,
                          color: AppThemeSystem.primaryColor,
                        ),
                      ),
              ),
            ),
            // Bouton + toujours visible
            Positioned(
              bottom: hasStories ? 10 : 12,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _openCreateStoryBottomSheet(context),
                  child: Container(
                    padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.primaryColor,
                      shape: BoxShape.circle,
                      border: hasStories ? Border.all(color: Colors.white, width: 2) : null,
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
            ),
            // Username ou "Ma story"
            if (!hasStories)
              Positioned(
                bottom: 54,
                left: 8,
                right: 8,
                child: Text(
                  'Ma story',
                  textAlign: TextAlign.center,
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(
    BuildContext context,
    dynamic feedItem,
    double width,
    double height,
    bool isDark,
    DeviceType deviceType,
  ) {
    final hasNew = feedItem.hasNew;
    final preview = feedItem.preview;

    return GestureDetector(
      onTap: () => _openStoryViewer(context, controller, feedItem.realUserId),
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(right: context.elementSpacing),
        child: Stack(
          children: [
            // Story Container with preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasNew
                      ? AppThemeSystem.primaryColor
                      : (isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300),
                  width: hasNew ? 3 : 1.5,
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
                color: preview.isTextType && preview.backgroundColor != null
                    ? _parseColor(preview.backgroundColor!)
                    : (isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildPreviewContent(preview, isDark, context),
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
                    color: hasNew ? AppThemeSystem.primaryColor : AppThemeSystem.grey500,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  backgroundImage: feedItem.user.avatarUrl.isNotEmpty
                      ? NetworkImage(feedItem.user.avatarUrl)
                      : null,
                  backgroundColor: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                  onBackgroundImageError: feedItem.user.avatarUrl.isNotEmpty
                      ? (exception, stackTrace) {
                          // Silently handle image error
                        }
                      : null,
                  child: feedItem.user.avatarUrl.isEmpty
                      ? Icon(
                          Icons.person_rounded,
                          size: deviceType == DeviceType.mobile ? 18 : 22,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
            ),
            // Username and story count
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feedItem.isAnonymous ? 'Anonyme' : feedItem.user.username,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (feedItem.storiesCount > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${feedItem.storiesCount} stories',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(dynamic preview, bool isDark, BuildContext context) {
    if (preview.isVideoType) {
      // Pour les vidéos, afficher le thumbnail s'il existe, sinon un gradient
      if (preview.thumbnailUrl != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail de la vidéo
            Image.network(
              preview.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // En cas d'erreur, afficher le gradient
                return _buildVideoGradientPlaceholder();
              },
            ),
            // Icône play par-dessus
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ],
        );
      } else {
        // Pas de thumbnail, afficher le gradient
        return _buildVideoGradientPlaceholder();
      }
    } else if (preview.isImageType && preview.mediaUrl != null) {
      // Pour les images, charger normalement et remplir tout l'espace
      return SizedBox.expand(
        child: Image.network(
          preview.mediaUrl!,
          fit: BoxFit.cover,
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
        ),
      );
    } else if (preview.isTextType && preview.content != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Text(
          preview.content!,
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.image_rounded,
        size: 40,
        color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
      ),
    );
  }

  Widget _buildLoadingState(
    double width,
    double height,
    DeviceType deviceType,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      height: height + 10,
      margin: EdgeInsets.only(
        top: context.elementSpacing * 0.8,
        bottom: context.elementSpacing * 0.5,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: width,
            height: height,
            margin: EdgeInsets.only(right: context.elementSpacing),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey300,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(StoryController controller, double height, bool isDark) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey500,
            ),
            const SizedBox(height: 12),
            Text(
              controller.feedError.value ?? 'Erreur de chargement',
              style: TextStyle(
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => controller.loadStoriesFeed(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, StoryController controller, int userId) async {
    print('📖 [STORY] Ouverture du viewer pour userId: $userId');

    await controller.loadUserStoriesById(userId);

    if (controller.currentUserStories.isNotEmpty) {
      Get.to(
        () => const StoryViewer(),
        fullscreenDialog: true,
        transition: Transition.fadeIn,
      );
    } else {
      print('⚠️ [STORY] Aucune story trouvée pour userId: $userId');
    }
  }

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      print('❌ Error parsing color: $hexColor');
    }
    return const Color(0xFF6366f1); // Default primary color
  }

  /// Ouvre la page de gestion de mes stories
  void _openMyStoriesManagement(BuildContext context) async {
    // Charger mes stories d'abord
    await controller.loadMyStories();

    // Ouvrir la page de gestion
    Get.to(() => const MyStoriesManagementView());
  }

  /// Ouvre le bottomsheet de création de story
  void _openCreateStoryBottomSheet(BuildContext context) {
    Get.bottomSheet(
      const CreateStoryBottomSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Build gradient placeholder for videos without thumbnail
  Widget _buildVideoGradientPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor.withValues(alpha: 0.8),
            AppThemeSystem.secondaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
