import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/profile_view_model.dart';
import '../../../data/services/user_profile_service.dart';

class ProfileVisitorsController extends GetxController {
  final _userProfileService = UserProfileService();

  // Observable variables
  final isLoading = false.obs;
  final profileViews = <ProfileViewModel>[].obs;
  final currentPage = 1.obs;
  final hasMorePages = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfileViews();
  }

  /// Load profile views
  Future<void> loadProfileViews({bool refresh = false}) async {
    if (refresh) {
      currentPage.value = 1;
      profileViews.clear();
      hasMorePages.value = true;
    }

    if (!hasMorePages.value && !refresh) {
      return;
    }

    try {
      isLoading.value = true;
      print('👁️ [PROFILE_VISITORS_CONTROLLER] Chargement des vues de profil (page: ${currentPage.value})');

      final views = await _userProfileService.getProfileViews(page: currentPage.value);

      if (views.isEmpty) {
        hasMorePages.value = false;
      } else {
        profileViews.addAll(views);
        currentPage.value++;
      }

      print('✅ [PROFILE_VISITORS_CONTROLLER] ${views.length} vues chargées');
    } catch (e) {
      print('❌ [PROFILE_VISITORS_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les visiteurs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh profile views
  Future<void> refreshProfileViews() async {
    await loadProfileViews(refresh: true);
  }

  /// Load more profile views
  void loadMore() {
    if (!isLoading.value && hasMorePages.value) {
      loadProfileViews();
    }
  }
}
