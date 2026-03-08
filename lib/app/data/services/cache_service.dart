import 'dart:convert';
import 'package:weylo/app/data/services/storage_service.dart';
import 'package:weylo/app/data/models/story_feed_item_model.dart';
import 'package:weylo/app/data/models/confession_model.dart';

/// Service de cache local pour les stories et confessions
/// Gère le cache persistant avec expiration de 24h
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final _storage = StorageService();

  // Cache keys
  static const String _storiesCacheKey = 'stories_cache';
  static const String _storiesTimestampKey = 'stories_cache_timestamp';
  static const String _storiesPageKey = 'stories_cache_page';

  static const String _confessionsCacheKey = 'confessions_cache';
  static const String _confessionsTimestampKey = 'confessions_cache_timestamp';
  static const String _confessionsPageKey = 'confessions_cache_page';

  // Durée de validité du cache: 24 heures
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  /// Vérifie si le cache est encore valide (< 24h)
  bool _isCacheValid(String timestampKey) {
    final timestamp = _storage.read<int>(timestampKey);
    if (timestamp == null) return false;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    final isValid = difference < _cacheValidityDuration;

    if (!isValid) {
      print('⏰ [CACHE] Cache expiré: ${difference.inHours}h (max: ${_cacheValidityDuration.inHours}h)');
    } else {
      print('✅ [CACHE] Cache valide: ${difference.inHours}h/${_cacheValidityDuration.inHours}h');
    }

    return isValid;
  }

  /// Nettoie les caches expirés
  Future<void> cleanExpiredCaches() async {
    // Nettoyer le cache des stories si expiré
    if (!_isCacheValid(_storiesTimestampKey)) {
      print('🗑️ [CACHE] Nettoyage du cache stories expiré');
      await clearStoriesCache();
    }

    // Nettoyer le cache des confessions si expiré
    if (!_isCacheValid(_confessionsTimestampKey)) {
      print('🗑️ [CACHE] Nettoyage du cache confessions expiré');
      await clearConfessionsCache();
    }
  }

  // ========== STORIES CACHE ==========

  /// Sauvegarde les stories en cache
  Future<void> saveStoriesCache(List<StoryFeedItemModel> stories, {int page = 1}) async {
    try {
      final jsonList = stories.map((s) => s.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _storage.write(_storiesCacheKey, jsonString);
      await _storage.write(_storiesTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await _storage.write(_storiesPageKey, page);

      print('💾 [CACHE] Stories sauvegardées: ${stories.length} items, page $page');
    } catch (e) {
      print('❌ [CACHE] Erreur sauvegarde stories: $e');
    }
  }

  /// Récupère les stories du cache
  List<StoryFeedItemModel>? getStoriesCache() {
    try {
      if (!_isCacheValid(_storiesTimestampKey)) {
        print('⏰ [CACHE] Cache stories expiré');
        return null;
      }

      final jsonString = _storage.read<String>(_storiesCacheKey);
      if (jsonString == null) {
        print('📭 [CACHE] Aucun cache stories trouvé');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final stories = jsonList
          .map((json) => StoryFeedItemModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final page = _storage.read<int>(_storiesPageKey) ?? 1;
      print('📦 [CACHE] Stories récupérées du cache: ${stories.length} items, page $page');

      return stories;
    } catch (e) {
      print('❌ [CACHE] Erreur lecture cache stories: $e');
      return null;
    }
  }

  /// Récupère la page actuelle du cache stories
  int getStoriesCachedPage() {
    return _storage.read<int>(_storiesPageKey) ?? 1;
  }

  /// Vérifie si le cache stories est valide
  bool isStoriesCacheValid() {
    return _isCacheValid(_storiesTimestampKey);
  }

  /// Supprime le cache des stories
  Future<void> clearStoriesCache() async {
    await _storage.remove(_storiesCacheKey);
    await _storage.remove(_storiesTimestampKey);
    await _storage.remove(_storiesPageKey);
    print('🗑️ [CACHE] Cache stories supprimé');
  }

  // ========== CONFESSIONS CACHE ==========

  /// Sauvegarde les confessions en cache
  Future<void> saveConfessionsCache(List<ConfessionModel> confessions, {int page = 1}) async {
    try {
      final jsonList = confessions.map((c) => c.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _storage.write(_confessionsCacheKey, jsonString);
      await _storage.write(_confessionsTimestampKey, DateTime.now().millisecondsSinceEpoch);
      await _storage.write(_confessionsPageKey, page);

      print('💾 [CACHE] Confessions sauvegardées: ${confessions.length} items, page $page');
    } catch (e) {
      print('❌ [CACHE] Erreur sauvegarde confessions: $e');
    }
  }

  /// Récupère les confessions du cache
  List<ConfessionModel>? getConfessionsCache() {
    try {
      if (!_isCacheValid(_confessionsTimestampKey)) {
        print('⏰ [CACHE] Cache confessions expiré');
        return null;
      }

      final jsonString = _storage.read<String>(_confessionsCacheKey);
      if (jsonString == null) {
        print('📭 [CACHE] Aucun cache confessions trouvé');
        return null;
      }

      final jsonList = json.decode(jsonString) as List;
      final confessions = jsonList
          .map((json) => ConfessionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final page = _storage.read<int>(_confessionsPageKey) ?? 1;
      print('📦 [CACHE] Confessions récupérées du cache: ${confessions.length} items, page $page');

      return confessions;
    } catch (e) {
      print('❌ [CACHE] Erreur lecture cache confessions: $e');
      return null;
    }
  }

  /// Récupère la page actuelle du cache confessions
  int getConfessionsCachedPage() {
    return _storage.read<int>(_confessionsPageKey) ?? 1;
  }

  /// Vérifie si le cache confessions est valide
  bool isConfessionsCacheValid() {
    return _isCacheValid(_confessionsTimestampKey);
  }

  /// Supprime le cache des confessions
  Future<void> clearConfessionsCache() async {
    await _storage.remove(_confessionsCacheKey);
    await _storage.remove(_confessionsTimestampKey);
    await _storage.remove(_confessionsPageKey);
    print('🗑️ [CACHE] Cache confessions supprimé');
  }

  // ========== NETTOYAGE GÉNÉRAL ==========

  /// Supprime tous les caches
  Future<void> clearAllCaches() async {
    await clearStoriesCache();
    await clearConfessionsCache();
    print('🗑️ [CACHE] Tous les caches supprimés');
  }

  /// Obtient des statistiques sur les caches
  Map<String, dynamic> getCacheStats() {
    final storiesValid = isStoriesCacheValid();
    final confessionsValid = isConfessionsCacheValid();

    final storiesTimestamp = _storage.read<int>(_storiesTimestampKey);
    final confessionsTimestamp = _storage.read<int>(_confessionsTimestampKey);

    String? storiesAge;
    String? confessionsAge;

    if (storiesTimestamp != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(storiesTimestamp),
      );
      storiesAge = '${age.inHours}h ${age.inMinutes % 60}min';
    }

    if (confessionsTimestamp != null) {
      final age = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(confessionsTimestamp),
      );
      confessionsAge = '${age.inHours}h ${age.inMinutes % 60}min';
    }

    return {
      'stories': {
        'valid': storiesValid,
        'age': storiesAge,
        'page': _storage.read<int>(_storiesPageKey),
      },
      'confessions': {
        'valid': confessionsValid,
        'age': confessionsAge,
        'page': _storage.read<int>(_confessionsPageKey),
      },
    };
  }
}
