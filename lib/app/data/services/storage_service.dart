import 'package:get_storage/get_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = GetStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  /// Initialize storage
  static Future<void> init() async {
    await GetStorage.init();
  }

  /// Save authentication data
  Future<void> saveAuthData({
    required String token,
    required String tokenType,
    required UserModel user,
  }) async {
    print('💾 [STORAGE] Sauvegarde des données d\'authentification...');
    print('🔑 [STORAGE] Token: ${token.substring(0, 20)}...');
    print('👤 [STORAGE] User: ${user.username} (${user.firstName})');

    await _storage.write(_tokenKey, token);
    await _storage.write(_tokenTypeKey, tokenType);
    await _storage.write(_userKey, user.toJson());
    await _storage.write(_isLoggedInKey, true);

    print('✅ [STORAGE] Données sauvegardées avec succès');
  }

  /// Get saved token
  String? getToken() {
    final token = _storage.read(_tokenKey);
    if (token != null) {
      print('🔑 [STORAGE] Token récupéré: ${token.substring(0, 20)}...');
    } else {
      print('❌ [STORAGE] Aucun token trouvé');
    }
    return token;
  }

  /// Get token type
  String? getTokenType() {
    return _storage.read(_tokenTypeKey) ?? 'Bearer';
  }

  /// Get full authorization header value
  String? getAuthHeader() {
    final token = getToken();
    if (token == null) return null;
    return '${getTokenType()} $token';
  }

  /// Get saved user data
  UserModel? getUser() {
    final userData = _storage.read(_userKey);
    if (userData == null) {
      print('❌ [STORAGE] Aucun utilisateur trouvé');
      return null;
    }
    final user = UserModel.fromJson(Map<String, dynamic>.from(userData));
    print('👤 [STORAGE] Utilisateur récupéré: ${user.username} (${user.firstName})');
    return user;
  }

  /// Update user data
  Future<void> updateUser(UserModel user) async {
    await _storage.write(_userKey, user.toJson());
  }

  /// Check if user is logged in
  bool isLoggedIn() {
    return _storage.read(_isLoggedInKey) ?? false;
  }

  /// Clear all authentication data (logout)
  Future<void> clearAuthData() async {
    print('🗑️ [STORAGE] Suppression des données d\'authentification...');
    await _storage.remove(_tokenKey);
    await _storage.remove(_tokenTypeKey);
    await _storage.remove(_userKey);
    await _storage.write(_isLoggedInKey, false);
    print('✅ [STORAGE] Données supprimées avec succès');
  }

  /// Clear all storage data
  Future<void> clearAll() async {
    await _storage.erase();
  }

  /// Save any key-value pair
  Future<void> write(String key, dynamic value) async {
    await _storage.write(key, value);
  }

  /// Read any key
  T? read<T>(String key) {
    return _storage.read<T>(key);
  }

  /// Remove any key
  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  /// Check if key exists
  bool hasData(String key) {
    return _storage.hasData(key);
  }

  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted() async {
    print('✅ [STORAGE] Marquage de l\'onboarding comme terminé');
    await _storage.write(_onboardingCompletedKey, true);
  }

  /// Check if onboarding has been completed
  bool isOnboardingCompleted() {
    final completed = _storage.read(_onboardingCompletedKey) ?? false;
    print('🔍 [STORAGE] Onboarding complété: $completed');
    return completed;
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    print('🔄 [STORAGE] Réinitialisation de l\'onboarding');
    await _storage.remove(_onboardingCompletedKey);
  }
}
