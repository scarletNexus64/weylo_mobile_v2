import 'package:get/get.dart';
import 'package:weylo/app/data/services/group_service.dart';
import 'package:weylo/app/data/models/group_model.dart';
import 'package:weylo/app/data/models/group_category_model.dart';
import 'dart:async';

enum GroupTab { myGroups, discover }

class GroupeController extends GetxController {
  final GroupService _groupService = GroupService();
  Timer? _searchDebounce;

  // Tab selection
  final selectedTab = GroupTab.myGroups.obs;

  // My Groups - États
  final isLoadingMyGroups = false.obs;
  final isLoadingMoreMyGroups = false.obs;
  final hasErrorMyGroups = false.obs;
  final errorMessageMyGroups = ''.obs;

  // My Groups - Données
  final myGroups = <GroupModel>[].obs;

  // My Groups - Pagination
  int myGroupsCurrentPage = 1;
  int myGroupsLastPage = 1;
  final canLoadMoreMyGroups = false.obs;

  // Discover Groups - États
  final isLoadingDiscoverGroups = false.obs;
  final isLoadingMoreDiscoverGroups = false.obs;
  final hasErrorDiscoverGroups = false.obs;
  final errorMessageDiscoverGroups = ''.obs;

  // Discover Groups - Données
  final discoverGroups = <GroupModel>[].obs;

  // Discover Groups - Pagination
  int discoverGroupsCurrentPage = 1;
  int discoverGroupsLastPage = 1;
  final canLoadMoreDiscoverGroups = false.obs;

  // Categories
  final categories = <GroupCategoryModel>[].obs;
  final isLoadingCategories = false.obs;
  final Rxn<int> selectedCategoryId = Rxn<int>();

  // Search
  final searchQuery = ''.obs;
  final isSearching = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyGroups();
    loadCategories();
    // Charger tous les groupes découverte dès le départ
    loadDiscoverGroups();
  }

  void setTab(GroupTab tab) {
    selectedTab.value = tab;
    // Plus besoin de charger ici car on charge dès le départ dans onInit()
  }

  /// Charger les catégories depuis l'API
  Future<void> loadCategories() async {
    if (isLoadingCategories.value) return;

    isLoadingCategories.value = true;

    try {
      final loadedCategories = await _groupService.getCategories();
      categories.value = loadedCategories;
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Sélectionner une catégorie et filtrer les groupes
  void selectCategory(int? categoryId) {
    selectedCategoryId.value = categoryId;
    // Recharger les groupes avec le nouveau filtre
    loadDiscoverGroups(refresh: true);
  }

  /// Charger mes groupes depuis l'API
  Future<void> loadMyGroups({bool refresh = false}) async {
    if (refresh) {
      myGroupsCurrentPage = 1;
      myGroups.clear();
    }

    if (isLoadingMyGroups.value || isLoadingMoreMyGroups.value) return;

    refresh ? isLoadingMyGroups.value = true : isLoadingMoreMyGroups.value = true;
    hasErrorMyGroups.value = false;

    try {
      final response = await _groupService.getMyGroups(
        page: myGroupsCurrentPage,
        perPage: 20,
      );

      if (refresh) {
        myGroups.value = response.groups;
      } else {
        myGroups.addAll(response.groups);
      }

      myGroupsCurrentPage = response.meta.currentPage;
      myGroupsLastPage = response.meta.lastPage;
      canLoadMoreMyGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorMyGroups.value = true;
      errorMessageMyGroups.value = e.toString();
      print('Error loading my groups: $e');
    } finally {
      isLoadingMyGroups.value = false;
      isLoadingMoreMyGroups.value = false;
    }
  }

  /// Charger plus de mes groupes (pagination)
  Future<void> loadMoreMyGroups() async {
    if (canLoadMoreMyGroups.value && !isLoadingMoreMyGroups.value) {
      myGroupsCurrentPage++;
      await loadMyGroups();
    }
  }

  /// Rafraîchir mes groupes
  Future<void> refreshMyGroups() async {
    await loadMyGroups(refresh: true);
  }

  /// Charger les groupes à découvrir depuis l'API
  Future<void> loadDiscoverGroups({bool refresh = false}) async {
    if (refresh) {
      discoverGroupsCurrentPage = 1;
      discoverGroups.clear();
    }

    if (isLoadingDiscoverGroups.value || isLoadingMoreDiscoverGroups.value) return;

    refresh ? isLoadingDiscoverGroups.value = true : isLoadingMoreDiscoverGroups.value = true;
    hasErrorDiscoverGroups.value = false;

    try {
      final response = await _groupService.discoverGroups(
        page: discoverGroupsCurrentPage,
        perPage: 10,
        categoryId: selectedCategoryId.value,
      );

      if (refresh) {
        discoverGroups.value = response.groups;
      } else {
        discoverGroups.addAll(response.groups);
      }

      discoverGroupsCurrentPage = response.meta.currentPage;
      discoverGroupsLastPage = response.meta.lastPage;
      canLoadMoreDiscoverGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorDiscoverGroups.value = true;
      errorMessageDiscoverGroups.value = e.toString();
      print('Error loading discover groups: $e');
    } finally {
      isLoadingDiscoverGroups.value = false;
      isLoadingMoreDiscoverGroups.value = false;
    }
  }

  /// Charger plus de groupes à découvrir (pagination)
  Future<void> loadMoreDiscoverGroups() async {
    if (canLoadMoreDiscoverGroups.value && !isLoadingMoreDiscoverGroups.value) {
      discoverGroupsCurrentPage++;
      await loadDiscoverGroups();
    }
  }

  /// Rafraîchir les groupes à découvrir
  Future<void> refreshDiscoverGroups() async {
    await loadDiscoverGroups(refresh: true);
  }

  /// Rechercher des groupes avec debounce
  void searchGroups(String query) {
    searchQuery.value = query;

    // Annuler le précédent timer s'il existe
    _searchDebounce?.cancel();

    // Si la recherche est vide, recharger tous les groupes
    if (query.trim().isEmpty) {
      loadDiscoverGroups(refresh: true);
      return;
    }

    // Ajouter un délai de 500ms avant de lancer la recherche
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Effectuer la recherche
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    isSearching.value = true;
    discoverGroupsCurrentPage = 1;
    discoverGroups.clear();
    hasErrorDiscoverGroups.value = false;

    try {
      final response = await _groupService.searchGroups(
        search: query,
        page: 1,
        perPage: 10,
        categoryId: selectedCategoryId.value,
      );

      discoverGroups.value = response.groups;
      discoverGroupsCurrentPage = response.meta.currentPage;
      discoverGroupsLastPage = response.meta.lastPage;
      canLoadMoreDiscoverGroups.value = response.meta.hasMorePages;
    } catch (e) {
      hasErrorDiscoverGroups.value = true;
      errorMessageDiscoverGroups.value = e.toString();
      print('Error searching groups: $e');
    } finally {
      isSearching.value = false;
    }
  }

  /// Rejoindre un groupe public par ID
  Future<bool> joinGroupById(int groupId) async {
    try {
      final joinedGroup = await _groupService.joinGroupById(groupId);

      // Ajouter le groupe aux "Mes groupes"
      myGroups.insert(0, joinedGroup);

      // Retirer le groupe de la liste discover
      discoverGroups.removeWhere((g) => g.id == groupId);

      Get.snackbar(
        'Succès',
        'Vous avez rejoint le groupe avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejoindre le groupe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  /// Rejoindre un groupe privé par code d'invitation
  Future<bool> joinGroupByCode(String inviteCode) async {
    if (inviteCode.trim().isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez entrer un code d\'invitation',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    }

    try {
      final joinedGroup = await _groupService.joinGroupByCode(inviteCode.trim());

      // Ajouter le groupe aux "Mes groupes"
      myGroups.insert(0, joinedGroup);

      Get.snackbar(
        'Succès',
        'Vous avez rejoint le groupe avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );

      // Changer de tab pour afficher les groupes rejoints
      selectedTab.value = GroupTab.myGroups;

      return true;
    } catch (e) {
      String errorMessage = 'Impossible de rejoindre le groupe';

      // Parser l'erreur pour afficher un message plus explicite
      if (e.toString().contains('404')) {
        errorMessage = 'Code d\'invitation invalide';
      } else if (e.toString().contains('déjà membre')) {
        errorMessage = 'Vous êtes déjà membre de ce groupe';
      } else if (e.toString().contains('limite')) {
        errorMessage = 'Le groupe a atteint sa limite de membres';
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 3),
      );
      return false;
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
