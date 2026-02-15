import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';

import '../controllers/groupe_controller.dart';
import '../../groupe_detail/views/groupe_detail_view.dart';
import '../../groupe_detail/bindings/groupe_detail_binding.dart';

class GroupeView extends GetView<GroupeController> {
  const GroupeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Segmented Button Filter (comme ChatView)
        _buildFilterSegment(context),
        // Content
        Expanded(
          child: Obx(() {
            final currentTab = controller.selectedTab.value;

            if (currentTab == GroupTab.myGroups) {
              return _buildMyGroupsView(context);
            } else {
              return _buildDiscoverGroupsView(context);
            }
          }),
        ),
      ],
    );
  }

  Widget _buildFilterSegment(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Container(
      margin: EdgeInsets.fromLTRB(
        context.horizontalPadding,
        context.elementSpacing,
        context.horizontalPadding,
        context.elementSpacing * 0.7,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppThemeSystem.grey800.withValues(alpha: 0.4)
            : AppThemeSystem.grey100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppThemeSystem.grey700.withValues(alpha: 0.5)
              : AppThemeSystem.grey200,
          width: 1,
        ),
      ),
      child: Obx(() {
        return Row(
          children: [
            _buildFilterButton(
              context: context,
              label: 'Mes groupes',
              tab: GroupTab.myGroups,
              isSelected: controller.selectedTab.value == GroupTab.myGroups,
              isDark: isDark,
              deviceType: deviceType,
            ),
            _buildFilterButton(
              context: context,
              label: 'Découvrir',
              tab: GroupTab.discover,
              isSelected: controller.selectedTab.value == GroupTab.discover,
              isDark: isDark,
              deviceType: deviceType,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterButton({
    required BuildContext context,
    required String label,
    required GroupTab tab,
    required bool isSelected,
    required bool isDark,
    required DeviceType deviceType,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setTab(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: deviceType == DeviceType.mobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      AppThemeSystem.tertiaryColor,
                      AppThemeSystem.secondaryColor,
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: context.textStyle(FontSizeType.body2).copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // My Groups View
  Widget _buildMyGroupsView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // ListView
        ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          itemCount: 8,
          itemBuilder: (context, index) {
            return _buildGroupCard(context, index);
          },
        ),
        // Waterfall Gradient Effect
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                        : AppThemeSystem.grey200.withValues(alpha: 0.4),
                    isDark
                        ? AppThemeSystem.grey700.withValues(alpha: 0.15)
                        : AppThemeSystem.grey200.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Discover Groups View
  Widget _buildDiscoverGroupsView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hauteur de la recherche + catégories pour le padding
    final headerHeight = 60.0 + 45.0 + (context.elementSpacing * 1.5);

    return Stack(
      children: [
        // Groups list - SCROLLABLE avec padding en haut
        Positioned.fill(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              context.horizontalPadding,
              headerHeight, // Padding pour éviter que les items soient cachés
              context.horizontalPadding,
              context.elementSpacing,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return _buildDiscoverGroupCard(context, index);
            },
          ),
        ),

        // Header FIXE (Recherche + Catégories)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: isDark ? AppThemeSystem.darkBackgroundColor : Colors.white,
            child: Column(
              children: [
                // Search bar simple et moderne
                Container(
                  margin: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    context.elementSpacing * 0.5,
                    context.horizontalPadding,
                    context.elementSpacing * 0.5,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                        : AppThemeSystem.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                        size: 20,
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
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          style: context.textStyle(FontSizeType.body2),
                          onChanged: (value) {
                            // TODO: Implement search functionality
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                Container(
                  height: 45,
                  margin: EdgeInsets.only(bottom: context.elementSpacing * 0.5),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Filter Chip
  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Get.snackbar(
          'Filtre',
          'Filtrer par $label',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppThemeSystem.tertiaryColor,
          colorText: Colors.white,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppThemeSystem.tertiaryColor,
                    AppThemeSystem.secondaryColor,
                  ],
                )
              : null,
          color: isSelected
              ? null
              : isDark
                  ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                  : AppThemeSystem.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppThemeSystem.tertiaryColor.withValues(alpha: 0.5)
                : (isDark
                    ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                    : AppThemeSystem.grey300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: context.textStyle(FontSizeType.body2).copyWith(
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppThemeSystem.grey300 : AppThemeSystem.grey700),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Discover Group Card
  Widget _buildDiscoverGroupCard(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ['Technologie', 'Sports', 'Musique', 'Éducation', 'Gaming'];
    final category = categories[index % categories.length];

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      padding: EdgeInsets.all(context.elementSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppThemeSystem.darkCardColor,
                  AppThemeSystem.darkCardColor.withValues(alpha: 0.8),
                ]
              : [
                  Colors.white,
                  AppThemeSystem.grey100.withValues(alpha: 0.3),
                ],
        ),
        borderRadius: context.borderRadius(BorderRadiusType.medium),
        border: Border.all(
          color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Group Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeSystem.tertiaryColor,
                  AppThemeSystem.secondaryColor,
                ],
              ),
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: isDark
                  ? AppThemeSystem.darkCardColor
                  : Colors.white,
              child: Icon(
                Icons.group_rounded,
                color: AppThemeSystem.tertiaryColor,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Group Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Groupe découverte ${index + 1}',
                        style: context.textStyle(FontSizeType.body1).copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppThemeSystem.blackColor,
                        ),
                      ),
                    ),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                            AppThemeSystem.secondaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: context.textStyle(FontSizeType.caption).copyWith(
                          color: AppThemeSystem.tertiaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Une communauté active pour partager et discuter...',
                  style: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_rounded,
                            size: 14,
                            color: AppThemeSystem.tertiaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(index + 10) * 50}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.tertiaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.public_rounded,
                      size: 14,
                      color: AppThemeSystem.grey600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Public',
                      style: context.textStyle(FontSizeType.caption).copyWith(
                        color: AppThemeSystem.grey600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Join Button with improved gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppThemeSystem.tertiaryColor,
                  AppThemeSystem.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Get.snackbar(
                    'Rejoindre',
                    'Rejoindre le groupe ${index + 1}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppThemeSystem.tertiaryColor,
                    colorText: Colors.white,
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

  Widget _buildGroupCard(BuildContext context, int index) {
    final hasUnseenStory = index % 4 != 0;
    final memberCount = (index + 3) * 10;

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnseenStory
                      ? AppThemeSystem.tertiaryColor
                      : AppThemeSystem.grey600.withValues(alpha: 0.3),
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppThemeSystem.tertiaryColor,
                child: const Icon(
                  Icons.group_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Groupe ${index + 1}',
                style: context.textStyle(FontSizeType.body1).copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : AppThemeSystem.blackColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$memberCount membres',
                style: context.textStyle(FontSizeType.caption).copyWith(
                  color: AppThemeSystem.tertiaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Vous: Dernier message du groupe...',
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
                  color: AppThemeSystem.tertiaryColor,
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
          final groupName = 'Groupe ${index + 1}';
          final groupId = index.toString();

          Get.to(
            () => const GroupeDetailView(),
            binding: GroupeDetailBinding(),
            arguments: {
              'groupName': groupName,
              'groupId': groupId,
              'memberCount': memberCount,
            },
            transition: Transition.rightToLeft,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }
}
