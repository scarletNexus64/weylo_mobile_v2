import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';
import '../models/profile_stats_model.dart';
import 'storage_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final _api = ApiService();
  final _storage = StorageService();

  /// Get user dashboard (profile + stats)
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      print('📊 [PROFILE_SERVICE] Récupération du dashboard...');
      final response = await _api.get(ApiConfig.dashboard);

      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      final statsData = response.data['stats'];
      final stats = ProfileStatsModel.fromJson(statsData);

      final shareLink = response.data['share_link'];

      // Update user in storage
      await _storage.updateUser(user);

      print('✅ [PROFILE_SERVICE] Dashboard récupéré avec succès');

      return {
        'user': user,
        'stats': stats,
        'share_link': shareLink,
      };
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la récupération du dashboard: $e');
      rethrow;
    }
  }

  /// Get user statistics only
  Future<ProfileStatsModel> getStats() async {
    try {
      print('📊 [PROFILE_SERVICE] Récupération des statistiques...');
      final response = await _api.get(ApiConfig.stats);

      final statsData = response.data['stats'];
      final stats = ProfileStatsModel.fromJson(statsData);

      print('✅ [PROFILE_SERVICE] Statistiques récupérées avec succès');
      return stats;
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la récupération des stats: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? bio,
    String? username,
  }) async {
    try {
      print('✏️ [PROFILE_SERVICE] Mise à jour du profil...');
      final response = await _api.put(
        ApiConfig.updateProfile,
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (username != null) 'username': username,
        },
      );

      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      // Update user in storage
      await _storage.updateUser(user);

      print('✅ [PROFILE_SERVICE] Profil mis à jour avec succès');
      return user;
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la mise à jour du profil: $e');
      rethrow;
    }
  }

  /// Upload avatar
  Future<String> uploadAvatar(File imageFile) async {
    try {
      print('📤 [PROFILE_SERVICE] Upload de l\'avatar...');

      // Create FormData
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'avatar.jpg',
        ),
      });

      final response = await _api.post(
        ApiConfig.uploadAvatar,
        data: formData,
      );

      final avatarUrl = response.data['avatar_url'];

      print('✅ [PROFILE_SERVICE] Avatar uploadé avec succès');
      return avatarUrl;
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de l\'upload de l\'avatar: $e');
      rethrow;
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar() async {
    try {
      print('🗑️ [PROFILE_SERVICE] Suppression de l\'avatar...');
      await _api.delete(ApiConfig.deleteAvatar);
      print('✅ [PROFILE_SERVICE] Avatar supprimé avec succès');
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la suppression de l\'avatar: $e');
      rethrow;
    }
  }

  /// Get share link
  Future<Map<String, dynamic>> getShareLink() async {
    try {
      print('🔗 [PROFILE_SERVICE] Récupération du lien de partage...');
      final response = await _api.get(ApiConfig.shareLink);

      print('✅ [PROFILE_SERVICE] Lien de partage récupéré');
      return {
        'link': response.data['link'],
        'username': response.data['username'],
        'share_text': response.data['share_text'],
        'share_options': response.data['share_options'],
      };
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la récupération du lien: $e');
      rethrow;
    }
  }

  /// Update settings
  Future<Map<String, dynamic>> updateSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      print('⚙️ [PROFILE_SERVICE] Mise à jour des paramètres...');
      final response = await _api.put(
        ApiConfig.updateSettings,
        data: settings,
      );

      final updatedSettings = response.data['settings'];
      print('✅ [PROFILE_SERVICE] Paramètres mis à jour avec succès');
      return updatedSettings;
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la mise à jour des paramètres: $e');
      rethrow;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔒 [PROFILE_SERVICE] Changement de mot de passe...');
      await _api.put(
        ApiConfig.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
      print('✅ [PROFILE_SERVICE] Mot de passe changé avec succès');
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors du changement de mot de passe: $e');
      rethrow;
    }
  }

  /// Delete account
  Future<void> deleteAccount(String password, {String? reason}) async {
    try {
      print('🗑️ [PROFILE_SERVICE] Suppression du compte...');
      await _api.delete(
        '/users/account',
        data: {
          'password': password,
          if (reason != null) 'reason': reason,
        },
      );

      // Clear local storage
      await _storage.clearAuthData();
      print('✅ [PROFILE_SERVICE] Compte supprimé avec succès');
    } catch (e) {
      print('❌ [PROFILE_SERVICE] Erreur lors de la suppression du compte: $e');
      rethrow;
    }
  }

  /// Get user from local storage
  UserModel? getCurrentUser() {
    return _storage.getUser();
  }
}
