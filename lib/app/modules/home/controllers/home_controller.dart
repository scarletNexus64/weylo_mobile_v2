import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:weylo/app/modules/feeds/controllers/feeds_controller.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  // Scaffold key for drawer
  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Tab controller
  late TabController tabController;

  // Current tab index
  final currentTabIndex = 0.obs;

  // Tab names
  final List<String> tabNames = ['Anonyme', 'Chat', 'Groupe', 'Confession', 'Profile'];

  // Tab icons
  final List<IconData> tabIcons = [
    Icons.masks, // Icône pour Anonyme
    Icons.chat_bubble_rounded,
    Icons.groups_rounded, // Icône pour Groupe
    Icons.dynamic_feed_rounded,
    Icons.account_circle_rounded,
  ];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(() {
      currentTabIndex.value = tabController.index;
    });
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  // Change tab programmatically
  void changeTab(int index) {
    tabController.animateTo(index);
  }

  // Handle tab tap - scroll to top if tapping on same tab
  void handleTabTap(int index) {
    // If tapping on Feed/Confession tab (index 3) and already on it
    if (index == 3 && currentTabIndex.value == 3) {
      try {
        final confessionsController = Get.find<ConfessionsController>();
        confessionsController.scrollToTop();
      } catch (e) {
        // Controller not found or not initialized
        print('ConfessionsController not found: $e');
      }
    }
    // Always allow tab change
    tabController.animateTo(index);
  }

  // Open drawer
  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  // Close drawer
  void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }
}
