import '../core/api_config.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final _api = ApiService();
  final _storage = StorageService();

  // Maximum number of search history items to keep
  static const int _maxHistoryItems = 20;

  /// Search users
  Future<List<UserModel>> searchUsers({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    print('🔍 [SEARCH_SERVICE] Recherche: "$query"');

    try {
      final response = await _api.get(
        ApiConfig.users,
        queryParameters: {
          'search': query,
          'page': page,
          'per_page': perPage,
        },
      );

      print('✅ [SEARCH_SERVICE] Réponse reçue du serveur');

      final List<dynamic> usersJson = response.data['users'] ?? [];
      final users = usersJson.map((json) => UserModel.fromJson(json)).toList();

      print('📋 [SEARCH_SERVICE] ${users.length} utilisateurs trouvés');

      // Save to search history if not empty
      if (query.trim().isNotEmpty && users.isNotEmpty) {
        await addToSearchHistory(query.trim());
      }

      return users;
    } catch (e) {
      print('💥 [SEARCH_SERVICE] Erreur lors de la recherche: $e');
      rethrow;
    }
  }

  /// Get search history
  Future<List<String>> getSearchHistory() async {
    try {
      final history = _storage.getSearchHistory();
      print('📜 [SEARCH_SERVICE] Historique récupéré: ${history.length} éléments');
      return history;
    } catch (e) {
      print('💥 [SEARCH_SERVICE] Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }

  /// Add to search history
  Future<void> addToSearchHistory(String query) async {
    try {
      final history = await getSearchHistory();

      // Remove if already exists (to avoid duplicates)
      history.remove(query);

      // Add to the beginning
      history.insert(0, query);

      // Keep only the last N items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await _storage.saveSearchHistory(history);
      print('✅ [SEARCH_SERVICE] "$query" ajouté à l\'historique');
    } catch (e) {
      print('💥 [SEARCH_SERVICE] Erreur lors de l\'ajout à l\'historique: $e');
    }
  }

  /// Clear a single item from search history
  Future<void> removeFromSearchHistory(String query) async {
    try {
      final history = await getSearchHistory();
      history.remove(query);
      await _storage.saveSearchHistory(history);
      print('✅ [SEARCH_SERVICE] "$query" supprimé de l\'historique');
    } catch (e) {
      print('💥 [SEARCH_SERVICE] Erreur lors de la suppression de l\'historique: $e');
    }
  }

  /// Clear all search history
  Future<void> clearSearchHistory() async {
    try {
      await _storage.saveSearchHistory([]);
      print('✅ [SEARCH_SERVICE] Historique de recherche effacé');
    } catch (e) {
      print('💥 [SEARCH_SERVICE] Erreur lors de l\'effacement de l\'historique: $e');
    }
  }
}
