import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/modules/anonymepage/views/anonymepage_view.dart';
import 'package:weylo/app/modules/chat/views/chat_view.dart';
import 'package:weylo/app/modules/feeds/views/feeds_view.dart';
import 'package:weylo/app/modules/groupe/views/groupe_view.dart';
import 'package:weylo/app/modules/profile/views/profile_view.dart';
import 'package:weylo/app/widgets/app_drawer.dart';
import 'package:weylo/app/widgets/app_theme_system.dart';
import 'package:weylo/app/widgets/burning_flame_icon.dart';
import 'package:weylo/app/widgets/custom_icons.dart';
import 'package:weylo/app/widgets/user_profile_header.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const AppDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: false,
              pinned: true,
              snap: false,
              stretch: false,
              elevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              backgroundColor: isDark
                  ? AppThemeSystem.darkCardColor
                  : Colors.white,
              toolbarHeight: deviceType == DeviceType.mobile ? 64 : 72,
              titleSpacing: 0,
              forceElevated: true,
              primary: true,
              // Utilisation de flexibleSpace pour un contrôle total du layout
              flexibleSpace: SafeArea(
                child: Container(
                  height: deviceType == DeviceType.mobile ? 64 : 72,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding,
                  ),
                  child: Row(
                    children: [
                      // Menu hamburger et avatar badge
                      Expanded(
                        child: UserProfileHeader(
                          onTap: () {
                            controller.scaffoldKey.currentState?.openDrawer();
                          },
                        ),
                      ),

                      // Icônes d'action alignées à droite
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search icon button
                          _buildIconButton(
                            context: context,
                            icon: CustomIcons.search(
                              size: deviceType == DeviceType.mobile ? 22 : 26,
                              color: isDark ? Colors.white : AppThemeSystem.blackColor,
                            ),
                            onPressed: () {
                              Get.snackbar(
                                'Recherche',
                                'Fonctionnalité à venir',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          ),

                          SizedBox(width: context.elementSpacing * 0.5),

                          // Flame icon animée avec badge
                          _buildIconButtonWithBadge(
                            context: context,
                            icon: BurningFlameIcon(
                              size: deviceType == DeviceType.mobile ? 28 : 34,
                              color: const Color(0xFFFF6B35),
                            ),
                            badgeCount: '5',
                            badgeColor: const LinearGradient(
                              colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
                            ),
                            onPressed: () {
                              Get.snackbar(
                                'Flammes',
                                'Vous avez 5 conversations actives',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          ),

                          SizedBox(width: context.elementSpacing * 0.5),

                          // Notifications button avec badge
                          _buildIconButtonWithBadge(
                            context: context,
                            icon: CustomIcons.notifications(
                              size: deviceType == DeviceType.mobile ? 22 : 26,
                              color: isDark ? Colors.white : AppThemeSystem.blackColor,
                            ),
                            badgeCount: '3',
                            badgeColor: null,
                            onPressed: () {
                              Get.snackbar(
                                'Notifications',
                                'Aucune nouvelle notification',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(
                  deviceType == DeviceType.mobile ? 72 : 80,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppThemeSystem.darkCardColor
                        : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? AppThemeSystem.grey800.withValues(alpha: 0.6)
                            : AppThemeSystem.grey200,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.horizontalPadding * 0.5,
                  ),
                  child: TabBar(
                    controller: controller.tabController,
                    onTap: controller.handleTabTap,
                    indicatorColor: AppThemeSystem.primaryColor,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppThemeSystem.primaryColor,
                          width: 3,
                        ),
                      ),
                    ),
                    labelColor: AppThemeSystem.primaryColor,
                    unselectedLabelColor: isDark
                        ? AppThemeSystem.grey400
                        : AppThemeSystem.grey600,
                    labelStyle: context.textStyle(FontSizeType.caption).copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: deviceType == DeviceType.mobile ? 11 : 13,
                    ),
                    unselectedLabelStyle: context.textStyle(FontSizeType.caption).copyWith(
                      fontWeight: FontWeight.normal,
                      fontSize: deviceType == DeviceType.mobile ? 11 : 13,
                    ),
                    tabs: [
                      // Anonyme - Nouvelle icône custom
                      Tab(
                        height: deviceType == DeviceType.mobile ? 64 : 72,
                        child: _AnimatedTabIcon(
                          controller: controller.tabController,
                          index: 0,
                          iconBuilder: (color) => CustomIcons.anonyme(
                            size: deviceType == DeviceType.mobile ? 24 : 28,
                            color: color,
                          ),
                          label: controller.tabNames[0],
                        ),
                      ),
                      // Chat - Nouvelle icône custom
                      Tab(
                        height: deviceType == DeviceType.mobile ? 64 : 72,
                        child: _AnimatedTabIcon(
                          controller: controller.tabController,
                          index: 1,
                          iconBuilder: (color) => CustomIcons.chat(
                            size: deviceType == DeviceType.mobile ? 24 : 28,
                            color: color,
                          ),
                          label: controller.tabNames[1],
                        ),
                      ),
                      // Groupe - Nouvelle icône custom
                      Tab(
                        height: deviceType == DeviceType.mobile ? 64 : 72,
                        child: _AnimatedTabIcon(
                          controller: controller.tabController,
                          index: 2,
                          iconBuilder: (color) => CustomIcons.groupe(
                            size: deviceType == DeviceType.mobile ? 24 : 28,
                            color: color,
                          ),
                          label: controller.tabNames[2],
                        ),
                      ),
                      // Feed - Nouvelle icône custom
                      Tab(
                        height: deviceType == DeviceType.mobile ? 64 : 72,
                        child: _AnimatedTabIcon(
                          controller: controller.tabController,
                          index: 3,
                          iconBuilder: (color) => CustomIcons.feed(
                            size: deviceType == DeviceType.mobile ? 24 : 28,
                            color: color,
                          ),
                          label: controller.tabNames[3],
                        ),
                      ),
                      // Profile - Nouvelle icône custom
                      Tab(
                        height: deviceType == DeviceType.mobile ? 64 : 72,
                        child: _AnimatedTabIcon(
                          controller: controller.tabController,
                          index: 4,
                          iconBuilder: (color) => CustomIcons.profile(
                            size: deviceType == DeviceType.mobile ? 24 : 28,
                            color: color,
                          ),
                          label: controller.tabNames[4],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: controller.tabController,
          children: const [
            AnonymepageView(),
            ChatView(),
            GroupeView(),
            ConfessionsView(),
            ProfileView(),
          ],
        ),
      ),
    );
  }

  /// Construit un bouton d'icône simple pour l'AppBar
  Widget _buildIconButton({
    required BuildContext context,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: icon,
      onPressed: onPressed,
      iconSize: context.deviceType == DeviceType.mobile ? 24 : 28,
      padding: EdgeInsets.all(context.deviceType == DeviceType.mobile ? 8 : 10),
      constraints: BoxConstraints(
        minWidth: context.deviceType == DeviceType.mobile ? 40 : 48,
        minHeight: context.deviceType == DeviceType.mobile ? 40 : 48,
      ),
    );
  }

  /// Construit un bouton d'icône avec badge pour l'AppBar
  Widget _buildIconButtonWithBadge({
    required BuildContext context,
    required Widget icon,
    required String badgeCount,
    required Gradient? badgeColor,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deviceType = context.deviceType;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: icon,
          onPressed: onPressed,
          iconSize: deviceType == DeviceType.mobile ? 24 : 28,
          padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 8 : 10),
          constraints: BoxConstraints(
            minWidth: deviceType == DeviceType.mobile ? 40 : 48,
            minHeight: deviceType == DeviceType.mobile ? 40 : 48,
          ),
        ),
        // Badge
        Positioned(
          right: deviceType == DeviceType.mobile ? 6 : 8,
          top: deviceType == DeviceType.mobile ? 6 : 8,
          child: Container(
            padding: EdgeInsets.all(deviceType == DeviceType.mobile ? 3 : 4),
            decoration: BoxDecoration(
              gradient: badgeColor,
              color: badgeColor == null ? AppThemeSystem.errorColor : null,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppThemeSystem.darkCardColor
                    : Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppThemeSystem.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              minWidth: deviceType == DeviceType.mobile ? 16 : 18,
              minHeight: deviceType == DeviceType.mobile ? 16 : 18,
            ),
            child: Center(
              child: Text(
                badgeCount,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: deviceType == DeviceType.mobile ? 9 : 10,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget d'icône de tab animé qui change de couleur selon la sélection
class _AnimatedTabIcon extends StatefulWidget {
  final TabController controller;
  final int index;
  final Widget Function(Color color) iconBuilder;
  final String label;

  const _AnimatedTabIcon({
    required this.controller,
    required this.index,
    required this.iconBuilder,
    required this.label,
  });

  @override
  State<_AnimatedTabIcon> createState() => _AnimatedTabIconState();
}

class _AnimatedTabIconState extends State<_AnimatedTabIcon> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.controller.index == widget.index;

    final color = isSelected
        ? AppThemeSystem.primaryColor
        : (isDark ? AppThemeSystem.grey400 : AppThemeSystem.grey600);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: context.deviceType == DeviceType.mobile ? 28 : 32,
          child: widget.iconBuilder(color),
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}