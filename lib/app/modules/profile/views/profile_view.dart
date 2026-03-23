import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/data/core/api_service.dart';
import 'package:weylo/app/widgets/verified_badge.dart';

import '../controllers/profile_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../feeds/controllers/feeds_controller.dart';
import '../../feeds/views/image_viewer_page.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin<ProfileView> {

  @override
  bool get wantKeepAlive => true;

  ProfileController get controller => Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    print('🎨 [PROFILE_VIEW] initState() - ProfileView initialisé');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('🔄 [PROFILE_VIEW] didChangeDependencies() - ProfileView visible');
  }

  @override
  void dispose() {
    print('🗑️ [PROFILE_VIEW] dispose() - ProfileView détruit');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Important pour AutomaticKeepAliveClientMixin
    print('🖼️ [PROFILE_VIEW] build() - Rendu du ProfileView');

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
                  // Cover photo - cliquable pour agrandir
                  GestureDetector(
                    onTap: user?.hasRealCoverPhoto ?? false
                        ? () {
                            Get.to(
                              () => ImageViewerPage(
                                imageUrl: _buildImageUrl(user!.coverPhotoUrl!),
                                content: '',
                              ),
                              transition: Transition.fadeIn,
                            );
                          }
                        : null,
                    child: user?.coverPhotoUrl != null
                        ? Image.network(
                            _buildImageUrl(user!.coverPhotoUrl!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                                      AppThemeSystem.secondaryColor.withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
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
                              );
                            },
                          )
                        : Container(
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
                  ),
                  // Edit cover button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        controller.showCoverPhotoPicker();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
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
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppThemeSystem.primaryColor,
                        child: user?.hasRealAvatar ?? false
                            ? GestureDetector(
                                onTap: () {
                                  Get.to(
                                    () => ImageViewerPage(
                                      imageUrl: _buildImageUrl(user!.avatarUrl!),
                                      content: user.fullName,
                                    ),
                                    transition: Transition.fadeIn,
                                  );
                                },
                                child: ClipOval(
                                  child: Image.network(
                                    _buildImageUrl(user!.avatarUrl!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Text(
                                          user.firstName.isNotEmpty
                                              ? user.firstName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : Text(
                                user?.firstName.isNotEmpty == true
                                    ? user!.firstName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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
                            Row(
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
                                if (user?.shouldShowBlueBadge ?? false) ...[
                                  const SizedBox(width: 6),
                                  const VerifiedBadge(size: 20),
                                ],
                              ],
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

  /// Build image URL with cache buster based on user's updatedAt
  /// This prevents infinite reloading while still busting cache when profile is updated
  String _buildImageUrl(String url) {
    final user = controller.user.value;
    if (user == null) return url;

    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=${user.updatedAt.millisecondsSinceEpoch}';
  }

  /// Retourne une paire de couleurs pour le gradient basé sur l'ID
  /// Style Google Keep avec des couleurs vives et bien contrastées
  List<Color> _getNoteColors(int id) {
    final colorPalettes = [
      // Rose-Rouge (chaud)
      [const Color(0xFFE91E63), const Color(0xFFC2185B)],
      // Orange-Amber
      [const Color(0xFFFF9800), const Color(0xFFF57C00)],
      // Violet-Indigo
      [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
      // Bleu profond
      [const Color(0xFF2196F3), const Color(0xFF1976D2)],
      // Vert émeraude
      [const Color(0xFF009688), const Color(0xFF00796B)],
      // Bleu-vert
      [const Color(0xFF00BCD4), const Color(0xFF0097A7)],
      // Rouge-Rose
      [const Color(0xFFF44336), const Color(0xFFD32F2F)],
      // Violet profond
      [const Color(0xFF673AB7), const Color(0xFF512DA8)],
      // Teal foncé
      [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
      // Orange foncé
      [const Color(0xFFFF5722), const Color(0xFFE64A19)],
    ];

    // Utiliser l'ID pour sélectionner une palette de manière cohérente
    final paletteIndex = id % colorPalettes.length;
    return colorPalettes[paletteIndex];
  }

  Widget _buildProfileStat(BuildContext context, String value, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingPosts.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 64,
                color: AppThemeSystem.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune publication',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: AppThemeSystem.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos publications apparaîtront ici',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.grey500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.posts.length,
        itemBuilder: (context, index) {
          final post = controller.posts[index];

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
                // Navigate directly to confession detail page
                Get.toNamed('/confession/${post.id}');
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Display media if available
                  if (post.mediaType == 'image' && post.mediaUrl != null)
                    Image.network(
                      post.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: AppThemeSystem.grey500,
                          ),
                        );
                      },
                    )
                  else if (post.mediaType == 'video' && post.mediaUrl != null)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display video thumbnail if available
                        if (post.thumbnailUrl != null)
                          Image.network(
                            post.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black87,
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Colors.black87,
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        // Play button overlay
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Text only post - Google Keep style note
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getNoteColors(post.id),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          post.content,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Stats overlay
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likesCount}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildGiftsGrid(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingGifts.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.sentGifts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: AppThemeSystem.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun cadeau envoyé',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: AppThemeSystem.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les cadeaux envoyés apparaîtront ici',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.grey500,
                ),
              ),
            ],
          ),
        );
      }

      // Group gifts by gift_id to count occurrences
      final giftCounts = <int, int>{};
      final giftTransactions = <int, dynamic>{};

      for (var transaction in controller.sentGifts) {
        final giftId = transaction.giftId ?? transaction.gift.id;
        giftCounts[giftId] = (giftCounts[giftId] ?? 0) + 1;
        giftTransactions[giftId] = transaction;
      }

      final uniqueGifts = giftTransactions.values.toList();

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: uniqueGifts.length,
        itemBuilder: (context, index) {
          final transaction = uniqueGifts[index];
          final gift = transaction.gift;
          final count = giftCounts[gift.id] ?? 1;

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
                  '${gift.name} - ${gift.formattedPrice}\nEnvoyé ${count}x',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: Stack(
                children: [
                  // Display gift icon (emoji)
                  Center(
                    child: Text(
                      gift.icon,
                      style: const TextStyle(
                        fontSize: 50,
                      ),
                    ),
                  ),

                  // Gift count badge
                  if (count > 1)
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
                          '${count}x',
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Gift name overlay
                  Positioned(
                    top: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gift.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: Colors.white,
                          fontSize: 9,
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
    });
  }

  Widget _buildSavedGrid(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingFavorites.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.favorites.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border_outlined,
                size: 64,
                color: AppThemeSystem.grey400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun favori',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  color: AppThemeSystem.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vos confessions favorites apparaîtront ici',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.grey500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.favorites.length,
        itemBuilder: (context, index) {
          final favorite = controller.favorites[index];

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
              onTap: () async {
                // If confession is deleted, show confirmation dialog
                if (favorite.isDeleted) {
                  _showDeletedConfessionDialog(context, favorite.id);
                  return;
                }

                // Capture screen height before async operations
                final screenHeight = MediaQuery.of(context).size.height;
                final isDark = Theme.of(context).brightness == Brightness.dark;

                // Show loading overlay
                Get.dialog(
                  PopScope(
                    canPop: false,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppThemeSystem.darkCardColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              'Recherche en cours...',
                              style: context.textStyle(FontSizeType.body2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  barrierDismissible: false,
                );

                try {
                  // Navigate to home and switch to Confession tab
                  HomeController? homeController;
                  try {
                    homeController = Get.find<HomeController>();
                  } catch (e) {
                    // HomeController not found, navigate to home
                    Get.offAllNamed('/home');
                    await Future.delayed(const Duration(milliseconds: 500));
                    homeController = Get.find<HomeController>();
                  }

                  homeController.changeTab(3); // Tab Confession
                  await Future.delayed(const Duration(milliseconds: 300));

                  // Find and scroll to the confession
                  final confessionsController = Get.find<ConfessionsController>();
                  final found = await confessionsController.navigateToConfession(
                    favorite.id,
                    screenHeight: screenHeight,
                  );

                  // Close loading dialog
                  Get.back();

                  // If confession not found (404 or deleted), mark it as deleted
                  if (!found) {
                    controller.markFavoriteAsDeleted(favorite.id);
                    Get.snackbar(
                      'Confession supprimée',
                      'Cette confession a été supprimée par son auteur',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppThemeSystem.warningColor,
                      colorText: Colors.white,
                    );
                  }
                } catch (e) {
                  // Close loading dialog on error
                  Get.back();

                  // Check if it's a 404 error (confession deleted)
                  bool is404 = false;
                  if (e is ApiException && e.statusCode == 404) {
                    is404 = true;
                  } else if (e.toString().toLowerCase().contains('404') ||
                             e.toString().toLowerCase().contains('not found')) {
                    is404 = true;
                  }

                  if (is404) {
                    controller.markFavoriteAsDeleted(favorite.id);
                    Get.snackbar(
                      'Confession supprimée',
                      'Cette confession a été supprimée par son auteur',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppThemeSystem.warningColor,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Apply grayscale filter if deleted
                  ColorFiltered(
                    colorFilter: favorite.isDeleted
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display media if available
                        if (favorite.mediaType == 'image' && favorite.mediaUrl != null)
                          Image.network(
                            favorite.mediaUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppThemeSystem.grey500,
                                ),
                              );
                            },
                          )
                        else if (favorite.mediaType == 'video' && favorite.mediaUrl != null)
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        // Display video thumbnail if available
                        if (favorite.thumbnailUrl != null)
                          Image.network(
                            favorite.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.black87,
                                child: const Icon(
                                  Icons.play_circle_outline,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Colors.black87,
                            child: const Icon(
                              Icons.play_circle_outline,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        // Play button overlay
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Text only confession - Google Keep style note
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getNoteColors(favorite.id),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          favorite.content,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textStyle(FontSizeType.caption).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),

                  // "Supprimé par l'auteur" badge overlay (only if deleted)
                  if (favorite.isDeleted)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeSystem.errorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'SUPPRIMÉ PAR L\'AUTEUR',
                                style: context.textStyle(FontSizeType.caption).copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bookmark icon overlay
                  if (!favorite.isDeleted)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bookmark,
                          color: AppThemeSystem.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),

                  // Stats overlay
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${favorite.likesCount}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  /// Show dialog to confirm removal of deleted favorite confession
  void _showDeletedConfessionDialog(BuildContext context, int confessionId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: AppThemeSystem.errorColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Supprimé par l\'auteur',
                style: context.textStyle(FontSizeType.h5).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppThemeSystem.blackColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Cette confession a été supprimée par son auteur. Voulez-vous la retirer de vos confessions enregistrées ?',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: Text(
              'Non',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: AppThemeSystem.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.removeFavorite(confessionId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppThemeSystem.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Oui, retirer',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
