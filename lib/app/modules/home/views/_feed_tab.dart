part of 'home_view.dart';

// Feed Tab
class _FeedTab extends StatelessWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stories section
        Container(
          height: 115,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkCardColor
              : Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: context.horizontalPadding,
              vertical: 8,
            ),
            children: [
              // Add story
              _buildAddStoryCard(context),
              const SizedBox(width: 12),
              // Stories
              ...List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildStoryCard(context, index),
                ),
              ),
            ],
          ),
        ),

        // Divider
        Container(
          height: 8,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppThemeSystem.darkBackgroundColor
              : AppThemeSystem.grey100,
        ),

        // Feed content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Create post
                Container(
                  margin: EdgeInsets.all(context.horizontalPadding),
                  padding: EdgeInsets.all(context.elementSpacing),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemeSystem.darkCardColor
                        : Colors.white,
                    borderRadius: context.borderRadius(BorderRadiusType.medium),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppThemeSystem.primaryColor,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Get.snackbar(
                              'Créer',
                              'Créer une nouvelle publication',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppThemeSystem.grey300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Quoi de neuf, John ?',
                              style: context.textStyle(FontSizeType.body2).copyWith(
                                color: AppThemeSystem.grey600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppThemeSystem.primaryColor,
                              AppThemeSystem.secondaryColor,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () {
                            Get.snackbar(
                              'Photo',
                              'Ajouter une photo',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Feed posts
                ...List.generate(
                  5,
                  (index) => _buildFeedPostCard(context, index),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add Story Card
  Widget _buildAddStoryCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Story',
          'Créer une story',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor.withValues(alpha: 0.2),
                        AppThemeSystem.secondaryColor.withValues(alpha: 0.2),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppThemeSystem.primaryColor,
                    size: 35,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
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
                            ? AppThemeSystem.darkCardColor
                            : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Vous',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Story Card
  Widget _buildStoryCard(BuildContext context, int index) {
    final hasStory = index % 3 != 2;
    return GestureDetector(
      onTap: () {
        Get.snackbar(
          'Story',
          'Voir la story de User ${index + 1}',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: hasStory
                    ? LinearGradient(
                        colors: [
                          AppThemeSystem.primaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                border: hasStory
                    ? null
                    : Border.all(
                        color: AppThemeSystem.grey300,
                        width: 2,
                      ),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppThemeSystem.darkCardColor
                      : Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppThemeSystem.primaryColor,
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'User ${index + 1}',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedPostCard(BuildContext context, int index) {
    final isLiked = index % 2 == 0;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.elementSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppThemeSystem.darkCardColor
            : Colors.white,
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(context.elementSpacing),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppThemeSystem.primaryColor,
                        AppThemeSystem.secondaryColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppThemeSystem.darkCardColor
                        : Colors.white,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppThemeSystem.primaryColor,
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Utilisateur ${index + 1}',
                        style: context.textStyle(FontSizeType.body1).copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppThemeSystem.blackColor,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Il y a ${index + 2}h',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.grey600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: AppThemeSystem.grey600,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    Get.snackbar(
                      'Options',
                      'Options de la publication',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  color: AppThemeSystem.grey600,
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
            child: Text(
              'Quelle belle journée ! 🌟 Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore.',
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: context.elementSpacing),
          // Image (optional)
          if (index % 2 == 0)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppThemeSystem.grey200,
                borderRadius: BorderRadius.circular(8),
              ),
              margin: EdgeInsets.symmetric(horizontal: context.elementSpacing),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 60,
                  color: AppThemeSystem.grey400,
                ),
              ),
            ),
          if (index % 2 == 0) SizedBox(height: context.elementSpacing),

          // Stats
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.elementSpacing),
            child: Row(
              children: [
                // Likes count
                Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFF44336)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(index + 1) * 15}',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.grey600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${(index + 1) * 5} commentaires',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(index + 1) * 2} partages',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Divider(
            height: 1,
            color: AppThemeSystem.grey300,
          ),

          // Actions
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.elementSpacing,
              vertical: 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPostActionButton(
                    context,
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    'J\'aime',
                    isLiked,
                  ),
                ),
                Expanded(
                  child: _buildPostActionButton(
                    context,
                    Icons.comment_outlined,
                    'Commenter',
                    false,
                  ),
                ),
                Expanded(
                  child: _buildPostActionButton(
                    context,
                    Icons.share_outlined,
                    'Partager',
                    false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActionButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isActive,
  ) {
    return InkWell(
      onTap: () {
        Get.snackbar(
          label,
          'Action: $label',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? const Color(0xFFE91E63)
                  : AppThemeSystem.grey600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textStyle(FontSizeType.body2).copyWith(
                color: isActive
                    ? const Color(0xFFE91E63)
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppThemeSystem.blackColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
