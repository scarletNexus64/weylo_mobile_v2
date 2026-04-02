import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/user_profile_service.dart';

class UserProfileController extends GetxController {
  final _userProfileService = UserProfileService();

  // Observable variables
  final isLoading = false.obs;
  final Rxn<UserModel> user = Rxn<UserModel>();

  String? username;
  int? userId;

  @override
  void onInit() {
    super.onInit();

    // Get username or userId from route parameters or arguments
    final args = Get.arguments;

    if (args is UserModel) {
      // If a UserModel was passed directly
      user.value = args;
      username = args.username;
    } else if (args is Map) {
      // If arguments are passed as a map
      username = args['username'] as String?;
      userId = args['userId'] as int?;

      if (args['user'] != null) {
        user.value = args['user'] as UserModel;
      }
    }

    // If no user data was passed, load it
    if (user.value == null) {
      loadUserProfile();
    }
  }

  /// Load user profile
  Future<void> loadUserProfile() async {
    if (username == null && userId == null) {
      print('❌ [USER_PROFILE_CONTROLLER] Aucun username ou userId fourni');
      Get.back();
      Get.snackbar(
        'Erreur',
        'Profil introuvable',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      print('👤 [USER_PROFILE_CONTROLLER] Chargement du profil...');

      UserModel loadedUser;
      if (username != null) {
        loadedUser = await _userProfileService.getUserByUsername(username!);
      } else {
        loadedUser = await _userProfileService.getUserById(userId!);
      }

      user.value = loadedUser;

      print('✅ [USER_PROFILE_CONTROLLER] Profil chargé avec succès');
    } catch (e) {
      print('❌ [USER_PROFILE_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le profil',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to send message
  void sendMessage() {
    if (user.value != null) {
      Get.toNamed('/sendmessage/${user.value!.username}');
    }
  }

  /// Navigate to chat with user
  void startChat() {
    if (user.value != null) {
      // TODO: Implement chat navigation
      Get.snackbar(
        'Chat',
        'Fonctionnalité à venir',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
