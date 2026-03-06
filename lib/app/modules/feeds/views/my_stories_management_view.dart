import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../controllers/story_controller.dart';
import 'widgets/story_viewers_bottom_sheet.dart';
import 'story_viewer.dart';
import 'create_story_view.dart';
import 'widgets/create_story_bottom_sheet.dart';
import '../../../widgets/app_theme_system.dart';

/// Page de gestion de mes stories
class MyStoriesManagementView extends StatelessWidget {
  const MyStoriesManagementView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StoryController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes stories',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: isDark ? 0 : 0.5,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton texte
          FloatingActionButton(
            heroTag: 'text_story',
            mini: true,
            backgroundColor: AppThemeSystem.primaryColor,
            onPressed: () => Get.to(() => const CreateStoryView()),
            child: Icon(
              Icons.edit,
              color: Colors.white,
              size: deviceType == DeviceType.mobile ? 20 : 24,
            ),
          ),
          SizedBox(height: context.elementSpacing * 0.75),
          // Bouton photo/vidéo
          FloatingActionButton(
            heroTag: 'media_story',
            backgroundColor: AppThemeSystem.primaryColor,
            onPressed: () {
              Get.bottomSheet(
                const CreateStoryBottomSheet(),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: Icon(
              Icons.add_photo_alternate,
              color: Colors.white,
              size: deviceType == DeviceType.mobile ? 24 : 28,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingMyStories.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppThemeSystem.primaryColor,
            ),
          );
        }

        if (controller.myStories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  size: deviceType == DeviceType.mobile ? 64 : 80,
                  color: isDark ? AppThemeSystem.grey600 : AppThemeSystem.grey400,
                ),
                SizedBox(height: context.elementSpacing),
                Text(
                  'Aucune story',
                  style: context.textStyle(FontSizeType.body1).copyWith(
                    color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: context.elementSpacing * 0.5),
          itemCount: controller.myStories.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? AppThemeSystem.grey800 : AppThemeSystem.grey200,
          ),
          itemBuilder: (context, index) {
            final story = controller.myStories[index];
            return _StoryManagementTile(
              story: story,
              controller: controller,
              isDark: isDark,
              deviceType: deviceType,
            );
          },
        );
      }),
    );
  }
}

/// Tile circulaire pour chaque story dans la liste de gestion
class _StoryManagementTile extends StatelessWidget {
  final StoryModel story;
  final StoryController controller;
  final bool isDark;
  final DeviceType deviceType;

  const _StoryManagementTile({
    required this.story,
    required this.controller,
    required this.isDark,
    required this.deviceType,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = deviceType == DeviceType.mobile ? 24.0 : 28.0;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.elementSpacing * 0.5,
      ),
      leading: GestureDetector(
        onTap: () => _openStory(context),
        child: _buildStoryCircle(context),
      ),
      title: Text(
        _getStoryTypeLabel(),
        style: context.textStyle(FontSizeType.body1).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _getTimeAgo(story.createdAt),
        style: context.textStyle(FontSizeType.caption).copyWith(
          color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton vues
          IconButton(
            icon: Icon(
              Icons.visibility_outlined,
              size: iconSize,
            ),
            color: AppThemeSystem.primaryColor,
            onPressed: () => _showViewersBottomSheet(context),
            tooltip: '${story.viewsCount} vues',
          ),
          // Bouton suppression
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: iconSize,
            ),
            color: AppThemeSystem.errorColor,
            onPressed: () => _deleteStory(context),
            tooltip: 'Supprimer',
          ),
        ],
      ),
      onTap: () => _openStory(context),
    );
  }

  Widget _buildStoryCircle(BuildContext context) {
    final circleSize = deviceType == DeviceType.mobile ? 60.0 : 72.0;

    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppThemeSystem.primaryColor,
            AppThemeSystem.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: _buildCircleContent(context),
        ),
      ),
    );
  }

  Widget _buildCircleContent(BuildContext context) {
    if (story.isImageType && story.mediaUrl != null) {
      return Image.network(
        story.mediaUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
            child: Icon(
              Icons.broken_image,
              size: 24,
              color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
            ),
          );
        },
      );
    } else if (story.isVideoType) {
      // Afficher le thumbnail de la vidéo s'il existe
      if (story.thumbnailUrl != null) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              story.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
                  child: Icon(
                    Icons.videocam_off,
                    size: 24,
                    color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
                  ),
                );
              },
            ),
            // Icône play pour indiquer que c'est une vidéo
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      } else {
        // Pas de thumbnail disponible
        return Container(
          color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
          child: Icon(
            Icons.videocam,
            size: 24,
            color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
          ),
        );
      }
    } else if (story.isTextType) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getGradientColors(story.displayBackgroundColor),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Text(
            story.content != null && story.content!.isNotEmpty
                ? story.content![0].toUpperCase()
                : 'A',
            style: context.textStyle(FontSizeType.h5).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? AppThemeSystem.grey700 : AppThemeSystem.grey300,
      child: Icon(
        Icons.image_outlined,
        size: 24,
        color: isDark ? AppThemeSystem.grey500 : AppThemeSystem.grey600,
      ),
    );
  }

  String _getStoryTypeLabel() {
    if (story.isImageType) {
      return story.content != null && story.content!.isNotEmpty
          ? story.content!
          : 'Photo';
    } else if (story.isVideoType) {
      return 'Vidéo';
    } else if (story.isTextType) {
      return story.content != null && story.content!.length > 30
          ? '${story.content!.substring(0, 30)}...'
          : story.content ?? 'Story texte';
    }
    return 'Story';
  }

  void _openStory(BuildContext context) async {
    // Utiliser directement myStories déjà chargées
    controller.currentUserStories.value = List.from(controller.myStories);

    // Trouver l'index de cette story
    final storyIndex = controller.currentUserStories.indexWhere((s) => s.id == story.id);
    if (storyIndex != -1) {
      controller.currentStoryIndex.value = storyIndex;
    } else {
      controller.currentStoryIndex.value = 0;
    }

    // Ouvrir le viewer
    Get.to(
      () => const StoryViewer(),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
  }

  Future<void> _deleteStory(BuildContext context) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        title: Text(
          'Supprimer la story ?',
          style: context.textStyle(FontSizeType.h6).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Cette action est irréversible.',
          style: context.textStyle(FontSizeType.body2),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'Annuler',
              style: context.textStyle(FontSizeType.button).copyWith(
                color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'Supprimer',
              style: context.textStyle(FontSizeType.button).copyWith(
                color: AppThemeSystem.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteStory(story.id);

      // If no more stories, go back to feed
      if (controller.myStories.isEmpty) {
        Get.back();
      }
    }
  }

  void _showViewersBottomSheet(BuildContext context) {
    Get.bottomSheet(
      StoryViewersBottomSheet(
        storyId: story.id,
        initialViewsCount: story.viewsCount,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Il y a ${difference.inDays}j';
    }
  }

  List<Color> _getGradientColors(String hexColor) {
    final color = _parseHexColor(hexColor);
    return [
      color,
      color.withValues(alpha: 0.7),
    ];
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
