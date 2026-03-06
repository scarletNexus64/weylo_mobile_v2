import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/profile_stats_model.dart';
import '../../../data/services/profile_service.dart';

class ProfileController extends GetxController {
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();

  // Observable variables
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rxn<ProfileStatsModel> stats = Rxn<ProfileStatsModel>();
  final shareLink = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Load dashboard data (user + stats)
  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      print('📊 [PROFILE_CONTROLLER] Chargement du dashboard...');

      final data = await _profileService.getDashboard();

      user.value = data['user'] as UserModel;
      stats.value = data['stats'] as ProfileStatsModel;
      shareLink.value = data['share_link'] as String;

      print('✅ [PROFILE_CONTROLLER] Dashboard chargé avec succès');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger le profil',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh dashboard
  Future<void> refreshDashboard() async {
    try {
      isRefreshing.value = true;
      print('🔄 [PROFILE_CONTROLLER] Rafraîchissement du dashboard...');

      final data = await _profileService.getDashboard();

      user.value = data['user'] as UserModel;
      stats.value = data['stats'] as ProfileStatsModel;
      shareLink.value = data['share_link'] as String;

      print('✅ [PROFILE_CONTROLLER] Dashboard rafraîchi');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rafraîchir le profil',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Upload avatar from camera
  Future<void> uploadAvatarFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur caméra: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la caméra',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload avatar from gallery
  Future<void> uploadAvatarFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadAvatar(File(image.path));
      }
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur galerie: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la galerie',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload avatar file
  Future<void> _uploadAvatar(File imageFile) async {
    try {
      isLoading.value = true;
      print('📤 [PROFILE_CONTROLLER] Upload de l\'avatar...');

      final avatarUrl = await _profileService.uploadAvatar(imageFile);

      // Refresh dashboard to get updated user data
      await loadDashboard();

      Get.snackbar(
        'Succès',
        'Photo de profil mise à jour',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Avatar uploadé: $avatarUrl');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur upload: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la photo',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    try {
      isLoading.value = true;
      print('🗑️ [PROFILE_CONTROLLER] Suppression de l\'avatar...');

      await _profileService.deleteAvatar();

      // Refresh dashboard to get updated user data
      await loadDashboard();

      Get.snackbar(
        'Succès',
        'Photo de profil supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Avatar supprimé');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur suppression: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la photo',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show avatar picker options
  void showAvatarPicker() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () {
                Get.back();
                uploadAvatarFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Get.back();
                uploadAvatarFromGallery();
              },
            ),
            if (user.value?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Share profile link
  Future<void> shareProfile() async {
    try {
      final data = await _profileService.getShareLink();
      final link = data['link'] as String;
      final text = data['share_text'] as String;

      // TODO: Implement share functionality using share_plus package
      Get.snackbar(
        'Partager',
        '$text\n$link',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur partage: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de récupérer le lien de partage',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? phone,
    String? bio,
  }) async {
    try {
      isLoading.value = true;
      print('✏️ [PROFILE_CONTROLLER] Mise à jour du profil...');

      final updatedUser = await _profileService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        phone: phone,
        bio: bio,
      );

      user.value = updatedUser;

      Get.snackbar(
        'Succès',
        'Profil mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Profil mis à jour');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur mise à jour: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le profil',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
