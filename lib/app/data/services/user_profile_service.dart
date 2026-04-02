import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

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
}
