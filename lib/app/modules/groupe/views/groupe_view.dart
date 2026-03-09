import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/group_details_modal.dart';

import '../controllers/groupe_controller.dart';
import '../../groupe_detail/views/groupe_detail_view.dart';
import '../../groupe_detail/bindings/groupe_detail_binding.dart';
import 'create_group_view.dart';

class GroupeView extends GetView<GroupeController> {
  const GroupeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
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
        ),
        // FAB pour créer un groupe
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).viewPadding.bottom + 16,
          child: FloatingActionButton(
            onPressed: () {
              Get.to(
                () => const CreateGroupView(),
                transition: Transition.downToUp,
                duration: const Duration(milliseconds: 300),
              );
            },
            backgroundColor: AppThemeSystem.tertiaryColor,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
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

    return Obx(() {
      // État de chargement
      if (controller.isLoadingMyGroups.value && controller.myGroups.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // État d'erreur
      if (controller.hasErrorMyGroups.value && controller.myGroups.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Erreur de chargement', style: context.textStyle(FontSizeType.body1)),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: controller.refreshMyGroups,
                child: Text('Réessayer'),
              ),
            ],
          ),
        );
      }

      // État vide
      if (controller.myGroups.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun groupe',
                style: context.textStyle(FontSizeType.h3),
              ),
              SizedBox(height: 8),
              Text(
                'Rejoignez ou créez un groupe pour commencer',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return Stack(
        children: [
          // ListView with RefreshIndicator
          RefreshIndicator(
            onRefresh: controller.refreshMyGroups,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
              itemCount: controller.myGroups.length + (controller.canLoadMoreMyGroups.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Item de chargement pour la pagination
                if (index == controller.myGroups.length) {
                  controller.loadMoreMyGroups();
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final group = controller.myGroups[index];
                return _buildGroupCardFromModel(context, group);
              },
            ),
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
    });
  }

  // Discover Groups View
  Widget _buildDiscoverGroupsView(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Hauteur de la recherche + catégories pour le padding
    final headerHeight = 60.0 + 45.0 + (context.elementSpacing * 1.5);

    return Obx(() {
      // État de chargement
      final isLoading = controller.isLoadingDiscoverGroups.value && controller.discoverGroups.isEmpty;
      final hasError = controller.hasErrorDiscoverGroups.value && controller.discoverGroups.isEmpty;
      final isEmpty = controller.discoverGroups.isEmpty;

      return Stack(
        children: [
          // Groups list - SCROLLABLE avec padding en haut
          Positioned.fill(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Erreur de chargement', style: context.textStyle(FontSizeType.body1)),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: controller.refreshDiscoverGroups,
                              child: Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.explore_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun groupe à découvrir',
                                  style: context.textStyle(FontSizeType.h3),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Revenez plus tard pour découvrir de nouveaux groupes',
                                  style: context.textStyle(FontSizeType.body2).copyWith(
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: controller.refreshDiscoverGroups,
                            child: ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                context.horizontalPadding,
                                headerHeight,
                                context.horizontalPadding,
                                context.elementSpacing,
                              ),
                              itemCount: controller.discoverGroups.length + (controller.canLoadMoreDiscoverGroups.value ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Item de chargement pour la pagination
                                if (index == controller.discoverGroups.length) {
                                  controller.loadMoreDiscoverGroups();
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final group = controller.discoverGroups[index];
                                return _buildDiscoverGroupCardFromModel(context, group);
                              },
                            ),
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
                // Search bar simple et moderne avec bouton code d'invitation
                Container(
                  margin: EdgeInsets.fromLTRB(
                    context.horizontalPadding,
                    context.elementSpacing * 0.5,
                    context.horizontalPadding,
                    context.elementSpacing * 0.5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher des groupes...',
                            hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                              color: AppThemeSystem.grey600,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                              size: 20,
                            ),
                            suffixIcon: Obx(() {
                              if (controller.searchQuery.value.isNotEmpty) {
                                return IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    controller.searchGroups('');
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            }),
                            filled: true,
                            fillColor: isDark
                                ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                                : AppThemeSystem.grey100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                                    : AppThemeSystem.grey200,
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                                    : AppThemeSystem.grey200,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppThemeSystem.tertiaryColor,
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          style: context.textStyle(FontSizeType.body2),
                          onChanged: (value) {
                            controller.searchGroups(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton pour rejoindre par code d'invitation
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppThemeSystem.tertiaryColor,
                              AppThemeSystem.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _showJoinByCodeDialog(context);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.vpn_key_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter chips
                Container(
                  height: 45,
                  margin: EdgeInsets.only(bottom: context.elementSpacing * 0.5),
                  child: Obx(() {
                    if (controller.isLoadingCategories.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
                      children: [
                        _buildFilterChipWidget(
                          context,
                          'Tous',
                          null,
                          controller.selectedCategoryId.value == null,
                        ),
                        const SizedBox(width: 8),
                        ...controller.categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChipWidget(
                              context,
                              category.name,
                              category.id,
                              controller.selectedCategoryId.value == category.id,
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        ],
      );
    });
  }

  // Build Group Card from GroupModel
  Widget _buildGroupCardFromModel(BuildContext context, group) {
    final lastMessage = group.lastMessage;

    return Container(
      margin: EdgeInsets.only(bottom: context.elementSpacing),
      child: ListTile(
        contentPadding: EdgeInsets.all(context.elementSpacing / 2),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppThemeSystem.tertiaryColor,
          child: const Icon(
            Icons.group_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: context.textStyle(FontSizeType.body1).copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppThemeSystem.blackColor,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  group.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                  size: 12,
                  color: AppThemeSystem.grey600,
                ),
                const SizedBox(width: 4),
                Text(
                  group.isPublic ? 'Public' : 'Privé',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${group.membersCount} membres',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.tertiaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
          lastMessage?.content ?? 'Aucun message',
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
              _formatGroupTimestamp(lastMessage?.createdAt),
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
              ),
            ),
            if (group.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppThemeSystem.tertiaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${group.unreadCount}',
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
          GroupDetailsModal.show(context, group, controller);
        },
      ),
    );
  }

  // Build Discover Group Card from GroupModel
  Widget _buildDiscoverGroupCardFromModel(BuildContext context, group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        GroupDetailsModal.show(context, group, controller);
      },
      child: Container(
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
            color: isDark
                ? AppThemeSystem.grey700.withValues(alpha: 0.3)
                : AppThemeSystem.grey300.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppThemeSystem.tertiaryColor,
            child: Icon(
              Icons.group_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: context.textStyle(FontSizeType.body1).copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppThemeSystem.blackColor,
                  ),
                ),
                if (group.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    group.description!,
                    style: context.textStyle(FontSizeType.body2).copyWith(
                      color: AppThemeSystem.grey600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                            '${group.membersCount}',
                            style: context.textStyle(FontSizeType.caption).copyWith(
                              color: AppThemeSystem.tertiaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      group.isPublic ? Icons.public_rounded : Icons.lock_rounded,
                      size: 14,
                      color: AppThemeSystem.grey600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      group.isPublic ? 'Public' : 'Privé',
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
          // Join Button - Afficher différent si déjà membre ou si peut rejoindre
          _buildJoinButton(context, group),
        ],
        ),
      ),
    );
  }

  String _formatGroupTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}j';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}min';
    } else {
      return 'maintenant';
    }
  }

  // Show Join by Code Dialog
  void _showJoinByCodeDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController codeController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppThemeSystem.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titre
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppThemeSystem.tertiaryColor,
                          AppThemeSystem.secondaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.vpn_key_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rejoindre par code',
                      style: context.textStyle(FontSizeType.h3).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppThemeSystem.blackColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Description
              Text(
                'Entrez le code d\'invitation du groupe privé que vous souhaitez rejoindre.',
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: AppThemeSystem.grey600,
                ),
              ),
              const SizedBox(height: 20),
              // TextField pour le code
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  hintText: 'Code d\'invitation',
                  hintStyle: context.textStyle(FontSizeType.body2).copyWith(
                    color: AppThemeSystem.grey600,
                  ),
                  prefixIcon: Icon(
                    Icons.pin_rounded,
                    color: AppThemeSystem.tertiaryColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppThemeSystem.grey800.withValues(alpha: 0.4)
                      : AppThemeSystem.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppThemeSystem.grey700.withValues(alpha: 0.5)
                          : AppThemeSystem.grey200,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppThemeSystem.tertiaryColor,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: context.textStyle(FontSizeType.body2).copyWith(
                  color: isDark ? Colors.white : AppThemeSystem.blackColor,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
              ),
              const SizedBox(height: 24),
              // Boutons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Get.back();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppThemeSystem.grey700,
                        side: BorderSide(
                          color: isDark
                              ? AppThemeSystem.grey700
                              : AppThemeSystem.grey300,
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Annuler',
                        style: context.textStyle(FontSizeType.button).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppThemeSystem.tertiaryColor,
                            AppThemeSystem.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final code = codeController.text.trim();
                            if (code.isNotEmpty) {
                              Get.back();
                              final success = await controller.joinGroupByCode(code);
                              if (success) {
                                codeController.dispose();
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            child: Text(
                              'Rejoindre',
                              style: context.textStyle(FontSizeType.button).copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build Join Button Widget
  Widget _buildJoinButton(BuildContext context, group) {
    // Si l'utilisateur est déjà membre
    if (group.isMember == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppThemeSystem.grey600.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeSystem.grey600.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppThemeSystem.grey600, size: 18),
            const SizedBox(width: 4),
            Text(
              'Membre',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Si le groupe ne peut pas accepter plus de membres
    if (group.canJoin == false) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppThemeSystem.grey600.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeSystem.grey600.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, color: AppThemeSystem.grey600, size: 18),
            const SizedBox(width: 4),
            Text(
              'Complet',
              style: context.textStyle(FontSizeType.caption).copyWith(
                color: AppThemeSystem.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Si le groupe est privé, demander le code
    if (group.isPublic == false) {
      return Container(
        decoration: BoxDecoration(
          color: AppThemeSystem.secondaryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemeSystem.secondaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Ouvrir le dialog pour entrer le code
              _showJoinByCodeDialog(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_rounded, color: AppThemeSystem.secondaryColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Code requis',
                    style: context.textStyle(FontSizeType.caption).copyWith(
                      color: AppThemeSystem.secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Bouton pour rejoindre (groupe public)
    return Container(
      decoration: BoxDecoration(
        color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppThemeSystem.tertiaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Rejoindre le groupe public directement
            await controller.joinGroupById(group.id);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppThemeSystem.tertiaryColor, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Rejoindre',
                  style: context.textStyle(FontSizeType.caption).copyWith(
                    color: AppThemeSystem.tertiaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Filter Chip Widget
  Widget _buildFilterChipWidget(
    BuildContext context,
    String label,
    int? categoryId,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        controller.selectCategory(categoryId);
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
          color: isDark
              ? AppThemeSystem.grey700.withValues(alpha: 0.3)
              : AppThemeSystem.grey300.withValues(alpha: 0.5),
          width: 1,
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
