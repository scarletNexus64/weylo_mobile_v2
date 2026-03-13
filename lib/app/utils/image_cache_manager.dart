import 'dart:collection';
import 'package:flutter/material.dart';

/// Gestionnaire de cache d'images avec limitation de mémoire
/// Évite les fuites mémoire en limitant le nombre d'images en cache
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  // Cache LRU (Least Recently Used) pour libérer les images les plus anciennes
  final _cache = LinkedHashMap<String, ImageProvider>();

  // Limite du cache (nombre d'images maximum)
  static const int _maxCacheSize = 50;

  // Compteur d'accès pour le LRU
  final _accessCount = <String, int>{};
  int _currentAccessId = 0;

  /// Obtenir une image depuis le cache ou la créer
  ImageProvider getImage(String url) {
    // Si l'image est déjà en cache, la marquer comme récemment utilisée
    if (_cache.containsKey(url)) {
      _accessCount[url] = ++_currentAccessId;
      print('✅ [CACHE] Image trouvée en cache: ${_getTruncatedUrl(url)}');
      return _cache[url]!;
    }

    // Créer une nouvelle image
    final image = NetworkImage(url);
    _addToCache(url, image);

    return image;
  }

  /// Ajouter une image au cache avec gestion LRU
  void _addToCache(String url, ImageProvider image) {
    // Si le cache est plein, supprimer l'image la moins récemment utilisée
    if (_cache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _cache[url] = image;
    _accessCount[url] = ++_currentAccessId;

    print('📦 [CACHE] Image ajoutée au cache: ${_getTruncatedUrl(url)} (${_cache.length}/$_maxCacheSize)');
  }

  /// Supprimer l'image la moins récemment utilisée
  void _evictOldest() {
    // Trouver l'URL avec le plus petit access count
    String? oldestUrl;
    int oldestAccess = _currentAccessId + 1;

    for (final entry in _accessCount.entries) {
      if (entry.value < oldestAccess && _cache.containsKey(entry.key)) {
        oldestAccess = entry.value;
        oldestUrl = entry.key;
      }
    }

    if (oldestUrl != null) {
      _cache.remove(oldestUrl);
      _accessCount.remove(oldestUrl);
      print('🗑️ [CACHE] Image évincée: ${_getTruncatedUrl(oldestUrl)}');

      // Libérer la mémoire de l'image
      try {
        PaintingBinding.instance.imageCache.evict(oldestUrl);
      } catch (e) {
        print('⚠️ [CACHE] Erreur lors de l\'éviction: $e');
      }
    }
  }

  /// Nettoyer tout le cache
  void clearCache() {
    print('🧹 [CACHE] Nettoyage complet du cache (${_cache.length} images)');

    // Libérer toutes les images de la mémoire
    for (final url in _cache.keys) {
      try {
        PaintingBinding.instance.imageCache.evict(url);
      } catch (e) {
        print('⚠️ [CACHE] Erreur lors de l\'éviction de $url: $e');
      }
    }

    _cache.clear();
    _accessCount.clear();
    _currentAccessId = 0;

    // Forcer le garbage collector Flutter
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    print('✅ [CACHE] Cache nettoyé');
  }

  /// Obtenir des statistiques du cache
  Map<String, dynamic> getStats() {
    return {
      'cacheSize': _cache.length,
      'maxCacheSize': _maxCacheSize,
      'memoryUsage': '${(_cache.length * 100 / _maxCacheSize).toStringAsFixed(1)}%',
    };
  }

  /// Tronquer l'URL pour les logs
  String _getTruncatedUrl(String url) {
    if (url.length <= 50) return url;
    return '${url.substring(0, 30)}...${url.substring(url.length - 15)}';
  }

  /// Pré-charger une image
  Future<void> precacheImageUrl(String url, BuildContext context) async {
    try {
      final image = getImage(url);
      await precacheImage(image, context);
      print('✅ [CACHE] Image pré-chargée: ${_getTruncatedUrl(url)}');
    } catch (e) {
      print('⚠️ [CACHE] Erreur lors du pré-chargement: $e');
    }
  }

  /// Supprimer une image spécifique du cache
  void removeImage(String url) {
    if (_cache.containsKey(url)) {
      _cache.remove(url);
      _accessCount.remove(url);

      try {
        PaintingBinding.instance.imageCache.evict(url);
      } catch (e) {
        print('⚠️ [CACHE] Erreur lors de la suppression: $e');
      }

      print('🗑️ [CACHE] Image supprimée: ${_getTruncatedUrl(url)}');
    }
  }
}
