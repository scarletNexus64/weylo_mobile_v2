import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';
import '../models/profile_view_model.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final _api = ApiService();

  /// Get public user profile by username
  Future<UserModel> getUserByUsername(String username) async {
    try {
      print('👤 [USER_PROFILE_SERVICE] Récupération du profil: $username');

      final response = await _api.get('${ApiConfig.users}/by-username/$username');

      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      print('✅ [USER_PROFILE_SERVICE] Profil récupéré avec succès');

      return user;
    } catch (e) {
      print('❌ [USER_PROFILE_SERVICE] Erreur lors de la récupération du profil: $e');
      rethrow;
    }
  }

  /// Get public user profile by ID
  Future<UserModel> getUserById(int userId) async {
    try {
      print('👤 [USER_PROFILE_SERVICE] Récupération du profil par ID: $userId');

      final response = await _api.get('${ApiConfig.users}/by-id/$userId');

      final userData = response.data['user'];
      final user = UserModel.fromJson(userData);

      print('✅ [USER_PROFILE_SERVICE] Profil récupéré avec succès');

      return user;
    } catch (e) {
      print('❌ [USER_PROFILE_SERVICE] Erreur lors de la récupération du profil: $e');
      rethrow;
    }
  }

  /// Record profile view
  Future<void> recordProfileView(int viewedUserId) async {
    try {
      print('👁️ [USER_PROFILE_SERVICE] Enregistrement de la vue de profil: $viewedUserId');

      await _api.post(
        ApiConfig.profileViews,
        data: {
          'viewed_user_id': viewedUserId,
        },
      );

      print('✅ [USER_PROFILE_SERVICE] Vue de profil enregistrée avec succès');
    } catch (e) {
      print('❌ [USER_PROFILE_SERVICE] Erreur lors de l\'enregistrement de la vue: $e');
      // Ne pas lancer d'exception pour éviter de bloquer l'affichage du profil
    }
  }

  /// Get profile views (who viewed my profile)
  Future<List<ProfileViewModel>> getProfileViews({int page = 1}) async {
    try {
      print('👁️ [USER_PROFILE_SERVICE] Récupération des vues de profil (page: $page)');
      print('👁️ [USER_PROFILE_SERVICE] URL: ${ApiConfig.baseUrl}${ApiConfig.profileViews}');

      final response = await _api.get(
        ApiConfig.profileViews,
        queryParameters: {'page': page},
      );

      print('👁️ [USER_PROFILE_SERVICE] Réponse reçue: ${response.data.toString().substring(0, 200)}...');

      if (response.data['views'] == null) {
        print('⚠️ [USER_PROFILE_SERVICE] La clé "views" est null dans la réponse');
        return [];
      }

      final viewsList = response.data['views'] as List;
      print('👁️ [USER_PROFILE_SERVICE] Nombre de vues dans la réponse: ${viewsList.length}');

      final views = viewsList
          .map((view) => ProfileViewModel.fromJson(view as Map<String, dynamic>))
          .toList();

      print('✅ [USER_PROFILE_SERVICE] ${views.length} vues de profil récupérées');

      return views;
    } catch (e, stackTrace) {
      print('❌ [USER_PROFILE_SERVICE] Erreur lors de la récupération des vues: $e');
      print('❌ [USER_PROFILE_SERVICE] StackTrace: $stackTrace');
      rethrow;
    }
  }
}
