import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/profile_stats_model.dart';
import '../../../data/models/confession_model.dart';
import '../../../data/models/gift_model.dart';
import '../../../data/services/profile_service.dart';
import '../../../data/services/confession_service.dart';
import '../../../data/services/gift_service.dart';
import '../../../utils/image_editor_page.dart';

class ProfileController extends GetxController {
  final _profileService = ProfileService();
  final _confessionService = ConfessionService();
  final _giftService = GiftService();
  final _imagePicker = ImagePicker();

  // Observable variables
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final Rxn<UserModel> user = Rxn<UserModel>();
  final Rxn<ProfileStatsModel> stats = Rxn<ProfileStatsModel>();
  final shareLink = ''.obs;

  // Posts (confessions) and gifts
  final RxList<ConfessionModel> posts = <ConfessionModel>[].obs;
  final RxList<ConfessionModel> favorites = <ConfessionModel>[].obs;
  final RxList<GiftTransactionModel> sentGifts = <GiftTransactionModel>[].obs;
  final RxList<GiftTransactionModel> receivedGifts = <GiftTransactionModel>[].obs;
  final isLoadingPosts = false.obs;
  final isLoadingFavorites = false.obs;
  final isLoadingGifts = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    loadPosts();
    loadFavorites();
    loadGifts();
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

      // Refresh posts, favorites and gifts
      await Future.wait([
        loadPosts(),
        loadFavorites(),
        loadGifts(),
      ]);

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

  /// Load user's posts (sent confessions)
  Future<void> loadPosts() async {
    try {
      isLoadingPosts.value = true;
      print('📝 [PROFILE_CONTROLLER] Chargement des posts...');

      final response = await _confessionService.getSentConfessions(
        page: 1,
        perPage: 50, // Load more for profile grid
      );

      posts.value = response.confessions;
      print('✅ [PROFILE_CONTROLLER] ${posts.length} posts chargés');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur chargement posts: $e');
      // Don't show error to user, just log it
    } finally {
      isLoadingPosts.value = false;
    }
  }

  /// Load user's favorite confessions
  Future<void> loadFavorites() async {
    try {
      isLoadingFavorites.value = true;
      print('⭐ [PROFILE_CONTROLLER] Chargement des favoris...');

      final response = await _confessionService.getFavoriteConfessions(
        page: 1,
        perPage: 50,
      );

      favorites.value = response.confessions;

      // Log deleted confessions for debugging
      final deletedCount = favorites.where((c) => c.isDeleted).length;
      print('✅ [PROFILE_CONTROLLER] ${favorites.length} favoris chargés ($deletedCount supprimés)');

      if (deletedCount > 0) {
        final deletedIds = favorites.where((c) => c.isDeleted).map((c) => c.id).toList();
        print('   IDs supprimés: $deletedIds');
      }
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur chargement favoris: $e');
      // Don't show error to user, just log it
    } finally {
      isLoadingFavorites.value = false;
    }
  }

  /// Load user's gifts (sent and received)
  Future<void> loadGifts() async {
    try {
      isLoadingGifts.value = true;
      print('🎁 [PROFILE_CONTROLLER] Chargement des cadeaux...');

      // Load both sent and received gifts
      final results = await Future.wait([
        _giftService.getSentGifts(page: 1, perPage: 50),
        _giftService.getReceivedGifts(page: 1, perPage: 50),
      ]);

      sentGifts.value = results[0].gifts;
      receivedGifts.value = results[1].gifts;

      print('✅ [PROFILE_CONTROLLER] ${sentGifts.length} cadeaux envoyés, ${receivedGifts.length} reçus');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur chargement cadeaux: $e');
      // Don't show error to user, just log it
    } finally {
      isLoadingGifts.value = false;
    }
  }

  /// Edit an image using ImageEditorPage
  Future<File?> _editImage(String imagePath) async {
    try {
      final editedImage = await Get.to<File?>(
        () => ImageEditorPage(
          imagePath: imagePath,
          showEditOptions: true,
        ),
        fullscreenDialog: true,
      );

      return editedImage;
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur édition image: $e');
      return null;
    }
  }

  /// Upload avatar from camera
  Future<void> uploadAvatarFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final editedFile = await _editImage(image.path);
        if (editedFile != null) {
          await _uploadAvatar(editedFile);
        }
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
        imageQuality: 85,
      );

      if (image != null) {
        final editedFile = await _editImage(image.path);
        if (editedFile != null) {
          await _uploadAvatar(editedFile);
        }
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

  /// Upload cover photo from camera
  Future<void> uploadCoverFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final editedFile = await _editImage(image.path);
        if (editedFile != null) {
          await _uploadCoverPhoto(editedFile);
        }
      }
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur caméra cover: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la caméra',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload cover photo from gallery
  Future<void> uploadCoverFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final editedFile = await _editImage(image.path);
        if (editedFile != null) {
          await _uploadCoverPhoto(editedFile);
        }
      }
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur galerie cover: $e');
      Get.snackbar(
        'Erreur',
        'Impossible d\'accéder à la galerie',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Upload cover photo file
  Future<void> _uploadCoverPhoto(File imageFile) async {
    try {
      isLoading.value = true;
      print('📤 [PROFILE_CONTROLLER] Upload de la cover photo...');

      final coverPhotoUrl = await _profileService.uploadCoverPhoto(imageFile);

      // Refresh dashboard to get updated user data
      await loadDashboard();

      Get.snackbar(
        'Succès',
        'Photo de couverture mise à jour',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Cover photo uploadée: $coverPhotoUrl');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur upload cover: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la photo de couverture',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete cover photo
  Future<void> deleteCoverPhoto() async {
    try {
      isLoading.value = true;
      print('🗑️ [PROFILE_CONTROLLER] Suppression de la cover photo...');

      await _profileService.deleteCoverPhoto();

      // Refresh dashboard to get updated user data
      await loadDashboard();

      Get.snackbar(
        'Succès',
        'Photo de couverture supprimée',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Cover photo supprimée');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur suppression cover: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la photo de couverture',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show cover photo picker options
  void showCoverPhotoPicker() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                  uploadCoverFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir dans la galerie'),
                onTap: () {
                  Get.back();
                  uploadCoverFromGallery();
                },
              ),
              // Afficher "Supprimer" seulement si l'utilisateur a uploadé une vraie cover photo
              if (user.value?.hasRealCoverPhoto ?? false)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Get.back();
                    deleteCoverPhoto();
                  },
                ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  /// Show avatar picker options
  void showAvatarPicker() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
              // Afficher "Supprimer" seulement si l'utilisateur a uploadé une vraie photo
              if (user.value?.hasRealAvatar ?? false)
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
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
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

  /// Mark a favorite confession as deleted locally
  void markFavoriteAsDeleted(int confessionId) {
    final index = favorites.indexWhere((c) => c.id == confessionId);
    if (index != -1) {
      favorites[index] = favorites[index].copyWith(isDeleted: true);
      favorites.refresh();
      print('⚠️ [PROFILE_CONTROLLER] Favori $confessionId marqué comme supprimé');
    }
  }

  /// Remove a deleted favorite from the list (after user confirmation)
  Future<void> removeFavorite(int confessionId) async {
    try {
      print('🗑️ [PROFILE_CONTROLLER] Suppression du favori $confessionId...');

      // Toggle favorite on the server (remove from favorites)
      await _confessionService.toggleFavorite(confessionId);

      // Remove from local list
      favorites.removeWhere((c) => c.id == confessionId);
      favorites.refresh();

      Get.snackbar(
        'Supprimé',
        'La confession a été retirée de vos favoris',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ [PROFILE_CONTROLLER] Favori supprimé de la liste');
    } catch (e) {
      print('❌ [PROFILE_CONTROLLER] Erreur suppression favori: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de retirer le favori',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
