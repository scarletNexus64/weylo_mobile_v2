import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/search_service.dart';
import '../../../data/services/auth_service.dart';

class SearchController extends GetxController {
  final _searchService = SearchService();
  final _authService = AuthService();

  // Search query
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  // Search results
  final searchResults = <UserModel>[].obs;
  final isSearching = false.obs;
  final hasSearched = false.obs;

  // Search history
  final searchHistory = <String>[].obs;

  // Pagination
  int currentPage = 1;
  final hasMoreResults = true.obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 [SearchController] onInit called');
    loadSearchHistory();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load search history from storage
  Future<void> loadSearchHistory() async {
    try {
      final history = await _searchService.getSearchHistory();
      searchHistory.value = history;
      print('✅ [SearchController] ${history.length} items loaded from history');
    } catch (e) {
      print('💥 [SearchController] Error loading search history: $e');
    }
  }

  /// Perform search
  Future<void> search({String? query}) async {
    final searchText = query ?? searchQuery.value;

    if (searchText.trim().isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }

    print('🔍 [SearchController] Searching for: "$searchText"');

    try {
      isSearching.value = true;
      currentPage = 1;

      final results = await _searchService.searchUsers(
        query: searchText,
        page: currentPage,
      );

      // Filter out current user from search results
      final currentUser = _authService.getCurrentUser();
      final filteredResults = currentUser != null
          ? results.where((user) => user.id != currentUser.id).toList()
          : results;

      searchResults.value = filteredResults;
      hasSearched.value = true;
      hasMoreResults.value = results.length >= 20; // If we got full page, there might be more

      // Reload history (in case search was added)
      await loadSearchHistory();

      print('✅ [SearchController] Found ${filteredResults.length} results (${results.length - filteredResults.length} filtered)');
    } catch (e) {
      print('💥 [SearchController] Search error: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de rechercher les utilisateurs',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isSearching.value = false;
    }
  }

  /// Search from history item
  Future<void> searchFromHistory(String query) async {
    searchQuery.value = query;
    searchController.text = query;
    await search(query: query);
  }

  /// Remove item from history
  Future<void> removeFromHistory(String query) async {
    try {
      await _searchService.removeFromSearchHistory(query);
      await loadSearchHistory();
      print('✅ [SearchController] Removed "$query" from history');
    } catch (e) {
      print('💥 [SearchController] Error removing from history: $e');
    }
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    try {
      await _searchService.clearSearchHistory();
      searchHistory.clear();
      print('✅ [SearchController] Search history cleared');
      Get.snackbar(
        'Historique effacé',
        'Votre historique de recherche a été supprimé',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('💥 [SearchController] Error clearing history: $e');
    }
  }

  /// Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    searchResults.clear();
    hasSearched.value = false;
  }

  /// Navigate to user profile
  void navigateToProfile(UserModel user) {
    // Navigate to user profile
    Get.toNamed('/user-profile', arguments: user);
  }
}
