import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/groupe_controller.dart';

class GroupeView extends GetView<GroupeController> {
  const GroupeView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Sub-tabs for Groupe
          Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppThemeSystem.darkCardColor
                : Colors.white,
            child: TabBar(
              indicatorColor: AppThemeSystem.primaryColor,
              indicatorWeight: 2,
              labelColor: AppThemeSystem.primaryColor,
              unselectedLabelColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppThemeSystem.grey400
                      : AppThemeSystem.grey600,
              labelStyle: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Mes groupes'),
                Tab(text: 'Découvrir'),
              ],
            ),
          ),
          // Sub-tab views
          Expanded(
            child: TabBarView(
              children: [
                _buildMyGroupsView(context),
                _buildDiscoverGroupsView(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // My Groups View
  Widget _buildMyGroupsView(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(context.horizontalPadding),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildChatCard(context, index, isGroup: true);
      },
    );
  }

  // Discover Groups View
  Widget _buildDiscoverGroupsView(BuildContext context) {
    return Column(
      children: [
        // Search bar with gradient
        Container(
          margin: EdgeInsets.all(context.horizontalPadding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppThemeSystem.primaryColor.withValues(alpha: 0.1),
                AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppThemeSystem.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher des groupes...',
                            hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                              color: AppThemeSystem.grey600,
                            ),
                            border: InputBorder.none,
                          ),
                          style: context.textStyle(FontSizeType.body2).copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : AppThemeSystem.blackColor,
                          ),
                          onChanged: (value) {
                            // TODO: Implement search functionality
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Filter button
              Container(
                margin: const EdgeInsets.only(right: 4),
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
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    Get.snackbar(
                      'Filtres',
                      'Filtrer par catégorie, taille, etc.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Filter chips
        Container(
          height: 50,
          margin: EdgeInsets.only(bottom: context.elementSpacing),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            children: [
              _buildFilterChip(context, 'Tous', true),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Technologie', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Sports', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Musique', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Éducation', false),
              const SizedBox(width: 8),
              _buildFilterChip(context, 'Gaming', false),
            ],
          ),
        ),

        // Groups list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
            itemCount: 8,
            itemBuilder: (context, index) {
              return _buildDiscoverGroupCard(context, index);
            },
          ),
        ),
      ],
    );
  }

  // Filter Chip
  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        Get.snackbar(
          'Filtre',
          'Filtrer par $label',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppThemeSystem.primaryColor,
                    AppThemeSystem.secondaryColor,
                  ],
                )
              : null,
          color: isSelected
              ? null
              : Theme.of(context).brightness == Brightness.dark
                  ? AppThemeSystem.darkCardColor
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(
                  color: AppThemeSystem.grey300,
                  width: 1,
                ),
        ),
        child: Center(
          child: Text(
            label,
            style: context.textStyle(FontSizeType.body2).copyWith(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // Discover Group Card
  Widget _buildDiscoverGroupCard(BuildContext context, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
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
          // Group Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppThemeSystem.tertiaryColor,
            child: const Icon(
              Icons.group_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          // Group Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Groupe découverte ${index + 1}',
                  style: context.textStyle(FontSizeType.body1).copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : AppThemeSystem.blackColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Une communauté active pour partager et discuter...',
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: AppThemeSystem.tertiaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${(index + 10) * 50} membres',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.tertiaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.public_rounded,
                      size: 16,
                      color: AppThemeSystem.grey600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Public',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Join Button
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
                  Get.snackbar(
                    'Rejoindre',
                    'Rejoindre le groupe ${index + 1}',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rejoindre',
                        style: context.textStyle(FontSizeType.caption).copyWith(
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
    );
  }

  Widget _buildChatCard(BuildContext context, int index, {bool isGroup = false}) {
    final isOnline = index % 3 == 0;
    final hasFlame = !isGroup && index % 2 == 0; // Some private chats have active flame
    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isGroup
                  ? AppThemeSystem.tertiaryColor
                  : AppThemeSystem.primaryColor,
              child: isGroup
                  ? const Icon(
                      Icons.group_rounded,
                      color: Colors.white,
                      size: 28,
                    )
                  : Text(
                      String.fromCharCode(65 + index),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            if (isOnline && !isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppThemeSystem.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppThemeSystem.darkBackgroundColor
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                isGroup ? 'Groupe ${index + 1}' : 'Contact ${index + 1}',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),
            ),
            if (hasFlame)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (isGroup)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(index + 3) * 10} membres',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.tertiaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          isGroup
              ? 'Vous: Dernier message du groupe...'
              : 'Dernier message ici...',
          style: context.textStyle(FontSizeType.body2).copyWith(
            color: AppThemeSystem.grey600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${index + 1}h',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
              ),
            ),
            if (index % 2 == 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isGroup
                      ? AppThemeSystem.tertiaryColor
                      : AppThemeSystem.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Get.snackbar(
            'Chat',
            isGroup
                ? 'Ouvrir le groupe ${index + 1}'
                : 'Ouvrir la conversation avec Contact ${index + 1}',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      ),
    );
  }
}
