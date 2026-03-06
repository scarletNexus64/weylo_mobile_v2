import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading indicator
      if (controller.isLoading.value && controller.user.value == null) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final user = controller.user.value;
      final stats = controller.stats.value;

      return RefreshIndicator(
        onRefresh: controller.refreshDashboard,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cover photo + Profile picture
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Cover photo
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 50,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // Edit cover button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          Get.snackbar(
                            'Cover',
                            'Modifier la photo de couverture',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                    ),
                  ),
                  // Profile picture
                  Positioned(
                    bottom: -50,
                    left: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppThemeSystem.darkBackgroundColor
                              : Colors.white,
                          width: 5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Avatar with network image or fallback
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppThemeSystem.primaryColor,
                            backgroundImage: user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                : null,
                            child: user?.avatarUrl == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppThemeSystem.primaryColor,
                                    AppThemeSystem.secondaryColor,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppThemeSystem.darkBackgroundColor
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                onPressed: controller.showAvatarPicker,
                                padding: const EdgeInsets.all(6),
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Profile info
              Padding(
                padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Utilisateur',
                              style: context.textStyle(FontSizeType.h2).copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : AppThemeSystem.blackColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${user?.username ?? 'username'}',
                              style: context.textStyle(FontSizeType.body2).copyWith(
                                color: AppThemeSystem.grey600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppThemeSystem.primaryColor,
                                AppThemeSystem.secondaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Get.toNamed('/edit-profile');
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Modifier',
                                      style: context.textStyle(FontSizeType.body2).copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bio
                    if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                      Text(
                        user.bio!,
                        style: context.textStyle(FontSizeType.body2).copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppThemeSystem.blackColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Stats
                    Row(
                      children: [
                        _buildProfileStat(
                          context,
                          '${stats?.messages.total ?? 0}',
                          'Messages',
                        ),
                        const SizedBox(width: 20),
                        _buildProfileStat(
                          context,
                          '${stats?.confessions.total ?? 0}',
                          'Confessions',
                        ),
                        const SizedBox(width: 20),
                        _buildProfileStat(
                          context,
                          '${stats?.conversations.total ?? 0}',
                          'Conversations',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tabs for posts/photos
                    DefaultTabController(
                      length: 3,
                      child: Column(
                        children: [
                          TabBar(
                            indicatorColor: AppThemeSystem.primaryColor,
                            labelColor: AppThemeSystem.primaryColor,
                            unselectedLabelColor: AppThemeSystem.grey600,
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.grid_on_rounded),
                                text: 'Publications',
                              ),
                              Tab(
                                icon: Icon(Icons.card_giftcard_rounded),
                                text: 'Cadeaux',
                              ),
                              Tab(
                                icon: Icon(Icons.bookmark_border_rounded),
                                text: 'Enregistrés',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 400,
                            child: TabBarView(
                              children: [
                                _buildPostsGrid(context),
                                _buildGiftsGrid(context),
                                _buildSavedGrid(context),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Settings button (empty for now)
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProfileStat(BuildContext context, String value, String label) {
    return InkWell(
      onTap: () {
        Get.snackbar(
          label,
          'Voir $label',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.textStyle(FontSizeType.h3).copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppThemeSystem.blackColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textStyle(FontSizeType.caption).copyWith(
              color: AppThemeSystem.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 18,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppThemeSystem.grey300,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkBackgroundColor
                  : Colors.white,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Get.snackbar(
                'Post',
                'Voir publication ${index + 1}',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: AppThemeSystem.grey500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftsGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkBackgroundColor
                  : Colors.white,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Get.snackbar(
                'Cadeau',
                'Voir cadeau envoyé ${index + 1}',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 40,
                    color: AppThemeSystem.primaryColor,
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemeSystem.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${index + 1}x',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppThemeSystem.grey300,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkBackgroundColor
                  : Colors.white,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              Get.snackbar(
                'Enregistré',
                'Voir publication enregistrée ${index + 1}',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 40,
                    color: AppThemeSystem.grey500,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(
                    Icons.bookmark,
                    color: AppThemeSystem.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
