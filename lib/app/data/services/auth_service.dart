import 'package:get/get.dart';
import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'fcm_service.dart';
import 'conversation_state_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _api = ApiService();
  final _storage = StorageService();

  /// Register a new user (without saving to storage)
  Future<AuthResponseModel> register({
    required String firstName,
    String? lastName,
    required String phone,
    required String password,
    String? email,
    bool saveToStorage = false, // Ne pas sauvegarder par défaut
  }) async {
    print('🔐 [AUTH_SERVICE] Début de l\'inscription');
    print('👤 [AUTH_SERVICE] Prénom: $firstName, Téléphone: $phone');

    try {
      final response = await _api.post(
        ApiConfig.register,
        data: {
          'first_name': firstName,
          if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
          'phone': phone,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      print('✅ [AUTH_SERVICE] Réponse reçue du serveur');
      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save authentication data to local storage only if requested
      if (saveToStorage) {
        print('💾 [AUTH_SERVICE] Sauvegarde des données en local...');
        await _storage.saveAuthData(
          token: authResponse.token,
          tokenType: authResponse.tokenType,
          user: authResponse.user,
        );
        print('✅ [AUTH_SERVICE] Données sauvegardées avec succès');

        // Send FCM token to backend after successful registration
        print('📱 [AUTH_SERVICE] Envoi du FCM token au backend...');
        await _sendFcmTokenToBackend();

        // Initialize ConversationStateService after successful registration
        print('💬 [AUTH_SERVICE] Initialisation du ConversationStateService...');
        try {
          // Check if service already exists
          if (!Get.isRegistered<ConversationStateService>()) {
            await Get.putAsync(() async {
              final service = ConversationStateService();
              await service.onInit();
              return service;
            }, permanent: true);
            print('✅ [AUTH_SERVICE] ConversationStateService initialisé avec succès');
          } else {
            print('ℹ️ [AUTH_SERVICE] ConversationStateService déjà initialisé');
          }
        } catch (e) {
          print('⚠️ [AUTH_SERVICE] Erreur lors de l\'initialisation du ConversationStateService: $e');
        }
      } else {
        print('⏭️ [AUTH_SERVICE] Pas de sauvegarde (redirection vers login)');
        print('⏭️ [AUTH_SERVICE] FCM token sera envoyé au prochain login');
      }

      return authResponse;
    } catch (e) {
      print('💥 [AUTH_SERVICE] Erreur lors de l\'inscription: $e');
      rethrow;
    }
  }

  /// Login user
  Future<AuthResponseModel> login({
    required String login, // Can be username, email, or phone
    required String password,
  }) async {
    print('🔐 [AUTH_SERVICE] Début de la connexion');
    print('👤 [AUTH_SERVICE] Login: $login');

    try {
      final response = await _api.post(
        ApiConfig.login,
        data: {
          'login': login,
          'password': password,
        },
      );

      print('✅ [AUTH_SERVICE] Réponse reçue du serveur');
      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save authentication data to local storage
      print('💾 [AUTH_SERVICE] Sauvegarde des données en local...');
      await _storage.saveAuthData(
        token: authResponse.token,
        tokenType: authResponse.tokenType,
        user: authResponse.user,
      );
      print('✅ [AUTH_SERVICE] Données sauvegardées avec succès');

      // Send FCM token to backend after successful login
      print('📱 [AUTH_SERVICE] Envoi du FCM token au backend...');
      await _sendFcmTokenToBackend();

      // Initialize ConversationStateService after successful login
      print('💬 [AUTH_SERVICE] Initialisation du ConversationStateService...');
      try {
        // Check if service already exists
        if (!Get.isRegistered<ConversationStateService>()) {
          await Get.putAsync(() async {
            final service = ConversationStateService();
            await service.onInit();
            return service;
          }, permanent: true);
          print('✅ [AUTH_SERVICE] ConversationStateService initialisé avec succès');
        } else {
          print('ℹ️ [AUTH_SERVICE] ConversationStateService déjà initialisé');
        }
      } catch (e) {
        print('⚠️ [AUTH_SERVICE] Erreur lors de l\'initialisation du ConversationStateService: $e');
      }

      return authResponse;
    } catch (e) {
      print('💥 [AUTH_SERVICE] Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout API
      await _api.post(ApiConfig.logout);
    } catch (e) {
      // Continue with local logout even if API call fails
      print('Logout API failed: $e');
    } finally {
      // Always clear local storage
      await _storage.clearAuthData();

      // NOTE: We don't manually delete controllers here.
      // The calling code should use Get.offAllNamed() to navigate,
      // which will automatically clean up all controllers.
      // This prevents crashes when trying to delete active controllers.
    }
  }

  /// Get current user profile from API
  Future<UserModel> me() async {
    try {
      final response = await _api.get(ApiConfig.me);

      final userData = response.data['user'];
      final user = UserModel.fromJson(
        userData['data'] ?? userData,
      );

      // Update user data in local storage
      await _storage.updateUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh authentication token
  Future<void> refreshToken() async {
    try {
      final response = await _api.post(ApiConfig.refresh);

      final token = response.data['token'];
      final tokenType = response.data['token_type'];

      // Update token in storage
      await _storage.write('auth_token', token);
      await _storage.write('token_type', tokenType);
    } catch (e) {
      // If refresh fails, logout user
      await logout();
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _storage.isLoggedIn() && _storage.getToken() != null;
  }

  /// Get current user from local storage
  UserModel? getCurrentUser() {
    return _storage.getUser();
  }

  /// Get authentication token from local storage
  String? getToken() {
    return _storage.getToken();
  }

  /// Verify token validity by calling /me endpoint
  Future<bool> verifyToken() async {
    print('🔍 [AUTH_SERVICE] Vérification du token...');

    if (!isAuthenticated()) {
      print('❌ [AUTH_SERVICE] Pas de token trouvé');
      return false;
    }

    final token = _storage.getToken();
    print('🔑 [AUTH_SERVICE] Token trouvé: ${token?.substring(0, 20)}...');

    try {
      print('📱 [AUTH_SERVICE] Appel de /auth/me...');
      await me();
      print('✅ [AUTH_SERVICE] Token valide');
      return true;
    } catch (e) {
      // Token is invalid, clear auth data
      print('❌ [AUTH_SERVICE] Token invalide: $e');
      print('🗑️ [AUTH_SERVICE] Suppression des données d\'authentification');
      await _storage.clearAuthData();

      // NOTE: We don't call _cleanupControllers() here because:
      // - We're about to navigate to WELCOMER which will replace all pages
      // - Calling Get.deleteAll() while on HOME would crash the TabController
      // - The navigation will handle cleanup automatically

      return false;
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.put(
        ApiConfig.changePassword,
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPassword,
        },
      );
    } catch (e) {
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
  }) async {
    try {
      final response = await _api.put(
        ApiConfig.updateProfile,
        data: {
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
        },
      );

      final userData = response.data['user'];
      final user = UserModel.fromJson(
        userData['data'] ?? userData,
      );

      // Update user data in local storage
      await _storage.updateUser(user);

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Send FCM token to backend (internal method)
  Future<void> _sendFcmTokenToBackend() async {
    try {
      // Check if FCMService is initialized
      if (!Get.isRegistered<FCMService>()) {
        print('⚠️ [AUTH_SERVICE] FCMService non initialisé, skip envoi FCM token');
        return;
      }

      final fcmService = Get.find<FCMService>();
      final fcmToken = await fcmService.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ [AUTH_SERVICE] Pas de FCM token disponible');
        return;
      }

      print('📱 [AUTH_SERVICE] FCM token récupéré: ${fcmToken.substring(0, 50)}...');
      await updateFcmToken(fcmToken);

      // Subscribe to all topics
      print('📢 [AUTH_SERVICE] Souscription aux topics FCM...');
      await fcmService.subscribeToAllTopics();
      print('✅ [AUTH_SERVICE] Souscription aux topics terminée');
    } catch (e) {
      print('❌ [AUTH_SERVICE] Erreur envoi FCM token: $e');
      // Ne pas rethrow pour ne pas bloquer le login/register
    }
  }

  /// Update FCM token and subscribe to topics
  Future<void> updateFcmToken(String fcmToken) async {
    print('📱 [AUTH_SERVICE] ========================================');
    print('📱 [AUTH_SERVICE] Mise à jour du FCM token...');
    print('📱 [AUTH_SERVICE] Token: ${fcmToken.substring(0, 50)}...');
    print('📱 [AUTH_SERVICE] ========================================');

    try {
      final response = await _api.post(
        ApiConfig.updateFcmToken,
        data: {
          'fcm_token': fcmToken,
        },
      );

      print('✅ [AUTH_SERVICE] Réponse du serveur: ${response.data}');
      print('✅ [AUTH_SERVICE] FCM token mis à jour avec succès');
      print('✅ [AUTH_SERVICE] L\'utilisateur a été souscrit aux topics FCM côté backend');
    } catch (e) {
      print('❌ [AUTH_SERVICE] Erreur lors de la mise à jour du FCM token: $e');
      // Ne pas rethrow pour ne pas bloquer le login/register si FCM échoue
    }
  }
}
