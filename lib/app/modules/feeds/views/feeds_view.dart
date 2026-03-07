import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/feeds_controller.dart';
import 'widgets/stories_vertical_bar.dart';

class ConfessionsView extends GetView<ConfessionsController> {
  const ConfessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        controller.refreshFeed();
      },
      color: AppThemeSystem.primaryColor,
      child: CustomScrollView(
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
            if (controller.feedItems.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = controller.feedItems[index];
                  return _buildPostCard(context, item);
                },
                childCount: controller.feedItems.length,
              ),
            );
          }),
        ],
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
    final hasImage = post['image'] != null;

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
                Container(
                  width: deviceType == DeviceType.mobile ? 44 : 52,
                  height: deviceType == DeviceType.mobile ? 44 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isAnonymous
                        ? LinearGradient(
                            colors: [
                              AppThemeSystem.grey700,
                              AppThemeSystem.grey600,
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppThemeSystem.primaryColor,
                              AppThemeSystem.secondaryColor,
                            ],
                          ),
                  ),
                  child: Icon(
                    isAnonymous ? Icons.lock_rounded : Icons.person_rounded,
                    color: Colors.white,
                    size: deviceType == DeviceType.mobile ? 22 : 26,
                  ),
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
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Content
          if (post['content'] != null && (post['content'] as String).isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
              child: Text(
                post['content'] as String,
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: isDark ? AppThemeSystem.grey200 : AppThemeSystem.grey900,
                  height: 1.5,
                ),
              ),
            ),

          // Image
          if (hasImage)
            Padding(
              padding: EdgeInsets.only(top: context.elementSpacing * 0.8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.network(
                  post['image'] as String,
                  width: double.infinity,
                  height: 320,
                  fit: BoxFit.cover,
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
            ),

          // Reactions Summary
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                // Reactions count
                if (post['reactions'] != null && post['reactions'] > 0) ...[
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
                        '${post['reactions']}',
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                // Comments & Shares count
                Text(
                  '${post['comments']} commentaires',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${post['shares']} partages',
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
                _buildPostActionButton(
                  context: context,
                  icon: Icons.favorite_border_rounded,
                  label: 'J\'aime',
                  onTap: () => controller.likePost(post['id'] as int),
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
}
