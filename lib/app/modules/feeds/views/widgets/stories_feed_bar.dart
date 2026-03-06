import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/story_controller.dart';
import '../../../../data/models/story_feed_item_model.dart';
import 'story_circle.dart';
import '../story_viewer.dart';
import '../my_stories_management_view.dart';
import 'create_story_bottom_sheet.dart';

/// Horizontal scrollable stories feed bar
class StoriesFeedBar extends StatelessWidget {
  const StoriesFeedBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Try to find the controller, return empty container if not found
    try {
      final controller = Get.find<StoryController>();
      return _StoriesFeedBarContent(controller: controller);
    } catch (e) {
      print('⚠️ StoryController not found: $e');
      return const SizedBox.shrink();
    }
  }
}

class _StoriesFeedBarContent extends StatelessWidget {
  final StoryController controller;

  const _StoriesFeedBarContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingFeed.value && controller.storiesFeed.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.feedError.value != null && controller.storiesFeed.isEmpty) {
        return _buildErrorState(controller);
      }

      // Debug: afficher le contenu du feed
      print('🔍 [STORIES] Total items in feed: ${controller.storiesFeed.length}');
      for (var i = 0; i < controller.storiesFeed.length; i++) {
        print('🔍 [STORIES] Item $i: isOwner=${controller.storiesFeed[i].isOwner}, username=${controller.storiesFeed[i].user.username}');
      }

      // Vérifier si l'utilisateur a des stories
      final myStoryFeedItem = controller.storiesFeed.firstWhereOrNull(
        (item) => item.isOwner,
      );

      // Filtrer les stories des autres utilisateurs (exclure la mienne si elle existe)
      final otherStories = controller.storiesFeed.where((item) => !item.isOwner).toList();

      print('🔍 [STORIES] myStoryFeedItem: ${myStoryFeedItem != null ? 'EXISTS' : 'NULL'}');
      print('🔍 [STORIES] otherStories count: ${otherStories.length}');

      return Container(
        height: 110,
        color: Colors.white,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          itemCount: 1 + otherStories.length, // Toujours 1 pour ma story + les autres
          itemBuilder: (context, index) {
            // Premier élément : toujours ma story card
            if (index == 0) {
              return _buildMyStoryCard(context, myStoryFeedItem);
            }

            // Les autres stories
            final feedItem = otherStories[index - 1];
            return StoryCircle(
              feedItem: feedItem,
              onTap: () => _openStoryViewer(context, controller, feedItem.realUserId),
            );
          },
        ),
      );
    });
  }

  /// Nouvelle card "Ma Story" unifiée (toujours en position 1)
  Widget _buildMyStoryCard(BuildContext context, StoryFeedItemModel? myStoryFeedItem) {
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
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                // Story circle avec ou sans gradient selon si j'ai des stories
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasStories
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasStories ? null : Colors.grey.shade300,
                  ),
                  padding: hasStories ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasStories ? Colors.white : null,
                    ),
                    padding: hasStories ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: hasStories &&
                              myStoryFeedItem.user.avatarUrl.isNotEmpty &&
                              !myStoryFeedItem.user.avatarUrl.contains('ui-avatars.com')
                          ? NetworkImage(myStoryFeedItem.user.avatarUrl)
                          : null,
                      backgroundColor: const Color(0xFF667eea),
                      child: !hasStories ||
                              myStoryFeedItem.user.avatarUrl.isEmpty ||
                              myStoryFeedItem.user.avatarUrl.contains('ui-avatars.com')
                          ? Text(
                              hasStories && myStoryFeedItem.user.username.isNotEmpty
                                  ? myStoryFeedItem.user.username[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Bouton + toujours visible
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _openCreateStoryBottomSheet(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF667eea),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 72,
              child: Text(
                hasStories ? myStoryFeedItem.user.username : 'Ma story',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: hasStories ? Colors.black87 : const Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 110,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 12,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(StoryController controller) {
    return Container(
      height: 110,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              controller.feedError.value ?? 'Erreur de chargement',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 8),
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
    await controller.loadUserStoriesById(userId);

    if (controller.currentUserStories.isNotEmpty) {
      Get.to(
        () => const StoryViewer(),
        fullscreenDialog: true,
        transition: Transition.fadeIn,
      );
    }
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
}
