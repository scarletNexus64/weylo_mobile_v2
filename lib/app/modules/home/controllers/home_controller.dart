import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  // Tab controller
  late TabController tabController;

  // Current tab index
  final currentTabIndex = 0.obs;

  // Tab names
  final List<String> tabNames = ['Anonyme', 'Chat', 'Groupe', 'Feed', 'Profile'];

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
}
